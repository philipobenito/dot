---
name: subagent-driven-development
description: Use when implementing an approved design or plan by decomposing it into tasks and executing each with a fresh subagent plus two-stage review. Includes complexity triage that routes genuinely simple mechanical work through a lightweight fast path (single implementation + single combined review) while preserving the full per-task decomposition and two-stage review for complex work
---

# Subagent-Driven Development

Implement an approved design by first triaging its complexity, then taking the appropriate path. Simple mechanical work (evidenced by strict binary criteria) gets a fast path: single implementation dispatch, single combined review. Complex work gets the full process: decompose into tasks, fresh subagent per task, two-stage review per task.

**Why subagents:** You delegate tasks to specialised agents with an isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Triage first, then either fast path (prove it's simple) or full path (decompose, implement per-task, two-stage review) = right-sized process for the work

## Subagent Type Selection

Before dispatching any subagent, check the available subagent types and select the most specific one that fits the task. Generic agents produce generic work. Specialised agents understand the domain, follow its conventions, and catch domain-specific issues that a general-purpose agent misses.

**The selection process for every dispatch:**

1. Look at the task: what language, framework, or domain does it involve?
2. Check the available subagent types for a match (e.g. `typescript-pro` for TypeScript, `react-specialist` for React components, `python-pro` for Python, `code-reviewer` for reviews)
3. If a specialised type matches, use it via the `subagent_type` parameter on `{{DISPATCH_AGENT_TOOL}}`
4. Fall back to `general-purpose` only when no specialised type fits

This applies to implementers, spec reviewers, and code quality reviewers alike. A TypeScript task should be implemented by a TypeScript specialist and reviewed by a code reviewer specialist, not by three general-purpose agents.

**During task decomposition**, annotate each task with the recommended subagent type. This avoids re-evaluating the selection at dispatch time and makes the choice explicit and reviewable.

## When to Use

```dot
digraph when_to_use {
    "Have approved design or plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "Brainstorm first" [shape=box];

    "Have approved design or plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have approved design or plan?" -> "Brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "subagent-driven-development" [label="yes"];
    "Tasks mostly independent?" -> "Brainstorm first" [label="no - tightly coupled"];
}
```

**Key advantages:**
- Handles both task decomposition and execution in one flow
- Fresh subagent per task (no context pollution)
- Two-stage review after each task: spec compliance first, then code quality
- Faster iteration (no human-in-loop between tasks)
- Complexity triage routes are genuinely simple work through a lightweight fast path

## Complexity Triage

Before decomposing work into tasks, assess whether the full process is warranted. **The default is always the full path.** The fast path is an optimisation for genuinely mechanical work where the per-task overhead adds no quality benefit.

### Why This Matters

The full process (per-task decomposition, each with two-stage review) is transformative for complex work. But for mechanical changes, like updating a version string across 8 files or fixing the same wording in 6 config files, the full process spends more tokens on coordination than on the actual work. Those files do not need 8 implementer dispatches, 8 spec reviews, and 8 quality reviews. They need one pass and one check.

The danger is that the fast path becomes an escape hatch from rigour. To prevent this, the triage uses strict binary criteria with mandatory evidence. You must prove the work is simple. You cannot assume it.

### Triage Criteria

**ALL** the following must be true for the fast path. A single failure means a full path, no exceptions.

| # | Criterion                    | Definition                                                                             | Fails if                                                                                                    |
|---|------------------------------|----------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| 1 | **Uniform change type**      | Every change is the same kind of edit applied across locations                         | Changes mix different concerns (e.g., docs + feature code, config + new logic)                              |
| 2 | **No new logic**             | Zero new functions, classes, conditionals, loops, error handling, or business rules    | Any new control flow or callable unit is introduced                                                         |
| 3 | **No new interfaces**        | No new exports, API endpoints, contracts, events, or public surface area               | Any new public-facing surface is created                                                                    |
| 4 | **Deterministic from spec**  | The correct change at each location is fully specified with no room for interpretation | Any change requires a design decision, judgment call, or contextual understanding beyond the immediate edit |
| 5 | **Independently verifiable** | Each change can be verified by reading it in isolation                                 | Correctness of one change depends on another change in a different file                                     |
| 6 | **Small total delta**        | Under ~50 lines of meaningful content change across all files                          | More than ~50 lines of substantive change                                                                   |

### Presenting the Evidence

Present the triage table before proceeding on either path. This is mandatory. The user needs to see the reasoning and can override the classification.

Format:

```
Complexity Triage

| # | Criterion | Evidence | Pass |
|---|-----------|----------|------|
| 1 | Uniform change type | [specific observation] | Y/N |
| 2 | No new logic | [specific observation] | Y/N |
| 3 | No new interfaces | [specific observation] | Y/N |
| 4 | Deterministic from spec | [specific observation] | Y/N |
| 5 | Independently verifiable | [specific observation] | Y/N |
| 6 | Small total delta | [line count estimate with method] | Y/N |

Classification: SIMPLE / COMPLEX
Path: Fast / Full
Justification: [one sentence]
```

### Evidence Standards

The evidence column must contain specific observations from the design, not restated criteria.

**These cause the criterion to fail (insufficient evidence):**
- "Changes are uniform" - restates the criterion, says nothing specific
- "No significant new logic" - qualifier ("significant") reveals ambiguity
- "Scope is small" - no numbers, no reasoning

**These are acceptable evidence:**
- "All 6 files: replace version string '2.3.0' with '2.4.0' in the module docstring header"
- "Zero new functions, conditionals, or loops; each change is a string literal replacement"
- "~18 lines total: 6 files x 3 lines each (version, date, changelog link)"

If a criterion needs qualifying language ("mostly", "generally", "essentially", "largely", "primarily"), it fails. The fast path is for work that is unambiguously simple.

### Triage Override

If during fast-path implementation or review it becomes clear the work is more complex than assessed, stop the fast path and switch to full. The combined reviewer can trigger this by reporting TRIAGE_INVALID. The sunk cost of the fast-path attempt is negligible compared to the cost of poorly reviewed complex work.

## Fast Path

When triage classifies work as SIMPLE, the process collapses to two subagent dispatches total.

### Process

1. **Single implementation dispatch**: One subagent receives all changes as a batch. Use the standard implementer prompt (`./implementer-prompt.md`) with the task description covering the full scope. Select the subagent type as normal.

2. **Single combined review**: One reviewer checks spec compliance and code quality in a single pass (`./fast-path-reviewer-prompt.md`). This is not a weaker review. It covers everything the two separate reviews cover, combined because the small scope makes separation unnecessary overhead.

3. **One commit** for all changes.

If the reviewer finds issues, the implementer fixes them and the reviewer reviews again. Same fix-and-re-review loop as the full path, with one reviewer instead of two sequential ones.

If the reviewer reports TRIAGE_INVALID, stop and switch to the full path. Re-decompose the work using the full path process below.

### Fast Path Flow

```dot
digraph fast_path {
    rankdir=TB;

    "Triage: SIMPLE" [shape=box, style=bold];
    "Dispatch implementer\n(all changes as single batch)" [shape=box];
    "Implementer asks questions?" [shape=diamond];
    "Answer questions, provide context" [shape=box];
    "Implementer implements, tests, commits, self-reviews" [shape=box];
    "Dispatch combined reviewer\n(./fast-path-reviewer-prompt.md)" [shape=box];
    "Reviewer result?" [shape=diamond];
    "Implementer fixes issues" [shape=box];
    "Switch to full path\n(re-decompose)" [shape=box];
    "Done" [shape=box, style=bold];

    "Triage: SIMPLE" -> "Dispatch implementer\n(all changes as single batch)";
    "Dispatch implementer\n(all changes as single batch)" -> "Implementer asks questions?";
    "Implementer asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer\n(all changes as single batch)";
    "Implementer asks questions?" -> "Implementer implements, tests, commits, self-reviews" [label="no"];
    "Implementer implements, tests, commits, self-reviews" -> "Dispatch combined reviewer\n(./fast-path-reviewer-prompt.md)";
    "Dispatch combined reviewer\n(./fast-path-reviewer-prompt.md)" -> "Reviewer result?";
    "Reviewer result?" -> "Done" [label="PASS"];
    "Reviewer result?" -> "Implementer fixes issues" [label="FAIL"];
    "Reviewer result?" -> "Switch to full path\n(re-decompose)" [label="TRIAGE_INVALID"];
    "Implementer fixes issues" -> "Dispatch combined reviewer\n(./fast-path-reviewer-prompt.md)" [label="re-review"];
}
```

## Task Decomposition (Full Path)

When complexity triage classifies work as COMPLEX (the default), decompose the design into implementable tasks before dispatching subagents. The design from brainstorming (or an existing plan file) is the input.

### File Structure

Map out which files will be created or modified and what each one is responsible for. This locks in the decomposition decisions before any code is written.

- Each file should have one clear responsibility with a well-defined interface
- Prefer smaller, focused files over large ones that do too much
- In existing codebases, follow established patterns
- Files that change together should live together

### Task Granularity

Each task should be a self-contained unit of work that produces working, testable code:

- Touches a focused set of files (ideally 1-3)
- Has clear acceptance criteria derivable from the design
- Can be verified independently
- Results in a commit

Within each task, steps should follow TDD: write the failing test, run it, implement the minimal code, run tests, commit. This level of detail is communicated to the implementer subagent, not tracked by the controller.

### Task Ordering

Order tasks to respect dependencies:

1. Foundation/infrastructure first
2. Core features next
3. Integration after dependencies
4. Polish/cleanup last

### Output

The decomposition produces a {{TASK_TRACKER_TOOL}} with all tasks. Each task entry includes:

- Task name and description
- Recommended subagent type (e.g. `typescript-pro`, `python-pro`, `react-specialist`)
- Files to create or modify (exact paths)
- Acceptance criteria
- Dependencies on other tasks
- Scene-setting context (where this fits in the overall design)

## The Process (Full Path)

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "Select specialised subagent type\n(from task annotation)" [shape=box, style=bold];
        "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
        "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [shape=box];
        "Spec reviewer subagent confirms code matches spec?" [shape=diamond];
        "Implementer subagent fixes spec gaps" [shape=box];
        "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [shape=box];
        "Code quality reviewer subagent approves?" [shape=diamond];
        "Implementer subagent fixes quality issues" [shape=box];
        "Mark task complete in {{TASK_TRACKER_TOOL}}" [shape=box];
    }

    "Decompose design into tasks, map files, select subagent types, create {{TASK_TRACKER_TOOL}}" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Dispatch final code reviewer subagent for entire implementation" [shape=box];

    "Decompose design into tasks, map files, select subagent types, create {{TASK_TRACKER_TOOL}}" -> "Select specialised subagent type\n(from task annotation)";
    "Select specialised subagent type\n(from task annotation)" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, commits, self-reviews" [label="no"];
    "Implementer subagent implements, tests, commits, self-reviews" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)";
    "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" -> "Spec reviewer subagent confirms code matches spec?";
    "Spec reviewer subagent confirms code matches spec?" -> "Implementer subagent fixes spec gaps" [label="no"];
    "Implementer subagent fixes spec gaps" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [label="re-review"];
    "Spec reviewer subagent confirms code matches spec?" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="yes"];
    "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" -> "Code quality reviewer subagent approves?";
    "Code quality reviewer subagent approves?" -> "Implementer subagent fixes quality issues" [label="no"];
    "Implementer subagent fixes quality issues" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="re-review"];
    "Code quality reviewer subagent approves?" -> "Mark task complete in {{TASK_TRACKER_TOOL}}" [label="yes"];
    "Mark task complete in {{TASK_TRACKER_TOOL}}" -> "More tasks remain?";
    "More tasks remain?" -> "Select specialised subagent type\n(from task annotation)" [label="yes"];
    "More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
}
```

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, inexpensive model. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture, design, and review tasks**: use the most capable available model.

**Task complexity signals:**
- Touches 1-2 files with a complete spec → inexpensive model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g. "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent (both paths)
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent (full path)
- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent (full path)
- `./fast-path-reviewer-prompt.md` - Dispatch combined reviewer subagent (fast path)

## Example Workflows

### Fast Path Example

```
You: I'm implementing the design for updating copyright headers across the codebase.

