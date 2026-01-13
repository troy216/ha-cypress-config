# Issue: GitHub CLI Authentication Errors

## What Happened

When attempting to create a GitHub issue using the `gh` CLI, multiple authentication errors occurred:

1. First attempt: `gh: command not found` - gh wasn't installed
2. After installing: `gh auth status` showed "You are not logged into any GitHub hosts"
3. Using `GH_TOKEN` environment variable: "the token in GH_TOKEN is missing required scope 'read:org'"

This resulted in 3 failed attempts before successfully creating the issue via direct GitHub API.

## Impact

- ~5 minutes spent troubleshooting authentication
- Multiple error messages before finding working approach
- User had to wait through trial-and-error process

## Root Cause

**Missing documentation/tooling:**

1. `github-cli` was not included in `/data/init-tools.sh` - required manual installation
2. No documentation in CLAUDE.md about how to authenticate gh CLI
3. The stored GitHub token (`/data/home/.github_token`) has limited scopes - doesn't include `read:org` which gh CLI requires for some operations
4. Claude attempted `gh auth login` style authentication instead of using stored token

## Resolution

1. Installed `github-cli` via `apk add`
2. Discovered that `GH_TOKEN` environment variable approach fails due to scope limitations
3. Used direct GitHub API with curl as fallback - this worked with the existing token
4. Created GitHub issue successfully via API

## Improvements

### For Claude
- Check for gh CLI availability at session start (added to init-tools.sh)
- Use `GH_TOKEN=$(cat /data/home/.github_token)` for authentication
- If gh CLI fails with scope errors, immediately fall back to direct API
- Don't attempt interactive `gh auth login`

### For System
- **Implemented:** Added `github-cli` to `/data/init-tools.sh` packages
- **Implemented:** Added "GitHub CLI (gh)" section to CLAUDE.md with:
  - Authentication via environment variable
  - Usage examples
  - Fallback to direct API when scope errors occur

### For User
- Consider creating a GitHub token with broader scopes if full gh CLI functionality is needed
- Current token works fine for basic operations (issues, comments) via direct API
