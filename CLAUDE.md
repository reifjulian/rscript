# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Git commits

Never create a git commit without explicit user permission — even in auto mode. Always wait for the user to ask before committing.

Do not add `Co-authored-by` trailers or sign yourself as a coauthor in commit messages.

## What this repo is

`rscript` is a Stata command that calls an external R script via the `Rscript` executable, captures stdout/stderr to temp files, echoes them to the Stata console, and breaks with a Stata error when R reports an error. It is distributed as a Stata package installed with `net install` directly from this GitHub repo (see `stata.toc` and `rscript.pkg`).

Authors: David Molitor and Julian Reif (University of Illinois). MIT license.

## Layout

```
src/rscript.ado      The command itself (Stata + Mata). This is the only real source file.
src/rscript.sthlp    Stata help file (SMCL). Must stay in sync with the ado's options.
test/examples.do     Test script. Runs every example and asserts on return codes/output.
test/example_*.R     Small R scripts used by examples.do (normal, error, warning, async, OLS).
rscript.pkg          Package manifest listing files installed by `net install`.
stata.toc            Table of contents for `net install`.
README.md            User-facing docs, tutorial, and update history.
images/              Screenshots used in the README.
```

## Structure of `src/rscript.ado`

- Header line `*! rscript X.Y date by ...` is the version stamp Stata reads (`which rscript`). Below it is a changelog comment block. Both are updated on every release.
- `program define rscript, rclass` — main command. Sections, in order: error checking / Rscript path resolution, `rversion()` and `require()` validation, `async` setup, version-control R script call, main R script call, stdout/stderr display, error parsing.
- `program define write_r_script` — writes a small R script to a tempfile that checks the base R version and installed packages. Used only when `rversion()` or `require()` is specified.
- Mata block at the bottom: `parse_stderr_version_control`, `parse_stderr`, `parse_stdout`. These scan the captured output files and `exit(error(...))` with specific codes that the Stata code branches on.
- `version 13.0` — keep the code compatible with Stata 13. Avoid newer syntax and functions.

## Behavior to preserve

- **Rscript path resolution order:** `rpath()` option, then global `RSCRIPT_PATH`, then OS-specific search (`/usr/local/bin/Rscript` and `/usr/bin/Rscript` on Mac/Unix; newest `C:/Program Files/R/R-?.?.?/bin/Rscript.exe` on Windows).
- **Error detection:** a run is flagged as an error only when a stderr line starts with the case-sensitive string `Error:` (or stdout contains `fatal error`). Warnings and `tidyverse` namespace conflicts on stderr must not break. `force` suppresses the break.
- **Locale:** shell calls set `LANG=C` (Unix/Mac) or `LANGUAGE=en` (Windows) so R's error strings are in English and parseable.
- **Windows batch mode is unsupported** and exits early with an informative message; don't try to "fix" this (Stata ignores shell requests there).
- **`async`:** Unix/Mac uses `nohup ... &` and returns the PID in `r(PID)` and appends to global `RSCRIPT_PID`; Windows uses `winexec` with no PID. `async` cannot be combined with `rversion()`.
- **`~` paths:** expanded to absolute paths before calling the shell (Unix/Mac).
- **Return codes** relied on by tests: 100 (no `using`), 601 (file/executable not found), 198 (invalid option or R error), 9 (version/package requirement not met).

## Testing

There is no automated CI. Tests are run manually in Stata:

```stata
global RSCRIPT_PATH "C:/Program Files/R/R-X.Y.Z/bin/Rscript.exe"   // or Unix path
cd test
do examples.do
```

`examples.do` requires `RSCRIPT_PATH` to be set and requires the R packages `tidyverse`, `haven`, and `estimatr`. It uses `rcof` to assert on expected error codes. Some blocks are Unix/Mac only (the `~` path test and PID checks), and one assumes the repo lives at `~/rscript`.

When changing behavior in the ado, add or update a corresponding check in `test/examples.do`.

## Conventions when editing

- Tabs for indentation in `.ado` and `.do` files (match existing style).
- Comments use `*` for line comments; section banners use `****` blocks.
- When adding or changing an option, update all four: `src/rscript.ado`, `src/rscript.sthlp`, `README.md` (usage and update history), and `test/examples.do`.
- On a release, bump the version in the `*!` header of the ado, the changelog comment block beneath it, and the "Current version" line and "Update History" in `README.md`.
- Files installed by users are exactly those listed in `rscript.pkg`. If you add a distributable file, add it there.