Complexity Triage

| # | Criterion | Evidence | Pass |
|---|-----------|----------|------|
| 1 | Uniform change type | All 8 files: replace "Copyright 2025" with "Copyright 2026" in file header | Y |
| 2 | No new logic | Zero new functions or control flow; each change is a string literal replacement | Y |
| 3 | No new interfaces | No new exports, APIs, or contracts | Y |
| 4 | Deterministic from spec | Design lists exact files and exact old/new strings | Y |
| 5 | Independently verifiable | Each file's header change is self-contained | Y |
| 6 | Small total delta | ~8 lines total (1 line per file x 8 files) | Y |

Classification: SIMPLE
Path: Fast
Justification: Identical string replacement across 8 independent files with zero logic changes.

[Dispatch single implementer with all 8 files as one batch]

Implementer:
  - Updated copyright year in all 8 files
  - Self-review: All changes are consistent string replacements
  - Committed

[Dispatch combined reviewer with triage evidence table]

Combined reviewer: [PASS] All 8 files correctly updated. Changes match spec exactly,
no extra modifications, consistent with surrounding code style.

Done!
```

### Full Path Example

```
You: I'm using Subagent-Driven Development to implement this design.

[Decompose design into tasks: map file structure, define 5 tasks with acceptance criteria]
[Create {{TASK_TRACKER_TOOL}} with all tasks]

