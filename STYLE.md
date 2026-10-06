# Stir code style

Stir has been around for a long time and contains code written at different stages of the project. This guide defines the style we want to use as the codebase is maintained and cleaned up.

The goal is not to rewrite working code simply to make it prettier. The goal is to make new and modified code predictable, readable, and easier to maintain.

## Bash version

Stir targets Linux with Bash 4.0 or newer.

POSIX shell compatibility is not required. Bash-specific features such as `[[ ... ]]`, arrays, and `local` variables are encouraged when they make the code clearer.

Avoid features that require Bash versions newer than 4.0 unless there is a specific reason to adopt them.

## Functions

Function names use lowercase names with underscores separating logical components.

```bash
post_commit() {
  ...
}
```

Use the `name() { ... }` form consistently:

```bash
op_addtime() {
  ...
}
```

Do not use:

```bash
function opAddTime {
  ...
}
```

### Naming logical components

Underscores should separate meaningful parts of the function name rather than mechanically separating every English word.

For example:

```bash
op_addtime()
op_get_work_package()
op_update_work_package()
```

In `op_addtime()`, `addtime` represents a concise operation name and is easy to read as a single unit.

In `op_get_work_package()`, `get` is the operation and `work_package` is the object being acted on.

Prefer:

```bash
op_get_work_package()
```

Rather than:

```bash
op_getworkpackage()
```

Likewise, there is no need to change a concise and readable operation such as:

```bash
op_addtime()
```

to:

```bash
op_add_time()
```

simply to enforce a mechanical word-by-word snake_case rule.

The goal is readability and clear logical grouping, not counting words.

### Integration prefixes

Functions that belong to a specific integration or dependency should begin with a short namespace prefix.

Examples:

```bash
op_addtime()
op_get_work_package()

wp_get_version()
wp_update_core()

mtc_get_contacts()

git_get_branch()
```

Current prefixes include:

- `op_` for OpenProject
- `wp_` for WordPress and WP-CLI
- `mtc_` for Mautic
- `git_` for Git-specific functionality

Generic Stir functionality does not need a prefix:

```bash
post_commit()
validate_path()
print_error()
```

Prefixes should identify a meaningful dependency or subsystem. Do not invent prefixes simply to categorize every function.

## Variables

Variable casing communicates scope and purpose.

### Configuration and global values

Use uppercase `SNAKE_CASE` for values that represent configuration, environment variables, constants, or intentional global state.

```bash
OPENPROJECT_URL="https://openproject.example.com"
WORK_PATH="/var/www"
GIT_STATS=true
```

These are values that affect Stir outside the immediate implementation of a single function.

### Local variables

Use lowercase `snake_case` for variables used internally by functions.

```bash
op_addtime() {
  local work_package_id="${1}"
  local hours="${2}"
  local comment="${3}"
}
```

Use `local` whenever a variable does not need to exist outside the function.

This makes scope easier to understand and reduces the chance of one function accidentally changing a value used somewhere else.

Avoid introducing new global variables when a local variable will work.

## Variable expansion

Brace and quote variable expansions by default.

Use:

```bash
"${OPENPROJECT_URL}"
"${work_package_id}"
"${comment}"
```

Rather than:

```bash
$OPENPROJECT_URL
$work_package_id
$comment
```

Braces make variable boundaries explicit. Quoting prevents unintended word splitting and pathname expansion.

Arrays should normally be expanded like this:

```bash
"${wp_cmd[@]}"
```

Not:

```bash
${wp_cmd[@]}
```

There are Bash contexts where quoting is unnecessary or inappropriate, particularly arithmetic expressions. The rule is a default rather than an attempt to fight Bash syntax.

## Conditionals

Prefer Bash's `[[ ... ]]` conditional syntax.

```bash
if [[ -n "${value}" ]]; then
  ...
fi
```

Rather than:

```bash
if [ ! -z "$value" ]; then
  ...
fi
```

Use the clearest native test for the job:

```bash
[[ -n "${value}" ]]
[[ -z "${value}" ]]
[[ -f "${file}" ]]
[[ -d "${directory}" ]]
[[ "${enabled}" == "true" ]]
```

Arithmetic should use arithmetic syntax where appropriate:

```bash
if (( count > 5 )); then
  ...
fi
```

Remember that Bash arithmetic does not support floating-point numbers.

## Indentation

Use 2 spaces per indentation level.

Do not use tabs for indentation.

```bash
if [[ "${enabled}" == "true" ]]; then
  if op_available; then
    op_addtime
  fi
fi
```

Opening syntax stays on the same line:

```bash
if [[ condition ]]; then
  ...
fi

for item in "${items[@]}"; do
  ...
done

my_function() {
  ...
}
```

## Assignments

Keep individual assignments on separate lines.

Use:

```bash
LATENCY_STATUS="${WARNING_COLOR}"
LATENCY_BTN="btn-warning"
```

Rather than:

```bash
LATENCY_STATUS="${WARNING_COLOR}"; LATENCY_BTN="btn-warning"
```

The extra vertical space is worthwhile when debugging or reviewing changes.

## Command substitution

Use `$()` for command substitution:

```bash
current_branch="$(git branch --show-current)"
```

Do not introduce backtick syntax:

```bash
current_branch=`git branch --show-current`
```

Nested `$()` expressions are also significantly easier to read.

## Commands stored in variables

When a command consists of multiple arguments, prefer a Bash array.

```bash
wp_cmd=(
  wp
  --path="${WORK_PATH}"
)

core_current_version="$("${wp_cmd[@]}" core version)"
```

This preserves argument boundaries and avoids many quoting problems.

Avoid constructing commands as strings and passing them through `eval` unless there is a specific reason it is required.

## Function-local command results

When the exit status of a command matters, declare the local variable separately from the assignment.

Prefer:

```bash
local response

response="$(curl ...)" || return 1
```

Rather than:

```bash
local response="$(curl ...)"
```

`local` itself can mask the exit status of the command substitution.

## Output

`echo` is fine for straightforward output:

```bash
echo "Updating WordPress..."
```

Use `printf` when formatting values:

```bash
printf 'Updated %s to version %s\n' "${plugin_name}" "${version}"
```

Prefer clarity over enforcing one output command everywhere.

## Readability

Stir should favor straightforward Bash over clever Bash.

Readable:

```bash
if [[ -d "${WORK_PATH}" ]]; then
  process_directory "${WORK_PATH}"
fi
```

Compact code is not automatically better code.

When several approaches behave the same way, prefer the version that another developer can understand quickly without needing to decode shell tricks.

## Formatting existing code

Do not create large unrelated formatting diffs while fixing a specific problem.

When changing a function, bring the lines being meaningfully modified into alignment with this guide.

Broader naming or formatting cleanup should happen as an intentional task so the resulting diff can be reviewed independently.

## ShellCheck

Modified Bash files should be checked with ShellCheck.

New changes should not introduce new ShellCheck findings.

If a warning must be suppressed, the reason should be clear and the suppression should be as narrow as possible.

## Guiding principle

Consistency is valuable, but behavior comes first.

Prefer code that is clear, predictable, easy to debug, and compatible with Stir's supported Bash environment.