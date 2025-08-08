terraform {
  required_version = ">= 1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Local resource to simulate infrastructure provisioning
resource "local_file" "infrastructure_config" {
  filename = "${path.root}/.terraform_state"
  content = jsonencode({
    infrastructure = {
      status      = "provisioned"
      timestamp   = timestamp()
      environment = var.environment
      app_name    = var.app_name
    }
  })
}

# Null resource to trigger Ansible playbook
resource "null_resource" "ansible_provisioning" {
  depends_on = [local_file.infrastructure_config]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Infrastructure provisioned successfully'"
  }

  provisioner "local-exec" {
    command = "echo 'Ready for Ansible configuration'"
    when    = create
  }
}