#!/bin/bash

set -e -o pipefail

chart_file="Chart.yaml"
if [ ! -f "${chart_file}" ]; then
  echo "ERROR: ${chart_file} not found!" 1>&2
  exit 1
fi

default_new_tag="$(git tag --sort=-version:refname | head -n 1)"
default_old_tag="$(git tag --sort=-version:refname | head -n 2 | tail -n 1)"

if [ -z "${1}" ]; then
  echo "Enter start tag [${default_old_tag}]:"
  read -r old_tag
  if [ -z "${old_tag}" ]; then
    old_tag="${default_old_tag}"
  fi

  while [ -z "$(git tag --list "${old_tag}")" ]; do
    echo "ERROR: Tag '${old_tag}' not found!" 1>&2
    echo "Enter start tag [${default_old_tag}]:"
    read -r old_tag
    if [ -z "${old_tag}" ]; then
      old_tag="${default_old_tag}"
    fi
  done
else
  old_tag=${1}
  if [ -z "$(git tag --list "${old_tag}")" ]; then
    echo "ERROR: Tag '${old_tag}' not found!" 1>&2
    exit 1
  fi
fi

if [ -z "${2}" ]; then
  echo "Enter end tag [${default_new_tag}]:"
  read -r new_tag
  if [ -z "${new_tag}" ]; then
    new_tag="${default_new_tag}"
  fi

  while [ -z "$(git tag --list "${new_tag}")" ]; do
    echo "ERROR: Tag '${new_tag}' not found!" 1>&2
    echo "Enter end tag [${default_new_tag}]:"
    read -r new_tag
    if [ -z "${new_tag}" ]; then
      new_tag="${default_new_tag}"
    fi
  done
else
  new_tag=${2}

  if [ -z "$(git tag --list "${new_tag}")" ]; then
    echo "ERROR: Tag '${new_tag}' not found!" 1>&2
    exit 1
  fi
fi

change_log_yaml=$(mktemp)
echo "[]" > "${change_log_yaml}"

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

commit_titles="$(git log --pretty=format:"%s" "${old_tag}..${new_tag}")"

echo "INFO: Generate change log entries from ${old_tag} until ${new_tag}"

while IFS= read -r line; do
  if [[ "${line}" =~ ^([a-zA-Z]+)(\([^\)]+\))?\:\ (.+)$ ]]; then
    type="${BASH_REMATCH[1]}"
    kind=$(map_type_to_kind "${type}")

    if [ "${kind}" == "skip" ]; then
      continue
    fi

    desc="${BASH_REMATCH[3]}"

    echo "- ${kind}: ${desc}"

    jq --arg kind "${kind}" --arg description "${desc}" '. += [ $ARGS.named ]' < "${change_log_yaml}" > "${change_log_yaml}.new"
    mv "${change_log_yaml}.new" "${change_log_yaml}"

  fi
done <<< "${commit_titles}"

if [ -s "${change_log_yaml}" ]; then
  yq --inplace --input-format json --output-format yml "${change_log_yaml}"
  yq --no-colors --inplace ".annotations.\"artifacthub.io/changes\" |= loadstr(\"${change_log_yaml}\") | sort_keys(.)" "${chart_file}"
else
  echo "ERROR: Changelog file is empty: ${change_log_yaml}" 1>&2
  exit 1
fi

rm "${change_log_yaml}"

regexp=".*-alpha-[0-9]+(\.[0-9]+){,2}$"
if [[ "${new_tag}" =~ $regexp ]]; then
  yq --inplace '.annotations."artifacthub.io/prerelease" = "true"' "${chart_file}"
else
  yq --inplace '.annotations."artifacthub.io/prerelease" = "false"' "${chart_file}"
fi
