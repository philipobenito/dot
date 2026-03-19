#!/usr/bin/env bash
#
# AI Config Generator
# Generates agent and skill files for different AI coding tools from a single source
#
# Supported tools:
#   - Claude Code (.claude/agents/, .claude/skills/)
#   - OpenCode (.config/opencode/agents/, .config/opencode/skills/)
#
# Run './ai/generate.sh format' to see full source format documentation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Source directories
AGENTS_DIR="$SCRIPT_DIR/agents"
SKILLS_DIR="$SCRIPT_DIR/skills"
INSTRUCTIONS_SOURCE="$SCRIPT_DIR/instructions.md"

# Output directories
CLAUDE_DIR="$ROOT_DIR/claude/.claude/agents"
CLAUDE_SKILLS_DIR="$ROOT_DIR/claude/.claude/skills"
CLAUDE_INSTRUCTIONS="$ROOT_DIR/claude/.claude/CLAUDE.md"
OPENCODE_DIR="$ROOT_DIR/opencode/.config/opencode/agents"
OPENCODE_SKILLS_DIR="$ROOT_DIR/opencode/.config/opencode/skills"
OPENCODE_INSTRUCTIONS="$ROOT_DIR/opencode/.config/opencode/AGENTS.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { [[ "${DEBUG:-}" == "1" ]] && echo -e "${BLUE}[DEBUG]${NC} $1" || true; }

# Skill template variables per tool
# These map {{VAR}} placeholders in skill source files to tool-specific values
CLAUDE_ASK_USER_TOOL="AskUserQuestion"
CLAUDE_INVOKE_SKILL_TOOL="Skill"
CLAUDE_TASK_TRACKER_TOOL="TodoWrite"
CLAUDE_DISPATCH_AGENT_TOOL="Agent"
CLAUDE_ENTER_PLAN_TOOL="EnterPlanMode"

OPENCODE_ASK_USER_TOOL="AskUserQuestion"
OPENCODE_INVOKE_SKILL_TOOL="Skill"
OPENCODE_TASK_TRACKER_TOOL="TodoWrite"
OPENCODE_DISPATCH_AGENT_TOOL="Agent"
OPENCODE_ENTER_PLAN_TOOL="EnterPlanMode"

# Global variables set by parse_agent_file
DESCRIPTION=""
MODEL=""
MODE=""
TEMPERATURE=""
MAX_STEPS=""
PERMISSION_MODE=""
HIDDEN=""
TOOLS_ARRAY=()
PERMISSIONS_EDIT=""
PERMISSIONS_BASH=""
PERMISSIONS_WEBFETCH=""
BODY=""

# Capitalize first letter (portable)
capitalize() {
    local str="$1"
    local first="${str:0:1}"
    local rest="${str:1}"
    echo "$(echo "$first" | tr '[:lower:]' '[:upper:]')$rest"
}

# Check if array contains element
array_contains() {
    local needle="$1"
    shift
    for element in "$@"; do
        [[ "$element" == "$needle" ]] && return 0
    done
    return 1
}

# Parse a value from frontmatter (simple key: value)
parse_value() {
    local key="$1"
    local frontmatter="$2"
    echo "$frontmatter" | grep "^${key}:" | sed "s/^${key}: *//" | sed 's/^"//' | sed 's/"$//' | head -1 || true
}

