#!/bin/bash

# Define the new Python path
NEW_PYTHON_PATH="/c/app/Python311"

# Remove any existing Python paths from PATH
CLEANED_PATH=$(echo "$PATH" | tr ':' '\n' | grep -vi '/python' | tr '\n' ':')

# Add the new Python path to the cleaned PATH
export PATH="$NEW_PYTHON_PATH:$CLEANED_PATH"

# Verify the updated PATH
echo "Updated PATH: $PATH"

# Verify the Python version to confirm it's from the new path
which python
python --version
