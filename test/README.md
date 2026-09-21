# Tests

The checks in `test/ci` are self-contained and do not install Stir, modify a
project, contact an integration, or deploy code.

Run the same syntax and smoke tests used by GitHub Actions:

```bash
bash test/ci/run.sh
```

If ShellCheck is installed, check the CI test scripts with:

```bash
shellcheck test/ci/*.sh
```

The workflow also reports existing high-severity ShellCheck findings in the
application code. That report is initially non-blocking so the known backlog
can be addressed incrementally without hiding failures in the new test code.

The older `test.sh` and `extended.sh` files depend on test frameworks downloaded
by the former Travis CI setup. They remain unchanged for now and are not run by
the new workflow.
