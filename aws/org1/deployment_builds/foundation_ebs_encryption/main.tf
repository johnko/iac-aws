# EBS Encryption by Default Deployment
# Uses the reusable module to enable encryption across all governed regions

module "ebs_encryption" {
  source = "../../../../modules/ebs-encryption-by-default"

  providers = {
    aws           = aws
    aws.ca_west   = aws.ca_west
    aws.us_east_1 = aws.us_east_1
    aws.us_east_2 = aws.us_east_2
    aws.us_west_2 = aws.us_west_2
  }
}
