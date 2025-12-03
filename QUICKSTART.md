# 🚀 Quick Guide - Hyperlane Validator & Relayer

## ⚡ Quick Start in 5 Steps

### 📋 Prerequisites

- Docker & Docker Compose installed
- AWS account with:
  - **S3 bucket** (required for validator signatures)
  - **KMS keys** (optional, for EVM/Sealevel chains: BSC, Ethereum, Solana)
- Private key for Terra Classic (hexadecimal) - **Required for Cosmos chains**
- **AWS CLI installed** (required for AWS commands)

#### Install AWS CLI v2 (Required)

**⚠️ IMPORTANT:** We only support AWS CLI v2. Do not install using apt, pip, or snap to avoid conflicts!

```bash
# Download and install AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli

# Verify installation
aws --version
# Should show: aws-cli/2.x.x
```

**Configure AWS CLI (if not already configured):**
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region: us-east-1
# Enter default output format: json
```

**⚠️ If you get "KeyError: 'opsworkscm'" or version conflict errors:**

This means you have conflicting AWS CLI installations. Run these commands to fix:

```bash
# PASSO 1: Remover completamente a versão antiga do /usr/bin
sudo rm -f /usr/bin/aws
sudo rm -f /usr/bin/aws_completer

# PASSO 2: Remover instalações antigas
sudo apt remove awscli -y
sudo apt purge awscli -y
pip3 uninstall awscli -y 2>/dev/null

# PASSO 3: Limpar arquivos restantes
sudo rm -rf /usr/local/aws-cli
rm -rf ~/.local/lib/python3.*/site-packages/awscli* 2>/dev/null
rm -rf ~/.local/lib/python3.*/site-packages/botocore* 2>/dev/null

# PASSO 4: Reinstalar AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli

# PASSO 5: Garantir que /usr/local/bin está no PATH antes de /usr/bin
echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# PASSO 6: Verificar qual versão está sendo usada
which aws
# Deve mostrar: /usr/local/bin/aws

# PASSO 7: Testar
aws --version
```

**See Troubleshooting section for more details if issues persist.**

---

## 🔧 STEP 1: Configure AWS Credentials

**Required for:**
- ✅ S3 bucket (validator signatures) - **Always required**
- ✅ KMS keys (EVM/Sealevel chains) - **If using BSC, Ethereum, or Solana**

### 1.1 Create .env File

```bash
# 1. Copy template
cp .env.example .env

# 2. Edit with your AWS credentials
nano .env
```

### 1.2 Fill in Your AWS Credentials

**⚠️ IMPORTANT:** Replace the placeholder values with your **actual AWS credentials** from your IAM user.

**`.env` file structure (example - replace with your values):**
```bash
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

**What to fill:**
- `AWS_ACCESS_KEY_ID`: Your IAM user's Access Key ID (starts with `AKIA...`)
- `AWS_SECRET_ACCESS_KEY`: Your IAM user's Secret Access Key (long random string)
- `AWS_REGION`: AWS region (usually `us-east-1`)

**⚠️ SECURITY WARNING:**
- Never commit `.env` file to Git (already in `.gitignore`)
- Never share your AWS credentials
- These are **sensitive credentials** - keep them secure!

