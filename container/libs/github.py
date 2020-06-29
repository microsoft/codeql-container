from datetime import datetime, MINYEAR
from github import Github, GitRelease, Repository, GithubException

def get_latest_github_repo_version(repo):
    client = Github()
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