# Parse a markdown file with YAML frontmatter
parse_agent_file() {
    local file="$1"
    
    # Reset globals
    DESCRIPTION=""
    MODEL=""
    MODE=""
    TEMPERATURE=""
    MAX_STEPS=""
    PERMISSION_MODE=""
    HIDDEN=""
    TOOLS_ARRAY=()
    PERMISSIONS_EDIT=""
    PERMISSIONS_BASH=""
    PERMISSIONS_WEBFETCH=""
    BODY=""
    
    local content
    content=$(cat "$file")
    
    # Extract frontmatter and body
    local in_frontmatter=false
    local frontmatter=""
    local body=""
    local found_first_marker=false
    local found_second_marker=false
    
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if [[ "$found_first_marker" == false ]]; then
                found_first_marker=true
                in_frontmatter=true
                continue
            else
                found_second_marker=true
                in_frontmatter=false
                continue
            fi
        fi
        
        if [[ "$in_frontmatter" == true ]]; then
            frontmatter+="$line"$'\n'
        elif [[ "$found_second_marker" == true ]]; then
            body+="$line"$'\n'
        fi
    done <<< "$content"
    
    # Parse simple values
    DESCRIPTION=$(parse_value "description" "$frontmatter")
    MODEL=$(parse_value "model" "$frontmatter")
    MODE=$(parse_value "mode" "$frontmatter")
    TEMPERATURE=$(parse_value "temperature" "$frontmatter")
    MAX_STEPS=$(parse_value "maxSteps" "$frontmatter")
    PERMISSION_MODE=$(parse_value "permissionMode" "$frontmatter")
    HIDDEN=$(parse_value "hidden" "$frontmatter")
    
    # Parse tools array
    TOOLS_ARRAY=()
    local in_tools=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^tools: ]]; then
            in_tools=true
            continue
        fi
        if [[ "$in_tools" == true ]]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.*) ]]; then
                TOOLS_ARRAY+=("${BASH_REMATCH[1]}")
            elif [[ ! "$line" =~ ^[[:space:]] ]] && [[ -n "$line" ]]; then
                break
            fi
        fi
    done <<< "$frontmatter"
    
    # Parse permissions block
    local in_permissions=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^permissions: ]]; then
            in_permissions=true
            continue
        fi
        if [[ "$in_permissions" == true ]]; then
            if [[ "$line" =~ ^[[:space:]]+edit:[[:space:]]*(.*) ]]; then
                PERMISSIONS_EDIT="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]+bash:[[:space:]]*(.*) ]]; then
                PERMISSIONS_BASH="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]+webfetch:[[:space:]]*(.*) ]]; then
                PERMISSIONS_WEBFETCH="${BASH_REMATCH[1]}"
            elif [[ ! "$line" =~ ^[[:space:]] ]] && [[ -n "$line" ]]; then
                break
            fi
        fi
    done <<< "$frontmatter"
    
    # Remove leading empty lines from body
    BODY=$(echo "$body" | sed '/./,$!d')
    
    log_debug "Parsed: model=$MODEL mode=$MODE temp=$TEMPERATURE tools=${TOOLS_ARRAY[*]+${TOOLS_ARRAY[*]}}"
}

# Map model alias to OpenCode format
map_model_to_opencode() {
    local model="$1"
    case "$model" in
        sonnet|"") echo "anthropic/claude-sonnet-4-20250514" ;;
        opus) echo "anthropic/claude-opus-4-20250514" ;;
        haiku) echo "anthropic/claude-haiku-4-20250514" ;;
        inherit) echo "" ;;
        *) echo "$model" ;;
    esac
}