**Example of what your `.env` should look like (with your real values):**
```bash
# Replace these with YOUR actual AWS credentials from your IAM user
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

**⚠️ Remember:** Use your **own** AWS credentials, not the examples above!

**Protect the file:**
```bash
chmod 600 .env
```

**See `SETUP-AWS-KMS.md` for complete AWS setup guide:**
- Create IAM user
- Create S3 bucket
- Create KMS keys (for BSC/Ethereum/Solana)

---

## 🔑 STEP 2: Configure Keys

### ⚠️ **IMPORTANT: Key Management by Blockchain Type**

| Blockchain Type | Key Management | Supported? |
|----------------|----------------|------------|
| **Cosmos** (Terra Classic) | `hexKey` (local) | ✅ Required |
| **EVM** (BSC, Ethereum, Polygon, etc.) | AWS KMS | ✅ Supported |
| **Sealevel** (Solana) | AWS KMS | ✅ Supported |

**Terra Classic does NOT support AWS KMS** - You must use **local private keys (hexKey)**.

### For Terra Classic: Generate/Use hexKey via terrad CLI

Terra Classic requires a local hexadecimal private key. Use the `terrad` CLI (Terra daemon) to generate or import keys.

#### Install terrad CLI

**Option 1: Download Binary (Recommended)**

```bash
# Download latest terrad binary
TERRA_VERSION="v3.0.1"  # Check latest version at: https://github.com/classic-terra/core/releases
wget https://github.com/classic-terra/core/releases/download/${TERRA_VERSION}/terrad-${TERRA_VERSION}-linux-amd64
chmod +x terrad-${TERRA_VERSION}-linux-amd64
sudo mv terrad-${TERRA_VERSION}-linux-amd64 /usr/local/bin/terrad

# Verify installation
terrad version
```

**Option 2: Build from Source**

```bash
# Clone repository
git clone https://github.com/classic-terra/core.git
cd core
git checkout v3.0.1
make install

# Verify installation
terrad version
```

---

#### Option A: Generate New Private Key (New Wallet)

**Step 1: Generate New Key with terrad**

```bash
# Generate new key (you'll be prompted for a password)
terrad keys add validator-key --keyring-backend file

# Or without password prompt (less secure, for testing only)
terrad keys add validator-key --keyring-backend file --no-backup
```

**Example output:**
```
- name: validator-key
  type: local
  address: terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"AqBcDeFgHiJkLmNoPqRsTuVwXyZaBcDeFgHiJkLmNoPqRsTuVwXyZa"}'
  mnemonic: ""

**Important write this mnemonic phrase in a safe place.**
It is the only way to recover your account if you ever forget your password.

word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12
word13 word14 word15 word16 word17 word18 word19 word20 word21 word22 word23 word24
```

**⚠️ IMPORTANT:** 
- **Save the mnemonic phrase immediately** - you'll need it to recover your key!
- Store it securely (password manager, encrypted file, etc.)
- Never share or commit this mnemonic to Git

**Step 2: Export Private Key in Hexadecimal Format**

```bash
# Export private key as hex (you'll need the keyring password)
terrad keys export validator-key --keyring-backend file --unarmored-hex --unsafe

# Or save to file
terrad keys export validator-key --keyring-backend file --unarmored-hex --unsafe > ~/.terra-private-key-hex
chmod 600 ~/.terra-private-key-hex
```

**Example output:**
```
abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
```

**Note:** Add `0x` prefix when using in configuration files:
```bash
# Add 0x prefix
echo "0x$(cat ~/.terra-private-key-hex)" > ~/.terra-private-key
```

**Step 3: Get Your Terra Classic Address**

```bash
# Show address
terrad keys show validator-key --keyring-backend file --address
```

**Example output:**
```
terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
```

**Or get full key information:**
```bash
terrad keys show validator-key --keyring-backend file
```

**Step 4: Fund Your Wallet**

Send LUNC to the Terra address shown above (e.g., `terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7`).

---

#### Option B: Import Existing Private Key (Existing Wallet)

If you already have a Terra Classic private key (hexadecimal format) or mnemonic phrase, you can import it.

**Method 1: Import from Hexadecimal Private Key**

```bash
# Import from hex key (you'll be prompted for a password)
echo "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890" | terrad keys import validator-key --keyring-backend file

# Or from file
cat ~/.terra-private-key | terrad keys import validator-key --keyring-backend file
```

**Method 2: Import from Mnemonic Phrase**

```bash
# Import from mnemonic (you'll be prompted for the phrase)
terrad keys add validator-key --recover --keyring-backend file
```

**Example:**
```
> Enter your bip39 mnemonic
word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20 word21 word22 word23 word24

