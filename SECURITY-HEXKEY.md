# 🔐 Security: Local Hexadecimal Keys

## ⚠️ **IMPORTANT: AWS KMS Limitation for Cosmos**

**AWS KMS is NOT supported** for Cosmos blockchains (including Terra Classic) in Hyperlane validator/relayer.

### Why?

Hyperlane parser (`hyperlane-base`) **does not accept** AWS KMS configuration for `cosmosKey` type signers:

```json
// ❌ DOESN'T WORK for Cosmos
"chains": {
  "terraclassic": {
    "signer": {
      "type": "cosmosKey",
      "aws": { ... }  // ❌ Parser requires "key" field
    }
  }
}
```

**Solution:** Use local hexadecimal keys (`hexKey`)

---

## 📋 **Current Configuration**

### Validator (`validator.terraclassic.json`)

```json
{
  "originChainName": "terraclassic",
  "validator": {
    "type": "hexKey",
    "key": "0x..."  // ← Local private key
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0x...",  // ← Same key
        "prefix": "terra"
      }
    }
  }
}
```

### Relayer (`relayer.json`)

```json
{
  "chains": {
    "bsc": {
      "signer": {
        "type": "aws",  // ✅ AWS KMS works for EVM chains
        "id": "alias/hyperlane-relayer-signer-bsc"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0x...",  // ← Local private key
        "prefix": "terra"
      }
    }
  }
}
```

---

## 🔒 **Implemented Security Measures**

### 1. File Permissions

```bash
# Restricted permissions (owner read/write only)
-rw------- (600) validator.terraclassic.json
-rw------- (600) relayer.json
```

**Command:**
```bash
chmod 600 hyperlane/validator.terraclassic.json
chmod 600 hyperlane/relayer.json
```

### 2. Git Ignore

Files with keys are **excluded from Git**:

```gitignore
# Configuration files with private keys
hyperlane/validator.*.json
hyperlane/relayer.json
```

**Verify:**
```bash
git check-ignore hyperlane/validator.terraclassic.json
# Should return: hyperlane/validator.terraclassic.json
```

### 3. Example Files

Created `.example` files (without real keys) for documentation:
- `validator.terraclassic.json.example`
- `relayer.json.example`

---

## 📝 **How to Get Wallet Address**

### Method 1: Via `cast` (Foundry)

```bash
# Install Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Get Ethereum address
cast wallet address --private-key "0xYOUR_PRIVATE_KEY"

# Convert to Terra
./eth-to-terra.py "0xETH_ADDRESS"
```

### Method 2: Via Python

```python
#!/usr/bin/env python3
from eth_account import Account
import bech32

# Your private key
private_key = "0xe45624f7aca7eb9e...."

# Get ETH address
account = Account.from_key(private_key)
eth_address = account.address
print(f"Ethereum: {eth_address}")

# Convert to Terra
addr_bytes = bytes.fromhex(eth_address[2:])
five_bit = bech32.convertbits(addr_bytes, 8, 5)
terra_address = bech32.bech32_encode('terra', five_bit)
print(f"Terra:    {terra_address}")
```

**Output:**
```
Ethereum: 0x6109b140b7165a4584e4ab09a93ccfb2d7be6b0f
Terra:    terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
```

---

## 💰 **Send Funds to Wallet**

### For Validator (Announcement)

```bash
# Terra address
terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7

# Recommended amount
50-100 LUNC (50,000,000 - 100,000,000 uluna)

# Purpose
Gas for announcement + validation
```

### For Relayer (Transactions)

```bash
# Same wallet (Terra)
terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7

# Recommended amount
1000-5000 LUNC (depending on message volume)

# Purpose
Gas for message relaying
```

---

## 🔄 **Key Backup**

### ⚠️ **CRITICAL: Make Secure Backup**

