# AGENTS.md

## Compatibility

- Target Linux with Bash 4.0 or newer.
- Do not introduce features requiring newer Bash versions
  without explicit approval.
- Prefer portable shell constructs when they remain clear
  and preserve behavior.
- Preserve existing CLI behavior, option names, and configuration formats
  unless a change is explicitly requested.
- Do not add dependencies without explicit approval.
- Full POSIX shell compliance is not currently required.
- macOS support is unverified and is not a current target.
- Do not undertake portability rewrites as part of unrelated changes.

## Changes

- Keep changes focused on the requested task.
- Avoid unrelated refactoring or formatting changes.
- Update documentation when user-facing behavior changes.

## Verification

- Run `bash test/ci/run.sh` before committing.
- Run ShellCheck on modified Bash files.
- Do not introduce new ShellCheck findings.
- Report pre-existing findings separately.
- Do not run installation, deployment, reset, or update commands
  against real projects as part of testing.
- If a required check cannot run, report why and do not claim it passed.

## Git workflow

- Work on the agreed branch.
- Do not push to `master` or merge changes without explicit approval.
- Summarize changes, checks performed, and any remaining concerns.
