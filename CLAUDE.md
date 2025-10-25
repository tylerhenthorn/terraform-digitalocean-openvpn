# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Terraform configuration for automated deployment of OpenVPN server on DigitalOcean using Terraform Cloud for remote state management.

## Common Commands

### Deployment
```bash
make apply          # Full deployment (init + plan + apply)
make destroy        # Tear down all infrastructure
```

### Post-Deployment Operations
```bash
make client-config  # Download client .ovpn file (retrieves SSH key from state first)
make ssh           # SSH into server (retrieves SSH key from state first)
make install-logs  # View cloud-init logs to monitor OpenVPN installation
```

### Development
```bash
make plan          # Preview changes without applying
terraform output   # View all outputs from state
terraform output -raw ssh_private_key > key.pem  # Extract SSH key manually
```

## Architecture Overview

### State Management Strategy
- **Remote State**: Stored in Terraform Cloud (org: TylerHenthorn, workspace: openvpn-server)
- **Critical**: SSH private keys are stored in state as sensitive outputs - state file is the only source
- **Pattern**: Makefile commands extract values from state on-demand rather than storing locally

### Key Architectural Decisions

1. **Zero-Touch Provisioning**: Cloud-init handles complete OpenVPN setup including PKI generation
2. **Dynamic SSH Keys**: Generated at deploy time via `tls_private_key`, no pre-existing keys required
3. **Single-File Client Config**: `.ovpn` files contain embedded certificates for portability
4. **Firewall-First Security**: DigitalOcean cloud firewall + iptables for defense in depth

### Resource Dependencies
```
tls_private_key.ssh → digitalocean_ssh_key.main → digitalocean_droplet.openvpn
                                                      ↓
                                                digitalocean_firewall.openvpn
                                                      ↓
                                                null_resource.wait_for_server
```

### Cloud-Init Workflow
The `cloud-init.yaml` file is templated with Terraform variables and performs:
1. Easy-RSA PKI initialization with batch mode (`EASYRSA_BATCH=yes`)
2. Certificate generation (CA, server, client, DH params, TLS auth)
3. OpenVPN server configuration with NAT/masquerading
4. Client configuration generation with embedded certificates

**Important**: Cloud-init runs asynchronously. The `wait_for_server` resource polls for completion (max 10 minutes).

## Non-Obvious Implementation Details

### Template Variables in cloud-init.yaml
- `${client_name}`, `${openvpn_port}`, `${openvpn_protocol}` are injected via `templatefile()`
- Public IP is fetched twice using `curl ifconfig.me` due to separate script blocks

### SSH Key Retrieval Pattern
```bash
terraform output -raw ssh_private_key > openvpn-ssh.pem
chmod 600 openvpn-ssh.pem
```
This is wrapped in `make ssh-key` and called automatically by other Make targets.

### Firewall Configuration
- DigitalOcean firewall: Allows SSH (22) and OpenVPN (default UDP 1194)
- iptables NAT: Masquerades 10.8.0.0/24 for internet access through VPN
- Full tunnel mode: `redirect-gateway def1 bypass-dhcp` routes all client traffic

### Certificate Expiration
- All certificates expire in 3650 days (10 years)
- No automatic rotation mechanism - manual renewal required

## Configuration Constraints

### Required Variables
- `do_token`: DigitalOcean API token (sensitive, no default)

### Defaults That Matter
- Droplet size: `s-1vcpu-512mb-10gb` (minimal, ~$4/month)
- OpenVPN subnet: `10.8.0.0/24`
- DNS servers pushed to clients: `8.8.8.8`, `8.8.4.4` (Google)
- Single client certificate generated: `client`

### Backend Configuration
The `backend.tf` file hardcodes the Terraform Cloud organization and workspace. For different deployments, you must edit this file or use partial backend configuration.

## Common Issues and Solutions

### Client Config Not Available
- Cloud-init takes 3-5 minutes to complete
- Check with `make install-logs` to monitor progress
- Verify with: `ssh -i openvpn-ssh.pem root@$(terraform output -raw droplet_ip) "ls -la /root/*.ovpn"`

### State-Related Issues
- Lost state = lost SSH access (droplet still exists but inaccessible)
- State is backed up in Terraform Cloud
- Can import existing resources if needed: `terraform import digitalocean_droplet.openvpn <droplet-id>`

### Configuration Changes
- Cloud-init doesn't support re-runs
- Must `make destroy` then `make apply` for configuration changes
- Alternative: SSH in and manually modify `/etc/openvpn/server.conf`

## Adding More Clients

Current setup generates only `client`. To add more clients via SSH:

```bash
make ssh
cd /etc/openvpn/easy-rsa
./easyrsa --batch build-client-full client2 nopass
# Then create .ovpn file similar to client
```