```bash
# 1. Create secure backup directory
mkdir -p ~/hyperlane-backup-CONFIDENTIAL
chmod 700 ~/hyperlane-backup-CONFIDENTIAL

# 2. Copy configuration files
cp hyperlane/validator.terraclassic.json ~/hyperlane-backup-CONFIDENTIAL/
cp hyperlane/relayer.json ~/hyperlane-backup-CONFIDENTIAL/
cp .env ~/hyperlane-backup-CONFIDENTIAL/

# 3. Create file with private keys
cat > ~/hyperlane-backup-CONFIDENTIAL/KEYS.txt << 'EOF'
TERRA CLASSIC PRIVATE KEY:
0xYOUR_PRIVATE_KEY_HERE

ETHEREUM ADDRESS (derived):
0xYOUR_ETH_ADDRESS_HERE

TERRA ADDRESS (derived):
terra1YOUR_TERRA_ADDRESS_HERE

AWS ACCESS KEY ID:
AKIAXXXXXXXXXXXXXXXXXXXX

AWS SECRET ACCESS KEY:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

S3 BUCKET:
hyperlane-validator-signatures-YOUR-BUCKET-NAME
EOF

# 4. Protect file
chmod 400 ~/hyperlane-backup-CONFIDENTIAL/KEYS.txt

# 5. Create encrypted backup (optional but recommended)
tar czf - ~/hyperlane-backup-CONFIDENTIAL | \
  gpg --symmetric --cipher-algo AES256 -o ~/hyperlane-backup-$(date +%Y%m%d).tar.gz.gpg

# 6. Store in secure location
# - Encrypted USB drive
# - Password manager (1Password, Bitwarden)
# - Encrypted cloud storage (Cryptomator + Dropbox)
```

---

## 🚨 **In Case of Compromise**

### If Key is Exposed:

1. **Stop Immediately:**
   ```bash
   docker-compose down
   ```

2. **Transfer Funds:**
   ```bash
   # Use transfer script to move funds to new wallet
   # (Create appropriate transfer script for your chain)
   ```

3. **Generate New Key:**
   ```bash
   cast wallet new
   # Save new key securely
   ```

4. **Update Configurations:**
   ```bash
   # Edit validator.terraclassic.json
   # Edit relayer.json
   # Update with new key
   ```

5. **Reconfigure AWS S3:**
   - If needed, create new bucket
   - Update access policies

6. **Restart Services:**
   ```bash
   docker-compose up -d
   ```

---

## 📊 **Monitoring**

### Check Balance

```bash
# Via curl
curl -s "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7" | jq

# Via explorer
https://finder.terraclassic.community/mainnet/address/terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
```

### Low Balance Alerts

```bash
# Monitoring script (run via cron)
#!/bin/bash
TERRA_ADDR="terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7"
MIN_BALANCE=10000000  # 10 LUNC

BALANCE=$(curl -s "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/$TERRA_ADDR" | jq -r '.balances[] | select(.denom=="uluna") | .amount')

if [ "$BALANCE" -lt "$MIN_BALANCE" ]; then
  echo "⚠️ ALERT: Low balance! $((BALANCE/1000000)) LUNC"
  # Send notification (email, telegram, etc)
fi
```

---

## 🔐 **Best Practices**

1. **Never Share:**
   - ❌ Don't send keys via email
   - ❌ Don't post in chat/slack
   - ❌ Don't commit to Git

2. **Key Rotation:**
   - 🔄 Consider changing keys every 3-6 months
   - 🔄 After any suspected compromise

3. **Production Environment:**
   - 🔒 Use dedicated server (not shared)
   - 🔒 Configured firewall
   - 🔒 SSH access by key only
   - 🔒 Automatic security updates

4. **Redundant Backup:**
   - 💾 Minimum 3 copies
   - 💾 In different locations
   - 💾 At least 1 offline

5. **Recovery Testing:**
   - ✅ Test restore backup every 3 months
   - ✅ Document the process
   - ✅ Train team

---

## 📚 **References**

- [Hyperlane Agent Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)
- [Terra Classic Security](https://docs.terra.money/docs/learn/security/)
- [Ethereum Key Management](https://ethereum.org/en/developers/docs/accounts/)
- [OWASP Key Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html)

---

## ✅ **Security Checklist**

- [x] File permissions (600)
- [x] Files in `.gitignore`
- [x] Backup created
- [x] Backup tested
- [x] Addresses documented
- [ ] Balance monitoring configured
- [ ] Recovery plan documented
- [ ] Team trained

---

**⚠️ REMEMBER:** The security of your keys is your responsibility!

