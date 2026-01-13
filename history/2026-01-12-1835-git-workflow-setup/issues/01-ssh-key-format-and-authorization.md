# Issue: SSH Key Format and Authorization Failure

## What Happened
User provided an SSH private key for GitHub authentication. The key was in PuTTY PPK format (not OpenSSH format). I successfully converted it using `puttygen`, but when testing the SSH connection to GitHub, authentication failed with "Permission denied (publickey)."

Upon inspection, the key had the comment `tanderson@guidewire.com`, suggesting it was an old work key not associated with the user's GitHub account (`troy216`) or the `ha-cypress-config` repository.

## Impact
- **Time wasted:** ~15 minutes
- Installed `putty` package unnecessarily (51MB)
- Created SSH config files that were later deleted
- Had to pivot to an entirely different authentication method

## Root Cause
Multiple factors:
1. **User-side:** The key provided was not the correct key for GitHub access—it was likely an old/unrelated key
2. **Claude-side:** I didn't ask clarifying questions about the key before proceeding:
   - "Is this key currently authorized as a deploy key on your GitHub repo?"
   - "When was this key last used successfully?"
3. **Missing information:** User wasn't certain which key was the right one

## Resolution
Switched from SSH authentication to HTTPS with a GitHub Personal Access Token (PAT). User generated a new PAT on GitHub, which worked immediately.

## Improvements

### For Claude
- Before attempting SSH key setup, ask:
  - "Is this key currently authorized on your GitHub account/repo?"
  - "What format is the key in?" (PuTTY vs OpenSSH)
- Consider suggesting HTTPS+token as the simpler default option, especially for containerized environments where key management is complex

### For User
- When providing credentials, verify they're currently valid and associated with the correct account
- PAT tokens are often simpler than SSH keys for automated/containerized use cases

### For System
- Could add to CLAUDE.md: "For GitHub auth, prefer HTTPS+token over SSH in containerized environments"
