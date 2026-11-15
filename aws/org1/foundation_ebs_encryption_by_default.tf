# EBS Encryption by Default
# Enables encryption across all governed regions using AWS CLI
# to avoid Terraform provider timeout issues with multiple regions

locals {
  ebs_encryption_regions = [
    "ca-central-1",
    "ca-west-1",
    "us-east-1",
    "us-east-2",
    "us-west-2",
  ]
}

resource "null_resource" "ebs_encryption_by_default" {
  for_each = toset(local.ebs_encryption_regions)

  provisioner "local-exec" {
    command = "aws ec2 enable-ebs-encryption-by-default --region ${each.value}"
  }

  triggers = {
    always_run = timestamp()
  }
}
