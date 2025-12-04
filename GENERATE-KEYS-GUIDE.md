# 🔑 Guide: Generate Private Keys for Hyperlane

This guide explains how to generate and configure private keys for **Solana**, **BSC**, and **Ethereum** in Hyperlane.

---

## 📋 **Quick Reference: Key Types by Chain**

According to [Hyperlane Official Documentation](https://docs.hyperlane.xyz/docs/operate/config/config-reference#chains-%3Cchain-name%3E-signer-region):

| Chain | VM Type | Signer Type | Format | Method |
|-------|---------|-------------|--------|--------|
| **Solana** | Sealevel | `hexKey` (ED25519) | Hexadecimal (64 bytes) | Local key generation |
| **BSC** | EVM | `aws` (ECDSA) or `hexKey` (ECDSA) | AWS KMS Key or Hex | AWS KMS or Local |
| **Ethereum** | EVM | `aws` (ECDSA) or `hexKey` (ECDSA) | AWS KMS Key or Hex | AWS KMS or Local |
| **Terra Classic** | Cosmos | `cosmosKey` | Hexadecimal (64 bytes) | See [QUICKSTART.md](QUICKSTART.md) |

**Reference:** [Hyperlane Configuration Reference - Signer Types](https://docs.hyperlane.xyz/docs/operate/config/config-reference#chains-%3Cchain-name%3E-signer-type)

---

## ☀️ **Solana: Generate hexKey**

**⚠️ IMPORTANT:** Solana does NOT support AWS KMS. You must use `hexKey` (local private key).

### Step 1: Install Solana CLI (if not installed)

```bash
# Install Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Verify installation
solana --version
```

**Alternative:** Download from [Solana Releases](https://github.com/solana-labs/solana/releases)

### Step 2: Generate New Solana Keypair

```bash
# Generate new keypair
solana-keygen new --outfile ./solana-keypair.json

# You'll be prompted for a passphrase (optional but recommended)
# Enter passphrase: [your-passphrase]
# Confirm passphrase: [your-passphrase]
```

**Example output:**
```
Generating a new keypair

For added security, enter a passphrase (empty for no passphrase): 
Wrote new keypair to ./solana-keypair.json

================================================================================
pubkey: 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU
================================================================================
Save this seed phrase to recover your new keypair:
word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12

================================================================================
```

**⚠️ IMPORTANT:** 
- **Save the seed phrase immediately** - you'll need it to recover your key!
- Store it securely (password manager, encrypted file, etc.)
- Never share or commit this seed phrase to Git

### Step 3: Extract Private Key in Hexadecimal Format

**Option A: Using Solana CLI (Recommended)**

```bash
# Extract private key as base58 (Solana's native format)
solana-keygen pubkey ./solana-keypair.json --outfile /dev/stdout

# To get the private key in hex format, we need to decode from base58
# Install base58 decoder if needed:
# pip install base58

# Or use this Python script:
python3 << EOF
import json
import base58

# Read the keypair file
with open('./solana-keypair.json', 'r') as f:
    keypair = json.load(f)

# The keypair is an array of 64 bytes (base58 encoded in the file)
# Convert to hex
private_key_bytes = bytes(keypair)
private_key_hex = private_key_bytes.hex()

print(f"Private key (hex): 0x{private_key_hex}")
EOF
```

**Option B: Using Python Script (Easier)**

Create a script `get-solana-hexkey.py`:

```python
#!/usr/bin/env python3
import json
import sys

def solana_keypair_to_hex(keypair_file):
    """Convert Solana keypair JSON to hexadecimal private key."""
    try:
        with open(keypair_file, 'r') as f:
            keypair = json.load(f)
        
        # Solana keypair is a JSON array of 64 integers (bytes)
        if isinstance(keypair, list) and len(keypair) == 64:
            # Convert bytes to hex
            private_key_bytes = bytes(keypair)
            private_key_hex = private_key_bytes.hex()
            return f"0x{private_key_hex}"
        else:
            print(f"Error: Invalid keypair format in {keypair_file}", file=sys.stderr)
            return None
    except Exception as e:
        print(f"Error reading keypair file: {e}", file=sys.stderr)
        return None

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 get-solana-hexkey.py <keypair.json>", file=sys.stderr)
        sys.exit(1)
    
    hex_key = solana_keypair_to_hex(sys.argv[1])
    if hex_key:
        print(hex_key)
    else:
        sys.exit(1)
```

**Make it executable and use it:**
```bash
chmod +x get-solana-hexkey.py

# Extract hex key
./get-solana-hexkey.py ./solana-keypair.json
```

**Example output:**
```
0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

### Step 4: Get Solana Address

```bash
# Get public address
solana-keygen pubkey ./solana-keypair.json

# Or for testnet
solana-keygen pubkey ./solana-keypair.json --url https://api.testnet.solana.com
```

**Example output:**
```
7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU
```

### Step 5: Configure in relayer.json

```json
{
  "chains": {
    "solanatestnet": {
      "signer": {
        "type": "hexKey",
        "key": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      }
    }
  }
}
```

### Step 6: Fund Your Solana Wallet

Send SOL to your Solana address (e.g., `7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU`).

**For testnet:**
- Get testnet SOL from: https://faucet.solana.com/
- Or use: `solana airdrop 1 YOUR_ADDRESS --url https://api.testnet.solana.com`

**For mainnet:**
- Send SOL from an exchange or another wallet

**Recommended amounts:**
- **Testnet**: 1-5 SOL (for testing)
- **Mainnet**: 1-5 SOL (for relaying)

### Step 7: Secure Your Key Files

```bash
# Set restrictive permissions
chmod 600 ./solana-keypair.json

# Add to .gitignore
echo "solana-keypair.json" >> .gitignore
echo "*.keypair.json" >> .gitignore
```

---

## 🔵 **BSC: Configure AWS KMS**

**✅ BSC supports AWS KMS** - no local private key needed!

### Step 1: Create AWS KMS Key for BSC

**Reference:** [SETUP-AWS-KMS.md](SETUP-AWS-KMS.md)

```bash
# Create KMS key
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1

# Response will show KeyId (UUID format)
# Example: a1b2c3d4-e5f6-7890-abcd-ef1234567890

# Create alias using the KeyId from above
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-bsc \
  --target-key-id a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --region us-east-1
```

**⚠️ IMPORTANT:** 
- Use the **Key ID** (UUID) from `create-key` response, NOT your Access Key ID (`AKIA...`)
- The Key ID looks like: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

### Step 2: Get BSC Address from KMS Key

```bash
# Install Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Get address from KMS key
cast wallet address --aws alias/hyperlane-relayer-signer-bsc
```

**Example output:**
```
0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0
```

### Step 3: Configure in relayer.json

```json
{
  "chains": {
    "bsctestnet": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-bsc",
        "region": "us-east-1"
      }
    }
  }
}
```

**For mainnet (domain ID 56):**
```json
{
  "chains": {
    "bsc": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-bsc",
        "region": "us-east-1"
      }
    }
  }
}
```

### Step 4: Fund Your BSC Wallet

Send BNB to your BSC address (e.g., `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0`).

**For testnet:**
- Get testnet BNB from: https://testnet.binance.org/faucet-smart
- Or use: https://testnet.bnbchain.org/faucet-smart

**For mainnet:**
- Send BNB from an exchange or another wallet

**Recommended amounts:**
- **Testnet**: 0.5-1 BNB (for testing)
- **Mainnet**: 0.5-1 BNB (for relaying)

---

## 🟢 **Ethereum: Configure AWS KMS**

**✅ Ethereum supports AWS KMS** - no local private key needed!

### Step 1: Create AWS KMS Key for Ethereum

```bash
# Create KMS key
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1

# Response will show KeyId (UUID format)
# Example: b2c3d4e5-f6a7-8901-bcde-f12345678901

# Create alias using the KeyId from above
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-ethereum \
  --target-key-id b2c3d4e5-f6a7-8901-bcde-f12345678901 \
  --region us-east-1
```

### Step 2: Get Ethereum Address from KMS Key

```bash
# Get address from KMS key
cast wallet address --aws alias/hyperlane-relayer-signer-ethereum
```

**Example output:**
```
0x8ba1f109551bD432803012645Hac136c22C929E
```

### Step 3: Configure in relayer.json

```json
{
  "chains": {
    "ethereum": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-ethereum",
        "region": "us-east-1"
      }
    }
  }
}
```

**For testnets (Sepolia, Goerli, etc.):**
```json
{
  "chains": {
    "sepolia": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-ethereum",
        "region": "us-east-1"
      }
    }
  }
}
```

### Step 4: Fund Your Ethereum Wallet

Send ETH to your Ethereum address (e.g., `0x8ba1f109551bD432803012645Hac136c22C929E`).

**For testnets:**
- **Sepolia**: https://sepoliafaucet.com/
- **Goerli**: https://goerlifaucet.com/

**For mainnet:**
- Send ETH from an exchange or another wallet

**Recommended amounts:**
- **Testnet**: 0.1-0.5 ETH (for testing)
- **Mainnet**: 0.5-1 ETH (for relaying)

---

## 📝 **Summary: Configuration Examples**

### Complete relayer.json Example

```json
{
  "db": "/etc/data/db",
  "relayChains": "terraclassic,bsctestnet,solanatestnet",
  "allowLocalCheckpointSyncers": "false",
  "gasPaymentEnforcement": [{ "type": "none" }],
  "whitelist": [
    {
      "originDomain": [1325],
      "destinationDomain": [97]
    },
    {
      "originDomain": [97],
      "destinationDomain": [1325]
    },
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
    "bsctestnet": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-bsc",
        "region": "us-east-1"
      }
    },
    "solanatestnet": {
      "signer": {
        "type": "hexKey",
        "key": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
        "prefix": "terra"
      }
    }
  }
}
```

---

## 🔒 **Security Best Practices**

### For Local Keys (Solana, Terra Classic):

1. **File Permissions:**
   ```bash
   chmod 600 ./solana-keypair.json
   chmod 600 ./hyperlane/relayer.json
   ```

2. **Git Ignore:**
   ```bash
   # Add to .gitignore
   echo "*.keypair.json" >> .gitignore
   echo "hyperlane/relayer.json" >> .gitignore
   ```

3. **Backup:**
   - Store seed phrases/mnemonics in encrypted password manager
   - Create encrypted backups of key files
   - Never commit keys to Git

### For AWS KMS Keys (BSC, Ethereum):

1. **IAM Permissions:**
   - Use least-privilege IAM policies
   - Rotate access keys regularly
   - Enable MFA for AWS console access

2. **Key Management:**
   - Use separate KMS keys for each chain
   - Enable CloudTrail for audit logging
   - Set up key rotation policies

---

## 🆘 **Troubleshooting**

### Solana: "Invalid key format"

**Problem:** Key is not in hexadecimal format.

**Solution:**
- Ensure key starts with `0x`
- Key must be 64 bytes (128 hex characters + `0x` prefix = 130 characters total)
- Use the Python script above to convert from Solana keypair JSON

### BSC/Ethereum: "AccessDeniedException"

**Problem:** IAM user lacks KMS permissions.

**Solution:**
- Add KMS permissions to IAM user (see [SETUP-AWS-KMS.md](SETUP-AWS-KMS.md))
- Ensure KMS key has correct usage permissions

### Solana: "key is not supported by sealevel"

**Problem:** Trying to use AWS KMS for Solana.

**Solution:**
- Solana does NOT support AWS KMS
- Use `hexKey` instead (see Solana section above)

---

## 📚 **Additional Resources**

- **Solana CLI Docs**: https://docs.solana.com/cli
- **AWS KMS Docs**: https://docs.aws.amazon.com/kms/
- **Foundry (cast) Docs**: https://book.getfoundry.sh/reference/cast/
- **Hyperlane Docs**: https://docs.hyperlane.xyz/

---

## ✅ **Checklist**

### Solana:
- [ ] Solana CLI installed
- [ ] Keypair generated (`solana-keypair.json`)
- [ ] Private key extracted in hex format
- [ ] Address obtained
- [ ] Wallet funded with SOL
- [ ] Key configured in `relayer.json`
- [ ] File permissions set (600)
- [ ] Added to `.gitignore`

### BSC:
- [ ] AWS KMS key created
- [ ] Alias created (`alias/hyperlane-relayer-signer-bsc`)
- [ ] Address obtained from KMS key
- [ ] Wallet funded with BNB
- [ ] Key configured in `relayer.json`
- [ ] IAM permissions verified

### Ethereum:
- [ ] AWS KMS key created
- [ ] Alias created (`alias/hyperlane-relayer-signer-ethereum`)
- [ ] Address obtained from KMS key
- [ ] Wallet funded with ETH
- [ ] Key configured in `relayer.json`
- [ ] IAM permissions verified

