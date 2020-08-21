#!/usr/bin/env python3
import os
import sys
import argparse
from sys import path as syspath
from libs.utils import *
from libs.github import *
from libs.codeql import *

CODEQL_HOME = get_env_variable('CODEQL_HOME')

logger = getLogger('codeql-container-setup')
logger.setLevel(INFO)

def parse_arguments():

    parser = argparse.ArgumentParser(description='Setup codeql components.')
    # should we update the local copy of codeql-cli if a new version is available?
    parser.add_argument("-c", "--check-latest-cli", help="check the latest codeql-cli package available and install it", 
                        default=False, action="store_true")
    # should we update the local copy of codeql queries if a new version is available?
    parser.add_argument("-q", "--check-latest-queries", help="check the latest codeql queries available and install it",
                        default=False, action="store_true")
    #(makes query execution faster, but building the container build slower).
    parser.add_argument("-p", "--precompile-latest-queries", help="if new queries were downloaded, precompile it",    
                        default=False, action="store_true")

    args = parser.parse_args()
    return args

def setup():
    """
    Download and install the latest codeql cli
    Download and install the latest codeql queries
    """
    logger.info("Starting setup...")
    args = parse_arguments()
    # check version and download the latest version
    get_latest_codeql(args)
    logger.info("End setup...")
def get_latest_codeql(args):
    # what version do we have?
    codeql = CodeQL(CODEQL_HOME)
    current_installed_version = codeql.get_current_local_version()
    logger.info(f'Current codeql version: {current_installed_version}')
    latest_online_version = codeql.get_latest_codeql_github_version()
    if current_installed_version != latest_online_version.title and args.check_latest_cli:
        # we got a newer version online, download and install it
        codeql.download_and_install_latest_codeql(latest_online_version)
    # get the latest queries regardless (TODO: Optimize by storing and checking the last commit hash?)
    if args.check_latest_queries:
        codeql.download_and_install_latest_codeql_queries()
    if args.precompile_latest_queries:
        codeql.precompile_queries()

logger = get_logger()
setup()

