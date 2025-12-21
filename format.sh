#!/bin/zsh
# Format files in place using `swift format` (Xcode 16+) and clean up whitespace issues.

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <file> [file...]" >&2
  echo "Supported formats: .swift (formatted and cleaned), .json, .yml, .yaml, .plist (cleaned only)" >&2
  exit 1
fi

# Process Swift files with formatting and cleanup
swift_files=()
other_files=()

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi
  
  if [[ "${file##*.}" == "swift" ]]; then
    swift_files+=("$file")
  else
    other_files+=("$file")
  fi
done

# Format Swift files
for file in "${swift_files[@]}"; do
  swift format --in-place "$file"
  echo "Formatted: $file"
done

# Remove trailing whitespaces from all files
for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi
  sed -i '' 's/[[:space:]]*$//' "$file"
  echo "Removed trailing whitespaces: $file"
done

# Remove consecutive empty lines, leaving only one empty line
for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi
  sed -i '' '/^$/N;/^\n$/d' "$file"
  echo "Removed consecutive empty lines: $file"
done

