#!/usr/bin/python3
# get the parent directory of the script, to link libs

import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))

from libs.github import get_latest_github_repo_version

def main():
    latest_release = get_latest_github_repo_version("github/codeql-cli-binaries")
    print(latest_release.title)

main()
