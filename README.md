# Using Mozilla SOPS and Age

## SOPS Commands

### Encrypting Files

> Before using SOPS, you need to create the SOPS configuration file `.sops.yaml` in your directory. This file defines the encryption rules for SOPS.

To encrypt a file and display the encrypted content in the terminal:

```sh
sops --encrypt values.yaml
```

To encrypt a file and save the encrypted content to a new file:

```sh
sops --encrypt values.yaml > encrypted-values.yaml
```

### Decrypting Files

To decrypt a file and save the decrypted content to a new file:

```sh
sops --decrypt encrypted-values.yaml > decrypted-values.yaml
```

## Age Commands

### Encrypting with Age

To encrypt a string and save it to a file using the public key:

```sh
echo "supersicher" | age -r $AGE_PUB_KEY --armor > prod.env
```

### Decrypting with Age

To decrypt a file using the secret key and save the output to a new file:

```sh
age -d -i $AGE_SECRET_KEY prod.env > prod-decrypted.env
```

### Encrypting with a Passphrase

To encrypt a string and secure it with a passphrase:

```sh
echo "supersicher" | age -p > dev.env
```

### Decrypting a Passphrase-Protected File

To decrypt a passphrase-protected file:

```sh
age -d dev.env > dev-decrypted.env
```