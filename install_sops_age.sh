#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(dirname "$0")"


echo "
1. Installing packages: curl"

if ! command -v curl &>/dev/null; then
  apt-get update && apt-get install -y curl
fi 

# Sops variables
SOPS_VERSION="3.8.1"
SOPS_OS="linux"
SOPS_ARC="amd64"

# Age variables
AGE_VERSION="1.1.1"
AGE_OS="linux"
AGE_ARC="amd64"

echo "
2. Downlaoad sops binary and make runnable"
curl -sSfL https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.${SOPS_OS}.${SOPS_ARC} -o /usr/local/bin/sops

# Make the sops binary executable
chmod +x /usr/local/bin/sops

echo "
3. Download age binary and make runnable"
curl -sSfL https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-${AGE_OS}-${AGE_ARC}.tar.gz -o age.tar.gz

# Unzip tgz file
tar xf age.tar.gz

# Move age binaries to bin directory
mv age/age /usr/local/bin && \
mv age/age-keygen /usr/local/bin 

# Clean up
rm -rf age.tar.gz age

echo "
4. Create age encryption key,
   and extact the public key as AGE_PUB_Key"

mkdir -m 0700 -p "${HOME}/.config/sops/age/"
age-keygen > "${HOME}/.config/sops/age/keys.txt"
chmod 600 "${HOME}/.config/sops/age/keys.txt"
AGE_PUB_KEY="$(grep 'public key' "${HOME}"/.config/sops/age/keys.txt | cut -d' ' -f 4)"


# Export private key as variable
export SOPS_AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"

#echo "$SOPS_AGE_KEY_FILE" >> $HOME/.bashrc && source $HOME/.bashrc

echo "
5. Create sops config file"

cat <<EOF > "${SCRIPT_DIR}/.sops.yaml"
creation_rules:
  - path_regex: .*\.(yaml|yml|env|json|ini)$
    encrypted_regex: '(?i).*(password|passwort|key|secret).*'
    key_groups:
      - age:
          - $AGE_PUB_KEY
EOF

echo "
6. use sops to encrypt with Age:
   sops -e -i secrets.yaml
"

echo "
7. use sops to decrypt:
   sops -d -i secret.yaml
"
