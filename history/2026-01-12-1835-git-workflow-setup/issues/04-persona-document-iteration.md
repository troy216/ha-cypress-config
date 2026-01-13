# Issue: Persona Document Required Multiple Iterations

## What Happened
The user provided a comprehensive home automation expert persona (~1,500 words) to add to CLAUDE.md. I incorporated it, but then the user expressed concern about "balancing benefits versus context consumption."

This led to multiple iterations:
1. User provided full persona
2. I analyzed it and recommended condensing to ~100 words
3. User approved the condensed version
4. Later in session, user asked to review CLAUDE.md for alignment with intent
5. Additional refinements made (Session Start directive, container context, etc.)

## Impact
- **Time spent:** ~15 minutes on persona iterations
- Multiple edits to the same file
- Back-and-forth to align on the right level of detail

## Root Cause
1. **Claude-side:** I didn't proactively ask about context consumption concerns when the user first mentioned adding a persona
2. **Communication gap:** The user's concern about token usage wasn't surfaced until after they provided the full document
3. **Iterative refinement:** Some iteration is natural, but could have been reduced with better upfront questions

## Resolution
- Condensed persona from ~1,500 words to ~100 words
- Preserved key expertise areas and principles
- Moved detailed content to README.md where it doesn't consume context every session

## Improvements

### For Claude
- When user mentions adding substantial content to CLAUDE.md, proactively ask:
  - "CLAUDE.md is loaded every session. How do you want to balance detail vs context consumption?"
  - "Would you like this summarized, or should detailed content go in README.md?"
- Remember that CLAUDE.md content consumes tokens on every interaction

### For User
- Stating constraints upfront ("keep it brief for context efficiency") helps avoid iterations
- The distinction between "always-loaded context" (CLAUDE.md) vs "reference docs" (README.md) is useful

### For System
- The final structure (brief CLAUDE.md + detailed README.md) is a good pattern
- Could add to CLAUDE.md principles: "Keep this file concise; detailed reference goes in README.md"
