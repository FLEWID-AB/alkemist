# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Alkemist is an Elixir library that provides helper methods to build admin interfaces for Phoenix applications quickly. It's designed as a modular and flexible toolkit for creating CRUD interfaces with built-in features like pagination, search, filtering, and CSV export.

## Common Development Commands

### Testing
- `mix test` - Run the full test suite
- `mix test --cover` - Run tests with coverage using ExCoveralls
- `mix coveralls` - Generate coverage report
- `mix coveralls.html` - Generate HTML coverage report

### Documentation and Quality
- `mix docs` - Generate documentation with ExDoc
- `mix credo` - Run static code analysis
- `mix inch` - Check documentation coverage

### Development
- `mix deps.get` - Install dependencies
- `mix compile` - Compile the project

### Generator Commands
- `mix alkemist.gen.controller ControllerName MyApp.ModelName` - Generate a basic Alkemist controller
- `mix alkemist.gen.controller ControllerName MyApp.ModelName MyNamespace` - Generate a controller in a namespace

## Architecture

### Core Components

**Alkemist.Controller** - The main module providing macros and helper functions for CRUD operations:
- `render_index/3` - Renders index views with pagination, filtering, and search
- `render_show/3` - Renders show pages with customizable rows and panels
- `render_new/2`, `render_edit/3` - Renders form pages
- `do_create/3`, `do_update/4`, `do_delete/3` - Handles CRUD operations
- `csv/3` - Exports data as CSV

**Alkemist.Config** - Configuration management module that handles all config.exs options and provides defaults for:
- Repository settings
- Router helpers
- Authorization providers
- Views and layouts
- Decorators for customizing display
- Query providers for search and pagination

**Alkemist.MenuRegistry** - Manages sidebar menu items and navigation structure

**Views and Templates** - Located in `lib/alkemist/views/`:
- `LayoutView` - Main layout and navigation
- `FormView` - Form rendering and field types
- `PaginationView` - Pagination controls
- `ViewHelpers` - Common view helper functions

### Key Design Patterns

1. **Macro-based DSL** - Controllers use macros like `render_index`, `render_show` to generate standard CRUD interfaces
2. **Configuration-driven** - Behavior is controlled through `config.exs` settings and controller callbacks
3. **Decorator pattern** - Customizable display logic through decorator functions
4. **Resource-centric** - Controllers are built around an `@resource` module attribute that defines the Ecto schema

### Static Assets

Static assets are served from `priv/static/` and include:
- CSS and JavaScript files (`alkemist.css`, `alkemist.js`)
- Font Awesome icons
- Source maps for development

### Testing Structure

Tests mirror the library structure under `test/`:
- Unit tests for core modules
- View tests for template rendering
- Integration tests for controller functionality

## Dependencies

Key dependencies include:
- Phoenix framework (1.6+)
- Ecto for database operations
- Phoenix HTML for form helpers
- Various utility libraries (atomic_map, flop, phoenix_mtm, etc.)
- Floki for HTML parsing/sanitization