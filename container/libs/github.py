import os
from datetime import datetime, MINYEAR
from github import Github, GitRelease, Repository, GithubException

def get_latest_github_repo_version(repo):
    # check for a github token that may be used alongside the codeql cli to upload github results
    # this will limit rate limting 403 errors on checking codeql versions, as the request will be authenticated if possible.
    # by default codeql uses env var "GITHUB_TOKEN" to authenticate
    # https://codeql.github.com/docs/codeql-cli/manual/github-upload-results/
    access_token = os.getenv('GITHUB_TOKEN')
    client = Github(access_token) if access_token != None else Github()
    repo = client.get_repo(repo)
    releases = repo.get_releases()
    latest_release = get_latest_github_release(releases)
    return latest_release

def get_latest_github_release(releases):
    latest_release = None
    latest_date = datetime(MINYEAR, 1, 1)
    for release in releases:
        if release.created_at > latest_date:
            latest_date = release.created_at
            latest_release = release
    return latest_release
