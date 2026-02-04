resource "github_branch" "main" {
  repository = github_repository.primary_repository.name
  branch     = "main"
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.primary_repository.id
  pattern       = github_branch.main.branch

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

resource "github_branch" "development" {
  repository = github_repository.primary_repository.name
  branch     = "development"
}

resource "github_branch_protection" "development" {
  repository_id = github_repository.primary_repository.id
  pattern       = github_branch.development.branch

  allows_deletions = false

  required_linear_history = true

  allows_force_pushes = true
}
