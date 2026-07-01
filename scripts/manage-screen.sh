#!/bin/bash

# Usage:
#   Start a task screen session:
#     ./scripts/manage-screen.sh start <task_name>
#   Change status of a task screen session (using task name or PID):
#     ./scripts/manage-screen.sh status <task_name|pid> <new_status>

COMMAND=$1
TARGET=$2
NEW_STATUS=$3

TASK_DIR="docs/tasks"

if [ -z "$COMMAND" ] || [ -z "$TARGET" ]; then
    echo "Usage:"
    echo "  Start task screen session:  $0 start <task_name>"
    echo "  Change session status:      $0 status <task_name|pid> <new_status>"
    exit 1
fi

# Helper function to find the markdown task file
find_task_file() {
    local target=$1
    if [ -f "$TASK_DIR/$target.md" ]; then
        echo "$TASK_DIR/$target.md"
    else
        # Try finding by PID inside yaml frontmatter of the markdown files
        local file=$(grep -l "^pid:[[:space:]]*$target" "$TASK_DIR"/*.md 2>/dev/null | head -n 1)
        if [ -n "$file" ]; then
            echo "$file"
        else
            # Try finding by task name pattern
            local file_by_name=$(find "$TASK_DIR" -name "*$target*.md" | head -n 1)
            if [ -n "$file_by_name" ]; then
                echo "$file_by_name"
            fi
        fi
    fi
}

# Helper function to update yaml frontmatter fields
update_task_field() {
    local file=$1
    local key=$2
    local value=$3
    
    if [ ! -f "$file" ]; then
        return 1
    fi

    # If the key already exists in YAML frontmatter, replace it. Otherwise, insert it before the second '---'
    if grep -q "^$key:" "$file"; then
        # Use a temporary file for safety across different OS sed versions
        sed "s/^$key:.*/$key: $value/" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    else
        # Insert key-value pair right before the second '---'
        awk -v key="$key" -v val="$value" '
        /^---$/ { count++ }
        count == 2 { print key ": " val; count = 0 }
        { print }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
}

# Helper function to get value from YAML frontmatter
get_task_field() {
    local file=$1
    local key=$2
    if [ -f "$file" ]; then
        grep "^$key:" "$file" | head -n 1 | cut -d':' -f2- | tr -d ' '
    fi
}

if [ "$COMMAND" = "start" ]; then
    TASK_NAME=$TARGET
    TASK_FILE="$TASK_DIR/$TASK_NAME.md"

    if [ ! -f "$TASK_FILE" ]; then
        echo "Error: Task file $TASK_FILE not found."
        exit 1
    fi

    # === Pre-flight Environment Checks ===
    
    # 1. Check if 'screen' (GNU Screen) command exists
    if ! command -v screen &> /dev/null; then
        echo "Error: 'screen' (GNU Screen) is not installed or not in PATH."
        echo "Please install screen before starting tasks (e.g. 'pacman -S screen' in MSYS2, or 'apt install screen' in WSL)."
        exit 1
    fi

    # 2. Check if the specified agent CLI is installed
    AGENT_CLI_VAL=$(get_task_field "$TASK_FILE" "agent_cli")
    
    # Resolve target CLI executable
    case "$AGENT_CLI_VAL" in
        sonnet|opus|claude)
            REQUIRED_CLI="claude"
            ;;
        agy|antigravity)
            REQUIRED_CLI="agy"
            ;;
        *)
            REQUIRED_CLI="${AI_CLI:-agy}"
            ;;
    esac

    # Extract only the binary command name (e.g., "claude" from "claude -m ...")
    CLI_BIN=$(echo "$REQUIRED_CLI" | awk '{print $1}')
    if ! command -v "$CLI_BIN" &> /dev/null; then
        echo "Error: Required agent CLI '$CLI_BIN' is not installed or not in PATH."
        echo "Please ensure the CLI is installed and running before starting tasks."
        exit 1
    fi

    # === Environment Checks Passed ===

    STATUS="planning"
    SESSION_NAME="${STATUS}-${TASK_NAME}"

    echo "Starting screen session: $SESSION_NAME"
    # Start screen in detached mode and run the automatic lifecycle runner
    screen -S "$SESSION_NAME" -d -m ./scripts/run-lifecycle.sh "$TASK_NAME"

    # Wait briefly for screen to register
    sleep 0.5

    # Get the PID of the created session
    PID=$(screen -ls | grep -E "[0-9]+\.${SESSION_NAME}" | awk '{print $1}' | cut -d'.' -f1)

    if [ -n "$PID" ]; then
        echo "Screen started successfully with PID: $PID"
        update_task_field "$TASK_FILE" "pid" "$PID"
        update_task_field "$TASK_FILE" "status" "$STATUS"
    else
        echo "Warning: Could not retrieve Screen PID. Ensure screen session was initiated correctly."
    fi

elif [ "$COMMAND" = "status" ]; then
    if [ -z "$NEW_STATUS" ]; then
        echo "Error: New status is required. Choose from: planning, doing, reviewing, fixing, done"
        exit 1
    fi

    case "$NEW_STATUS" in
        planning|doing|reviewing|fixing|done) ;;
        *)
            echo "Error: Invalid status '$NEW_STATUS'. Use planning, doing, reviewing, fixing, or done."
            exit 1
            ;;
    esac

    TASK_FILE=$(find_task_file "$TARGET")

    if [ -z "$TASK_FILE" ] || [ ! -f "$TASK_FILE" ]; then
        echo "Error: Task file not found for target '$TARGET'"
        exit 1
    fi

    TASK_NAME=$(basename "$TASK_FILE" .md)
    OLD_PID=$(get_task_field "$TASK_FILE" "pid")
    OLD_STATUS=$(get_task_field "$TASK_FILE" "status")

    if [ -z "$OLD_STATUS" ]; then
        OLD_STATUS="planning"
    fi

    NEW_SESSION_NAME="${NEW_STATUS}-${TASK_NAME}"

    if [ -n "$OLD_PID" ] && screen -ls | grep -q -E "^[[:space:]]*${OLD_PID}\."; then
        echo "Updating screen session PID $OLD_PID name to $NEW_SESSION_NAME"
        screen -S "$OLD_PID" -X sessionname "$NEW_SESSION_NAME"
    else
        # Fallback to name-based match if PID is missing or session was restarted
        OLD_SESSION_NAME="${OLD_STATUS}-${TASK_NAME}"
        if screen -ls | grep -q -E "\.${OLD_SESSION_NAME}[[:space:]]"; then
            echo "Updating screen session $OLD_SESSION_NAME to $NEW_SESSION_NAME"
            screen -S "$OLD_SESSION_NAME" -X sessionname "$NEW_SESSION_NAME"
            
            # Re-fetch PID and save it
            NEW_PID=$(screen -ls | grep -E "[0-9]+\.${NEW_SESSION_NAME}" | awk '{print $1}' | cut -d'.' -f1)
            if [ -n "$NEW_PID" ]; then
                update_task_field "$TASK_FILE" "pid" "$NEW_PID"
            fi
        else
            echo "Screen session for $TASK_NAME not running. Updating file only."
        fi
    fi

    # Update metadata in markdown file
    update_task_field "$TASK_FILE" "status" "$NEW_STATUS"
    echo "Task $TASK_NAME status updated to $NEW_STATUS."

else
    echo "Unknown command: $COMMAND"
    exit 1
fi
