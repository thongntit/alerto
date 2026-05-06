## ADDED Requirements

### Requirement: Claude Code Detection

The system SHALL detect whether Claude Code is installed on the system.

#### Scenario: Claude Code is installed
- **WHEN** the user opens Alerto settings
- **THEN** the system SHALL detect Claude Code by checking for `~/.claude/settings.json` or `~/.claude.json`
- **AND** display that Claude Code is detected

#### Scenario: Claude Code is not installed
- **WHEN** the user opens Alerto settings
- **THEN** the system SHALL show that Claude Code is not detected
- **AND** disable the hook setup options

### Requirement: Hook Installation

The system SHALL install Claude Code hooks into `~/.claude/settings.json` with idempotent behavior.

#### Scenario: First-time hook installation
- **WHEN** the user enables Claude Code hook integration
- **AND** Claude Code hooks are not yet configured
- **THEN** the system SHALL create the hooks configuration
- **AND** add TaskStart, TaskComplete, and Stop hooks to settings.json

#### Scenario: Re-installation (hooks already exist)
- **WHEN** the user enables Claude Code hook integration
- **AND** Alerto hooks are already installed
- **THEN** the system SHALL update existing hooks (idempotent)
- **AND** not create duplicate hooks

### Requirement: Hook Configuration

The system SHALL generate valid Claude Code hook configurations.

#### Scenario: TaskStart hook configuration
- **WHEN** installing hooks
- **THEN** the system SHALL create a TaskStart hook with id `alerto:task-start`
- **AND** the hook command SHALL send HTTP POST to `/notify` with source, type, and message

#### Scenario: TaskComplete hook configuration
- **WHEN** installing hooks
- **THEN** the system SHALL create a TaskComplete hook with id `alerto:task-complete`
- **AND** the hook command SHALL send HTTP POST to `/notify` with source, type, and message

#### Scenario: Stop hook configuration
- **WHEN** installing hooks
- **THEN** the system SHALL create a Stop hook with id `alerto:stop`
- **AND** the hook command SHALL send HTTP POST to `/notify` with source, type, and message

### Requirement: Hook Uninstallation

The system SHALL cleanly remove hooks from Claude Code settings.

#### Scenario: Uninstall hooks
- **WHEN** the user disables Claude Code hook integration
- **THEN** the system SHALL remove only Alerto hooks (by id prefix)
- **AND** preserve other user-configured hooks

### Requirement: Port Configuration

The system SHALL handle port configuration for HTTP notifications.

#### Scenario: Default port available
- **WHEN** installing hooks
- **AND** port 21452 is available
- **THEN** the system SHALL use port 21452 for notifications

#### Scenario: Default port in use
- **WHEN** installing hooks
- **AND** port 21452 is in use
- **THEN** the system SHALL try alternative ports (21453, 21454)
- **AND** use the first available port
