#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(dirname "$0")"

# Use sudo to install curl if it's not already installed
if ! command -v curl &>/dev/null; then
  sudo apt-get update && sudo apt-get install -y curl
fi 

# Sops variables
SOPS_VERSION="3.8.1"
SOPS_OS="linux"
SOPS_ARC="amd64"

# Age variables
AGE_VERSION="1.2.0"
AGE_OS="linux"
AGE_ARC="amd64"

# Function to download and install binaries with sudo
download_and_install() {
  local url=$1
  local output=$2

  sudo curl -sSfL "$url" -o "$output"
  sudo chmod +x "$output"
}

# Download and install the sops binary
download_and_install "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.${SOPS_OS}.${SOPS_ARC}" "/usr/local/bin/sops"

# Download, unzip, and install the age binaries
curl -sSfL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-${AGE_OS}-${AGE_ARC}.tar.gz" -o age.tar.gz
tar xf age.tar.gz
sudo mv age/age /usr/local/bin
sudo mv age/age-keygen /usr/local/bin

# Clean up
rm -rf age.tar.gz age

# Create age encryption key and extract the public key as AGE_PUB_KEY (in user context)
AGE_KEY_DIR="${HOME}/.config/sops/age"
mkdir -m 0700 -p "$AGE_KEY_DIR"
age-keygen > "$AGE_KEY_DIR/keys.txt"
chmod 600 "$AGE_KEY_DIR/keys.txt"
AGE_PUB_KEY="$(grep 'public key:' "$AGE_KEY_DIR/keys.txt" | cut -d' ' -f 4)"

# Export environment variables for SOPS (in user context)
AGE_SECRET_KEY="$AGE_KEY_DIR/keys.txt"
echo "export AGE_PUB_KEY=${AGE_PUB_KEY}" >> "$HOME/.bashrc"
echo "export AGE_SECRET_KEY=${AGE_SECRET_KEY}" >> "$HOME/.bashrc"
echo "export SOPS_AGE_KEY_FILE=${AGE_SECRET_KEY}" >> "$HOME/.bashrc"
source "$HOME/.bashrc"

# Create sops rules and add the public key (in user context)
cat <<EOF > "${SCRIPT_DIR}/.sops.yaml"
creation_rules:
  - path_regex: .*\.(yaml|yml|env|json|ini)$
    encrypted_regex: '(?i).*(id|token|ca|crt|password|passwort|key|secret).*'
    key_groups:
      - age:
          - $AGE_PUB_KEY
EOF