output "public_ip_ipv4" {
  value = [
    for ip in stackit_public_ip.veilid : ip.ip
  ]
}
