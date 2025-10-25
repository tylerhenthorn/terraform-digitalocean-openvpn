output "droplet_ip" {
  description = "Public IP address of the OpenVPN server"
  value       = digitalocean_droplet.openvpn.ipv4_address
}

output "droplet_id" {
  description = "ID of the OpenVPN droplet"
  value       = digitalocean_droplet.openvpn.id
}

output "droplet_name" {
  description = "Name of the OpenVPN droplet"
  value       = digitalocean_droplet.openvpn.name
}

output "droplet_region" {
  description = "Region where the OpenVPN server is deployed"
  value       = digitalocean_droplet.openvpn.region
}

output "ssh_private_key" {
  description = "SSH private key for connecting to the server"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}