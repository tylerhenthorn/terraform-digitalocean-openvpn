# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload SSH public key to DigitalOcean
resource "digitalocean_ssh_key" "main" {
  name       = var.ssh_key_name
  public_key = tls_private_key.ssh.public_key_openssh
}

# This resource is only used to track the SSH key in state
# When using remote execution, files are not created locally
resource "null_resource" "ssh_key_tracker" {
  triggers = {
    private_key = tls_private_key.ssh.private_key_pem
    public_key  = tls_private_key.ssh.public_key_openssh
  }
}

# Create a DigitalOcean droplet
resource "digitalocean_droplet" "openvpn" {
  name     = var.droplet_name
  region   = var.region
  size     = "s-1vcpu-512mb-10gb"
  image    = "ubuntu-22-04-x64"
  ssh_keys = [digitalocean_ssh_key.main.id]

  # Use cloud-init for initial setup
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    openvpn_port     = var.openvpn_port
    openvpn_protocol = var.openvpn_protocol
    client_name      = var.client_name
  })

  tags = ["openvpn"]
}

# Create a firewall for the OpenVPN server
resource "digitalocean_firewall" "openvpn" {
  name = "openvpn-firewall"

  droplet_ids = [digitalocean_droplet.openvpn.id]

  # Allow SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow OpenVPN
  inbound_rule {
    protocol         = var.openvpn_protocol
    port_range       = tostring(var.openvpn_port)
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Wait for server to be ready
resource "null_resource" "wait_for_server" {
  depends_on = [digitalocean_droplet.openvpn]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.openvpn.ipv4_address
      private_key = tls_private_key.ssh.private_key_pem
    }

    inline = [
      "echo 'Waiting for OpenVPN installation to complete...'",
      "max_attempts=20",
      "attempt=1",
      "while [ $attempt -le $max_attempts ]; do",
      "  if [ -f /root/${var.client_name}.ovpn ]; then",
      "    echo 'Client configuration file is ready!'",
      "    echo 'File location: /root/${var.client_name}.ovpn'",
      "    break",
      "  else",
      "    echo \"Attempt $attempt: Waiting for client config...\"",
      "    sleep 30",
      "  fi",
      "  attempt=$((attempt + 1))",
      "done",
      "if [ ! -f /root/${var.client_name}.ovpn ]; then",
      "  echo 'ERROR: Client configuration file not found after waiting'",
      "  exit 1",
      "fi"
    ]
  }
}