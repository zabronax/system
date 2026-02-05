# GitHub Actions Workflows

This directory contains GitHub Actions workflows for continuous integration and branch reconciliation.

## Workflows

### Continuous Integration (`continuous-integration.yaml`)

Runs validation checks on code changes.

**Triggers:**
- Push to `main` branch
- Pull requests to `main`
- Manual dispatch

**Jobs:**
- Runs validation checks (evaluation, formatting, tests, etc.)
- All jobs must pass for the workflow to succeed

**Purpose:** Ensures code quality and correctness before merging.

### Reconcile Main (`reconcile-main.yaml`)

Automatically creates and updates pull requests from `development` to `main`.

**Triggers:**
- Push to `development` branch

**Behavior:**
- Creates a PR from `development` to `main` if one doesn't exist
- Updates existing PR if one already exists
- Uses concurrency control to prevent duplicate PRs

**Purpose:** Automates the reconciliation of commits from `development` to `main`. Branch protection enforces validation checks on the PR.

## Two-Stage Branch Workflow

This repository uses a two-stage branch workflow:

### Branches

- **`development`**: Working branch where you push directly
  - No required CI checks (allows direct pushes)
  - Protected: no deletions, linear history required
  - PRs created automatically on push

- **`main`**: Production branch that only accepts validated commits
  - Required CI checks (configured in branch protection)
  - Protected: no deletions, linear history required
  - Only merges PRs that pass all required checks

### Flow

```
1. Push to development
   ↓
2. Reconciliation workflow creates/updates PR
   ↓
3. PR runs CI (required by branch protection)
   ↓
4. If CI passes:
   → PR can be merged
   
5. If CI fails:
   → PR blocked by branch protection
   → Commits stay in development
```

### Benefits

- **No ceremony**: Push directly to `development`, automation handles the rest
- **Quality gate**: Branch protection ensures only validated code reaches `main`
- **Single enforcement point**: CI runs once on PRs, enforced by branch protection
- **Stable main**: `main` only contains commits that have passed all checks
- **Fast PR creation**: PRs created immediately on push, validation happens on PR

## Branch Protection

Branch protection is configured via Terraform in `project/branches.tf`:

- **Main branch**: Requires all configured CI checks to pass before merging
- **Development branch**: Protected but no required checks (allows direct pushes)

## Auto-Merge

The repository has `allow_auto_merge = true` enabled. PRs can be configured to auto-merge once all required checks pass, though this workflow doesn't enable it programmatically (can be done manually or via GitHub CLI).
