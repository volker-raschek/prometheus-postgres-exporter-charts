#!/bin/bash

set -e

CHART_FILE="Chart.yaml"
if [ ! -f "${CHART_FILE}" ]; then
  echo "ERROR: ${CHART_FILE} not found!" 1>&2
  exit 1
fi

DEFAULT_NEW_TAG="$(git tag --sort=-version:refname | head -n 1)"
DEFAULT_OLD_TAG="$(git tag --sort=-version:refname | head -n 2 | tail -n 1)"

if [ -z "${1}" ]; then
  read -p "Enter start tag [${DEFAULT_OLD_TAG}]: " OLD_TAG
  if [ -z "${OLD_TAG}" ]; then
    OLD_TAG="${DEFAULT_OLD_TAG}"
  fi

  while [ -z "$(git tag --list "${OLD_TAG}")" ]; do
    echo "ERROR: Tag '${OLD_TAG}' not found!" 1>&2
    read -p "Enter start tag [${DEFAULT_OLD_TAG}]: " OLD_TAG
    if [ -z "${OLD_TAG}" ]; then
      OLD_TAG="${DEFAULT_OLD_TAG}"
    fi
  done
else
  OLD_TAG=${1}
  if [ -z "$(git tag --list "${OLD_TAG}")" ]; then
    echo "ERROR: Tag '${OLD_TAG}' not found!" 1>&2
    exit 1
  fi
fi

if [ -z "${2}" ]; then
  read -p "Enter end tag [${DEFAULT_NEW_TAG}]: " NEW_TAG
  if [ -z "${NEW_TAG}" ]; then
    NEW_TAG="${DEFAULT_NEW_TAG}"
  fi

  while [ -z "$(git tag --list "${NEW_TAG}")" ]; do
    echo "ERROR: Tag '${NEW_TAG}' not found!" 1>&2
    read -p "Enter end tag [${DEFAULT_NEW_TAG}]: " NEW_TAG
    if [ -z "${NEW_TAG}" ]; then
      NEW_TAG="${DEFAULT_NEW_TAG}"
    fi
  done
else
  NEW_TAG=${2}

  if [ -z "$(git tag --list "${NEW_TAG}")" ]; then
    echo "ERROR: Tag '${NEW_TAG}' not found!" 1>&2
    exit 1
  fi
fi

CHANGE_LOG_YAML=$(mktemp)
echo "[]" > "${CHANGE_LOG_YAML}"

function map_type_to_kind() {
  case "${1}" in
    feat)
      echo "added"
    ;;
    fix)
      echo "fixed"
    ;;
    chore|style|test|ci|docs|refac)
      echo "changed"
    ;;
    revert)
      echo "removed"
    ;;
    sec)
      echo "security"
    ;;
    *)
      echo "skip"
    ;;
  esac
}

COMMIT_TITLES="$(git log --pretty=format:"%s" "${OLD_TAG}..${NEW_TAG}")"

echo "INFO: Generate change log entries from ${OLD_TAG} until ${NEW_TAG}"

while IFS= read -r line; do
  if [[ "${line}" =~ ^([a-zA-Z]+)(\([^\)]+\))?\:\ (.+)$ ]]; then
    TYPE="${BASH_REMATCH[1]}"
    KIND=$(map_type_to_kind "${TYPE}")

    if [ "${KIND}" == "skip" ]; then
      continue
    fi

    DESC="${BASH_REMATCH[3]}"

    echo "- ${KIND}: ${DESC}"

    jq --arg kind "${KIND}" --arg description "${DESC}" '. += [ $ARGS.named ]' < "${CHANGE_LOG_YAML}" > "${CHANGE_LOG_YAML}.new"
    mv "${CHANGE_LOG_YAML}.new" "${CHANGE_LOG_YAML}"

  fi
done <<< "${COMMIT_TITLES}"

if [ -s "${CHANGE_LOG_YAML}" ]; then
  yq --inplace --input-format json --output-format yml "${CHANGE_LOG_YAML}"
  yq --no-colors --inplace ".annotations.\"artifacthub.io/changes\" |= loadstr(\"${CHANGE_LOG_YAML}\") | sort_keys(.)" "${CHART_FILE}"
else
  echo "ERROR: Changelog file is empty: ${CHANGE_LOG_YAML}" 1>&2
  exit 1
fi

rm "${CHANGE_LOG_YAML}"