# Generate Claude Code format
generate_claude() {
    local source_file="$1"
    local agent_name
    agent_name=$(basename "$source_file" .md)
    local output_file="$CLAUDE_DIR/$agent_name.md"
    
    parse_agent_file "$source_file"
    
    # Build tools list (comma-separated, capitalized)
    local tools_list=""
    if [[ ${#TOOLS_ARRAY[@]} -gt 0 ]]; then
        for tool in "${TOOLS_ARRAY[@]}"; do
            local cap_tool
            cap_tool=$(capitalize "$tool")
            if [[ -n "$tools_list" ]]; then
                tools_list+=", $cap_tool"
            else
                tools_list="$cap_tool"
            fi
        done
    fi
    
    # Start frontmatter
    local fm="---
name: $agent_name
description: $DESCRIPTION"
    
    # Add tools if specified
    if [[ -n "$tools_list" ]]; then
        fm+="
tools: $tools_list"
    fi
    
    # Add model (default to sonnet)
    local model="${MODEL:-sonnet}"
    if [[ "$model" != "inherit" ]]; then
        fm+="
model: $model"
    fi
    
    # Add permissionMode if specified
    if [[ -n "$PERMISSION_MODE" ]]; then
        fm+="
permissionMode: $PERMISSION_MODE"
    fi
    
    fm+="
---"
    
    # Write file
    echo "$fm" > "$output_file"
    echo "" >> "$output_file"
    echo "$BODY" >> "$output_file"
    
    log_info "Claude: $agent_name"
}

# Generate OpenCode format
generate_opencode() {
    local source_file="$1"
    local agent_name
    agent_name=$(basename "$source_file" .md)
    local output_file="$OPENCODE_DIR/$agent_name.md"
    
    parse_agent_file "$source_file"
    
    # Start frontmatter
    local fm="---
description: $DESCRIPTION
mode: ${MODE:-subagent}"
    
    # Add model if specified and not inherit
    if [[ -n "$MODEL" ]] && [[ "$MODEL" != "inherit" ]]; then
        local opencode_model
        opencode_model=$(map_model_to_opencode "$MODEL")
        if [[ -n "$opencode_model" ]]; then
            fm+="
model: $opencode_model"
        fi
    fi
    
    # Add temperature if specified
    if [[ -n "$TEMPERATURE" ]]; then
        fm+="
temperature: $TEMPERATURE"
    fi
    
    # Add maxSteps if specified
    if [[ -n "$MAX_STEPS" ]]; then
        fm+="
maxSteps: $MAX_STEPS"
    fi
    
    # Add hidden if true
    if [[ "$HIDDEN" == "true" ]]; then
        fm+="
hidden: true"
    fi
    
    # Build tools section for restrictions
    local has_restriction=false
    if [[ ${#TOOLS_ARRAY[@]} -gt 0 ]]; then
        if ! array_contains "write" "${TOOLS_ARRAY[@]}" || \
           ! array_contains "edit" "${TOOLS_ARRAY[@]}" || \
           ! array_contains "bash" "${TOOLS_ARRAY[@]}"; then
            has_restriction=true
        fi
    fi
    
    if [[ "$has_restriction" == true ]]; then
        fm+="
tools:"
        if ! array_contains "write" "${TOOLS_ARRAY[@]}"; then
            fm+="
  write: false"
        fi
        if ! array_contains "edit" "${TOOLS_ARRAY[@]}"; then
            fm+="
  edit: false"
        fi
        if ! array_contains "bash" "${TOOLS_ARRAY[@]}"; then
            fm+="
  bash: false"
        fi
    fi
    
    # Add permissions if specified
    if [[ -n "$PERMISSIONS_EDIT" ]] || [[ -n "$PERMISSIONS_BASH" ]] || [[ -n "$PERMISSIONS_WEBFETCH" ]]; then
        fm+="
permission:"
        [[ -n "$PERMISSIONS_EDIT" ]] && fm+="
  edit: $PERMISSIONS_EDIT"
        [[ -n "$PERMISSIONS_BASH" ]] && fm+="
  bash: $PERMISSIONS_BASH"
        [[ -n "$PERMISSIONS_WEBFETCH" ]] && fm+="
  webfetch: $PERMISSIONS_WEBFETCH"
    fi
    
    fm+="
---"
    
    # Write file
    echo "$fm" > "$output_file"
    echo "" >> "$output_file"
    echo "$BODY" >> "$output_file"
    
    log_info "OpenCode: $agent_name"
}

# Apply tool-specific template variables to all .md files in a directory
apply_tool_vars() {
    local dir="$1"
    local prefix="$2"

    local ask_user="${prefix}_ASK_USER_TOOL"
    local invoke_skill="${prefix}_INVOKE_SKILL_TOOL"
    local task_tracker="${prefix}_TASK_TRACKER_TOOL"
    local dispatch_agent="${prefix}_DISPATCH_AGENT_TOOL"
    local enter_plan="${prefix}_ENTER_PLAN_TOOL"

    for md_file in "$dir"/*.md; do
        [[ -f "$md_file" ]] || continue
        local tmp="${md_file}.tmp"
        sed -e "s/{{ASK_USER_TOOL}}/${!ask_user}/g" \
            -e "s/{{INVOKE_SKILL_TOOL}}/${!invoke_skill}/g" \
            -e "s/{{TASK_TRACKER_TOOL}}/${!task_tracker}/g" \
            -e "s/{{DISPATCH_AGENT_TOOL}}/${!dispatch_agent}/g" \
            -e "s/{{ENTER_PLAN_TOOL}}/${!enter_plan}/g" \
            "$md_file" > "$tmp"
        mv "$tmp" "$md_file"
    done
}

# Copy skill directory to output location with template variable substitution
copy_skill() {
    local skill_dir="$1"
    local output_base="$2"
    local label="$3"
    local tool_prefix="$4"
    local skill_name
    skill_name=$(basename "$skill_dir")
    local output_dir="$output_base/$skill_name"

    mkdir -p "$output_dir"
    cp -r "$skill_dir"/* "$output_dir/"
    apply_tool_vars "$output_dir" "$tool_prefix"

    log_info "$label skill: $skill_name"
}

generate_instructions() {
    local output="$1"
    local label="$2"
    local tool_name="$3"
    local instructions_file="$4"

    sed -e "s/{{TOOL_NAME}}/$tool_name/g" \
        -e "s/{{INSTRUCTIONS_FILE}}/$instructions_file/g" \
        "$INSTRUCTIONS_SOURCE" > "$output"

    log_info "$label: $(basename "$output")"
}

# Clean generated files
clean() {
    log_info "Cleaning generated files..."
    rm -f "$CLAUDE_DIR"/*.md 2>/dev/null || true
    rm -rf "$CLAUDE_SKILLS_DIR" 2>/dev/null || true
    rm -f "$CLAUDE_INSTRUCTIONS" 2>/dev/null || true
    rm -f "$OPENCODE_DIR"/*.md 2>/dev/null || true
    rm -rf "$OPENCODE_SKILLS_DIR" 2>/dev/null || true
    rm -f "$OPENCODE_INSTRUCTIONS" 2>/dev/null || true
    log_info "Clean complete"
}

# Generate all agents and skills
generate_all() {
    log_info "Generating from source..."
    echo ""

    mkdir -p "$CLAUDE_DIR" "$OPENCODE_DIR"
    mkdir -p "$CLAUDE_SKILLS_DIR" "$OPENCODE_SKILLS_DIR"

    if [[ -f "$INSTRUCTIONS_SOURCE" ]]; then
        generate_instructions "$CLAUDE_INSTRUCTIONS" "Claude Code" "Claude Code" "CLAUDE.md"
        generate_instructions "$OPENCODE_INSTRUCTIONS" "OpenCode" "OpenCode" "AGENTS.md"
    else
        log_warn "No instructions source found at $INSTRUCTIONS_SOURCE"
    fi

    local agent_count=0
    for source_file in "$AGENTS_DIR"/*.md; do
        [[ -f "$source_file" ]] || continue
        [[ "$(basename "$source_file")" == "README.md" ]] && continue

        generate_claude "$source_file"
        generate_opencode "$source_file"
        ((++agent_count))
    done

    local skill_count=0
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        [[ -f "$skill_dir/SKILL.md" ]] || continue

        copy_skill "$skill_dir" "$CLAUDE_SKILLS_DIR" "Claude" "CLAUDE"
        copy_skill "$skill_dir" "$OPENCODE_SKILLS_DIR" "OpenCode" "OPENCODE"
        ((++skill_count))
    done

    echo ""
    log_info "Generated $agent_count agents and $skill_count skills for each tool"
    echo ""
    log_info "Output locations:"
    echo "  Claude Code instructions: $CLAUDE_INSTRUCTIONS"
    echo "  Claude Code agents:       $CLAUDE_DIR"
    echo "  Claude Code skills:       $CLAUDE_SKILLS_DIR"
    echo "  OpenCode instructions:    $OPENCODE_INSTRUCTIONS"
    echo "  OpenCode agents:          $OPENCODE_DIR"
    echo "  OpenCode skills:          $OPENCODE_SKILLS_DIR"
    echo ""
    log_info "Run 'stow claude opencode' to deploy"
}

# List source agents and skills with descriptions
list_agents() {
    log_info "Source agents in $AGENTS_DIR:"
    echo ""
    printf "  %-22s %-8s %s\n" "NAME" "MODEL" "DESCRIPTION"
    printf "  %-22s %-8s %s\n" "----" "-----" "-----------"
    for source_file in "$AGENTS_DIR"/*.md; do
        [[ -f "$source_file" ]] || continue
        [[ "$(basename "$source_file")" == "README.md" ]] && continue
        local name
        name=$(basename "$source_file" .md)
        parse_agent_file "$source_file"
        printf "  %-22s %-8s %s\n" "$name" "${MODEL:-sonnet}" "${DESCRIPTION:0:45}..."
    done

    echo ""
    log_info "Source skills in $SKILLS_DIR:"
    echo ""
    printf "  %-35s %-8s %s\n" "NAME" "FILES" "DESCRIPTION"
    printf "  %-35s %-8s %s\n" "----" "-----" "-----------"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        [[ -f "$skill_dir/SKILL.md" ]] || continue
        local name
        name=$(basename "$skill_dir")
        parse_agent_file "$skill_dir/SKILL.md"
        local supporting
        supporting=$(find "$skill_dir" -maxdepth 1 -name "*.md" ! -name "SKILL.md" | wc -l | tr -d ' ')
        printf "  %-35s %-8s %s\n" "$name" "+${supporting}" "${DESCRIPTION:0:40}..."
    done
}

# Show format documentation
format_help() {
    cat << 'EOF'
Agent Source Format
===================

Place .md files in agents/ with YAML frontmatter:

```yaml
---
# Required
description: Brief description of what the agent does

# Model selection (default: sonnet)
# Options: sonnet, opus, haiku, inherit
model: sonnet

# Tools the agent can use (allowlist)
tools:
  - read
  - write
  - edit
  - bash
  - glob
  - grep

# === OpenCode-specific options ===

# How agent can be used (default: subagent)
# Options: primary, subagent, all
mode: subagent

# Response randomness (0.0-1.0)
temperature: 0.3

# Max agentic iterations before forcing text response
maxSteps: 10

# Hide from @ autocomplete
hidden: false

# Granular tool permissions
# Options: ask, allow, deny
permissions:
  edit: ask
  bash: allow
  webfetch: deny

# === Claude Code-specific options ===

# Permission handling mode
# Options: default, acceptEdits, dontAsk, bypassPermissions, plan
permissionMode: default
---

Your system prompt in markdown.
This becomes the agent's instructions.
```

Field Mapping
=============

Source Field      → Claude Code           → OpenCode
--------------    ------------------      -----------------------
description       description             description
model             model (as-is)           model (mapped to provider/id)
tools             tools (capitalized)     tools (as restrictions)
mode              (ignored)               mode
temperature       (ignored)               temperature
maxSteps          (ignored)               maxSteps
hidden            (ignored)               hidden
permissions       (ignored)               permission
permissionMode    permissionMode          (ignored)

Model Mapping (OpenCode)
========================
sonnet  → anthropic/claude-sonnet-4-20250514
opus    → anthropic/claude-opus-4-20250514
haiku   → anthropic/claude-haiku-4-20250514
inherit → (no model field, inherits from parent)

Tool Restriction Logic (OpenCode)
=================================
If tools list is missing write/edit/bash, those are set to false.
Example: tools: [read, grep, glob] → tools: { write: false, edit: false, bash: false }

Skill Source Format
===================

Place skill directories in skills/ with a SKILL.md and optional supporting files:

    skills/
      my-skill/
        SKILL.md                      # Required: main skill definition
        prompt-template.md            # Optional: supporting file
        anti-patterns.md              # Optional: supporting file

SKILL.md format:

\`\`\`yaml
---
name: my-skill
description: "Brief description of when/how to use this skill"
---

Skill instructions in markdown.
Reference supporting files with ./filename.md syntax.
\`\`\`

Skill Template Variables
========================

Skills can use {{VAR}} placeholders for tool-specific references.
These are substituted per target tool during generation.

Variable                 Claude Code          OpenCode
-----------------------  -------------------  -------------------
{{ASK_USER_TOOL}}        AskUserQuestion      AskUserQuestion
{{INVOKE_SKILL_TOOL}}    Skill                Skill
{{TASK_TRACKER_TOOL}}    TodoWrite            TodoWrite
{{DISPATCH_AGENT_TOOL}}  Agent                Agent
{{ENTER_PLAN_TOOL}}      EnterPlanMode        EnterPlanMode

Update the variable mappings at the top of generate.sh when
OpenCode equivalents are confirmed.

Skill Output Mapping
=====================

Skill directories are copied with template variable substitution
applied to all .md files.

Source                          Claude Code                         OpenCode
------------------------------  ----------------------------------  ------------------------------------
skills/<name>/SKILL.md          .claude/skills/<name>/SKILL.md      .config/opencode/skills/<name>/SKILL.md
skills/<name>/<file>.md         .claude/skills/<name>/<file>.md     .config/opencode/skills/<name>/<file>.md
EOF
}

usage() {
    cat << EOF
Usage: $(basename "$0") [command]

Commands:
    generate    Generate agents and skills for all tools (default)
    clean       Remove all generated files
    list        List source agents and skills with details
    format      Show source file format documentation
    help        Show this help message

Environment:
    DEBUG=1     Enable debug output

Examples:
    $(basename "$0")              # Generate all agents and skills
    $(basename "$0") list         # List agents and skills
    $(basename "$0") format       # Show format docs
    DEBUG=1 $(basename "$0")      # Generate with debug
EOF
}

main() {
    local command="${1:-generate}"
    
    case "$command" in
        generate) generate_all ;;
        clean) clean ;;
        list) list_agents ;;
        format) format_help ;;
        help|--help|-h) usage ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
