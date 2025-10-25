variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "droplet_name" {
  description = "Name of the droplet"
  type        = string
  default     = "openvpn-server"
}

variable "ssh_key_name" {
  description = "Name for the SSH key to be created in DigitalOcean"
  type        = string
  default     = "openvpn-ssh-key"
}

variable "openvpn_port" {
  description = "OpenVPN server port"
  type        = number
  default     = 1194
}

variable "openvpn_protocol" {
  description = "OpenVPN protocol (udp or tcp)"
  type        = string
  default     = "udp"
}

variable "client_name" {
  description = "Name for the first OpenVPN client"
  type        = string
  default     = "client"
}