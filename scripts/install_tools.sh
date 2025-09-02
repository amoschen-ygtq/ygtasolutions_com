#!/bin/bash

# Initializes a new instance of the MyClass class with the specified parameters.
# This constructor sets up the object's initial state based on the provided arguments.
set -e

# Install Hugo Extended if not already installed
if ! command -v hugo &> /dev/null; then
    mkdir -p .temp
    # Get current system's architecture
    arch=$(dpkg --print-architecture)

    # Get the latest Hugo Extended release tag
    latest_tag=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep tag_name | cut -d '"' -f4)

    # Build the download URL for the latest extended .deb
    deb_url="https://github.com/gohugoio/hugo/releases/download/${latest_tag}/hugo_extended_${latest_tag#v}_linux-${arch}.deb"

    # Download and install
    wget -O ".temp/hugo_extended_${latest_tag#v}_linux-${arch}.deb" "$deb_url"
    sudo dpkg -i ".temp/hugo_extended_${latest_tag#v}_linux-${arch}.deb"

    # Verify installation
    hugo version
else
    echo "Hugo is already installed."
fi

# Install blowfish-tools if not already installed
if ! command -v blowfish-tools &> /dev/null; then
    npm i -g blowfish-tools
else
    echo "blowfish-tools is already installed."
fi
