#!/bin/bash

# Usage: ./scripts/run-lifecycle.sh <task_name>
# This script runs inside a screen session and drives the automatic lifecycle of a single task:
#   planning/doing/fixing (implementer) -> reviewing (reviewer) -> done (pr-create)
#
# Implementation tasks use the tool/model specified in the task's 'agent_cli' field.
# Code reviews and PR creations are handled by the parent agent (Opus) who authored the spec and plan.

TASK_NAME=$1
TASK_FILE="docs/tasks/${TASK_NAME}.md"
NOTIFY_SCRIPT="./scripts/notify.sh"

if [ -z "$TASK_NAME" ] || [ ! -f "$TASK_FILE" ]; then
    echo "Error: Task name is required and the markdown file must exist."
    echo "Usage: $0 <task_name>"
    exit 1
fi

get_status() {
    grep "^status:" "$TASK_FILE" | head -n 1 | cut -d':' -f2- | tr -d ' '
}

get_pid() {
    grep "^pid:" "$TASK_FILE" | head -n 1 | cut -d':' -f2- | tr -d ' '
}

get_agent_cli() {
    grep "^agent_cli:" "$TASK_FILE" | head -n 1 | cut -d':' -f2- | tr -d ' '
}

# Resolve target command execution based on metadata or role
resolve_cli_command() {
    local val=$1
    case "$val" in
        sonnet)
            echo "claude -m claude-3-5-sonnet"
            ;;
        opus)
            echo "claude -m claude-3-opus"
            ;;
        claude)
            echo "claude"
            ;;
        agy|antigravity)
            echo "agy"
            ;;
        *)
            echo "${AI_CLI:-agy}"
            ;;
    esac
}

# Check if command binary is executable
check_executable() {
    local full_cmd=$1
    local cmd_bin=$(echo "$full_cmd" | awk '{print $1}')
    if ! command -v "$cmd_bin" &> /dev/null; then
        echo "Error: Required command CLI '$cmd_bin' is not installed or not in PATH."
        if [ -f "$NOTIFY_SCRIPT" ]; then
            "$NOTIFY_SCRIPT" "Lifecycle error: '$cmd_bin' is not executable. Session terminated."
        fi
        exit 1
    fi
}

# Resolve implementer CLI (from task metadata)
AGENT_CLI_VAL=$(get_agent_cli)
IMPLEMENTER_CLI=$(resolve_cli_command "$AGENT_CLI_VAL")

# Resolve parent/reviewer CLI (Always Opus for design integrity)
PARENT_CLI=$(resolve_cli_command "opus")

# === Check if required CLI executables exist before running loop ===
check_executable "$IMPLEMENTER_CLI"
check_executable "$PARENT_CLI"

echo "Resolved Implementer: $IMPLEMENTER_CLI"
echo "Resolved Reviewer/Orchestrator: $PARENT_CLI"

echo "=== Starting Automatic Lifecycle for $TASK_NAME ==="

while true; do
    STATUS=$(get_status)
    echo "[$(date '+%H:%M:%S')] Current Status: $STATUS"

    case "$STATUS" in
        planning|doing|fixing)
            echo "Invoking implementer agent for $TASK_NAME using $IMPLEMENTER_CLI..."
            $IMPLEMENTER_CLI /start-with-plan "$TASK_NAME"
            
            # Check if status has advanced. If not, notify user and pause.
            NEW_STATUS=$(get_status)
            if [ "$NEW_STATUS" = "$STATUS" ]; then
                echo "Warning: Implementer did not advance status. Agent might be waiting for input."
                if [ -f "$NOTIFY_SCRIPT" ]; then
                    "$NOTIFY_SCRIPT" "Implementer for task $TASK_NAME needs attention (Status remains $STATUS)."
                fi
                sleep 30
            fi
            ;;

        reviewing)
            # The review MUST be done by the parent agent (Opus) who planned the task
            echo "Invoking parent reviewer agent for $TASK_NAME using $PARENT_CLI..."
            $PARENT_CLI /code-review "$TASK_NAME"
            
            NEW_STATUS=$(get_status)
            if [ "$NEW_STATUS" = "reviewing" ]; then
                echo "Warning: Parent reviewer did not advance status. Agent might be waiting for input."
                if [ -f "$NOTIFY_SCRIPT" ]; then
                    "$NOTIFY_SCRIPT" "Parent reviewer for task $TASK_NAME needs attention (Status remains reviewing)."
                fi
                sleep 30
            fi
            ;;

        done)
            echo "Task $TASK_NAME is done. Creating Pull Request using $PARENT_CLI..."
            $PARENT_CLI /pr-create "$TASK_NAME"
            
            if [ -f "$NOTIFY_SCRIPT" ]; then
                "$NOTIFY_SCRIPT" "Task $TASK_NAME successfully completed and PR created."
            fi
            echo "=== Lifecycle Completed for $TASK_NAME ==="
            exit 0
            ;;

        *)
            echo "Unknown or unexpected status '$STATUS'. Pausing execution."
            if [ -f "$NOTIFY_SCRIPT" ]; then
                "$NOTIFY_SCRIPT" "Task $TASK_NAME encountered unexpected status: $STATUS"
            fi
            sleep 60
            ;;
    esac

    # Cool down period between cycles
    sleep 3
done
