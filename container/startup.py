#!/usr/bin/env python3
import os
import sys
from time import sleep
from libs.utils import get_env_variable, check_output_wrapper, get_logger
from libs.codeql import *

CODEQL_HOME = get_env_variable('CODEQL_HOME')

# should we update the local copy of codeql-cli if a new version is available?
CHECK_LATEST_CODEQL_CLI = get_env_variable('CHECK_LATEST_CODEQL_CLI', True)

# should we update the local copy of codeql queries if a new version is available?
CHECK_LATEST_QUERIES = get_env_variable('CHECK_LATEST_QUERIES', True)

# if we are downloading new queries, should we precompile them 
#(makes query execution faster, but building the container build slower).
PRECOMPILE_QUERIES = get_env_variable('PRECOMPILE_QUERIES', True)

# ql packs, requested to run, if any
CODEQL_CLI_ARGS = get_env_variable('CODEQL_CLI_ARGS', True)

# should we just exit after execution, or should we wait for user to stop container?
WAIT_AFTER_EXEC = get_env_variable('WAIT_AFTER_EXEC', True)

def main():
    # do the setup, if requested
    scripts_dir = os.path.dirname(os.path.realpath(__file__)) # get the parent directory of the script
    setup_script_args = ''
    if CHECK_LATEST_CODEQL_CLI:
        setup_script_args += ' --check-latest-cli'
    if CHECK_LATEST_QUERIES:
        setup_script_args += ' --check-latest-queries'
    if PRECOMPILE_QUERIES:
        setup_script_args += ' --precompile-latest-queries'

    run_result = check_output_wrapper(
        f"{scripts_dir}/setup.py {setup_script_args}", 
        shell=True).decode("utf-8")

    # what command did the user ask to run? 
    if CODEQL_CLI_ARGS == False or CODEQL_CLI_ARGS == None or CODEQL_CLI_ARGS == ' ':
        # nothing to do
        logger.info("No argument passed in for codeql-cli, nothing to do. To perform some task, please set the CODEQL_CLI_ARGS environment variable to a valid argument...")
    else:
        codeql = CodeQL(CODEQL_HOME)
        run_result = codeql.execute_codeql_command(CODEQL_CLI_ARGS)
        print(run_result)
        
    if WAIT_AFTER_EXEC:
        logger.info("Wait forever specified, waiting...")
        while True:
            sleep(10)

logger = get_logger()
main()
