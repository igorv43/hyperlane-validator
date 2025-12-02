# 🌉 Hyperlane Validator & Relayer - Terra Classic ↔ BSC

Hyperlane validator and relayer configured for Terra Classic ↔ BSC.

---

## ⚠️ **IMPORTANT: AWS KMS Support**

| Blockchain | Type | Key Management | AWS KMS Support |
|------------|------|----------------|-----------------|
| **BSC** | EVM | **AWS KMS** | ✅ Supported |
| **Solana** | Sealevel | **AWS KMS** | ✅ Supported |
| **Terra Classic** | Cosmos | **hexKey** (local keys) | ❌ NOT Supported |

### ⚠️ **Cosmos chains do NOT support AWS KMS**

Hyperlane **does not support AWS KMS** for Cosmos blockchains (like Terra Classic). You **must use local private keys** (hexKey) for Cosmos chains.

**Supported protocols for AWS KMS:**
- ✅ **EVM chains** (Ethereum, BSC, Polygon, etc.)
- ✅ **Sealevel chains** (Solana)
- ❌ **Cosmos chains** (Terra Classic, Osmosis, etc.)

📖 **Read**: [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md) for key security

---

## 🚀 Quick Start

### **[📘 QUICKSTART.md](QUICKSTART.md) ← Start here!**

Complete step-by-step guide with all necessary commands.

### Quick summary:

```bash
# 1. Configure AWS credentials (BSC only)
cp .env.example .env
nano .env

# 2. Configure validator (Terra Classic)
cp hyperlane/validator.terraclassic.json.example hyperlane/validator.terraclassic.json
nano hyperlane/validator.terraclassic.json
# Replace: S3 bucket and private key

# 3. Discover addresses
pip3 install eth-account bech32
./get-address-from-hexkey.py 0xYOUR_PRIVATE_KEY

# 4. Send LUNC to Terra address
# (100-500 LUNC recommended)

# 5. Start validator
docker-compose up -d validator-terraclassic
docker logs -f hpl-validator-terraclassic
```

---

## 📚 Documentation

### Guides

| File | Description |
|------|-------------|
| **[QUICKSTART.md](QUICKSTART.md)** ⭐ | **Complete step-by-step guide** |
| [RELAYER-CONFIG-GUIDE.md](RELAYER-CONFIG-GUIDE.md) 🔄 | **Configure relayer for other blockchains** |
| [SECURITY-HEXKEY.md](SECURITY-HEXKEY.md) | Local key security |
| [SETUP-AWS-KMS.md](SETUP-AWS-KMS.md) | Configure AWS KMS for BSC |
| [DOCKER-VOLUMES-EXPLAINED.md](DOCKER-VOLUMES-EXPLAINED.md) | Docker volumes explanation |
| [CHECKLIST.md](CHECKLIST.md) | Configuration checklist |

### Scripts

| Script | Usage |
|--------|-------|
| `get-address-from-hexkey.py` | Get ETH/Terra addresses from private key |
| `get-kms-addresses.sh` | Get AWS KMS key addresses |
| `eth-to-terra.py` | Convert ETH address → Terra |

---

## 🏗️ Architecture

```
Terra Classic ←→ Hyperlane ←→ BSC
     ↓                           ↓
  Validator                  Relayer
     ↓                           ↓
  hexKey                     AWS KMS (BSC)
     ↓                       hexKey (Terra)
  AWS S3                         ↓
(signatures)              (transactions)
```

### Components

- **Terra Classic Validator**: Signs cross-chain message checkpoints
- **Relayer**: Transmits messages between Terra Classic and BSC
- **AWS S3**: Stores validator signatures (public)
- **AWS KMS**: Manages BSC relayer key (BSC only)

---

## 🔑 Key Management

### Terra Classic (Cosmos)

```json
// ✅ CORRECT - hexKey
{
  "validator": {
    "type": "hexKey",
    "key": "0x..."
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0x...",
        "prefix": "terra"
      }
    }
  }
}
```

### BSC (EVM)

```json
// ✅ CORRECT - AWS KMS
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

---

## 🐳 Docker Commands

### Validator

```bash
# Start
docker-compose up -d validator-terraclassic

# View logs
docker logs -f hpl-validator-terraclassic

# Stop
docker-compose stop validator-terraclassic

# Restart
docker-compose restart validator-terraclassic

# Status
docker ps | grep validator
```

### Relayer

```bash
# Start
docker-compose up -d relayer

# View logs
docker logs -f hpl-relayer

# Stop
docker-compose stop relayer

# Restart
docker-compose restart relayer
```

### All Services

```bash
# Start all
docker-compose up -d

# Stop all
docker-compose down

# View status
docker ps

# Clean and restart
docker-compose down -v
docker-compose up -d
```

---

## 📊 Monitoring

### Metrics APIs

- **Validator**: http://localhost:9121/metrics
- **Relayer**: http://localhost:9110/metrics

### Check Balance

```bash
# Terra Classic
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/YOUR_TERRA_ADDRESS" | jq

