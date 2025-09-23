#!/usr/bin/env bash

# CI Environment Setup Script for imgxsh
# Ensures consistent test environment between local development and CI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Export essential CI environment variables
export CI="${CI:-true}"
export SHELL_STARTER_CI_MODE="${SHELL_STARTER_CI_MODE:-true}"
export SHELL_STARTER_SPINNER_DISABLED="${SHELL_STARTER_SPINNER_DISABLED:-true}"
# Don't set BATS_NO_PARALLELIZE_ACROSS_FILES in CI unless we're using parallel jobs
# export BATS_NO_PARALLELIZE_ACROSS_FILES="${BATS_NO_PARALLELIZE_ACROSS_FILES:-true}"
export TERM="${TERM:-xterm-256color}"

# Create CI temp directory
CI_TEMP_DIR="${CI_TEMP_DIR:-/tmp/imgxsh-ci-$$}"
export IMGXSH_CI_TEMP="$CI_TEMP_DIR"
mkdir -p "$CI_TEMP_DIR"

echo "Setting up CI environment for imgxsh tests..."

# Check for required POSIX tools
required_tools=("bash" "grep" "sed" "awk" "find" "sort")
missing_tools=()

for tool in "${required_tools[@]}"; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		missing_tools+=("$tool")
	fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
	echo "❌ Missing required tools: ${missing_tools[*]}" >&2
	exit 1
else
	echo "✅ All required POSIX tools available"
fi

# Check for timeout command (for test timeouts)
if command -v timeout >/dev/null 2>&1; then
	echo "✅ timeout command available: $(timeout --version | head -1)"
else
	echo "⚠️  timeout command not available (tests may hang)"
fi

# Check for imgxsh-specific dependencies
echo "Checking imgxsh dependencies..."
missing_imgxsh_deps=()

# Install pdfimages/poppler-utils for PDF processing tests
if ! command -v pdfimages >/dev/null 2>&1; then
	echo "Installing pdfimages (poppler-utils) for PDF processing tests..."
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update -qq
		sudo apt-get install -y poppler-utils
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y poppler-utils
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y poppler-utils
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -S --noconfirm poppler
	else
		echo "⚠️  Cannot install pdfimages automatically on this system"
		missing_imgxsh_deps+=("pdfimages")
	fi
fi

if command -v pdfimages >/dev/null 2>&1; then
	echo "✅ pdfimages available for PDF processing tests"
	export IMGXSH_PDFIMAGES_AVAILABLE=true
else
	echo "⚠️  pdfimages not available - PDF processing tests will be skipped"
	export IMGXSH_PDFIMAGES_AVAILABLE=false
	missing_imgxsh_deps+=("pdfimages")
fi

# Check for ImageMagick (either magick or convert command)
if command -v magick >/dev/null 2>&1; then
	echo "✅ ImageMagick (magick) available for image processing tests"
	export IMGXSH_IMAGEMAGICK_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
	echo "✅ ImageMagick (convert) available for image processing tests"
	export IMGXSH_IMAGEMAGICK_CMD="convert"
else
	missing_imgxsh_deps+=("imagemagick")
fi

# Check for identify command
if ! command -v identify >/dev/null 2>&1; then
	missing_imgxsh_deps+=("identify")
fi

# Ensure unzip for .xlsx extraction
if ! command -v unzip >/dev/null 2>&1; then
	echo "Installing unzip for .xlsx extraction..."
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update -qq
		sudo apt-get install -y unzip
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y unzip
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y unzip
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -S --noconfirm unzip
	else
		echo "⚠️  Cannot install unzip automatically on this system"
		missing_imgxsh_deps+=("unzip")
	fi
fi

if command -v unzip >/dev/null 2>&1; then
	echo "✅ unzip available for .xlsx extraction"
else
	echo "⚠️  unzip not available - some Excel extraction tests will be limited"
fi

# Best-effort install for 7z (p7zip) to support .xls extraction
if ! command -v 7z >/dev/null 2>&1; then
	echo "Attempting to install 7z (p7zip) for .xls extraction..."
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update -qq
		sudo apt-get install -y p7zip-full || true
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y p7zip || true
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y p7zip || true
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -S --noconfirm p7zip || true
	else
		echo "⚠️  Cannot install 7z automatically on this system"
	fi
fi

if command -v 7z >/dev/null 2>&1; then
	echo "✅ 7z available for .xls extraction"
	export IMGXSH_7Z_AVAILABLE=true
else
	echo "ℹ️  7z not available - .xls extraction will be skipped gracefully"
	export IMGXSH_7Z_AVAILABLE=false
fi

# Set environment flags based on dependencies
if [[ ${#missing_imgxsh_deps[@]} -gt 0 ]]; then
	echo "⚠️  Missing imgxsh dependencies: ${missing_imgxsh_deps[*]}"
	echo "   Image processing tests will be skipped"
	export IMGXSH_SKIP_IMAGE_TESTS=true
else
	export IMGXSH_SKIP_IMAGE_TESTS=false
fi

# Set up Git configuration if needed
if command -v git >/dev/null 2>&1; then
	if ! git config --global user.email >/dev/null 2>&1; then
		git config --global user.email "ci@imgxsh.test" 2>/dev/null || true
	fi
	if ! git config --global user.name >/dev/null 2>&1; then
		git config --global user.name "imgxsh CI" 2>/dev/null || true
	fi
fi

# Create isolated shell configuration for tests
SHELL_CONFIG_FILE="$CI_TEMP_DIR/shell_config"
cat >"$SHELL_CONFIG_FILE" <<EOF
# Isolated shell configuration for CI tests
export PS1='$ '
export PATH="$PROJECT_ROOT/bin:\$PATH"
unset CDPATH
export LANG=C
export LC_ALL=C
EOF

# Also update the current PATH for immediate use
export PATH="$PROJECT_ROOT/bin:$PATH"

export SHELL_STARTER_TEST_CONFIG="$SHELL_CONFIG_FILE"
echo "✅ Isolated shell configuration created"

# Set up cleanup trap
cleanup_ci_environment() {
	if [[ -d "$CI_TEMP_DIR" ]]; then
		rm -rf "$CI_TEMP_DIR" 2>/dev/null || true
	fi
}

trap cleanup_ci_environment EXIT INT TERM

echo ""
echo "imgxsh CI Environment Setup Complete"
echo "===================================="
echo "Project Root: $PROJECT_ROOT"
echo "CI Temp Dir:  $CI_TEMP_DIR"
echo "Shell Config: $SHELL_CONFIG_FILE"
echo "CI Mode:      $SHELL_STARTER_CI_MODE"
echo "Skip Image Tests: $IMGXSH_SKIP_IMAGE_TESTS"
echo "PATH: $PATH"
echo ""
echo "Environment ready for imgxsh testing!"
