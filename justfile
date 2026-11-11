# Commands for working on the plugin. `just check` is the gate.

default:
    @just --list

# Test the session-start hook and the size budgets
test:
    sh tests/test.sh

# Validate the plugin and marketplace manifests
validate:
    claude plugin validate .

# Show what the plugin costs in context: bytes per skill and for the status line
budget:
    @wc -c skills/*/SKILL.md hooks/state.sh

# The gate: everything that must pass before work is done
check: test validate
