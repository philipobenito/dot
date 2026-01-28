# General Coding Guidelines for AI Agents

## Abstract

This document establishes general coding principles and practices for LLM agents. These guidelines apply universally across all programming languages and project types unless superseded by language-specific or project-specific requirements in CLAUDE.md or project level AGENTS.md.

---

## 1. Language and Communication

### 1.1 British English

You **MUST** use British English spelling and grammar in all:
- Code comments (when necessary)
- Documentation
- Commit messages
- Variable names and identifiers
- User-facing strings

Examples:
- `colour` not `color`
- `initialise` not `initialize`
- `behaviour` not `behavior`
- `organise` not `organize`

### 1.2 Emoji Usage

You MUST NOT use emojis, unicode symbols, or special characters in:
- Code or comments
- Commit messages
- Documentation
- Communication with users
- Status indicators or checkmarks (use [PASS]/[FAIL]/[OK] instead)

---

## 2. Code Quality and Style

### 2.1 Self-Documenting Code

You **MUST** prioritise writing descriptive, self-explanatory code over adding comments or docblocks.

**Good practices:**
- Use meaningful, descriptive variable and function names
- Keep functions small and focused on a single responsibility
- Structure code to reveal intent through organisation and naming
- Use explicit over implicit logic

**Example (avoiding comments):**

```typescript
// Poor: Requires comment to explain
function calc(a: number, b: number): number {
  // Calculate total with 20% tax
  return a * b * 1.2;
}

// Good: Self-documenting
function calculateOrderTotalIncludingVAT(
  pricePerItem: number,
  quantity: number
): number {
  const VAT_RATE = 0.2;
  const subtotal = pricePerItem * quantity;
  return subtotal * (1 + VAT_RATE);
}
```

### 2.2 Default rule: Write code without comments

You **MUST NOT** add comments unless ALL of these conditions are met:
1. The code implements a workaround for an external bug/limitation (e.g., browser quirk, library bug)
2. You have a specific ticket/issue reference to cite
3. The workaround logic cannot be extracted to a well-named function
4. The user has not explicitly forbidden comments for this file type

**Specifically FORBIDDEN:**
- Comments explaining what code does (code should be self-documenting)
- Comments before function calls (`// Publish the article` before `publishArticle()`)
- Comments before variable assignments (`// Store the result` before `$result = ...`)
- Comments describing assertion intent in tests
- "Step X" comments in tests - use the test name instead
- Any comment that just repeats what the code says

**ABSOLUTE BAN in test files:**
Tests are documentation. Test names and assertions must be self-explanatory. Zero comments except ticket references for regression tests.

**When you think a comment is needed:**
1. FIRST: Can I rename variables/functions to make this clearer? (Do this)
2. SECOND: Can I extract to a well-named method? (Do this)
3. THIRD: Can I simplify the logic? (Do this)
4. LAST: Do I have a ticket reference for a workaround? (Only then add comment)

```php
<?php

// Example - When a comment IS appropriate:

// Workaround for Laravel bug #12345: Eager loading fails on self-referential relationships
// Remove this when upgrading to Laravel 12.x
$items = Model::all()->load('parent');

// Example - When to NEVER comment:

// BAD - comment is useless
// Publish the article
$this->articlesLibrary->publishArticle($article->ID, now());
// GOOD - no comment needed
$this->articlesLibrary->publishArticle($article->ID, now());
```

Your default behaviour: Write code. Ship code. No comments. If you catch yourself about to write a comment, stop and refactor instead.

This makes the hierarchy crystal clear:
1. Default = no comments
2. Refactor first (always)
3. Only comment for documented workarounds with ticket references
4. Tests get zero comments (except regression test references)

### 2.3 Docblocks

You **MUST** avoid docblocks where type systems and function signatures provide sufficient information.

You **MAY ONLY** use docblocks when:
- Required for API documentation generation
- Providing usage examples for complex public APIs
- Documenting framework-specific annotations or decorators
- Type information alone cannot convey the contract

---

## 3. Code Organisation

### 3.1 Function and Method Length

You **SHOULD** keep functions concise and focused:
- Aim for functions under 20 lines where practical
- Extract complex logic into well-named helper functions
- If a function requires extensive commenting, consider decomposition

### 3.2 File Structure

You **SHOULD** organise files to reflect domain concepts:
- One primary class or module per file (language-dependent)
- Group related functionality together
- Use directory structure to represent architectural boundaries

### 3.3 Naming Conventions

