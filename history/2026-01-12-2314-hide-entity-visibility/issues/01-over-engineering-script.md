# Issue: Over-engineering with Script File

## What Happened
When tasked with hiding 7 entities, I attempted to write a Python script file (`/tmp/hide_entities.js`) instead of executing the commands directly. User rejected this approach and asked "No. don't write a script to do it, just do each one directly."

## Impact
- Minor time wasted (one rejected tool call)
- Would have created an unnecessary artifact requiring cleanup

## Root Cause
**Claude mistake/assumption:** Defaulted to "organized" approach of creating a reusable script, when the task was clearly a one-off operation. This is a form of over-engineering that adds unnecessary complexity:
1. Create file
2. Run file
3. Clean up file

When direct execution requires only:
1. Run commands

## Resolution
Executed WebSocket commands directly via Node.js one-liners, hiding each entity in parallel.

## Improvements

### For Claude
- **Recognize one-off tasks:** When a user asks to do something once to specific entities, execute directly rather than creating scripts
- **Apply YAGNI principle:** "You Aren't Gonna Need It" - don't create reusable artifacts for single-use operations
- **Question the urge to "organize":** Creating files feels more structured but adds overhead for simple tasks
- **Consider cleanup burden:** Any file created needs to be deleted; direct execution leaves no trace

### For User
- None needed - user correctly identified and redirected the approach

### For System
- None needed
