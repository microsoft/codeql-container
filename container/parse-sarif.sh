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
UNKNOWN=0

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
echo "## [${CIRCLE_PROJECT_USERNAME:-trade-platform}](https://github.com/${CIRCLE_PROJECT_USERNAME:-trade-platform}) / [${CIRCLE_PROJECT_REPONAME:-}](https://github.com/${CIRCLE_PROJECT_USERNAME:-trade-platform}/${CIRCLE_PROJECT_REPONAME:-})   "
if [ -n "${CIRCLE_BUILD_URL}" ]; then
    echo
    echo "## [Build ${CIRCLE_BUILD_NUM}](${CIRCLE_BUILD_URL})"
fi
echo
echo $(date)
echo

LAST_RULE=
LAST_RULE_COUNT=0
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
        ICON="‼️ "
    elif [ "${SEVERITY}" == "warning" ]; then
        WARNINGS=$((${WARNINGS} + 1))
        ICON="⚠️ "
    elif [ "${SEVERITY}" == "recommendation" ]; then
        RECOMMENDATIONS=$((${RECOMMENDATIONS} + 1))
        ICON="😢"
    else
        UNKNOWN=$((${UNKNOWN} + 1))
        ICON="❔"
    fi

    if [ "${LAST_RULE}" != "${TRIGGERED_RULE_ID}" ]; then

        if [ ${LAST_RULE_COUNT} -ge 10 ]; then
            echo
            echo "_There are $(( ${LAST_RULE_COUNT} - 10 )) more locations like this..._"
        fi

        LINK="https://help.semmle.com/wiki/display/JS/$(uriencode "${NAME}")"
        echo
        echo "## ${ICON} [${NAME}](${LINK}) (${SEVERITY} / ${LEVEL})"

        if [ "$(echo ${PROPERTIES} | jq -r 'has("tags")')" = "true" ]; then
            echo
            for TAG in $(echo ${PROPERTIES} | jq -r -c '.tags[]'); do
                if [[ ${TAG} =~ ^external\/cwe\/cwe- ]]; then
                    NUMBER=$(basename ${TAG} | cut -d '-' -f 2)
                    TAG="[${TAG}](https://cwe.mitre.org/data/definitions/${NUMBER}.html)"
                fi
                echo " - ${TAG}"
            done
        fi

        echo
        printf "${DESCRIPTION}"
        echo
        echo
        echo "| File | Location | Comment |"
        echo "|------|----------|---------|"
        LAST_RULE_COUNT=0
    fi

    LAST_RULE="${TRIGGERED_RULE_ID}"

    COMMENT=$(echo ${TRIGGERED_RULE} | jq -r '.message.text')

    if [ "$(echo ${TRIGGERED_RULE} | jq -r 'has("relatedLocations")')" = "true" ]; then
        for LOCATION in $(echo ${TRIGGERED_RULE} | jq -r -c '.relatedLocations[]'); do
            FILE=$(echo ${LOCATION} | jq -r '.physicalLocation.fileLocation.uri')
            START_L=$(echo ${LOCATION} | jq -r '.physicalLocation.region.startLine')
            ANCHOR=$(echo ${LOCATION} | jq -r '.message.text')
            COMMENT=$(echo "${COMMENT}" | sed -e "s;\\[${ANCHOR}\\]([0-9]);[${ANCHOR}](${BASE_URL}${FILE}#L${START_L});")
        done
    fi

    for LOCATION in $(echo ${TRIGGERED_RULE} | jq -r -c '.locations[]'); do
        FILE=$(echo ${LOCATION} | jq -r '.physicalLocation.fileLocation.uri')
        START_L=$(echo ${LOCATION} | jq -r '.physicalLocation.region.startLine')
        START_C=$(echo ${LOCATION} | jq -r '.physicalLocation.region.startColumn')

        if [ ${LAST_RULE_COUNT} -lt 10 ]; then
            echo "| [${FILE}](${BASE_URL}${FILE}) | [${START_L}:${START_C}](${BASE_URL}${FILE}#L${START_L}) | ${COMMENT} |"
        fi

        LAST_RULE_COUNT=$(( ${LAST_RULE_COUNT} + 1 ))
    done
done

if [ ${LAST_RULE_COUNT} -ge 10 ]; then
    echo
    echo "_There are $(( ${LAST_RULE_COUNT} - 10 )) more locations like this..._"
fi

echo
echo "## Summary"
echo
echo "|    | Type            | Count |"
echo "|----|-----------------|-------|"
if [ ${ERRORS} -gt 0 ]; then echo "| ‼️  | Errors          |   ${ERRORS}   |"; fi
if [ ${WARNINGS} -gt 0 ]; then echo "| ⚠️  | Warnings        |   ${WARNINGS}   |"; fi
if [ ${RECOMMENDATIONS} -gt 0 ]; then echo "| 😢 | Recommendations |   ${RECOMMENDATIONS}   |"; fi
if [ ${UNKNOWN} -gt 0 ]; then echo "| ❔ | Unknown         |   ${UNKNOWN}   |"; fi
echo

rm -f rules.json

exit ${ERRORS}
