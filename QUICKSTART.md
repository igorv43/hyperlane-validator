# 🚀 Quick Guide - Hyperlane Validator & Relayer

## ⚡ Quick Start in 5 Steps

### 📋 Prerequisites

- Docker & Docker Compose installed
- AWS account with KMS and S3 configured (BSC only)
- Private key for Terra Classic (hexadecimal)

---

## 🔧 STEP 1: Configure AWS Credentials

Only necessary if using **BSC** (the relayer).

```bash
# 1. Copy template
cp .env.example .env

# 2. Edit with your credentials
nano .env
```

**`.env` content:**
```bash
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

---

## 🔑 STEP 2: Configure Keys

### ⚠️ **IMPORTANT: Terra Classic does NOT support AWS KMS**

Terra Classic is a **Cosmos** blockchain, and Hyperlane **does not support AWS KMS** for Cosmos. You must use **local private keys (hexKey)**.

### Option A: Generate New Key

```bash
# Install Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Generate new wallet
cast wallet new

# Save the displayed private key
```

### Option B: Use Existing Key

If you already have a private key, skip to the next step.

### Discover Key Addresses

```bash
# Install dependencies
pip3 install eth-account bech32

# Get addresses
./get-address-from-hexkey.py 0xYOUR_PRIVATE_KEY
```

**Example output:**
```
Ethereum: 0x6109b140b7165a4584e4ab09a93ccfb2d7be6b0f
Terra:    terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
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

**Replace:**
- For **Terra Classic**: `0xYOUR_PRIVATE_KEY_HERE` → Your private key
- For **BSC**: Keep AWS KMS or create KMS key first

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

### BSC Relayer (Optional)

If you configured KMS for BSC:

```bash
# Discover address
cast wallet address --aws alias/hyperlane-relayer-signer-bsc

# Send 0.1-0.5 BNB to this address
```

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

Only if you configured BSC:

```bash
# Start relayer
docker-compose up -d relayer

# View logs
docker logs -f hpl-relayer
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

**Solution:** Use `hexKey` as shown in this guide

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
- **`SETUP-AWS-KMS.md`** - Configure AWS KMS for BSC
- **`DOCKER-VOLUMES-EXPLAINED.md`** - Understand Docker volumes
- **`README.md`** - Complete overview

---

## 🆘 Need Help?

1. Check logs: `docker logs hpl-validator-terraclassic`
2. Consult `SECURITY-HEXKEY.md` for security questions
3. Check Hyperlane GitHub issues

---

## ✅ Checklist

- [ ] AWS credentials configured (`.env`) - **BSC only**
- [ ] Private key generated or obtained
- [ ] Addresses discovered (ETH + Terra)
- [ ] Files configured (`validator.terraclassic.json`)
- [ ] Correct permissions (600)
- [ ] Wallet funded with LUNC
- [ ] Validator running (`docker ps`)
- [ ] Announcement successful (logs)
- [ ] Key backup completed

---

**🎉 Ready! Your validator is running!**

To run the relayer, follow the same steps but start with:
```bash
docker-compose up -d relayer
```
