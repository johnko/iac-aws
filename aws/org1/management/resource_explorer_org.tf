
resource "aws_resourceexplorer2_view" "org_resources" {
  name = "org-resources"

  included_property {
    name = "tags"
  }

  scope = aws_organizations_organization.org.id

  depends_on = [
    aws_resourceexplorer2_index.account,
  ]
}
