# Claude Code Integration Guide

## Introduction

Claude Code is an agentistic coding tool developed by Anthropic that operates directly in your terminal. It understands your codebase context and helps you program faster through natural language commands. For our AGI system, Claude Code provides powerful capabilities for code exploration, development, and maintenance while integrating seamlessly with our existing memory-bank system and MCP tools.

This document serves as a comprehensive guide for integrating Claude Code into the AGI system workflow, with specific instructions tailored to our project structure and development needs.

## Key Claude Code Features for AGI Development

### Terminal-Based Integration
Claude Code operates directly in your terminal, complementing our AGI-CLI tools and integrating seamlessly with our existing bash scripts and command-line workflow.

### Contextual Understanding
Claude Code explores and understands our codebase without requiring manual file addition to context, which is particularly valuable for navigating our memory-bank system and complex project structure.

### Memory System
Claude Code's memory system (via CLAUDE.md files) provides a natural extension to our own memory-bank concept, allowing persistent storage of project knowledge, conventions, and preferences across development sessions.

### MCP Integration
Claude Code works with Model Context Protocol (MCP), aligning with our use of various MCP tools like memory-bank-mcp, desktop-commander, and brave-web-search.

### Git Workflow Support
Robust Git integration helps with commit creation, PR management, and merge conflict resolution—streamlining our development process.

### Non-Interactive Mode
Supports automation and CI/CD integration through its non-interactive mode, enhancing our build and testing pipelines.

### Security Model
Multi-layered permission system ensures secure operation, an essential consideration for AI development projects.

## Installation Guide

### Prerequisites:
- Node.js 18+ (required for Claude Code)
- Git 2.23+ (for full Git functionality)

```bash
# Create a dedicated npm global directory (recommended approach)
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install Claude Code
npm install -g @anthropic-ai/claude-code
```

## Setting Up in AGI Projects

1. Navigate to your project directory and start Claude Code:

```bash
cd /path/to/agi-project
claude
```

2. Generate a project guide with initialization assistant:

```bash
claude
> /init
```

3. Configure project-specific settings:

```bash
# Allow common AGI-CLI commands without repeated authorization
claude config add allowedTools "Bash(./agi-cli.sh:*)"

# Ignore node_modules and similar directories
claude config add ignorePatterns "node_modules/**"
claude config add ignorePatterns "dist/**"
```

## Memory Configuration

Create a project-specific CLAUDE.md file with AGI-specific knowledge:

```markdown
# AGI Project Context

## Project Structure
- `memory-bank/`: Core knowledge storage system
- `APP/`: Application-specific components
- `MARKETING/`: Marketing-related assets and tools
- `FINANCE/`: Financial modeling and tools

## Coding Standards
- Use camelCase for variables and functions
- Use PascalCase for class names
- Follow ESLint configuration

## Common Workflows
- Use `./agi-cli.sh config` to run the configuration process
- Use `./agi-cli.sh update` to update the memory bank
```

## Common Use Cases in AGI Development

### Exploring the Memory-Bank System

```bash
claude "explain how our memory-bank system works"
```

Claude Code will analyze the memory-bank directory structure and provide an explanation of the system's architecture and functionality.

### Debugging AGI Components

```bash
claude "debug the issue with memory retrieval in activeContext.js"
```

Claude Code will explore the file, identify potential issues, and suggest solutions.

### Generating Documentation

```bash
claude "generate comprehensive documentation for the memory-bank API"
```

Claude Code will analyze the API and create detailed markdown documentation that can be saved to the appropriate location.

### Integrating New MCP Tools

```bash
claude "help me integrate browser-tools-mcp into our project"
```

Claude Code will provide step-by-step guidance for adding new MCP tools to the AGI system.

### Automating Git Workflows

```bash
claude commit
```

Claude Code will analyze your changes, generate a meaningful commit message following project conventions, and create the commit.

### Understanding Complex Code

```bash
claude "explain the algorithm in contextRetrieval.js"
```

Claude Code will analyze the file and provide a detailed explanation of the algorithm with relevant context.

## Troubleshooting

### Installation Issues

If you encounter npm permission errors:
- Follow the dedicated npm directory setup described in the Installation section
- Avoid using `sudo npm install -g`, as this can lead to permission issues

For WSL users:
- Run `npm config set os linux` before installation
- Install with `npm install -g @anthropic-ai/claude-code --force --no-os-check`

### Authentication Problems

If you experience authentication issues:
```bash
# Clear authentication cache
rm -rf ~/.config/claude-code/auth.json
# Restart Claude Code
claude
```

### Performance Considerations

For large codebases:
- Use `/compact` regularly to reduce context size
- Utilize specific queries rather than vague requests
- Add frequently used directories to ignorePatterns to reduce scanning

### Container Environments

For containerized development:
- Ensure the container has access to api.anthropic.com, statsig.anthropic.com, and sentry.io
- Configure the environment variables (ANTHROPIC_API_KEY, etc.) appropriately

## Advanced Techniques

### CI/CD Integration

Integrate Claude Code into your CI/CD pipelines using the non-interactive mode:

```bash
# Example: Automated documentation generation
export ANTHROPIC_API_KEY=sk_...
claude -p "update the API documentation based on recent changes" \
  --allowedTools "Read" "Write(docs/api/*)" "Bash(git diff:*)" \
  --disallowedTools "Bash(curl:*)"
```

### Deep Thinking for Complex Problems

Leverage Claude's deep thinking capabilities for complex architectural decisions:

```bash
claude "think deeply about how we should redesign the context retrieval system"
```

Claude Code will engage its advanced reasoning capabilities to provide in-depth analysis and recommendations.

### Custom MCP Tool Integration

Combine Claude Code with custom MCP tools for enhanced capabilities:

```bash
# Configure MCP server
claude mcp install --name memory-bank-mcp --command "npx" \
  --args "-y" "@allpepper/memory-bank-mcp" \
  --env MEMORY_BANK_ROOT="/path/to/memory-bank"
```

### Project-Specific Memory Hierarchy

Create a structured memory system that aligns with our AGI architecture:

1. User-level memory (`~/.claude/CLAUDE.md`) for developer preferences
2. Project-level shared memory (`./CLAUDE.md`) for team conventions
3. Local project memory (`./CLAUDE.local.md`) for personal workspace settings

## Integration with AGI-System

### Auto-Configuration Script

The AGI-System provides a configuration script for automatically setting up Claude Code with the correct settings:

```bash
# Run from any project directory
/path/to/AGI-System-Public/core/scripts/setup-claude-code.sh
```

### Memory-Bank Synchronization

Claude Code works seamlessly with our memory-bank system:

1. Claude Code reads from memory-bank files automatically
2. Use the `update_memory.sh` script to synchronize Claude's understanding with memory-bank updates
3. Claude Code can update memory-bank files directly when instructed

## Resources

- [Claude Code Official Documentation](https://console.anthropic.com/docs/claude-code)
- [Model Context Protocol (MCP) Guide](https://console.anthropic.com/docs/mcp)
- [Claude Code GitHub Repository](https://github.com/anthropics/claude-code)
- [Memory-Bank MCP Server](https://github.com/allpepper/memory-bank-mcp)

For additional support, contact the AGI project core team or submit issues via the `/bug` command in Claude Code.