- name: validator-key
  type: local
  address: terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"AqBcDeFgHiJkLmNoPqRsTuVwXyZaBcDeFgHiJkLmNoPqRsTuVwXyZa"}'
```

**Step 2: Export Private Key in Hex Format (if needed for config)**

```bash
# Export as hex for use in configuration files
terrad keys export validator-key --keyring-backend file --unarmored-hex --unsafe

# Save to file with 0x prefix
echo "0x$(terrad keys export validator-key --keyring-backend file --unarmored-hex --unsafe)" > ~/.terra-private-key
chmod 600 ~/.terra-private-key
```

**Step 3: Verify Your Wallet**

```bash
# Show address
terrad keys show validator-key --keyring-backend file --address

# Check balance
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7"
```

**Step 4: Use the Private Key in Configuration**

You'll use the hexadecimal private key (with `0x` prefix) in:
- `validator.terraclassic.json` (validator configuration)
- `relayer.json` (relayer configuration for Terra Classic)

**⚠️ Security Reminder:**
- Never share your private key or mnemonic
- Never commit it to Git
- Store it securely
- Use file permissions `600` for config files

---

#### Alternative: Get Address from Hex Key (Without terrad)

If you only have the hexadecimal private key and want to get the Terra address without using terrad:

```bash
# Install dependencies
pip3 install eth-account bech32

# Get addresses from hex key
./get-address-from-hexkey.py 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
```

**Example output:**
```
Ethereum: 0x1234567890123456789012345678901234567890
Terra:    terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
```

### For EVM Chains (BSC, Ethereum): AWS KMS

**⚠️ Prerequisite:** Make sure AWS CLI is installed (see Prerequisites section above)

**See `SETUP-AWS-KMS.md` for complete setup guide.**

#### Quick Setup:

1. **Create KMS Key** (via AWS Console or CLI):
   ```bash
   # For BSC
   # Make sure AWS CLI is installed first!
   aws kms create-key \
     --key-spec ECC_SECG_P256K1 \
     --key-usage SIGN_VERIFY \
     --region us-east-1
   
   # Create alias
   aws kms create-alias \
     --alias-name alias/hyperlane-relayer-signer-bsc \
     --target-key-id <KEY-ID> \
     --region us-east-1
   ```

2. **Discover Address:**
   ```bash
   # Get BSC address
   cast wallet address --aws alias/hyperlane-relayer-signer-bsc
   
   # Or use script
   ./get-kms-addresses.sh
   ```

**Example output:**
```
BSC Address: 0x1234567890123456789012345678901234567890
```

#### For Ethereum (Same Process):

```bash
# Create KMS key for Ethereum
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1

# Create alias
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-ethereum \
  --target-key-id <KEY-ID> \
  --region us-east-1

# Get address
cast wallet address --aws alias/hyperlane-relayer-signer-ethereum
```

### For Solana: AWS KMS

**⚠️ Prerequisite:** Make sure AWS CLI is installed (see Prerequisites section above)

**Solana supports AWS KMS!** Same process as EVM chains.

#### Quick Setup:

1. **Create KMS Key:**
   ```bash
   # Make sure AWS CLI is installed first!
   aws kms create-key \
     --key-spec ECC_SECG_P256K1 \
     --key-usage SIGN_VERIFY \
     --region us-east-1
   
   # Create alias
   aws kms create-alias \
     --alias-name alias/hyperlane-relayer-signer-solana \
     --target-key-id <KEY-ID> \
     --region us-east-1
   ```

2. **Discover Address:**
   ```bash
   # Solana address will be shown in relayer logs after startup
   # Or use AWS KMS API to get public key
   aws kms get-public-key \
     --key-id alias/hyperlane-relayer-signer-solana \
     --region us-east-1
   ```

---

## 📝 STEP 3: Configure Files

### 3.1 Validator (Terra Classic)

```bash
# Copy template
cp hyperlane/validator.terraclassic.json.example hyperlane/validator.terraclassic.json

