locals {
  governedRegions = [ # List of regions to govern, order matters to prevent change
    "ca-central-1",
    "us-east-2",
    "us-east-1",
    "ca-west-1"
  ]
}
