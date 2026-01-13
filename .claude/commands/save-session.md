# Save Session Report

Generate a comprehensive session report documenting this conversation's activities, decisions, and any issues or inefficiencies.

## Instructions

1. **Determine session name**: `YYYY-MM-DD-HHMM-<brief-summary>` using current date/time and a 2-4 word summary of the session's main focus.

2. **Get current session ID using your session marker**:
   - Find your session marker from your startup status output (format: `SESS-xxxxxxxxxxxx`)
   - Run the lookup script:
     ```bash
     /data/scripts/find-session.sh SESS-xxxxxxxxxxxx
     ```
   - This searches JSONL files for your marker and returns the session UUID
   - The marker ensures you find YOUR session, even with concurrent sessions running

3. **Check for existing session report**:
   - Run: `/data/scripts/find-session.sh SESS-xxxxxxxxxxxx --report`
   - If it returns a path, update that report instead of creating a new folder
   - If it returns `NO_REPORT`, this is a new session - create a new folder

4. **Create session folder structure**:
   ```
   /config/history/<session-name>/
   ├── report.md              # Main detailed report
   └── issues/                # Issue analysis files (if any)
       ├── 01-issue-name.md
       ├── 02-issue-name.md
       └── ...
   ```

5. **Generate `report.md`** with comprehensive detail:
   ```markdown
   # Session Report: <summary>

   **Date:** YYYY-MM-DD HH:MM
   **Session ID:** <session-guid-from-step-2>
   **Duration:** ~X minutes (estimated)

   ## Summary
   Detailed description of what was accomplished, context, and outcomes.

   ## Goals
   - What the user wanted to achieve
   - Any evolving requirements during the session

   ## Changes Made
   For each file, provide:
   - Full path
   - What was changed and why
   - Key code/config snippets if relevant

   ## Key Decisions
   For each decision:
   - What was decided
   - Alternatives considered
   - Rationale for the choice

   ## Technical Details
   - Commands run
   - Configuration details
   - Architecture decisions

   ## Issues Encountered
   List issues with links to detailed analysis in issues/ folder:
   - [Issue 1: Brief description](issues/01-issue-name.md)
   - [Issue 2: Brief description](issues/02-issue-name.md)

   ## Follow-up Items
   - Outstanding tasks
   - Future considerations
   - Open questions
   ```

6. **Create issue files** in `issues/` folder for each problem encountered:
   ```markdown
   # Issue: <descriptive name>

   ## What Happened
   Describe the issue, mistake, rabbit hole, or inefficiency.

   ## Impact
   Time wasted, confusion caused, or other consequences.

   ## Root Cause
   Why did this happen? Was it:
   - Claude mistake/assumption?
   - User miscommunication?
   - Missing information?
   - Tool/environment limitation?

   ## Resolution
   How was it resolved?

   ## Improvements
   What could prevent this in the future?
   - For Claude: behavior changes, better questions to ask
   - For User: information to provide upfront, clearer instructions
   - For System: documentation, tooling, or process improvements
   ```

7. **Commit and push**:
   - Stage all current changes: `git add -A`
   - Commit with message: `Session report: <session-name>`
   - Push to origin: `git push origin main`
   - Report commit hash and push status to user

8. **Inform user**: Confirm report location, commit hash, and summarize any issues documented.

## Important
- Be thorough and honest in issue analysis
- Issues are learning opportunities, not blame assignment
- Include enough detail that future sessions can learn from this one
- If updating an existing report, preserve previous content and append/update as needed
