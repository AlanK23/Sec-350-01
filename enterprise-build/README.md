# SYS-350 Enterprise Build Part I

Terraform project deploying Docker services and KVM VMs on a shared hypervisor.

## Files
- main.tf
- cloud-init-server.yaml
- .gitignore
- terraform.tfvars (not committed)

## Usage
terraform init
terraform plan
terraform apply

## Redacted tfvars example
student_name = "alank"
corp_octet   = 50
services     = { gitea = { image = "gitea/gitea:latest", network = "devops", ports = [{ internal = 3000, external = 3000 }] } }
vms          = { "alank-ubuntu-srv" = { os = "ubuntu-server", memory_mb = 2048, vcpu = 1 } }
