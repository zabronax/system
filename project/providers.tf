terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.10"
    }
  }
}

variable "github_repository_token" {
  description = "GitHub token for administering the repository"
  type        = string
  sensitive   = true
}

provider "github" {
  token = var.github_repository_token
}
