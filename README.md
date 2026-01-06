# shell-scripts

Handy shell scripts to make life easier. This repository provides two common utility libraries for consistent logging and output formatting across shell scripts and Python CLI applications.

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

---

## clicommon.py

Common CLI utilities for Python scripts with similar functionality to the shell library.

### Features
- Installable via pip (`pip install clicommon`) or dynamically loaded from GitHub
- ANSI color code support with Windows console mode handling
- Automatic color disabling when not in TTY

### Classes & Functions

#### Colors Class
- Provides all ANSI color codes as class attributes
- 16 colors + text styles (bold, faint, italic, underline, blink, negative, crossed)
- Auto-disables colors on non-TTY output or Windows terminals
- Preferred colors for each message type (e.g., `Colors.INFO`, `Colors.ERROR`)

#### Functions
- `mlog(msg_type, msg_string, exit_code, datelog, colors)` - Logging with the same levels as shell version
- `bcheck(var)` - Boolean check using caller's global scope
- `rcmd(command)` - Execute shell command and capture output

### Expected Globals
- `DATELOG` - Include timestamp in logs (default: False)
- `COLORS` - Enable colored output (default: False)
- `DEBUG`, `VERBOSE`, `TEST` - Enable respective log levels

### Installation Options

#### Install via PIP
```bash
pip install clicommon
```

#### Install via UV
```bash
uv pip install clicommon
```

#### Install dynamically in Python script
```python
#############################
# Declaration Section
#############################
DEBUG = False
VERBOSE = False
DATELOG = True
COLORS = True
COMMON_INCLUDE_URL = "https://raw.githubusercontent.com/franksplace/shell-scripts/refs/heads/main/clicommon.py"

#############################
# Import Section
#############################
import subprocess, sys, argparse
from datetime import datetime

try:
    import clicommon as f
except ImportError:
    print("Fetching clicommon.py from GitHub")
    subprocess.check_call(f"curl -s {COMMON_INCLUDE_URL} -o ./clicommon.py", shell=True, text=True)
finally:
    import clicommon as f

# Now use the functions
f.mlog("INFO", "Script started successfully")
f.mlog("ERROR", "Something went wrong", 1)
```
