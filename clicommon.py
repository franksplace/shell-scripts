
#
#Copyright 2024 Frank Stutz.
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#
import subprocess, re, sys, inspect
from datetime import datetime

#############################
# Declaration Section
#############################
#

#############################
# Class Section
#############################
class Colors:
    """ ANSI color codes - see see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors """
    BOLD = "\033[1m"
    FAINT = "\033[2m"
    ITALIC = "\033[3m"
    UNDERLINE = "\033[4m"
    BLINK = "\033[5m"
    NEGATIVE = "\033[7m"
    CROSSED = "\033[9m"
    BLACK = "\033[0;30m"
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    BROWN = "\033[0;33m"
    BLUE = "\033[0;34m"
    PURPLE = "\033[0;35m"
    MAGENTA = PURPLE
    CYAN = "\033[0;36m"
    LIGHT_GRAY = "\033[0;37m"
    DARK_GRAY = "\033[1;30m"
    LIGHT_RED = "\033[1;31m"
    LIGHT_GREEN = "\033[1;32m"
    YELLOW = "\033[1;33m"
    LIGHT_BLUE = "\033[1;34m"
    LIGHT_PURPLE = "\033[1;35m"
    LIGHT_CYAN = "\033[1;36m"
    LIGHT_WHITE = "\033[1;37m"
    GRAY = "\033[0;90m"
    BRIGHT_RED = "\033[0;91m"
    BRIGHT_GREEN = "\033[0;92m"
    BRIGHT_YELLOW = "\033[0;93m"
    BRIGHT_BLUE = "\033[0;94m"
    BRIGHT_MAGENTA = "\033[0;95m"
    BRIGHT_CYAN = "\033[0;96m"
    BRIGHT_WHITE = "\033[0;97m"
    END = "\033[0m"
    # preferred color for message/log types 
    INFO=GREEN
    SUCCESS=GREEN
    WARN=YELLOW
    WARNING=YELLOW
    FATAL=RED
    ERROR=RED
    CRITICAL=RED
    TEST=GRAY
    DEBUG=MAGENTA
    VERBOSE=BRIGHT_CYAN
    BUILD_DEBUG=BRIGHT_GREEN
    CODE_DEBUG=BRIGHT_GREEN

    if not __import__("sys").stdout.isatty():
        for _ in dir():
            if isinstance(_, str) and _[0] != "_":
                locals()[_] = ""
    else:
        if __import__("platform").system() == "Windows":
            kernel32 = __import__("ctypes").windll.kernel32
            kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
            del kernel32

#############################
# Module Section
#############################
def bcheck(var):
    caller_globals = dict(inspect.getmembers(inspect.stack()[1][0]))["f_globals"]
    try:
        if caller_globals[var]:
            return True
    except KeyError:
        return False

    return False


def mlog(msg_type, msg_string = None, exit_code = None, datelog = None, colors = None ):
    caller_globals = dict(inspect.getmembers(inspect.stack()[1][0]))["f_globals"]
    if datelog is None:
        try:
            if caller_globals['DATELOG']:
                datelog = caller_globals['DATELOG']
        except KeyError:
            datelog = False

    if colors is None:
        try:
            if caller_globals['COLORS']:
                colors = caller_globals['COLORS']
        except KeyError:
            colors = False

    if not msg_string:
        msg_string = msg_type
        msg_type = ''

    if re.search("TEST|DEBUG|VERBOSE", msg_type):
        try:
            if not caller_globals[msg_type]:
                return
        except KeyError:
            return

    if datelog:
        prefix = datetime.now(tz=datetime.now().astimezone().tzinfo).strftime('%Y-%m-%dT%H:%M:%S.%f%z')
        if msg_type:
            prefix += f" {msg_type}"
    else:
        if msg_type:
            prefix = msg_type
        else:
            prefix = ''

    if prefix:
        out=f"{prefix} {msg_string}"
    else:
        out=msg_string

    if colors:
        if msg_type:
            print(getattr(Colors,msg_type) + f"msg_type is {msg_type} " + out + Colors.END)
        else:
            print(Colors.END + f"msg_type is {msg_type} " + out + Colors.END)

    else:
        print(out)

    if exit_code:
        exit(exit_code)

def rcmd(command):
    try:
        result = subprocess.check_output(command, shell=True, text=True)
        return result
    except subprocess.CalledProcessError as e:
        mlog("ERROR", f"Error executing command: {e}", 1)

