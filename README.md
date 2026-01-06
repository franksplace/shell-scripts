# shell-scripts

Handy shell scripts to make life easier. This repository provides a common utility library for consistent logging and output formatting across Bash and ZSH scripts.

Licensed under the Apache License, Version 2.0

---

## include-common.sh

A reusable Bash/ZSH library with common utility functions designed to be sourced in scripts.

### Features
- Cross-shell compatibility (Bash & ZSH)
- Dynamic loading from GitHub if not found locally
- Can be placed in script directory or `~/`
- Multi-level colored logging with timestamps
- Boolean variable checking
- Semantic version comparison

### Functions

#### Logging & Output
- `mlog(TYPE, MSG, CODE)` - Multi-level logging with support for:
  - `INFO`, `SUCCESS`, `WARN`, `WARNING`, `ERROR`, `FATAL`, `CRITICAL`
  - `DEBUG` (requires `DEBUG=true`)
  - `VERBOSE` (requires `VERBOSE=true`)
  - `BUILD_DEBUG` (requires `BUILD_DEBUG=true`)
  - `CODE_DEBUG` (requires `CODE_DEBUG=true`)
  - `TEST` (requires `TEST=true`)
- `color(args)` - Generate ANSI color codes (accepts space-separated styles/colors)
  - Styles: `bold`, `faint`, `italic`, `underline`, `blink`, `invert`
  - Colors: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`
  - Bright variants: `brightred`, `brightgreen`, `brightyellow`, `brightblue`, `brightmagenta`, `brightcyan`, `brightwhite`, `gray`
- `cecho(color, text)` - Echo text with color (resets color after)
- `secho(text)` - Print separator line spanning terminal width

#### Utilities
- `init()` - Initialize library, detect shell type (sets `BASH_FLAG`/`ZSH_FLAG`)
- `bcheck(var)` - Boolean check for variables (handles `true`/`1`/`false`/`0`)
- `exitnow(code, msg)` - Clean exit with error message to stderr
- `nullify(cmd)` - Suppress all output from a command
- `nullerr(cmd)` - Suppress stderr only from a command
- `compareSemanticVersions(v1, v2)` - Compare semantic versions (returns: 0=equal, 1=greater, 2=less)
- `LOGTFMT()` - ISO 8601 timestamp formatting
- `isSourced()` - Check if script is being sourced vs executed

### Variables
- `DATELOG` - Include timestamp in logs (default: true)
- `SHOW_APP_NAME` - Display application name in logs (requires `APPNAME` to be set)
- `DEBUG`, `VERBOSE`, `TEST`, `BUILD_DEBUG`, `CODE_DEBUG` - Enable respective log levels

### Example: Dynamically load include file in shell script

```bash
#####################################
# Sourcing of Common Include File
#####################################
COMMON_INCLUDE_FILE="include-common.sh"
COMMON_INCLUDE_URL="https://raw.githubusercontent.com/franksplace/shell-scripts/refs/heads/main/include-common.sh"

# shellcheck disable=SC2164
ABSPATH="$(
  cd "${0%/*}" 2>/dev/null
  echo "$PWD"/"${0##*/}"
)"
BASEDIR="$(dirname "$ABSPATH")" && declare BASEDIR
APPNAME="$(basename "$ABSPATH")" && declare APPNAME

if [ -f "$BASEDIR/${COMMON_INCLUDE_FILE}" ]; then
  # shellcheck disable=SC1090
  source "$BASEDIR/${COMMON_INCLUDE_FILE}"
elif [ -f "$HOME/${COMMON_INCLUDE_FILE}" ]; then
  # shellcheck disable=SC1090
  source "$HOME/${COMMON_INCLUDE_FILE}"
else
  echo "Downloading include-common.sh from git"
  if curl -s "$COMMON_INCLUDE_URL" -o "${BASEDIR}/${COMMON_INCLUDE_FILE}"; then
    echo "Re-executing ${0}"
    exec ${0} $@
  else
    echo "Unable to download the include-common.sh, exiting"
  fi
  exit 1
fi

# Now use the functions
mlog INFO "Script started successfully"
mlog DEBUG "Debug information"
mlog ERROR "Something went wrong" 1
```


