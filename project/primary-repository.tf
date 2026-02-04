resource "github_repository" "primary_repository" {
  name = "system"

  # Configuration
  visibility       = "public"
  allow_auto_merge = true

  # Metadata
  description  = "Personal systems configuration"
  homepage_url = "https://github.com/zabronax/system"
  topics = [
    "nix"
  ]

  # Features
  has_discussions = false
  has_issues      = false
  has_projects    = false
  has_wiki        = false
}
