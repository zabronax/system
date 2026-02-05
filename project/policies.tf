resource "github_workflow_repository_permissions" "auto_merge_policy" {
  repository = github_repository.primary_repository.name

  default_workflow_permissions = "read"
  can_approve_pull_request_reviews = true
}
