#!/usr/bin/env bash

##
## Generates a Markdown summary of a .sarif file, then
## exits with the number of errors found.
##

set -euo pipefail

# https://stackoverflow.com/a/34407620/16780
function uriencode { jq -nr --arg v "$1" '$v|@uri'; }

SARIF_FILE=${1:-issues.sarif}

if [ ! -r "${SARIF_FILE}" ]; then
    echo
    echo USAGE: ${0:-parse-sarif.sh} path/to/file.sarif
    echo
    exit 1
fi

jq '.runs[0].resources.rules' ${SARIF_FILE} > rules.json

ERRORS=0
WARNINGS=0
RECOMMENDATIONS=0

BASE_URL="https://github.com/"
if [ -n "${CIRCLE_PROJECT_USERNAME:-trade-platform}" ]; then
    BASE_URL+="${CIRCLE_PROJECT_USERNAME:-}/"
fi
if [ -n "${CIRCLE_PROJECT_REPONAME:-}" ]; then
    BASE_URL+="${CIRCLE_PROJECT_REPONAME:-}/"
fi
if [ -n "${CIRCLE_BRANCH:-}" -a "${CIRCLE_BRANCH:-}" != "master" -a "${CIRCLE_BRANCH:-}" != "main" ]; then
    BASE_URL+="blob/$(uriencode "${CIRCLE_BRANCH:-}")/"
fi

echo
echo "# Static Code Analysis Results"
echo
echo $(date)
echo

LAST_RULE=
IFS=$'\n'
for TRIGGERED_RULE in $(jq -r -c '.runs[0].results[]' ${SARIF_FILE}); do
    TRIGGERED_RULE_ID=$(echo ${TRIGGERED_RULE} | jq -r '.ruleId')
    RULE=$(jq -r -c ".\"${TRIGGERED_RULE_ID}\"" rules.json)
    PROPERTIES=$(echo ${RULE} | jq -r -c '.properties')

    NAME=$(echo ${PROPERTIES} | jq -r '.name')
    LEVEL=$(echo ${PROPERTIES} | jq -r '.precision')
    SEVERITY=$(echo ${PROPERTIES} | jq -r '."problem.severity"')
    DESCRIPTION=$(echo ${PROPERTIES} | jq -r '.description')

    if [ "${SEVERITY}" == "error" ]; then
        ERRORS=$((${ERRORS} + 1))
        ICON=":bangbang:"
    elif [ "${SEVERITY}" == "warning" ]; then
        WARNINGS=$((${WARNINGS} + 1))
        ICON=":warning:"
    elif [ "${SEVERITY}" == "recommendation" ]; then
        RECOMMENDATIONS=$((${RECOMMENDATIONS} + 1))
        ICON=":cry:"
    else
        ICON=":question:"
    fi

    if [ "${LAST_RULE}" != "${TRIGGERED_RULE_ID}" ]; then
        echo
        echo "## ${ICON} ${NAME} (${LEVEL})"

        if [ "$(echo ${PROPERTIES} | jq -r 'has("tags")')" = "true" ]; then
            echo
            for TAG in $(echo ${PROPERTIES} | jq -r -c '.tags[]'); do
                echo " - \`${TAG}\`"
            done
        fi

        echo
        printf "${DESCRIPTION}"
        echo
        echo
        echo "| File | Location | Comment | Context |"
        echo "|---|---|---|---|"
    fi

    LAST_RULE="${TRIGGERED_RULE_ID}"

    COMMENT=$(echo ${TRIGGERED_RULE} | jq -r '.message.text')

    for LOCATION in $(echo ${TRIGGERED_RULE} | jq -r -c '.locations[]'); do
        FILE=$(echo ${LOCATION} | jq -r '.physicalLocation.fileLocation.uri')
        START_L=$(echo ${LOCATION} | jq -r '.physicalLocation.region.startLine')
        START_C=$(echo ${LOCATION} | jq -r '.physicalLocation.region.startColumn')
        END_L=$(echo ${LOCATION} | jq -r '.physicalLocation.region.endLine')
        END_C=$(echo ${LOCATION} | jq -r '.physicalLocation.region.endColumn')

        echo "| [${FILE}](${BASE_URL}${FILE}) | [${START_L}:${START_C}](${BASE_URL}${FILE}#${START_L}) | ${COMMENT} | |"
    done
    if [ "$(echo ${TRIGGERED_RULE} | jq -r 'has("relatedLocations")')" = "true" ]; then
        for LOCATION in $(echo ${TRIGGERED_RULE} | jq -r -c '.relatedLocations[]'); do
            FILE=$(echo ${LOCATION} | jq -r '.physicalLocation.fileLocation.uri')
            START_L=$(echo ${LOCATION} | jq -r '.physicalLocation.region.startLine')
            START_C=$(echo ${LOCATION} | jq -r '.physicalLocation.region.startColumn')
            END_L=$(echo ${LOCATION} | jq -r '.physicalLocation.region.endLine')
            END_C=$(echo ${LOCATION} | jq -r '.physicalLocation.region.endColumn')
            CONTEXT=$(echo ${LOCATION} | jq -r '.message.text')
    
            echo "| [${FILE}](${BASE_URL}${FILE}) | [${START_L}:${START_C}](${BASE_URL}${FILE}#${START_L}) | ${COMMENT} | ${CONTEXT} |"
        done
    fi

done

echo
echo "## Summary"
echo
echo Errors: ${ERRORS}
echo Warnings: ${WARNINGS}
echo Recommendations: ${RECOMMENDATIONS}
echo

exit ${ERRORS}
