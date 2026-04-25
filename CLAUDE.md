# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nova text editor extension that provides Rust language support for macOS. It's written in TypeScript and transpiled to JavaScript to run in Nova's extension environment. The extension integrates:

- **Rust Analyzer** language server for IDE features
- **Tree-sitter** for syntax highlighting and symbol detection
- **rustfmt** for code formatting
- **Cargo** task integration

## Code Intelligence with Codanna

This repository includes `.claude/codanna.md` which provides instructions for using Codanna's semantic search and code intelligence features. **When exploring unfamiliar parts of the codebase or trying to understand how specific features work**, refer to that file for:

- Semantic search to find relevant code by concept (not just text matching)
- Symbol exploration with `symbol_id` references
- Call graph analysis to understand code relationships
- Token-efficient strategies for reading only relevant code sections

Use Codanna when you need to understand how functionality is implemented across multiple files, especially for complex features like LSP integration, preference handling, or formatter logic.

## Common Commands

### Building and Testing

```sh
# Install dependencies (uses pnpm, not npm)
pnpm install

# Compile TypeScript to JavaScript
pnpm run build

# Run tests
pnpm run test
```

### Initial Setup

```sh
# Clone with submodules (required for tree-sitter-rust)
git clone --recurse-submodules https://github.com/chriskrycho/nova-rust

# Or if already cloned
git submodule update --init --recursive

# Download Rust Analyzer binary (for development)
./Rust.novaextension/bin/update_server.sh

# Build syntax highlighting library
./tree-sitter/compile_parser.sh "$(pwd)/tree-sitter/tree-sitter-rust" /Applications/Nova.app
mv ./tree-sitter/libtree-sitter-rust.dylib ./Rust.novaextension/Syntaxes/libtree-sitter-rust.dylib
```

### Testing in Nova

Activate the extension via **Extensions → Activate Project as Extension** in Nova. Monitor logs via **Extensions → Show Extension Console**.

## Architecture

### Extension Entry Point

The extension lifecycle is managed in `src/main.ts`:

- `activate()`: Initializes the language server, formatter, and Cargo task assistant
- `deactivate()`: Cleans up resources

### Core Components

**RustLanguageServer** (`src/rust-lang-server.ts`):

- Manages the Rust Analyzer LSP client
- Handles server crashes and restarts
- Configured via preferences for lint commands, arguments, and environment variables
- In dev mode, logs all LSP communication to `../logs/` directory
- Supports custom Rust Analyzer binary path via `RA_PATH` environment variable
- Auto-restarts when `Cargo.toml` or `rust-project.json` changes

**RustFormatter** (`src/rust-formatter.ts`):

- Invokes `rustfmt` on save (when enabled)
- Searches upward for `rustfmt.toml` or `Cargo.toml` to determine formatting config
- Extracts Rust edition from `Cargo.toml` if no `rustfmt.toml` exists
- Supports nightly rustfmt features

**CargoTaskAssistant** (`src/cargo-task-assistant.ts`):

- Provides Nova task integration for Cargo commands
- Resolves build/run tasks configured in `extension.json`
- Inherits environment variables from user preferences

**ServerInstall** (`src/server-install.ts`):

- Auto-downloads latest Rust Analyzer from GitHub releases
- Bypasses updates in dev mode to prevent extension reload loops
- Downloads to temporary file, then swaps on language server restart

### Preference System

The `preference-resolver.ts` module handles both global and workspace-specific preferences:

- `onPreferenceChange()`: Reconciles global and local settings
- `envVarObject()`: Parses `KEY=VALUE` strings into environment object
- `splitArgString()`: Handles quoted arguments in preference strings

### Build Output

TypeScript compiles from `src/**/*.ts` to `Rust.novaextension/Scripts/` (defined in `tsconfig.json`). Tests are excluded from compilation.

## Important Notes

- The extension requires macOS 11.0+ (defined in tree-sitter build flags)
- Dev mode prevents Rust Analyzer auto-updates to avoid restart loops
- Syntax highlighting requires building a universal binary (`arm64` + `x86_64`) of `tree-sitter-rust`
- The extension auto-activates when a workspace contains `Cargo.toml` or `rust-project.json`
- All Nova API interactions happen through the global `nova` object (no imports needed)
- Conventional Commits style is preferred for commit messages

## Extension Configuration

Key preference namespaces (defined in `extension.json`):

- `chriskrycho.rust.rustfmt-on-save`: Enable format on save
- `chriskrycho.rust.rustfmt-nightly`: Use nightly rustfmt
- `chriskrycho.rust.lint-command`: Choose `check` or `clippy`
- `chriskrycho.rust.lint-args`: Additional cargo arguments
- `chriskrycho.rust.env-vars`: Array of environment variables
- `chriskrycho.rust.cargo.build.*`: Build task configuration
- `chriskrycho.rust.cargo.run.*`: Run task configuration
