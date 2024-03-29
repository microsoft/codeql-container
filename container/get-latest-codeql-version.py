#!/usr/bin/env python3
# get the parent directory of the script, to link libs
from libs.github import get_latest_github_repo_version

def main():
    latest_release = get_latest_github_repo_version("github", "codeql-cli-binaries")
    print(latest_release.tag_name)

main()
