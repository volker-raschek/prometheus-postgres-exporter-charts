#!/bin/bash

set -e

CHART_FILE="Chart.yaml"
if [ ! -f "${CHART_FILE}" ]; then
  echo "ERROR: ${CHART_FILE} not found!"
  exit 1
fi


DEFAULT_NEW_TAG="$(git describe --abbrev=0)"
DEFAULT_OLD_TAG="$(git describe --abbrev=0 --tags "$(git rev-list --tags --skip=1 --max-count=1)")"

if [ -z "${1}" ]; then
  read -p "Enter start tag [${DEFAULT_OLD_TAG}]: " OLD_TAG
  if [ -z "${OLD_TAG}" ]; then
    OLD_TAG="${DEFAULT_OLD_TAG}"
  fi

  while [ -z "$(git tag --list "${OLD_TAG}")" ]; do
    echo "ERROR: Tag '${OLD_TAG}' not found!"
    read -p "Enter start tag [${DEFAULT_OLD_TAG}]: " OLD_TAG
    if [ -z "${OLD_TAG}" ]; then
      OLD_TAG="${DEFAULT_OLD_TAG}"
    fi
  done
else
  OLD_TAG=${1}
  if [ -z "$(git tag --list "${OLD_TAG}")" ]; then
    echo "ERROR: Tag '${OLD_TAG}' not found!"
    exit 1
  fi
fi

if [ -z "${1}" ]; then
  read -p "Enter end tag [${DEFAULT_NEW_TAG}]: " NEW_TAG
  if [ -z "${NEW_TAG}" ]; then
    NEW_TAG="${DEFAULT_NEW_TAG}"
  fi

  while [ -z "$(git tag --list "${NEW_TAG}")" ]; do
    echo "ERROR: Tag '${NEW_TAG}' not found!"
    read -p "Enter end tag [${DEFAULT_NEW_TAG}]: " NEW_TAG
    if [ -z "${NEW_TAG}" ]; then
      NEW_TAG="${DEFAULT_NEW_TAG}"
    fi
  done
else
  NEW_TAG=${1}

  if [ -z "$(git tag --list "${NEW_TAG}")" ]; then
    echo "ERROR: Tag '${NEW_TAG}' not found!"
    exit 1
  fi
fi

YAML_FILE=$(mktemp)

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

COMMIT_TITLES=$(git log "${OLD_TAG}..${NEW_TAG}" --pretty=format:"%s")

while IFS= read -r line; do
  if [[ "${line}" =~ ^([a-zA-Z]+)(\([^\)]+\))?\:\ (.+)$ ]]; then
    TYPE="${BASH_REMATCH[1]}"

    if [ "${TYPE}" == "skip" ]; then
      continue
    fi

    DESC="${BASH_REMATCH[3]}"
    KIND=$(map_type_to_kind "${TYPE}")

    yq --inplace ". += [ {\"kind\": \"${KIND}\", \"description\": \"${DESC}\"}]" "${YAML_FILE}"
  fi
done <<< "${COMMIT_TITLES}"

yq --no-colors --inplace ".annotations.\"artifacthub.io/changes\" |= loadstr(\"${YAML_FILE}\") | sort_keys(.)" "${CHART_FILE}"
yq --no-colors --inplace ".version = \"${NEW_TAG}\"" "${CHART_FILE}"

rm "${YAML_FILE}"