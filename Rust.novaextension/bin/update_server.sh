#!/bin/bash
set -e
set -o pipefail

# Save original directory and change to the script directory
original_dir="$(pwd)"
cd "$(dirname "$0")"

# Function to restore original directory on exit
restore_directory() {
    cd "$original_dir"
}

trap restore_directory EXIT

# As of 2023-03-18, `rust-analyzer --version` outputs the following format:
# rust-analyzer 0.3.1435-standalone (f1e51afa4 2023-03-12)
# We want to compare the commit SHA to check for new version
version_regex="\(([[:alnum:]]+)[[:space:]][[:digit:]]{4}\-[[:digit:]]{2}\-[[:digit:]]{2}\)"
download=false
if [[ ! -f "./rust-analyzer" ]]; then
    download=true
elif [[ "$(./rust-analyzer --version)" =~ $version_regex ]]; then
    if [[ "$1" != "${BASH_REMATCH[1]}"* ]]; then
        download=true
    fi
fi

if [[ $download = true ]]; then
    echo "downloading new binary..."
    binary="rust-analyzer-aarch64-apple-darwin.gz"
    if [[ "$(uname -p)" = "x86_64" ]]; then
        binary="rust-analyzer-x86_64-apple-darwin.gz"
    fi
    # We intentionally *don't* download or rename to "rust-analzyer" (sans "-new") in this script
    # Once this script exits, the plugin will stop, rename & restart
    curl -L --fail --silent --show-error \
        https://github.com/rust-lang/rust-analyzer/releases/latest/download/$binary \
        | gunzip -c - > ./rust-analyzer-new

    # Verify the download succeeded
    if [[ ! -f "./rust-analyzer-new" ]] || [[ ! -s "./rust-analyzer-new" ]]; then
        echo "Error: Failed to download rust-analyzer binary"
        exit 1
    fi

    if [[ -f "./rust-analyzer" ]]; then
        echo "archiving old binary..."
        cp ./rust-analyzer ./rust-analyzer-old
    fi
    chmod +x ./rust-analyzer-new
fi
