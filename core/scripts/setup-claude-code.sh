#!/usr/bin/env bash

# ============================================================================
# setup-claude-code.sh
# 
# This script configures Claude Code to work seamlessly with the AGI system.
# It sets up the necessary Claude Code configuration, permissions, and memory
# integration for optimal use with AGI-System projects.
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AGI_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Default paths
CLAUDE_CONFIG_DIR="$HOME/.config/Claude"
CLAUDE_LOCAL_MD="$PWD/CLAUDE.local.md"

# Print header
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   Claude Code Setup for AGI-System Projects   ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo -e "${RED}[ERROR] Claude Code is not installed.${NC}"
    echo -e "${YELLOW}Please install Claude Code using the following commands:${NC}"
    echo ""
    echo "mkdir -p ~/.npm-global"
    echo "npm config set prefix ~/.npm-global"
    echo "echo 'export PATH=~/.npm-global/bin:\$PATH' >> ~/.bashrc"
    echo "source ~/.bashrc"
    echo "npm install -g @anthropic-ai/claude-code"
    echo ""
    exit 1
fi

# Check if this is an AGI project directory
if [[ ! -d "./memory-bank" ]]; then
    echo -e "${YELLOW}[WARNING] No memory-bank directory found in the current directory.${NC}"
    echo -e "This may not be an AGI project directory."
    echo -e "Do you want to continue anyway? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        echo -e "${RED}Setup aborted.${NC}"
        exit 0
    fi
fi

# Create config directory if it doesn't exist
mkdir -p "$CLAUDE_CONFIG_DIR"

# Create or update Claude local memory file
echo -e "${GREEN}Creating/updating Claude local memory file...${NC}"
if [[ ! -f "$CLAUDE_LOCAL_MD" ]]; then
    cat > "$CLAUDE_LOCAL_MD" << 'EOF'
# AGI Project Local Context

This file contains local context specific to your development environment for this AGI project.
Claude Code will use this information but it will not be synced with the repository.

## Project Structure
- `memory-bank/`: Core knowledge storage system
- `APP/`: Application-specific components
- `MARKETING/`: Marketing-related assets and tools
- `FINANCE/`: Financial modeling and tools

## Local Development Configuration
- Personal preferences for this project
- Local paths and configurations

## Development Workflow
- Use `./agi-cli.sh config` to run the configuration process
- Use `./agi-cli.sh update` to update the memory bank

## Notes
- Add your personal notes and reminders here
EOF
    echo -e "${GREEN}Created CLAUDE.local.md with default content.${NC}"
else
    echo -e "${GREEN}CLAUDE.local.md already exists, skipping.${NC}"
fi

# Setup Claude Code configuration
echo -e "${GREEN}Configuring Claude Code for AGI system...${NC}"

# Add default ignorePatterns
echo -e "${YELLOW}Adding default ignorePatterns...${NC}"
claude config add ignorePatterns "node_modules/**" || true
claude config add ignorePatterns "dist/**" || true
claude config add ignorePatterns ".git/**" || true
claude config add ignorePatterns ".env*" || true
claude config add ignorePatterns ".DS_Store" || true

# Allow agi-cli.sh commands
if [[ -f "./agi-cli.sh" ]]; then
    echo -e "${YELLOW}Allowing agi-cli.sh commands...${NC}"
    claude config add allowedTools "Bash(./agi-cli.sh:*)" || true
fi

# Configure Claude Code to work with memory-bank
echo -e "${GREEN}Setting up memory-bank integration...${NC}"
if [[ -d "./memory-bank" ]]; then
    # Calculate relative path to the memory-bank directory
    MEMORY_BANK_REL_PATH=$(realpath --relative-to="$PWD" "./memory-bank")
    
    # Configure memory-bank MCP if available
    if command -v npx &> /dev/null; then
        echo -e "${YELLOW}Setting up memory-bank MCP tool...${NC}"
        claude mcp install --name memory-bank-mcp --command "npx" \
            --args "-y" "@allpepper/memory-bank-mcp" \
            --env MEMORY_BANK_ROOT="$MEMORY_BANK_REL_PATH" \
            || true
    fi
fi

# Copy AGI-System global reference to Claude config
echo -e "${GREEN}Copying AGI-System reference to Claude config...${NC}"
cp "$AGI_ROOT/docs/CLAUDE_CODE_INTEGRATION.md" "$CLAUDE_CONFIG_DIR/AGI_SYSTEM_REFERENCE.md" || true

# Final message
echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}   Claude Code setup complete!                 ${NC}"
echo -e "${GREEN}===============================================${NC}"
echo ""
echo -e "Your AGI project is now configured to work with Claude Code."
echo -e "Run ${YELLOW}claude${NC} to start using Claude Code in this project."
echo -e ""
echo -e "For more information, see the documentation:"
echo -e "  ${BLUE}$AGI_ROOT/docs/CLAUDE_CODE_INTEGRATION.md${NC}"
echo -e ""

exit 0