#!/bin/bash

# Parse possible arguments
while getopts "tp:" arg; do
  case $arg in
    t) TESTING=true;;
    p) FILE_PREFIX=$OPTARG;;
  esac
done

# Check for operating system
if [ -z "$FILE_PREFIX" ]; then
  case $( uname -s ) in
  Linux)

    case $( uname -i ) in
    x86_64)
      FILE_PREFIX="linux-amd64"
      ;;
    arm64)
      FILE_PREFIX="linux-arm64"
      ;;
    esac

  ;;
  Darwin)
    FILE_PREFIX="darwin-arm64"
    ;;
  esac
fi

# If prefix is still empty, exit 1
if [ -z "$FILE_PREFIX" ]; then
  echo "File prefix couldn't be automatically determined. Set manually."
  echo "Usage: $0 -p [linux-amd64|darwin-arm64|linux-arm64]"
  exit 1
fi

if ! [ "$(which jq)" ]; then
  echo "jq is not installed (sudo apt-get install jq)"
  exit 1
fi

# Repo to download
GITHUB_OWNER="UnownHash"
GITHUB_REPO="Dragonite-Public"

# Fetch the latest tags from the local Git repository
git fetch --tags

# Do we want the testing version?
if [ "$TESTING" = "true" ]; then
  # Get the latest Testing Git tag for the "dragonite-" prefix
  latest_dragonite_tag=$(git tag --list 'dragonite-v*' | sort -V | tail -n 1)
  # Get the latest Testing Git tag for the "admin-" prefix
  latest_admin_tag=$(git tag --list 'admin-v*' | sort -V | tail -n 1)
else
  # Get the latest Production Git tag for the "dragonite-" prefix
  latest_dragonite_tag=$(git tag --list 'dragonite-v*' | grep -v '\-testing' | sort -V | tail -n 1)
  # Get the latest Production Git tag for the "admin-" prefix
  latest_admin_tag=$(git tag --list 'admin-v*' | grep -v '\-testing' | sort -V | tail -n 1)
fi

download_latest_release() {
  local application="$1"
  local FILE_NAME="$application-$FILE_PREFIX"

  # Set the correct variable based on the prefix
  if [ "$application" == "dragonite" ]; then
    local latest_tag_var="$latest_dragonite_tag"
  elif [ "$application" == "admin" ]; then
    local latest_tag_var="$latest_admin_tag"
  else
    echo "Invalid prefix: $prefix"
    exit 1
  fi

  # Get the list of releases using the GitHub API
  local api_url="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/releases/tags/$latest_tag_var"
  local releases_info=$(curl -sf "$api_url")

  if [ -z "$releases_info" ]; then
    echo "Failed to download $application release information"
    exit 1
  fi

  # Extract the download URL for the specific file in the latest release
  local download_url=$(echo "$releases_info" | jq -r ".assets[] | select(.name == \"$FILE_NAME\").url")

  # Define the download file name based on the selected file
  local download_filename="$FILE_NAME"

  # Download the specific release file
  echo "Downloading $download_filename $latest_tag_var ... waiting ..."
  curl -sL -H "Accept: application/octet-stream" -o "$application/${download_filename}_new" "$download_url"

  # Check if the download was successful
  if [ $? -ne 0 ]; then
    echo "Failed to download the release file"
    exit 1
  fi
  if [ -f "$application/$download_filename" ]; then
    # Delete the old download
    rm -f "$application/${download_filename}"
  fi
  
  # Rename the new file without "_new" suffix
  mv "$application/${download_filename}_new" "$application/$download_filename"

  echo "Downloaded $download_filename $latest_tag_var"
  chmod +x "$application/$download_filename"
}

download_latest_release "dragonite"
download_latest_release "admin"
