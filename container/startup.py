import os

# should we update the local copy of codeql-cli if a new version is available?
CHECK_LATEST_CODEQL_CLI = False

# should we update the local copy of codeql queries if a new version is available?
CHECK_LATEST_QUERIES = False


# if we are downloading new queries, should we precompile them 
#(makes query execution faster, but building the container build slower).
PRECOMPILE_QUERIES = False

def main():
    # get all the command-line args/envs required
    # check if the latest codeql cli need to be downloaded
    # check if the latest codeql queries need to be downloaded
    # check if we need to precompile the new queries
