#!/usr/bin/env bash


set -eou pipefail

SCRIPT_DIR="$(dirname "$0")"

sudo apt-get install -y git golang
echo 'export GOPATH=~/go' >> ~/.bashrc
source ~/.bashrc
mkdir $GOPATH

mkdir -p $GOPATH/src/github.com/getsops/sops/
git clone https://github.com/getsops/sops.git $GOPATH/src/github.com/getsops/sops/
cd $GOPATH/src/github.com/getsops/sops/
make install



# create key
create_key() {
  export GPG_NAME="my-key"
  export GPG_COMMENT="sops secrets"
  export GPG_EMAIL="MYEMAIL@example.com"

 gpg --batch --full-generate-key <<EOF
 %no-protection
 Key-Type: 1
 Key-Length: 4096
 Subkey-Type: 1
 Subkey-Length: 4096
 Expire-Date: 0
 Name-Real: ${GPG_NAME}
 Name-Comment: ${GPG_COMMENT}
 Name-Email: ${GPG_EMAIL}
EOF

# Check if key corretly created
gpg --list-secret-keys --keyid-format LONG

GPG_ID="$(gpg --with-colons --fingerprint | awk -F: '$1 == "fpr" {print $10}' | awk 'NR==1')"

}
# Export keys
echo "Do you want to export keys to ~/.ssh/? [y/n]:"
read -r answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [[ $answer == y || $answer == j ]]; then
    if [[ ! -f ~/.ssh/gpg_public.key || ! -f ~/.ssh/gpg_private.key ]]; then
        gpg --export -a "$GPG_ID" > ~/.ssh/gpg_public.key && \
        gpg --export-secret-key -a "$GPG_ID" > ~/.ssh/gpg_private.key
    else
	echo "Keys allready exists, do you want to overwirte them? [y/n]:"
	read -r overwrite_answer
	overwrite_answer=$(echo "$overwrite_answer" | tr '[:upper:]' '[:lower:]')
	if [[ "$overwrite_answer" == "y" || "$overwrite_answer" == "j" ]]; then
	    echo "Overwriting keys..."
            gpg --export -a "$GPG_ID" > ~/.ssh/gpg_public.key && \
            gpg --export-secret-key -a "$GPG_ID" > ~/.ssh/gpg_private.key
	fi
     
    fi
fi 


# Checking if keys are imported
echo "Checking if keys are imported..."

if gpg --list-keys "$GPG_ID" > /dev/null 2>&1 && \
   gpg --list-secret-keys "$GPG_ID" > /dev/null 2>&1; then
   echo "Keys are successfuly imported."
else
   echo "Keys are not found or not imported correctly."  
   # Import keys
   gpg --import ~/.ssh/gpg_public.key
   echo -e "\n"
   gpg --import ~/.ssh/gpg_private.key 
fi



# Create sops rules and add master key fingerprint
cat <<EOF > "${SCRIPT_DIR}/.sops.yaml"
creation_rules:
  - path_regex: .*\.(yaml|yml|.env|json)$
    encrypted_regex: '.*(password|passwort|key|secret).*'
    pgp: "$GPG_ID"
EOF