You **MUST** follow language-specific conventions while prioritising clarity:
- Use full words over abbreviations unless the abbreviation is ubiquitous (e.g., `HTTP`, `URL`, `ID`)
- Avoid single-letter variables except in narrow scopes (loop counters, mathematical formulae)
- Boolean variables should read as predicates: `isActive`, `hasPermission`, `canExecute`

---

## 4. Error Handling

### 4.1 Explicit Error States

You **SHOULD** make error conditions explicit and handled:
- Avoid silent failures
- Use exceptions for exceptional circumstances, not control flow
- Validate input at system boundaries
- Return explicit error types where appropriate (Result/Either types)

### 4.2 Error Messages

You **MUST** provide actionable error messages:
- Describe what went wrong
- Include relevant context (what operation was attempted)
- Suggest remediation where applicable
- Use British English

---

## 5. Dependencies and Imports

### 5.1 Dependency Management

You **SHOULD** minimise external dependencies:
- Evaluate whether a dependency is truly necessary
- Prefer standard library solutions where adequate
- Consider maintenance burden and security implications

### 5.2 Import Organisation

You **SHOULD** organise imports logically:
- Group by type (standard library, third-party, local)
- Sort alphabetically within groups (allow formatting tools to handle this if defined in project instructions)
- Remove unused imports

---

## 6. Testing

### 6.1 Test Naming

You **MUST** write descriptive test names that explain the scenario:
- Use complete sentences or clear phrases
- Describe the expected behaviour, not implementation
- Make failures self-explanatory

Example:
```typescript
// Good
test('calculateOrderTotalIncludingVAT adds 20% VAT to subtotal')
test('user authentication fails when password is incorrect')

// Poor
test('test1')
test('calcTotal')
```

### 6.2 Test Structure

You **SHOULD** follow Arrange-Act-Assert pattern:
- Setup test data (Arrange)
- Execute the code under test (Act)
- Verify outcomes (Assert)

---

## 7. Version Control

### 7.1 General Rule

You **MUST** never commit, push, or perform destructive version control commands without explicit permission from the user.

---

## 8. Performance and Optimisation

### 8.1 Premature Optimisation

You **SHOULD** prioritise correctness and clarity over premature optimisation:
- Write clear code first
- Measure performance before optimising
- Document performance-critical sections when optimisation affects readability

### 8.2 Resource Management

You **MUST** handle resources properly:
- Close file handles, database connections, network sockets
- Use language-appropriate patterns (RAII, defer, using statements, context managers)
- Avoid resource leaks

---

## 9. Security

### 9.1 Input Validation

You **MUST** validate and sanitise external input:
- Never trust user input
- Validate at system boundaries
- Use parameterised queries for database access
- Encode output appropriately for context

### 9.2 Sensitive Data

You **MUST NOT** commit sensitive data:
You **MUST** point out to the user if there is potential to commit sensitive data:
- Credentials, API keys, tokens
- Personal or confidential information
- Use environment variables or secure secret management

---

## 10. Accessibility and Inclusivity

### 10.1 Inclusive Language

You **SHOULD** use inclusive, professional terminology:
- Avoid unnecessarily gendered language
- Use industry-standard terms that are clear and respectful
- Prefer `allowlist/denylist` over `whitelist/blacklist`
- Prefer `main` over `master` for primary branches

---

## 11. Consistency

### 11.1 Follow Existing Patterns

You **MUST** maintain consistency with existing codebase:
- Match established patterns and conventions
- If improving patterns, refactor consistently
- Don't mix styles within a file or module

### 11.2 Formatters and Linters

You **SHOULD** use automated tooling where available:
- Code formatters (Prettier, Black, gofmt, rustfmt)
- Linters (ESLint, Pylint, RuboCop, Clippy)
- Static analysis tools
- Respect existing tool configurations

---

## 12. Documentation

### 12.1 README Files

You **SHOULD** maintain clear README documentation:
- Installation instructions
- Usage examples
- Architecture overview (for complex projects)
- Contribution guidelines

### 12.2 Architectural Documentation

You **MAY** provide architectural documentation for complex systems:
- System diagrams
- Decision records (ADRs)
- API specifications
- Deployment guides

---

## Compliance

These guidelines **MUST** be followed unless:
1. Language-specific conventions dictate otherwise
2. Project-specific requirements in CLAUDE.md or AGENTS.md override them
3. The user explicitly requests a different approach

When in doubt, prioritise clarity, maintainability, and consistency with the existing codebase.
