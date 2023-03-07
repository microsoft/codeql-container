from datetime import datetime, MINYEAR
from ghapi.all import GhApi
from datetime import datetime, timezone
from dateutil import parser

def get_latest_github_repo_version(owner, repository):
    api = GhApi(owner=owner, repo=repository)
    releases = api.repos.list_releases()
    latest_release = get_latest_github_release(releases)
    return latest_release

def get_latest_github_release(releases):
    latest_release = None
    latest_date = datetime(MINYEAR, 1, 1).replace(tzinfo=timezone.utc)
    for release in releases:
        release_date = parser.parse(release.created_at)
        if release_date > latest_date:
            latest_date = release_date
            latest_release = release
    return latest_release
