resource "stackit_network" "veilid" {
  project_id         = var.project_id
  name               = "veilid-network"
  ipv4_prefix_length = 24
}

resource "stackit_security_group" "veilid" {
  project_id  = var.project_id
  name        = "veilid-node"
  description = "Inbound SSH and veilid traffic. New security groups allow all egress by default."
  stateful    = true
}

resource "stackit_security_group_rule" "ssh" {
  for_each          = toset(var.ssh_allowed_cidrs)
  project_id        = var.project_id
  security_group_id = stackit_security_group.veilid.security_group_id
  description       = "SSH from ${each.key}"
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = each.key
  protocol = {
    name = "tcp"
  }
  port_range = {
    min = 22
    max = 22
  }
}

# veilid uses port 5150 for both TCP (and websockets) and UDP
resource "stackit_security_group_rule" "veilid" {
  for_each          = toset(["tcp", "udp"])
  project_id        = var.project_id
  security_group_id = stackit_security_group.veilid.security_group_id
  description       = "veilid ${each.key}"
  direction         = "ingress"
  ether_type        = "IPv4"
  ip_range          = "0.0.0.0/0"
  protocol = {
    name = each.key
  }
  port_range = {
    min = 5150
    max = 5150
  }
}