# Edit
nano hyperlane/validator.terraclassic.json
```

**Replace:**
- `YOUR-BUCKET-NAME` → Your S3 bucket name
- `0xYOUR_PRIVATE_KEY_HERE` → Your private key (both places)

**Example:**
```json
{
  "db": "/etc/data/db",
  "checkpointSyncer": {
    "type": "s3",
    "bucket": "hyperlane-validator-signatures-my-bucket",
    "region": "us-east-1"
  },
  "originChainName": "terraclassic",
  "validator": {
    "type": "hexKey",
    "key": "0xe45624f7aca7eb9e...."
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xe45624f7aca7eb9e....",
        "prefix": "terra"
      }
    }
  }
}
```

**Protect file:**
```bash
chmod 600 hyperlane/validator.terraclassic.json
```

### 3.2 Relayer (Optional)

If running the relayer:

```bash
# Copy template
cp hyperlane/relayer.json.example hyperlane/relayer.json

# Edit
nano hyperlane/relayer.json
```

#### Example 1: Terra Classic + BSC (Default)

```json
{
  "db": "/etc/data/db",
  "relayChains": "terraclassic,bsc",
  "allowLocalCheckpointSyncers": "false",
  "gasPaymentEnforcement": [{ "type": "none" }],
  "whitelist": [
    {
      "originDomain": [1325],
      "destinationDomain": [56]
    },
    {
      "originDomain": [56],
      "destinationDomain": [1325]
    }
  ],
  "chains": {
    "bsc": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-bsc",
        "region": "us-east-1"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xYOUR_PRIVATE_KEY_HERE",
        "prefix": "terra"
      }
    }
  }
}
```

#### Example 2: Terra Classic + Ethereum

```json
{
  "db": "/etc/data/db",
  "relayChains": "terraclassic,ethereum",
  "allowLocalCheckpointSyncers": "false",
  "gasPaymentEnforcement": [{ "type": "none" }],
  "whitelist": [
    {
      "originDomain": [1325],
      "destinationDomain": [1]
    },
    {
      "originDomain": [1],
      "destinationDomain": [1325]
    }
  ],
  "chains": {
    "ethereum": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-ethereum",
        "region": "us-east-1"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xYOUR_PRIVATE_KEY_HERE",
        "prefix": "terra"
      }
    }
  }
}
```

#### Example 3: Terra Classic + Solana

```json
{
  "db": "/etc/data/db",
  "relayChains": "terraclassic,solanatestnet",
  "allowLocalCheckpointSyncers": "false",
  "gasPaymentEnforcement": [{ "type": "none" }],
  "whitelist": [
    {
      "originDomain": [1325],
      "destinationDomain": [1399811150]
    },
    {
      "originDomain": [1399811150],
      "destinationDomain": [1325]
    }
  ],
  "chains": {
    "solanatestnet": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-solana",
        "region": "us-east-1"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xYOUR_PRIVATE_KEY_HERE",
        "prefix": "terra"
      }
    }
  }
}
```

#### Example 4: Multiple Chains (Terra + BSC + Ethereum + Solana)

```json
{
  "db": "/etc/data/db",
  "relayChains": "terraclassic,bsc,ethereum,solanatestnet",
  "allowLocalCheckpointSyncers": "false",
  "gasPaymentEnforcement": [{ "type": "none" }],
  "whitelist": [
    // Terra ↔ BSC
    {"originDomain": [1325], "destinationDomain": [56]},
    {"originDomain": [56], "destinationDomain": [1325]},
    // Terra ↔ Ethereum
    {"originDomain": [1325], "destinationDomain": [1]},
    {"originDomain": [1], "destinationDomain": [1325]},
    // Terra ↔ Solana
    {"originDomain": [1325], "destinationDomain": [1399811150]},
    {"originDomain": [1399811150], "destinationDomain": [1325]}
  ],
  "chains": {
    "bsc": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-bsc",
        "region": "us-east-1"
      }
    },
    "ethereum": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-ethereum",
        "region": "us-east-1"
      }
    },
    "solanatestnet": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-solana",
        "region": "us-east-1"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xYOUR_PRIVATE_KEY_HERE",
        "prefix": "terra"
      }
    }
  }
}
```

**Replace:**
- For **Terra Classic**: `0xYOUR_PRIVATE_KEY_HERE` → Your private key
- For **BSC/Ethereum/Solana**: Use AWS KMS aliases (create keys first via `SETUP-AWS-KMS.md`)

**Protect file:**
```bash
chmod 600 hyperlane/relayer.json
```

---

## 💰 STEP 4: Fund Wallets

### Validator/Relayer Terra Classic

```bash
# Send LUNC to Terra address
# Address: (obtained in Step 2)
# Amount: 100-500 LUNC

