terraform {
  required_version = ">= 1.5.0"

  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.119.0"
    }
  }
}

provider "stackit" {
  default_region = var.region
  # Authentication is picked up from the environment, see the README.
  # e.g. STACKIT_SERVICE_ACCOUNT_KEY_PATH=/path/to/sa-key.json
}

# Look up the most recent public Ubuntu 24.04 image, so we don't have to hard code an image ID.
data "stackit_image_v2" "ubuntu" {
  project_id = var.project_id
  filter = {
    distro  = "ubuntu"
    version = "24.04"
  }
}

resource "stackit_key_pair" "veilid" {
  name       = "veilid-key"
  public_key = chomp(var.ssh_public_key)
}

resource "stackit_network_interface" "veilid" {
  for_each           = toset(var.availability_zones)
  project_id         = var.project_id
  name               = "veilid-nic-${each.key}"
  network_id         = stackit_network.veilid.network_id
  security_group_ids = [stackit_security_group.veilid.security_group_id]
}

resource "stackit_server" "veilid" {
  # I used a for_each here so it's easy to run a node in more than one availability zone,
  # even though the default is to only run one VM.
  for_each          = toset(var.availability_zones)
  project_id        = var.project_id
  name              = "veilid-node-${each.key}"
  availability_zone = each.key
  # veilid-server is a super low resource consumer, so the smallest flavor is plenty
  machine_type = var.machine_type
  keypair_name = stackit_key_pair.veilid.name

  boot_volume = {
    size                  = var.boot_volume_size
    source_type           = "image"
    source_id             = data.stackit_image_v2.ubuntu.image_id
    delete_on_termination = true
  }

  network_interfaces = [
    stackit_network_interface.veilid[each.key].network_interface_id
  ]

  # this is the cloud init script used to install and configure the veilid-server
  user_data = file("${path.module}/setup-veilid.yaml")

  lifecycle {
    # a newer Ubuntu image being published shouldn't destroy the node (and all its DHT data),
    # since veilid gets updated in place by the cron job in the cloud init script anyway.
    ignore_changes = [boot_volume]
  }
}

# Each node gets its own public IPv4 address, which is 1:1 NATed to the private address of the NIC.
resource "stackit_public_ip" "veilid" {
  for_each             = toset(var.availability_zones)
  project_id           = var.project_id
  network_interface_id = stackit_network_interface.veilid[each.key].network_interface_id
}
