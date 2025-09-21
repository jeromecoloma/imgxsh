#!/bin/bash

# Shell Starter - Release Notes Generator
# Generates automated release notes from git commits using conventional commit format

set -euo pipefail

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Default values
OUTPUT_FILE="release_notes.md"
CURRENT_VERSION=""
PREVIOUS_VERSION=""
REPOSITORY=""

show_help() {
	cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate automated release notes from git commits using conventional commit format.

OPTIONS:
    -c, --current VERSION     Current version (required)
    -p, --previous VERSION    Previous version (auto-detected if not provided)
    -o, --output FILE         Output file (default: release_notes.md)
    -r, --repository REPO     Repository in format owner/repo (auto-detected if not provided)
    -h, --help               Show this help message

EXAMPLES:
    $(basename "$0") -c 1.2.0
    $(basename "$0") -c 1.2.0 -p 1.1.0 -o CHANGELOG.md
    $(basename "$0") --current 2.0.0 --repository owner/my-repo

CONVENTIONAL COMMITS:
    This script recognizes conventional commit format:
    - feat: new features
    - fix: bug fixes
    - docs: documentation changes
    - chore: maintenance tasks
    - feat!: breaking changes (with !)

EOF
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		-c | --current)
			CURRENT_VERSION="$2"
			shift 2
			;;
		-p | --previous)
			PREVIOUS_VERSION="$2"
			shift 2
			;;
		-o | --output)
			OUTPUT_FILE="$2"
			shift 2
			;;
		-r | --repository)
			REPOSITORY="$2"
			shift 2
			;;
		-h | --help)
			show_help
			exit 0
			;;
		*)
			echo "Error: Unknown option $1" >&2
			show_help >&2
			exit 1
			;;
		esac
	done

	# Validate required arguments
	if [[ -z "$CURRENT_VERSION" ]]; then
		echo "Error: Current version is required (-c/--current)" >&2
		exit 1
	fi
}

auto_detect_values() {
	# Auto-detect previous version if not provided
	if [[ -z "$PREVIOUS_VERSION" ]]; then
		PREVIOUS_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
		echo "Auto-detected previous version: $PREVIOUS_VERSION" >&2
	fi

	# Auto-detect repository if not provided
	if [[ -z "$REPOSITORY" ]]; then
		if git remote get-url origin >/dev/null 2>&1; then
			REMOTE_URL=$(git remote get-url origin)
			if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
				REPOSITORY="${BASH_REMATCH[1]}"
				echo "Auto-detected repository: $REPOSITORY" >&2
			fi
		fi
	fi
}

generate_release_notes() {
	local current_version="$1"
	local previous_version="$2"
	local output_file="$3"
	local repository="$4"

	echo "Generating release notes: $previous_version -> $current_version" >&2

	# Initialize release notes
	cat >"$output_file" <<EOF
# Release $current_version

EOF

	if [[ "$previous_version" != "0.0.0" ]] && git rev-parse "v$previous_version" >/dev/null 2>&1; then
		local prev_tag="v$previous_version"
		local commits
		commits=$(git log --pretty=format:"%H|%s|%an|%ae" --reverse "$prev_tag..HEAD")
		local commit_count
		commit_count=$(echo "$commits" | wc -l | tr -d ' ')

		echo "Found $commit_count commits since $previous_version" >&2

		# Initialize temporary files for categorization
		local temp_dir
		temp_dir=$(mktemp -d) || {
			echo "Error: Failed to create temporary directory" >&2
			exit 1
		}
		trap 'if [[ -n "${temp_dir:-}" && -d "$temp_dir" ]]; then rm -rf "$temp_dir"; fi' EXIT

		true >"$temp_dir/features.tmp"
		true >"$temp_dir/fixes.tmp"
		true >"$temp_dir/docs.tmp"
		true >"$temp_dir/chores.tmp"
		true >"$temp_dir/breaking.tmp"
		true >"$temp_dir/other.tmp"

		# Parse commits using conventional commit format
		while IFS='|' read -r hash subject author email; do
			[[ -z "$hash" ]] && continue

			# Extract conventional commit type and scope
			if echo "$subject" | grep -E "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build)(\(.+\))?\!?:" >/dev/null; then
				local type scope desc breaking entry
				type=$(echo "$subject" | sed -E 's/^([a-z]+)(\(.+\))?\!?:.*/\1/')
				scope=$(echo "$subject" | sed -E 's/^[a-z]+\((.+)\)\!?:.*/\1/' | grep -v "^$subject$" || echo "")
				desc=$(echo "$subject" | sed -E 's/^[a-z]+(\(.+\))?\!?: ?//')
				breaking=$(echo "$subject" | grep -E "\!" >/dev/null && echo "true" || echo "false")

				# Format the entry with commit link
				if [[ -n "$repository" ]]; then
					entry="- **$desc** ([${hash:0:7}](https://github.com/$repository/commit/$hash))"
					if [[ -n "$scope" ]]; then
						entry="- **$scope**: $desc ([${hash:0:7}](https://github.com/$repository/commit/$hash))"
					fi
				else
					entry="- **$desc** (${hash:0:7})"
					if [[ -n "$scope" ]]; then
						entry="- **$scope**: $desc (${hash:0:7})"
					fi
				fi

				# Categorize by type
				case "$type" in
				feat)
					echo "$entry" >>"$temp_dir/features.tmp"
					;;
				fix)
					echo "$entry" >>"$temp_dir/fixes.tmp"
					;;
				docs)
					echo "$entry" >>"$temp_dir/docs.tmp"
					;;
				chore | style | refactor | test | perf | ci | build)
					echo "$entry" >>"$temp_dir/chores.tmp"
					;;
				esac

				# Check for breaking changes
				if [[ "$breaking" == "true" ]]; then
					echo "$entry" >>"$temp_dir/breaking.tmp"
				fi
			else
				# Non-conventional commits go to other
				local desc="$subject"
				local entry
				if [[ -n "$repository" ]]; then
					entry="- $desc ([${hash:0:7}](https://github.com/$repository/commit/$hash))"
				else
					entry="- $desc (${hash:0:7})"
				fi
				echo "$entry" >>"$temp_dir/other.tmp"
			fi
		done <<<"$commits"

		# Build release notes with categories
		cat >>"$output_file" <<EOF