# Check balance
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/YOUR_TERRA_ADDRESS"
```

**Or view in explorer:**
```
https://finder.terraclassic.community/mainnet/address/YOUR_TERRA_ADDRESS
```

### BSC Relayer (AWS KMS)

If you configured KMS for BSC:

```bash
# Discover address
cast wallet address --aws alias/hyperlane-relayer-signer-bsc

# Send 0.1-0.5 BNB to this address
# Check balance
cast balance 0xYOUR_BSC_ADDRESS --rpc-url https://bsc.drpc.org
```

**Explorer:**
```
https://bscscan.com/address/YOUR_BSC_ADDRESS
```

### Ethereum Relayer (AWS KMS)

If you configured KMS for Ethereum:

```bash
# Discover address
cast wallet address --aws alias/hyperlane-relayer-signer-ethereum

# Send 0.5-1 ETH to this address
# Check balance
cast balance 0xYOUR_ETH_ADDRESS --rpc-url https://eth.llamarpc.com
```

**Explorer:**
```
https://etherscan.io/address/YOUR_ETH_ADDRESS
```

**Recommended amounts:**
- **Mainnet**: 0.5-1 ETH (gas can be expensive)
- **Testnet**: 0.1-0.5 ETH (for testing)

### Solana Relayer (AWS KMS)

If you configured KMS for Solana:

```bash
# Address will be shown in relayer logs after startup
# Or get from KMS public key
aws kms get-public-key \
  --key-id alias/hyperlane-relayer-signer-solana \
  --region us-east-1
```

**Send SOL:**
- **Testnet**: 1-5 SOL
- **Mainnet**: 1-5 SOL (depending on volume)

**Check balance:**
```bash
# Via Solana CLI (if installed)
solana balance YOUR_SOLANA_ADDRESS --url https://api.testnet.solana.com
```

**Explorer:**
```
https://explorer.solana.com/address/YOUR_SOLANA_ADDRESS?cluster=testnet
```

### Funding Summary

| Chain | Key Type | Recommended Amount | Currency |
|-------|----------|-------------------|----------|
| Terra Classic | hexKey | 100-500 | LUNC |
| BSC | AWS KMS | 0.1-0.5 | BNB |
| Ethereum | AWS KMS | 0.5-1 | ETH |
| Solana | AWS KMS | 1-5 | SOL |

---

## 🐳 STEP 5: Run Docker

### 5.1 Start Validator

```bash
# Start validator only
docker-compose up -d validator-terraclassic

# View logs in real-time
docker logs -f hpl-validator-terraclassic
```

**Wait for message:**
```
✅ Successfully announced validator
```

**Stop logs:** `Ctrl+C`

### 5.2 Start Relayer (Optional)

Only if you configured relayer for BSC, Ethereum, Solana, or other chains:

```bash
# Start relayer
docker-compose up -d relayer

