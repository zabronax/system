# GitHub Actions Workflows

This directory contains GitHub Actions workflows for continuous integration and branch reconciliation.

## Workflows

### Continuous Integration (`continuous-integration.yaml`)

Runs validation checks on code changes.

**Triggers:**
- Push to `main` or `development` branches
- Pull requests to `main`
- Manual dispatch

**Jobs:**
- Runs validation checks (evaluation, formatting, tests, etc.)
- All jobs must pass for the workflow to succeed

**Purpose:** Ensures code quality and correctness before merging.

### Reconcile Main (`reconcile-main.yaml`)

Automatically creates and updates pull requests from `development` to `main` when commits pass CI.

**Triggers:**
- When Continuous Integration workflow completes successfully on `development`

**Behavior:**
- Creates a PR from `development` to `main` if one doesn't exist
- Updates existing PR if one already exists
- Only runs when CI passes (creates "trailing" effect)
- Uses concurrency control to prevent duplicate PRs

**Purpose:** Automates the reconciliation of validated commits from `development` to `main`.

## Two-Stage Branch Workflow

This repository uses a two-stage branch workflow:

### Branches

- **`development`**: Working branch where you push directly
  - No required CI checks (allows direct pushes)
  - Protected: no deletions, linear history required
  - CI runs on every push for validation

- **`main`**: Production branch that only accepts validated commits
  - Required CI checks (configured in branch protection)
  - Protected: no deletions, linear history required
  - Only merges PRs that pass all required checks

### Flow

```
1. Push to development
   ↓
2. CI runs (all validation checks)
   ↓
3. If CI passes:
   → Reconciliation workflow creates/updates PR
   → PR runs its own CI (required by branch protection)
   → PR can be merged when all checks pass
   
4. If CI fails:
   → Reconciliation workflow doesn't run
   → Commits stay in development
   → PR doesn't advance
```

### Benefits

- **Trailing validation**: PR only advances when commits pass CI
- **No ceremony**: Push directly to `development`, automation handles the rest
- **Quality gate**: Branch protection ensures only validated code reaches `main`
- **Fast feedback**: CI runs immediately on `development` pushes
- **Stable main**: `main` only contains commits that have passed all checks

### Example Scenario

```
Push commit A → CI runs → Passes → PR updates to include A
Push commit B → CI runs → Passes → PR updates to include B  
Push commit C → CI runs → Fails → PR stays at B (C not included)
Push commit D → CI runs → Passes → PR updates to include D
```

The PR "trails" `development`, only including commits that have been validated. This ensures `main` only contains code that has passed all validation checks.

## Branch Protection

Branch protection is configured via Terraform in `project/branches.tf`:

- **Main branch**: Requires all configured CI checks to pass before merging
- **Development branch**: Protected but no required checks (allows direct pushes)

## Auto-Merge

The repository has `allow_auto_merge = true` enabled. PRs can be configured to auto-merge once all required checks pass, though this workflow doesn't enable it programmatically (can be done manually or via GitHub CLI).