Task 1: Hook installation script

[Dispatch implementation subagent with full task text + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/hooks/)"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed

[Dispatch spec compliance reviewer]
Spec reviewer: [PASS] Spec compliant - all requirements met, nothing extra

[Get git SHAs, dispatch code quality reviewer]
Code reviewer: Strengths: Good test coverage, clean. Issues: None. Approved.

[Mark Task 1 complete]

Task 2: Recovery modes

[Dispatch implementation subagent with full task text + context]

Implementer: [No questions, proceeds]
Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Committed

[Dispatch spec compliance reviewer]
Spec reviewer: [FAIL] Issues:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)

[Implementer fixes issues]
Implementer: Removed --json flag, added progress reporting

[Spec reviewer reviews again]
Spec reviewer: [PASS] Spec compliant now

[Dispatch code quality reviewer]
Code reviewer: Strengths: Solid. Issues (Important): Magic number (100)

[Implementer fixes]
Implementer: Extracted PROGRESS_INTERVAL constant

[Code reviewer reviews again]
Code reviewer: [PASS] Approved

[Mark Task 2 complete]

...

[After all tasks]
[Dispatch final code-reviewer]
Final reviewer: All requirements met, ready to merge

Done!
```

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**Efficiency gains:**
- No file reading overhead (controller provides full text)
- Controller curates exactly what context is needed
- Design-to-execution in one flow (no intermediate handoff)
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)

**Quality gates:**
- Self-review catches issues before handoff
- Two-stage review: spec compliance, then code quality
- Review loops to ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures the implementation is well-built

**Cost:**
- More subagent invocations (implementer + 2 reviewers per task)
- Controller does more prep work (extracting all tasks upfront)
- Review loops add iterations
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make a subagent discover context on its own (provide full text instead)
- Skip scene-setting context (subagent needs to understand where a task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (spec reviewer found issues = not done)
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace the actual review (both are needed)
- **Start code quality review before spec compliance is correct** (wrong order)
- Move to the next task while either review has open issues

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If the reviewer finds issues:**
- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

**Complexity triage:**
- Never classify work as SIMPLE without presenting the full evidence table
- Never use qualifying language in evidence ("mostly", "largely", "primarily", "essentially")
- Never skip the combined review on the fast path
- Never continue the fast path after a TRIAGE_INVALID from the reviewer
- Never use the fast path as a default. COMPLEX is the default. SIMPLE must be proven
- Never split genuinely simple work into the full path to look thorough. That wastes tokens without adding quality

## Integration

**Required workflow skills:**
- **brainstorming** or **guided-brainstorming** - Creates the design this skill implements
- **work-on-ticket** - Recovers design context from tickets in new sessions and feeds it into this skill
- **requesting-code-review** - Code review template for reviewer subagents

**Subagents should use:**
- **test-driven-development** - Subagents follow TDD for each task

