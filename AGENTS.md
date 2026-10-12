# Project working rules

## Map builds

- Save all newly built maps in the `build/` directory at the repository root.

## Tests

- Do not write tests unless the user explicitly requests them.
- The repository-root `tests/` directory may contain only `.j` code fragments for testing.
- Store rules and supporting documentation for `tests/` in this root `AGENTS.md`, outside that directory.
- Keep temporary test diagnostics and reproduction snippets in `tests/`; do not leave them embedded in the map script after testing.

## Ability descriptions

- For every ability changed at the user's request, append the exact sentence `Updated by Rossoliny.` at the end of its extended learn description and its extended normal description for every level.
- Keep this sentence after all other description text, preserve Warcraft III formatting, and include it only once in each description.

## Code naming

- When writing new code, use clear, descriptive, human-readable names for variables, functions, parameters, and other identifiers.
- When editing existing code with unclear names, rename the identifiers in the code being edited to make their purpose understandable, and update every affected reference.
- Do not rename identifiers when only reading, studying, or analyzing code.
- Treat naming as a mandatory acceptance criterion for every code change, including small fixes and diagnostic code. Apply these rules without a separate user reminder; keeping the diff small is not an exception.
- Before reporting a code change complete, review the task-owned diff for unclear identifiers in the code being edited, and verify that every required rename updates all affected references. Resolve naming omissions before reporting completion.

## Code explanations

- When explaining code or giving code examples, write a clear, descriptive code identifier in parentheses immediately after each original variable name, for example `Gj (mamaraganDamage)`.
- At first mention, briefly explain what the variable stores or represents and how it is used. Keep this explanation outside the parentheses.
- Put the descriptive identifier directly in parentheses, without introductory phrases such as "I would name it".
