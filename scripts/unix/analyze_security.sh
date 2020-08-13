#!/bin/bash
scriptname=$(basename "$0")
inputfile=${1}
outputfile=${2}
language=${3}

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
RESET="\033[0m"

print_yellow() {
    echo -e "${YELLOW}${1}${RESET}"
}

print_red() {
    echo -e "${RED}${1}${RESET}"
}

print_green() {
    echo -e "${GREEN}${1}${RESET}"
}

if [ "$#" -ne 3 ]; then
    print_yellow "\nPlease provide the folder to analyze, the folder to store results, and the coding language of the project."
    print_yellow "\nUsage: ${scriptname} <folder to analyze> <folder to store result> <language>"
    print_yellow "\nExample: ${scriptname} /tmp/pandas /tmp/results python"
   exit 1
fi

print_yellow "Getting/Updating the codeQL container\n"
docker pull mcr.microsoft.com/cstsectools/codeql-container:latest
if [ $? -eq 0 ]
then
    print_green "\nPulled the container" 
else
    print_red "\nFailed to pull container"
    exit 1
fi

print_yellow "\nCreating the codeQL database. This might take some time depending on the size of the project..."
docker run --rm --name codeql-container -v "${inputfile}:/opt/src" -v "${outputfile}:/opt/results" -e CODEQL_CLI_ARGS=database\ create\ --language=${3}\ /opt/results/source_db\ -s\ /opt/src mcr.microsoft.com/cstsectools/codeql-container
if [ $? -eq 0 ]
then
    print_green "\nCreated the database" 
else
    print_red "\nFailed to create the database"
    exit 1
fi

docker run --rm --name codeql-container -v "${inputfile}:/opt/src" -v "${outputfile}:/opt/results" -e CODEQL_CLI_ARGS=database\ upgrade\ /opt/results/source_db mcr.microsoft.com/cstsectools/codeql-container 
if [ $? -eq 0 ]
then
    print_green "\nUpgraded the database\n" 
else
    print_red "\nFailed to upgrade the database"
    exit 2
fi

print_yellow "\nRunning the Quality and Security rules on the project"
docker run --rm --name codeql-container -v ${inputfile}:/opt/src -v ${outputfile}:/opt/results -e CODEQL_CLI_ARGS=database\ analyze\ /opt/results/source_db\ --format=sarifv2\ --output=/opt/results/issues.sarif\ ${language}-security-and-quality.qls mcr.microsoft.com/cstsectools/codeql-container 
if [ $? -eq 0 ]
then
    print_green "\nQuery execution successful" 
else
    print_red "\nQuery execution failed\n"
    exit 3
fi

[ $? -eq 0 ] && print_yellow "The results are saved at ${2}/issues.sarif"