## What's Changed

EOF

		# Breaking Changes (highest priority)
		if [[ -s "$temp_dir/breaking.tmp" ]]; then
			cat >>"$output_file" <<EOF
### ⚠️ Breaking Changes

EOF
			cat "$temp_dir/breaking.tmp" >>"$output_file"
			echo "" >>"$output_file"
		fi

		# Features
		if [[ -s "$temp_dir/features.tmp" ]]; then
			cat >>"$output_file" <<EOF
### ✨ New Features

EOF
			cat "$temp_dir/features.tmp" >>"$output_file"
			echo "" >>"$output_file"
		fi

		# Bug Fixes
		if [[ -s "$temp_dir/fixes.tmp" ]]; then
			cat >>"$output_file" <<EOF
### 🐛 Bug Fixes

EOF
			cat "$temp_dir/fixes.tmp" >>"$output_file"
			echo "" >>"$output_file"
		fi

		# Documentation
		if [[ -s "$temp_dir/docs.tmp" ]]; then
			cat >>"$output_file" <<EOF
### 📚 Documentation

EOF
			cat "$temp_dir/docs.tmp" >>"$output_file"
			echo "" >>"$output_file"
		fi

		# Maintenance & Chores
		if [[ -s "$temp_dir/chores.tmp" ]]; then
			cat >>"$output_file" <<EOF
### 🔧 Maintenance

EOF
			cat "$temp_dir/chores.tmp" >>"$output_file"
			echo "" >>"$output_file"
		fi

		# Other changes
		if [[ -s "$temp_dir/other.tmp" ]]; then
			cat >>"$output_file" <<EOF
### 📝 Other Changes

EOF
			cat "$temp_dir/other.tmp" >>"$output_file"
			echo "" >>"$output_file"
		fi

		# Contributors section
		local contributors contributor_count
		contributors=$(git log --pretty=format:"%an" "$prev_tag..HEAD" | sort | uniq)
		contributor_count=$(echo "$contributors" | wc -l | tr -d ' ')

		cat >>"$output_file" <<EOF
### 👥 Contributors

Thank you to the $contributor_count contributor(s) who made this release possible:

EOF
		echo "$contributors" | while read -r contributor; do
			echo "- @$contributor" >>"$output_file"
		done
		echo "" >>"$output_file"

	else
		# First release
		cat >>"$output_file" <<EOF
## 🎉 Initial Release

This is the first release of Shell Starter - a comprehensive shell scripting framework.

### ✨ Core Features

- 🎨 **Complete Library System**: Standardized colors, logging, spinner, and utility functions
- 📦 **Smart Installation**: Intelligent installer and uninstaller with manifest tracking
- 🔄 **Update Management**: Built-in update checking with GitHub release integration
- 🧪 **Testing Framework**: Comprehensive test suite using Bats framework
- 🚀 **CI/CD Pipeline**: Automated testing with shellcheck, shfmt, and quality checks
- 🤖 **AI-Ready**: Documentation and workflows optimized for AI-assisted development

EOF
	fi

	# Add footer with metadata
	cat >>"$output_file" <<EOF

---

**Release Information:**
- **Version**: $current_version
- **Previous Version**: $previous_version
- **Generated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
EOF

	if [[ -n "$repository" ]]; then
		cat >>"$output_file" <<EOF
- **Full Changelog**: https://github.com/$repository/compare/v$previous_version...v$current_version
EOF
	fi

	cat >>"$output_file" <<EOF

*Generated by Shell Starter release automation.*
EOF

	echo "✅ Release notes generated: $output_file" >&2
}

main() {
	parse_args "$@"
	auto_detect_values
	generate_release_notes "$CURRENT_VERSION" "$PREVIOUS_VERSION" "$OUTPUT_FILE" "$REPOSITORY"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