# View logs
docker logs -f hpl-relayer
```

**Wait for messages:**
```
✅ Connected to chains
✅ Processing messages
```

### 5.3 Useful Docker Commands

```bash
# View running containers
docker ps

# Stop validator
docker-compose stop validator-terraclassic

# Stop all
docker-compose down

# Restart validator
docker-compose restart validator-terraclassic

# View last 100 log lines
docker logs hpl-validator-terraclassic --tail 100

# Clean and restart (if needed)
docker-compose down
docker-compose up -d validator-terraclassic
```

---

## ✅ Verify It's Working

### Validator

```bash
# 1. View logs
docker logs hpl-validator-terraclassic --tail 50

# Look for:
# ✅ "Successfully announced validator"
# ✅ "Validator has announced signature storage location"

# 2. Check checkpoints on S3 (when there are Hyperlane messages)
aws s3 ls s3://YOUR-BUCKET/us-east-1/ --recursive

# 3. Check validator API
curl http://localhost:9121/metrics
```

### Relayer (if running)

```bash
# View logs
docker logs hpl-relayer --tail 50

# Check API
curl http://localhost:9110/metrics
```

---

## 🚨 Troubleshooting

### Error: "docker-compose command not found" or "Cannot connect to Docker daemon" (WSL 2)

**Cause:** Docker is not properly configured in WSL 2, or Docker Desktop is not running.

**Solution for WSL 2:**

**Option 1: Enable WSL Integration in Docker Desktop (Recommended)**

1. Open **Docker Desktop** on Windows
2. Go to **Settings** → **Resources** → **WSL Integration**
3. Enable **"Enable integration with my default WSL distro"**
4. Enable integration for your specific WSL distro (e.g., "Ubuntu")
5. Click **"Apply & Restart"**
6. Wait for Docker Desktop to restart

**Option 2: Install Docker in WSL 2 (Alternative)**

If you don't have Docker Desktop, install Docker directly in WSL 2:

```bash
# Update package index
sudo apt update

# Install Docker
sudo apt install docker.io docker-compose -y

# Start Docker service
sudo service docker start

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Log out and log back in, or run:
newgrp docker

# Verify Docker is working
docker --version
docker-compose --version

# Test Docker
docker ps
```

**Verify Docker is working:**
```bash
# Check if Docker daemon is running
docker ps

# If you see an empty list (no errors), Docker is working!
# If you see an error, try:
sudo service docker start
```

**If using Docker Desktop with WSL 2:**
```bash
# Make sure Docker Desktop is running on Windows
# Then verify connection from WSL:
docker ps

# Should work without sudo if WSL integration is enabled
```

**Common Issues:**

1. **Docker Desktop not running:** Start Docker Desktop on Windows
2. **WSL integration disabled:** Enable it in Docker Desktop settings
3. **Wrong WSL distro:** Make sure your distro is enabled in Docker Desktop WSL settings
4. **Need to restart WSL:** Close and reopen your WSL terminal

**Test the fix:**
```bash
docker --version
docker-compose --version
docker ps
```

### Error: "Cannot announce validator without a signer"

**Cause:** Wallet has no LUNC funds

**Solution:**
```bash
# 1. Get address
./get-address-from-hexkey.py 0xYOUR_KEY

# 2. Send LUNC to Terra address

