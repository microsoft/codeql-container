#!/bin/bash
scriptname=$(basename "$0")
inputfile=${1}
outputfile=${2}

if [ "$#" -ne 2 ]; then
    echo "Please provide the folder to analyze, and the folder to store results"
    echo "Usage: ${scriptname} <folder to analyze> <folder to store result>"
    exit 1
fi

RED='[7;31m'
RESET='[0m'
#docker pull sargemonkey/codeql-container
#[ $? -eq 0 ] && echo "Pulled the container" || echo -e "failed to pull container";exit 1
docker run --rm --name codeql-container -v "${inputfile}:/opt/src" -v "${outputfile}:/opt/results" -e CODEQL_CLI_ARGS=database\ create\ --language=python\ /opt/src/source_db csteosstools.azurecr.io/codeql/codeql-container
[ $? -eq 0 ] && echo "Created the database" || echo -e "\n${RED}Failed to create the database${RESET}\n";exit 1
docker run --rm --name codeql-container -v "${inputfile}:/opt/src" -v "${outputfile}:/opt/results" -e CODEQL_CLI_ARGS=database\ upgrade\ /opt/src/source_db csteosstools.azurecr.io/codeql/codeql-container 
[ $? -eq 0 ] && echo "Upgraded the database" || echo -e "\n${RED}failed to upgrade the database${RESET}\n";exit 2
docker run --rm --name codeql-container -v ${inputfile}:/opt/src -v ${outputfile}:/opt/results -e CODEQL_CLI_ARGS=database\ analyze\ /opt/src/source_db\ --format=sarifv2\ --output=/opt/results/issues.sarif\ python-security-and-quality.qls csteosstools.azurecr.io/codeql/codeql-container 
[ $? -eq 0 ] && echo "Query execution successful" || echo -e "\n${RED}Query execution failed${RESET}\n"; exit 3

echo "The results file should be located at ${2}/issues.sarif"