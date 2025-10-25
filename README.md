# terraform-digitalocean-openvpn

Quickly deploys a VPN server using Terraform Cloud and DigitalOcean.  

A simple `make` creates the server and the client config, and `make destroy` deletes it.  

DigitalOcean is fast, and if you destroy after using it costs almost nothing.  

## Prerequisites

- Terraform >= 1.0
- DigitalOcean account
- Terraform Cloud account (free tier works)
- `make` command available on your system

## Terraform Cloud Workspace Setup

### 1. Create Workspace

1. Log in to [Terraform Cloud](https://app.terraform.io)
2. Create a new workspace:
   - Click **"New workspace"**
   - Select **"CLI-driven workflow"**
   - Name your workspace (e.g., `openvpn-server`)
   - Click **"Create workspace"**

### 2. Configure Workspace Settings

Navigate to your workspace settings:

1. **Execution Mode**: Ensure it's set to "Remote" (default)
2. **Terraform Version**: Select >= 1.0 or "latest"

### 3. Add Environment Variables

In your workspace, go to **Variables** and add:

#### Required Variable:
- **Variable category**: Environment variable
- **Key**: `DO_TOKEN`
- **Value**: Your DigitalOcean API token
- **Sensitive**: ✓ (check this box)

To get your DigitalOcean API token:
1. Log in to [DigitalOcean](https://www.digitalocean.com)
2. Go to **API** → **Tokens/Keys**
3. Generate a new token with read/write access

### 4. Update Terraform Configuration

Edit the `backend.tf` with your Terraform Cloud organization and workspace:

```hcl
terraform {
  cloud {
    organization = "your-organization-name"

    workspaces {
      name = "your-workspace-name"
    }
  }
}
```

### 5. Configure Terraform Cloud Authentication

On your local machine:

```bash
terraform login
```

Follow the prompts to authenticate with Terraform Cloud.

## Deployment

### Create the OpenVPN Server

```bash
make
```

This command will:
1. Initialize Terraform providers and modules
2. Deploy the OpenVPN server
3. Download the client configuration file (`client.ovpn`)

### Alternative Commands

If you prefer to run steps separately:
```bash
make init           # Initialize the Terraform repository 
make apply          # Deploy server 
make client-config  # Download OpenVPN client config 
```

### Server Management

**SSH into the server**:
```bash
make ssh
```

**View installation logs**:
```bash
make install-logs
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make` | **Default**: Deploy server and download client config |
| `make init` | Initialize Terraform providers and modules |
| `make plan` | Preview infrastructure changes |
| `make apply` | Deploy the OpenVPN server only |
| `make destroy` | Destroy all resources |
| `make ssh-key` | Retrieve SSH private key from Terraform state |
| `make client-config` | Download OpenVPN client configuration |
| `make ssh` | SSH into the OpenVPN server |
| `make install-logs` | View cloud-init installation logs |

## Client Configuration

### Connect to OpenVPN

1. Install an OpenVPN client:
   - **macOS**: [Tunnelblick](https://tunnelblick.net/) or [OpenVPN Connect](https://openvpn.net/connect-docs/connect-for-macos.html)
   - **Windows**: [OpenVPN GUI](https://openvpn.net/community-downloads/)
   - **Linux**: `sudo apt install openvpn` or equivalent

2. Import the `client.ovpn` configuration file into your OpenVPN client

3. Connect to your VPN server

## Customization

### Variables

You can customize the deployment by creating a `terraform.tfvars` file:

```hcl
# Droplet configuration
droplet_name = "my-vpn-server"
region = "nyc3"  # DigitalOcean region

# OpenVPN configuration
openvpn_port = 1194
openvpn_protocol = "udp"
```

### Available Regions

Common DigitalOcean regions:
- `nyc1`, `nyc3` - New York
- `sfo3` - San Francisco
- `ams3` - Amsterdam
- `sgp1` - Singapore
- `lon1` - London
- `fra1` - Frankfurt
- `tor1` - Toronto
- `blr1` - Bangalore

## Cleanup

To destroy all resources:

```bash
make destroy
```
