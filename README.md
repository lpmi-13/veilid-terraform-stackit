# Veilid Terraform STACKIT

[Veilid-Server](https://veilid.com) is a super low resource consumer, so we can easily run a small node on [STACKIT](https://www.stackit.de) to sustain and grow the network.

This terraform configuration will help you do that! It's a port of [veilid-terraform-gcp](https://github.com/lpmi-13/veilid-terraform-gcp).

## What gets created

- a private network (`veilid-network`) with a `/24` IPv4 range
- a stateful security group allowing inbound SSH (`22/tcp`) and veilid (`5150/tcp` + `5150/udp`). Outbound traffic is allowed by default on new STACKIT security groups.
- an SSH key pair
- one Ubuntu 24.04 server per availability zone (default: one node in `eu01-1`), each with its own network interface and public IPv4 address
- a cloud-init script (`setup-veilid.yaml`) that installs `veilid-server` and `veilid-cli` from the official veilid apt repo, starts the service, and sets up a daily cron job to upgrade just those two packages

## Cost

STACKIT doesn't have a free tier, so this will cost a small amount each month: the server (the default `g2i.1` flavor), its 20GB boot volume, and the public IPv4 address. Check the [STACKIT pricing calculator](https://calculator.stackit.cloud) for current prices. If you want something cheaper, change `machine_type` to a smaller flavor (you can list them with the `stackit_machine_types` data source or the STACKIT portal).

## Setting up access

1. Sign up for a STACKIT account and create a project (or use an existing one). Copy the project ID.

2. Create a service account in the project, give it a role that can manage IaaS resources (e.g. `editor`), and create a service account key. Download the JSON key file.

3. Point the provider at the key:

```sh
export STACKIT_SERVICE_ACCOUNT_KEY_PATH=/path/to/sa-key.json
```

> See the [provider docs](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs) for other ways to authenticate.

## Running the terraform commands

1. Copy the example variables file and fill in your project ID and public SSH key:

```sh
cp terraform.tfvars.example terraform.tfvars
```

> If you want to use a separate SSH key, then generate one in this folder like `ssh-keygen -t ed25519 -o -a 100 -f veilid-key` and use the contents of `veilid-key.pub`.

2. (optional) Change `availability_zones` if you want the node somewhere else, or want more than one node (one node is created per zone, and each one costs money!). Lock `ssh_allowed_cidrs` down to your own IP if you can.

3. Run the terraform command and get a/some shiny new node(s)!

```sh
terraform init && terraform apply
```

```sh
Outputs:

public_ip_ipv4 = [
  "193.148.160.10",
]
```

and you can connect via ssh like so:

```sh
ssh -i ROUTE_TO_PRIVATE_KEY ubuntu@IP_ADDRESS_FROM_OUTPUT
```

> NOTE: since the cloud init script takes a bit of time to run, if you SSH in immediately, you might not have access to the `veilid-cli` command for a few minutes. You can check progress with `cloud-init status --wait`.

## Notes

- The server ignores changes to its boot volume, so when a newer Ubuntu 24.04 image is published, `terraform apply` won't destroy and recreate your node (and throw away its stored DHT data). veilid itself is kept up to date by the cron job.
- The node is IPv4 only. The public IP is 1:1 NATed to the server's private address, so the cloud init script sets `detect_address_changes: true` in the veilid config.
- Tear everything down with `terraform destroy`.
