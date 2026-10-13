variable "project_id" {
  description = "ID of the STACKIT project to create the veilid node(s) in."
  type        = string
}

variable "ssh_public_key" {
  description = "Contents of the public SSH key used to log in to the node(s) as the `ubuntu` user."
  type        = string
}

variable "region" {
  description = "STACKIT region to deploy into."
  type        = string
  default     = "eu01"
}

variable "availability_zones" {
  description = "Availability zone(s) to run a veilid node in. One node is created per zone."
  type        = list(string)
  # other options in eu01 are "eu01-2", "eu01-3" and "eu01-m" (metro)
  default = ["eu01-1"]
}

variable "machine_type" {
  description = "STACKIT machine type (flavor) for the node(s). See https://docs.stackit.cloud for the list of virtual machine flavors."
  type        = string
  default     = "g2i.1"
}

variable "boot_volume_size" {
  description = "Size of the boot volume in GB."
  type        = number
  default     = 20
}

variable "ssh_allowed_cidrs" {
  description = "IPv4 CIDR ranges that are allowed to SSH into the node(s). Lock this down to your own IP if you can."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
