# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**rscript** is a Stata package that calls R scripts from within Stata. It provides cross-platform shell integration (Windows/Mac/Linux), optional R version and package validation, and asynchronous execution support. Authors: David Molitor and Julian Reif (University of Illinois).

## Repository Structure

- `src/rscript.ado` — Main Stata program (~430 lines). Contains the command implementation, platform-specific shell logic, and Mata helper functions for parsing R output.
- `src/rscript.sthlp` — Stata help file in SMCL format.
- `test/examples.do` — Test script that exercises all features. Run with Stata.
- `test/example_*.R` — R scripts used by the test suite.
- `rscript.pkg` / `stata.toc` — Stata package distribution metadata.

## Running Stata on Windows

**Important:** `rscript` does not work in Stata's batch mode on Windows because Stata ignores `shell` requests in that setting. You must run Stata interactively.

To run a `.do` file interactively from PowerShell, create a wrapper `.do` file that opens a log, runs the target script, and exits:

```stata
* run_tests.do
log using "run_tests.log", replace text
do examples.do
log close
exit, clear STATA
```

Then launch Stata interactively (no `/e` flag):

```bash
powershell.exe -Command "Start-Process -FilePath 'C:\Program Files\Stata19\StataMP-64.exe' -ArgumentList 'do run_tests.do' -WorkingDirectory '<directory>' -Wait"
```

- Do NOT use the `/e` flag (batch mode) — `rscript` will error with `r(1)`.
- `-Wait` ensures the command blocks until Stata finishes.
- `-WorkingDirectory` sets the working directory (e.g., the `test/` subdirectory).
- Output is captured in the log file opened by the wrapper script.

## Running Tests

Open Stata and run `test/examples.do`. The `RSCRIPT_PATH` global macro must point to the `Rscript` executable, or it must be discoverable via OS-specific defaults (see below).

## Architecture

The `.ado` file has three main sections:

1. **Main program (`rscript`)**: Parses Stata syntax, resolves the R executable path, executes shell commands, and displays output. R path resolution priority: `rpath()` option > `$RSCRIPT_PATH` global macro > OS defaults (`/usr/local/bin/Rscript` on Unix/Mac, newest version in `C:/Program Files/R/` on Windows).

2. **`write_r_script` program**: Generates a temporary R script that validates the R version and checks for required packages before the user's script runs.

3. **Mata functions** (`parse_stderr_version_control`, `parse_stderr`, `parse_stdout`): Read captured stdout/stderr files and detect errors. Lines starting with `"Error:"` in stderr trigger Stata error 198. The `force` option suppresses this.

### Platform-specific behavior

- **Unix/Mac**: Executes via `sh -c` with `LANG=C`. Async uses `nohup` with `&`.
- **Windows**: Executes via `shell` with `LANGUAGE=en`. Async uses `winexec` / `cmd.exe /c start /B /MIN`. Batch mode is not supported on Windows.

### Key options

- `rpath()` — Path to Rscript executable
- `args()` — Arguments passed to the R script
- `rversion()` — Enforce min (and optionally max) R version
- `require()` — Check that R packages are installed before execution
- `async` — Run R script in background; PID stored in `r(PID)` and `$RSCRIPT_PID`
- `force` — Suppress Stata errors when R reports errors

## Stata Coding Conventions

- Minimum Stata version: 13.0
- The program uses `syntax using/, ...` for argument parsing
- Temporary files/variables use Stata's `tempfile` and `tempname` system
- Mata blocks handle file I/O and string parsing for output processing
- Version history is tracked in comments at the top of the `.ado` file

## Distribution

Installed via: `net install rscript, from("https://raw.githubusercontent.com/reifjulian/rscript/master") replace`

The `rscript.pkg` file lists distributable files under `src/`.