# 3. Restart
docker-compose restart validator-terraclassic
```

### Error: "Expected key `key` to be defined"

**Cause:** Trying to use AWS KMS for Terra Classic (not supported)

**Solution:** Use `hexKey` for Terra Classic. AWS KMS only works for EVM chains (BSC, Ethereum) and Sealevel chains (Solana).

### Error: "Chain not configured" (Relayer)

**Cause:** Chain in `relayChains` but no signer configured in `chains`

**Solution:** Add signer configuration for each chain:
- **EVM chains** (BSC, Ethereum): Use AWS KMS
- **Sealevel chains** (Solana): Use AWS KMS
- **Cosmos chains** (Terra Classic): Use hexKey

### Error: "Route not whitelisted" (Relayer)

**Cause:** Message route not included in `whitelist`

**Solution:** Add bidirectional routes to `whitelist`:
```json
{
  "originDomain": [1325],      // Terra Classic
  "destinationDomain": [1]      // Ethereum
},
{
  "originDomain": [1],           // Ethereum
  "destinationDomain": [1325]    // Terra Classic
}
```

### Error: "Insufficient funds" (EVM/Solana)

**Cause:** KMS wallet has no funds for gas

**Solution:**
```bash
# Check balance
# BSC:
cast balance 0xADDRESS --rpc-url https://bsc.drpc.org

# Ethereum:
cast balance 0xADDRESS --rpc-url https://eth.llamarpc.com

# Solana:
solana balance ADDRESS --url https://api.testnet.solana.com

# Send funds and restart
docker-compose restart relayer
```

### Error: "Command 'aws' not found"

**Cause:** AWS CLI v2 is not installed on your system.

**Solution:**
```bash
# Install AWS CLI v2 (see Prerequisites section)
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli

# Verify installation
aws --version

# Configure AWS CLI
aws configure
```

**See Prerequisites section for detailed installation instructions.**

### Error: "KeyError: 'opsworkscm'" or AWS CLI version conflict

**Cause:** Multiple AWS CLI installations conflicting. The system is using the old `/usr/bin/aws` instead of AWS CLI v2.

**Solution - Complete Cleanup and Reinstall:**

```bash
# PASSO 1: Remover completamente a versão antiga do /usr/bin
sudo rm -f /usr/bin/aws
sudo rm -f /usr/bin/aws_completer

# PASSO 2: Remover instalações antigas
sudo apt remove awscli -y
sudo apt purge awscli -y
pip3 uninstall awscli -y 2>/dev/null

# PASSO 3: Limpar arquivos restantes
sudo rm -rf /usr/local/aws-cli
rm -rf ~/.local/lib/python3.*/site-packages/awscli* 2>/dev/null
rm -rf ~/.local/lib/python3.*/site-packages/botocore* 2>/dev/null

# PASSO 4: Reinstalar AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli

# PASSO 5: Garantir que /usr/local/bin está no PATH antes de /usr/bin
echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# PASSO 6: Verificar qual versão está sendo usada
which aws
# Deve mostrar: /usr/local/bin/aws

# PASSO 7: Testar
aws --version
```

**If still having issues:**
```bash
# Check which aws is being used
which aws

# Check all aws locations
whereis aws

# If /usr/bin/aws still exists, remove it
sudo rm -f /usr/bin/aws

# Verify
which aws
aws --version
```

**⚠️ Important:** 
- Always use AWS CLI v2 only (no apt, pip, or snap installations)
- `/usr/local/bin/aws` (v2) should take priority over `/usr/bin/aws` (old)
- Check `which aws` to verify the correct version is being used

### Error: "Permission denied" when reading files

**Solution:**
```bash
# Fix permissions
chmod 600 hyperlane/validator.terraclassic.json
chmod 600 hyperlane/relayer.json
```

### Container won't start

```bash
# View complete logs
docker logs hpl-validator-terraclassic

# Restart from scratch
docker-compose down
docker rm -f hpl-validator-terraclassic
docker-compose up -d validator-terraclassic
```

### Rate limit (429 Too Many Requests)

**Cause:** Public RPCs have request limits

**Solution:** Wait a few seconds. Validator uses multiple RPCs as fallback.

---

## 📊 Monitoring

### Check Status

```bash
# Running containers
docker ps

# Resource usage
docker stats

# Real-time logs
docker logs -f hpl-validator-terraclassic
```

### Check Wallet Balance

```bash
# Via curl
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/YOUR_TERRA_ADDRESS" | jq

