#!/bin/bash

# WezTerm Auto-rename Script - Complete Replication
# This script replicates WezTerm's automatic tab renaming functionality
# Original logic from events.lua lines 83-136

# Get the current pane ID and working directory
PANE_ID=$(tmux display-message -p '#{pane_id}')
CURRENT_PATH=$(tmux display-message -p '#{pane_current_path}')

# Remove HOME prefix (like WezTerm's rm_home logic)
if [[ "$CURRENT_PATH" == "$HOME"* ]]; then
    PATH_WITHOUT_HOME="${CURRENT_PATH#$HOME}"
else
    PATH_WITHOUT_HOME="$CURRENT_PATH"
fi

# Remove /src/github.com prefix (like WezTerm's prj logic)
if [[ "$PATH_WITHOUT_HOME" == "/src/github.com/"* ]]; then
    PROJECT_PATH="${PATH_WITHOUT_HOME#/src/github.com/}"
    
    # Split by '/' and get the second element (project name)
    IFS='/' read -ra DIRS <<< "$PROJECT_PATH"
    if [[ ${#DIRS[@]} -gt 1 ]]; then
        PROJECT_NAME="${DIRS[1]}"
    else
        PROJECT_NAME="${DIRS[0]}"
    fi
else
    # If not a GitHub project, use basename of current path
    PROJECT_NAME=$(basename "$CURRENT_PATH")
fi

# Handle edge cases
if [[ -z "$PROJECT_NAME" || "$PROJECT_NAME" == "." ]]; then
    if [[ "$CURRENT_PATH" == "$HOME" ]]; then
        PROJECT_NAME="~"
    else
        PROJECT_NAME=$(basename "$CURRENT_PATH")
    fi
fi

# Rename the window to the project name
tmux rename-window "$PROJECT_NAME"