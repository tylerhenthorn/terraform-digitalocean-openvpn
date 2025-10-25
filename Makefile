.PHONY: all init plan apply destroy ssh-key client-config ssh install-logs

# Use bash for advanced features
SHELL := /bin/bash

# Default target - deploy server and download client config
all: init apply client-config

# Initialize Terraform
init:
	terraform init

# Plan Terraform changes
plan:
	terraform plan

# Apply Terraform configuration
apply: 
	terraform apply -auto-approve

# Destroy all resources
destroy:
	terraform destroy -auto-approve

# Retrieve SSH key from Terraform state (for manual use)
ssh-key:
	@echo "Retrieving SSH private key from Terraform state..."
	@terraform output -raw ssh_private_key > openvpn-ssh.pem
	@chmod 600 openvpn-ssh.pem
	@echo "SSH key saved to openvpn-ssh.pem"

# Download client configuration from server
client-config: ssh-key
	@echo "Downloading OpenVPN client configuration..."
	@scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		-i openvpn-ssh.pem \
		root@$$(terraform output -raw droplet_ip):/root/client.ovpn \
		./client.ovpn
	@echo "Client configuration saved to client.ovpn"
	@rm -f openvpn-ssh.pem

# SSH into the OpenVPN server
ssh: ssh-key
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		-i openvpn-ssh.pem \
		root@$$(terraform output -raw droplet_ip) ; \
	rm -f openvpn-ssh.pem

# View cloud-init logs to monitor OpenVPN installation
install-logs: ssh-key
	@echo "Fetching OpenVPN installation logs..."
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		-i openvpn-ssh.pem \
		root@$$(terraform output -raw droplet_ip) \
		"tail -n 100 -f /var/log/cloud-init-output.log" ; \
	rm -f openvpn-ssh.pem