---
name: create-tickets
description: "Use after brainstorming when the user chooses to create tickets instead of starting implementation, or whenever the user wants to break a design or requirements into tracked tickets. Detects the project's ticketing system (GitHub Issues, Jira, GitLab, Linear) from available MCP tools and project configuration, then creates well-structured tickets from the approved design."
---

# Create Tickets

Turn an approved design into tickets in the project's ticketing system. Detects the system automatically, decomposes the design into right-sized tickets, creates them with proper dependencies and ordering.

**Announce at start:** "I'm using the create-tickets skill to break this design into tracked tickets."

**Context:** The design from brainstorming lives in the conversation context. Use it as the source of truth for what to ticket.

## Detection

Identify the ticketing system by checking signals in this order:

### 1. Available MCP Tools

Check which MCP tools are available in your environment:

| MCP Tool Pattern | System |
|---|---|
| `mcp__*Atlassian*__createJiraIssue` | Jira |
| `mcp__*github*__issue_write` | GitHub Issues |
| Linear MCP tools | Linear |
| GitLab MCP tools | GitLab Issues |

### 2. Git Remote

If MCP tools don't disambiguate:

```bash
git remote get-url origin
```

| Remote Contains | System |
|---|---|
| `github.com` | GitHub Issues |
| `gitlab.com` | GitLab Issues |
| `dev.azure.com` | Azure DevOps |

### 3. Resolution

- **One system detected**: Confirm with the user and proceed
- **Multiple systems detected**: Present what was found, ask which to use
- **None detected**: Offer a structured markdown document as fallback

## Decomposition

### From Design to Tickets

The design summary from brainstorming contains architecture, components, data flow, and interfaces. Map these to tickets:

| Design Element | Ticket Type |
|---|---|
| Overall goal | Epic or parent issue |
| Independent component | Individual ticket |
| Cross-cutting concern (auth, logging, config) | Individual ticket |
| Integration between components | Individual ticket, depends on component tickets |

### Ticket Content

Each ticket includes:

- **Title**: Action-oriented, describes what the ticket delivers (e.g. "Add user authentication middleware")
- **Description**:
  - What to build
  - Key technical decisions from the design relevant to this ticket
  - Acceptance criteria (when is this done?)
  - Dependencies on other tickets
- **Labels/Tags**: Based on the type of work (feature, infrastructure, testing)

### Sizing

Each ticket should be completable in a single focused session. If a component needs more, break it into sub-tickets. The rule of thumb: if you can't describe the acceptance criteria in 3-5 bullet points, the ticket is too large.

### Ordering

Present tickets in suggested implementation order:

1. Foundation/infrastructure tickets first
2. Core feature tickets next
3. Integration tickets after their dependencies
4. Polish/cleanup tickets last

## Creating Tickets

### GitHub Issues

**With MCP tools** (preferred):

1. Use `issue_write` to create each issue
2. Use `get_label` to check for existing labels, create new ones as needed
3. Use `sub_issue_write` for sub-issues under an epic
4. Reference dependencies in the description: "Depends on #N"

**With gh CLI** (fallback):

```bash
gh issue create --title "..." --body "..." --label "..."
```

### Jira

**With Atlassian MCP tools:**

1. `getVisibleJiraProjects` to find the right project (ask user if multiple)
2. `getJiraProjectIssueTypesMetadata` for available issue types (Epic, Story, Task, etc.)
3. `createJiraIssue` for each ticket, using the appropriate issue type
4. `createIssueLink` to create dependency links between issues

Ask the user which Jira project to use if multiple are visible.

### GitLab Issues

**With GitLab MCP tools** if available, otherwise:

```bash
glab issue create --title "..." --description "..."
```

### Linear

**With Linear MCP tools** if available. Ask the user for team/project context before creating issues.

### Markdown Fallback

If no ticketing system is available, write a structured markdown file:

```markdown
# [Feature Name] - Tickets

## Ticket 1: [Title]

**Type:** feature | infrastructure | testing
**Dependencies:** none | Ticket N
**Acceptance Criteria:**
- [ ] ...

**Description:**
...
```

Save to the project root or a location the user specifies.

## After Creation

Report:

- Number of tickets created
- Links to each ticket (or file path for markdown fallback)
- Suggested implementation order
- Dependencies between tickets

Ask if the user wants to adjust anything (reorder, split, merge, relabel).
