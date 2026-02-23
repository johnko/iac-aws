locals {
  governedRegions = [ # List of regions to govern
    ##### ORDER MATTERS TO PREVENT CHANGE
    "ca-central-1",
    "us-east-2", # bedrock cross-region inference profile
    "us-east-1",
    "ca-west-1",
    "us-west-2", # bedrock cross-region inference profile
  ]
}
