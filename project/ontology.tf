resource "github_issue_labels" "name" {
  repository = github_repository.primary_repository.name

  label {
    name = "auto-merge"
    description = "Automatically merged by the CI workflow"
    color = "0075ca"
  }
}