
import subprocess
import os
import sys
import shutil
import re
from security import safe_command

nose_run = [
    "nosetests",
    "test",
    "-vv",
    "--with-coverage",
    "--cover-inclusive",
    "--cover-package=thermotools",
    "--with-doctest",
    "--doctest-options=+NORMALIZE_WHITESPACE,+ELLIPSIS"]

res = safe_command.run(subprocess.call, nose_run)

sys.exit(res)