# BSC (if using KMS)
cast balance 0xYOUR_BSC_ADDRESS --rpc-url https://bsc.drpc.org
```

### Check Checkpoints on S3

```bash
# List checkpoints
aws s3 ls s3://YOUR-BUCKET/us-east-1/ --recursive

# View last checkpoint
aws s3 ls s3://YOUR-BUCKET/us-east-1/ --recursive | tail -1
```

---

## 🌐 Networks

### Terra Classic

- **Chain ID**: `columbus-5`
- **Domain ID**: `1325`
- **RPC**: https://rpc.terra-classic.hexxagon.io:443
- **LCD**: https://terra-classic-lcd.publicnode.com
- **Explorer**: https://finder.terraclassic.community

### Binance Smart Chain

- **Chain ID**: `56`
- **Domain ID**: `56`
- **RPC**: https://bsc.drpc.org
- **Explorer**: https://bscscan.com

---

## 🚨 Troubleshooting

### Container won't start

```bash
# View complete error
docker logs hpl-validator-terraclassic

# Restart
docker-compose restart validator-terraclassic

# Clean and restart
docker-compose down
docker rm -f hpl-validator-terraclassic
docker-compose up -d validator-terraclassic
```

### "Cannot announce validator without a signer"

**Cause**: Wallet has no LUNC funds

**Solution**:
1. Discover address: `./get-address-from-hexkey.py 0xYOUR_KEY`
2. Send 100-500 LUNC to Terra address
3. Restart: `docker-compose restart validator-terraclassic`

### "Expected key `key` to be defined"

**Cause**: Trying to use AWS KMS for Terra Classic (not supported)

**Solution**: See [`QUICKSTART.md`](QUICKSTART.md) for correct hexKey configuration

### Permission denied

```bash
# Fix permissions
chmod 600 hyperlane/validator.terraclassic.json
chmod 600 hyperlane/relayer.json
```

### Rate limit (429 Too Many Requests)

**Cause**: Public RPCs have limits

**Solution**: Wait. Validator uses multiple RPCs as fallback.

---

## 🔐 Security

### ⚠️ Confidential Files

These files should **NOT** be committed to Git:

- `.env` - AWS credentials
- `hyperlane/validator.terraclassic.json` - Terra private key
- `hyperlane/relayer.json` - Private keys
- `validator/` - Validator data
- `relayer/` - Relayer data

✅ **All already in `.gitignore`**

### Implemented Protections

```bash
# Restricted permissions (owner read only)
-rw------- (600) validator.terraclassic.json
-rw------- (600) relayer.json

# Verify
chmod 600 hyperlane/validator.terraclassic.json
chmod 600 hyperlane/relayer.json
```

### Backup

**IMPORTANT**: Backup private keys in a secure location!

See [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md) for complete backup guide.

---

## 🛠️ Requirements

### Required Software

- **Docker & Docker Compose** (required)
- **Python 3.8+** (required)
- **Foundry (cast)** (optional, for generating keys)
- **AWS CLI** (optional, for managing S3)

### Installation

```bash
# Docker
curl -fsSL https://get.docker.com | sh

# Python packages
pip3 install eth-account bech32

# Foundry (optional)
curl -L https://foundry.paradigm.xyz | bash && foundryup

# AWS CLI (optional)
pip3 install awscli
```

---

## 📁 Project Structure

```
hyperlane-validator/
├── docker-compose.yml                 # Docker configuration
├── .env                               # AWS credentials (not committed)
├── .env.example                       # Template
├── .gitignore                         # Ignored files
├── README.md                          # This file
├── QUICKSTART.md                      # ⭐ Step-by-step guide
├── SECURITY-HEXKEY.md                 # Security guide
├── SETUP-AWS-KMS.md                   # AWS setup
├── get-address-from-hexkey.py         # Script: get addresses
├── get-kms-addresses.sh               # Script: KMS addresses
├── eth-to-terra.py                    # Script: convert addresses
├── hyperlane/
│   ├── agent-config.docker.json       # Chains config
│   ├── validator.terraclassic.json    # Validator config (local)
│   ├── validator.terraclassic.json.example  # Template
│   ├── relayer.json                   # Relayer config (local)
│   └── relayer.json.example           # Template
├── validator/                          # Validator data (local)
└── relayer/                            # Relayer data (local)
```

---

## 📞 Resources

- [Hyperlane Documentation](https://docs.hyperlane.xyz)
- [Hyperlane Discord](https://discord.gg/hyperlane)
- [Terra Classic Docs](https://docs.terra.money)
- [AWS KMS Guide](https://docs.aws.amazon.com/kms/)

---

## ✅ Project Status

**Configured on**: Nov 26, 2025  
**Validator**: ✅ Working (hexKey)  
**Relayer**: ⏳ Optional (configure BSC KMS)  
**Networks**: Terra Classic ↔ BSC  

---

**🎉 Start now:** [`QUICKSTART.md`](QUICKSTART.md)