# Via explorer
# https://finder.terraclassic.community/mainnet/address/YOUR_TERRA_ADDRESS
```

### Low Balance Alerts

Create script to monitor:

```bash
#!/bin/bash
TERRA_ADDR="terra1..."
MIN_BALANCE=10000000  # 10 LUNC in uluna

BALANCE=$(curl -s "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/$TERRA_ADDR" | jq -r '.balances[] | select(.denom=="uluna") | .amount')

if [ "$BALANCE" -lt "$MIN_BALANCE" ]; then
  echo "⚠️ Low balance! $((BALANCE/1000000)) LUNC"
  # Send notification
fi
```

---

## 🔐 Security

### ⚠️ IMPORTANT

1. **Never commit** files with private keys to Git
   - ✅ Already in `.gitignore`

2. **Backup** keys in a secure location
   - See: `SECURITY-HEXKEY.md` for complete guide

3. **Restricted permissions** on files:
   ```bash
   chmod 600 hyperlane/validator.terraclassic.json
   chmod 600 hyperlane/relayer.json
   ```

4. **Key rotation**: Consider changing every 3-6 months

---

## 📚 Complete Documentation

For more details:

- **`SECURITY-HEXKEY.md`** - Security and key backup
- **`SETUP-AWS-KMS.md`** - Configure AWS KMS for EVM/Sealevel chains (BSC, Ethereum, Solana)
- **`RELAYER-CONFIG-GUIDE.md`** - Complete relayer configuration guide with examples
- **`DOCKER-VOLUMES-EXPLAINED.md`** - Understand Docker volumes
- **`README.md`** - Complete overview

---

## 🆘 Need Help?

1. Check logs: `docker logs hpl-validator-terraclassic`
2. Consult `SECURITY-HEXKEY.md` for security questions
3. Check Hyperlane GitHub issues

---

## ✅ Checklist

### Validator Setup
- [ ] AWS credentials configured (`.env`) - **For S3 bucket only**
- [ ] Private key generated or obtained (Terra Classic)
- [ ] Addresses discovered (ETH + Terra)
- [ ] Files configured (`validator.terraclassic.json`)
- [ ] Correct permissions (600)
- [ ] Wallet funded with LUNC
- [ ] Validator running (`docker ps`)
- [ ] Announcement successful (logs)
- [ ] Key backup completed

### Relayer Setup (Optional)
- [ ] AWS KMS keys created (BSC/Ethereum/Solana)
- [ ] KMS addresses discovered
- [ ] Relayer configuration (`relayer.json`) set up
- [ ] Whitelist configured for desired routes
- [ ] Wallets funded:
  - [ ] Terra Classic (LUNC)
  - [ ] BSC (BNB) - if using
  - [ ] Ethereum (ETH) - if using
  - [ ] Solana (SOL) - if using
- [ ] Relayer running (`docker ps`)
- [ ] Messages being processed (logs)

---

## 📚 Additional Resources

### AWS KMS Setup
- **Complete guide**: `SETUP-AWS-KMS.md`
- **Step-by-step**: Create IAM user, S3 bucket, KMS keys

### Relayer Configuration
- **Complete guide**: `RELAYER-CONFIG-GUIDE.md`
- **Examples**: Multiple chain configurations, whitelist setup

### Security
- **Key security**: `SECURITY-HEXKEY.md`
- **Backup procedures**: Complete backup guide

---

**🎉 Ready! Your validator is running!**

To run the relayer, follow the same steps but start with:
```bash
docker-compose up -d relayer
```

**Supported Chains:**
- ✅ **Terra Classic** (Cosmos) - hexKey required
- ✅ **BSC** (EVM) - AWS KMS supported
- ✅ **Ethereum** (EVM) - AWS KMS supported
- ✅ **Solana** (Sealevel) - AWS KMS supported
- ✅ **Other EVM chains** (Polygon, Avalanche, etc.) - AWS KMS supported
