#!/usr/bin/env bash
set -euo pipefail

input=${1:?Usage: get-template github:user/repo#path/to/template}
repo_part=${input#github:}
repo_url="https://github.com/${repo_part%%#*}.git"
template_path=${repo_part#*#}

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

git clone --depth 1 --quiet "$repo_url" "$tmp_dir/repo"
if [[ ! -d "$tmp_dir/repo/$template_path" ]]; then
    echo "Error: Template path '$template_path' not found in repository." >&2
    exit 1
fi

cp -r "$tmp_dir/repo/$template_path/." .
echo "Template '$template_path' initialized successfully."