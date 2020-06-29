#!/usr/bin/python3

import os
import sys
from logging import Logger, getLogger, INFO
from sys import path as syspath
from libs.utils import *
from libs.github import *
from libs.codeql import *

 # get the parent directory of the script, to link libs
sys.path.append(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))

CODEQL_HOME = environ['CODEQL_HOME']

logger = getLogger('codeql-container')
logger.setLevel(INFO)

def setup():
    """
    Download and install the latest codeql cli
    Download and install the latest codeql queries
    """

    # check version and download the latest version
    get_latest_codeql()
    # install vscode?
    # clone codeql libs
    # setup vscode + codeql
    # wait for user


def get_latest_codeql():
    # what version do we have?
    codeql = CodeQL(CODEQL_HOME)
    current_installed_version = codeql.get_current_local_version()
    logger.info(f'Current codeql version: {current_installed_version}')
    latest_online_version = codeql.get_latest_codeql_github_version()
    if current_installed_version != latest_online_version.title:
        # we got a newer version online, download and install it
        codeql.download_and_install_latest_codeql(latest_online_version)
    # get the latest queries regardless (TODO: Optimize by storing and checking the last commit hash?)
    codeql.download_and_install_latest_codeql_queries()

setup()

