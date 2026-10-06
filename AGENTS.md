# AGENTS.md

## Compatibility

- Target Linux with Bash 4.0 or newer.
- Do not introduce features requiring newer Bash versions without explicit approval.
- Prefer portable shell constructs when they remain clear and preserve behavior.
- Preserve existing CLI behavior, option names, and configuration formats unless a change is explicitly requested.
- Do not add dependencies without explicit approval.
- Full POSIX shell compliance is not currently required.
- macOS support is unverified and is not a current target.
- Do not undertake portability rewrites as part of unrelated changes.

## Changes

- Keep changes focused on the requested task.
- Avoid unrelated refactoring or formatting changes.
- Update documentation when user-facing behavior changes.
- When modifying existing code, follow the code style below for new or substantially changed lines.
- Do not rename functions or variables solely for style unless a formatting or consistency cleanup is explicitly requested.

## Code style

### Functions

- Use lowercase `snake_case` function names.
- Use the `name() { ... }` form rather than the `function` keyword.
- Functions tied to an integration or dependency should use a short namespace prefix.

Examples:

```bash
op_addtime() {
  ...
}

wp_get_version() {
  ...
}

mtc_get_contacts() {
  ...
}

post_commit() {
  ...
}
```

Common namespace prefixes include:

- `op_` for OpenProject
- `wp_` for WordPress and WP-CLI
- `mtc_` for Mautic
- `git_` for Git-specific helpers

Do not add a namespace prefix to generic Stir functions unless it improves clarity.

### Variables

- Use uppercase `SNAKE_CASE` for configuration values, environment variables, constants, and intentionally global state.
- Use lowercase `snake_case` for function-local and implementation variables.
- Declare function-local variables with `local` whenever practical.
- Avoid introducing new global variables when a local variable will work.

Example:

```bash
OPENPROJECT_URL="https://example.com"

op_addtime() {
  local work_package_id="${1}"
  local comment="${2}"
}
```

### Variable expansion

- Brace and quote variable expansions by default.

Preferred:

```bash
"${OPENPROJECT_URL}"
"${work_package_id}"
"${items[@]}"
```

Avoid:

```bash
$OPENPROJECT_URL
${work_package_id}
${items[@]}
```

- Use Bash syntax appropriate to the context when quoting is unnecessary or inappropriate, such as arithmetic expressions.
- Always quote array expansions as `"${array[@]}"` unless word splitting is explicitly intended.

### Conditionals

- Prefer `[[ ... ]]` over `[ ... ]`.
- Use Bash-native string and file tests.
- Keep variable expansions quoted and braced where practical.

Example:

```bash
if [[ -n "${work_package_id}" ]]; then
  ...
fi
```

### Indentation

- Use 2 spaces for each indentation level.
- Do not use tabs for indentation.
- Put `then`, `do`, and opening function braces on the same line.

Example:

```bash
if [[ "${enabled}" == "true" ]]; then
  for item in "${items[@]}"; do
    process_item "${item}"
  done
fi
```

### Commands and assignments

- Prefer `$()` over backticks for command substitution.
- Prefer arrays when constructing commands with multiple arguments.
- Keep separate assignments on separate lines.
- Avoid `eval` unless it is required and the reason is clear.
- Prefer readable Bash over compact or clever constructs.

Preferred:

```bash
LATENCY_STATUS="${WARNING_COLOR}"
LATENCY_BTN="btn-warning"
```

Avoid:

```bash
LATENCY_STATUS="${WARNING_COLOR}"; LATENCY_BTN="btn-warning"
```

### Output

- `echo` is acceptable for simple static output.
- Prefer `printf` when output requires formatting or when values may contain unusual characters.

## Verification

- Run `bash test/ci/run.sh` before committing.
- Run ShellCheck on modified Bash files.
- Do not introduce new ShellCheck findings.
- Report pre-existing findings separately.
- Do not run installation, deployment, reset, or update commands against real projects as part of testing.
- If a required check cannot run, report why and do not claim it passed.

## Git workflow

- Work on the agreed branch.
- Do not push to `master` or merge changes without explicit approval.
- Summarize changes, checks performed, and any remaining concerns.