resource "github_branch_protection" "main" {
  repository_id = github_repository.primary_repository.id
  pattern       = "main"

  allows_deletions = false

  required_linear_history = true

  required_status_checks {
    strict = true
    contexts = [
      "ci/smoke",
      "ci/formatted",
    ]
  }
}
