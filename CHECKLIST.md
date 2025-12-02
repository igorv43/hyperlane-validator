# ✅ Hyperlane Configuration Checklist

Use this checklist to ensure everything is configured correctly.

## 🎯 Phase 1: AWS Configuration (Required)

### AWS IAM User
- [ ] ✅ IAM user created: `hyperlane-validator`
- [ ] ✅ Access Key ID obtained
- [ ] ✅ Secret Access Key obtained (securely stored)

### AWS S3 Bucket
- [ ] ✅ Bucket created: `hyperlane-validator-signatures-YOUR-NAME`
- [ ] ✅ Bucket policy configured (public read, IAM user write)
- [ ] ✅ Region: `us-east-1`

### AWS KMS Keys
- [ ] ⏳ Key 1 (BSC): `hyperlane-relayer-signer-bsc`
  - Type: Asymmetric, ECC_SECG_P256K1
  - Usage: BSC Relayer
- [ ] ⏳ Key 2 (Solana - optional): `hyperlane-relayer-signer-solana`
  - Type: Asymmetric, ECC_SECG_P256K1
  - Usage: Solana Relayer

---

## 🔧 Phase 2: Local Configuration (Required)

### Configuration Files
- [ ] ✅ `.env` created with AWS credentials
- [ ] ✅ `.gitignore` protecting sensitive files
- [ ] ✅ `docker-compose.yml` updated with environment variables
- [ ] ✅ `validator.terraclassic.json` configured with hexKey and S3
- [ ] ✅ `relayer.json` configured (hexKey for Terra, KMS for EVM)

### Installed Dependencies
- [ ] 📦 Docker and Docker Compose
  ```bash
  docker --version
  docker-compose --version
  ```
- [ ] 📦 Foundry (cast) - optional
  ```bash
  cast --version
  ```
- [ ] 📦 Python 3 and pip
  ```bash
  python3 --version
  pip3 --version
  ```
- [ ] 📦 Python libraries (eth-account, bech32)
  ```bash
  pip3 install eth-account bech32
  ```

---

## 🔍 Phase 3: Discover Addresses (Required)

### Wallet Addresses (hexKey for Terra)
- [ ] 🔑 Validator/Relayer Terra Classic address discovered
  ```bash
  ./get-address-from-hexkey.py 0xYOUR_PRIVATE_KEY
  ```
  - Ethereum format: `0x...`
  - Terra format: `terra1...`
  
### Wallet Addresses (KMS for EVM)
- [ ] 🔑 BSC Relayer address discovered (after creating KMS key)
  ```bash
  ./get-kms-addresses.sh
  ```
  - Format: `0x...`

- [ ] 🔑 Solana Relayer address discovered (optional, after creating KMS key)
  ```bash
  ./get-kms-addresses.sh
  ```
  - Format: Solana public key

---

## 💰 Phase 4: Fund Wallets (Required)

### Validator/Relayer Terra Classic
- [ ] 💸 LUNC sent to: `terra1...`
  - Recommended amount: 100-500 LUNC
  - Status: _____ LUNC sent
  - TX Hash: _________________

### BSC Relayer (optional)
- [ ] 💸 BNB sent to: `0x...`
  - Recommended amount: 0.1-0.5 BNB
  - Status: _____ BNB sent
  - TX Hash: _________________

### Solana Relayer (optional)
- [ ] 💸 SOL sent to: (Solana address)
  - Recommended amount: 1-5 SOL
  - Status: _____ SOL sent
  - TX Hash: _________________

### Balance Verification
- [ ] ✅ Terra balance verified
  ```bash
  curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/terra1..."
  ```
- [ ] ✅ BSC balance verified (if using)
  ```bash
  cast balance 0x... --rpc-url https://bsc.drpc.org
  ```

---

## 🚀 Phase 5: Start Services (Required)

### Terra Classic Validator
- [ ] ▶️ Container started
  ```bash
  docker-compose up -d validator-terraclassic
  ```
- [ ] 📋 Logs verified (no errors)
  ```bash
  docker logs -f hpl-validator-terraclassic
  ```
- [ ] ✅ Checkpoints being signed
  ```bash
  docker logs hpl-validator-terraclassic | grep "signed checkpoint"
  ```
- [ ] ✅ Successfully announced validator
  ```bash
  docker logs hpl-validator-terraclassic | grep "Successfully announced"
  ```
- [ ] 📊 Metrics accessible: http://localhost:9121

### Relayer (After funding wallets)
- [ ] ▶️ Container started
  ```bash
  docker-compose up -d relayer
  ```
- [ ] 📋 Logs verified (no errors)
  ```bash
  docker logs -f hpl-relayer
  ```
- [ ] ✅ Messages being processed
  ```bash
  docker logs hpl-relayer | grep "delivered message"
  ```
- [ ] 📊 Metrics accessible: http://localhost:9110

---

## 🔍 Phase 6: Verify Operation (Recommended)

### Validator
- [ ] 🔐 Signatures appearing in S3
  ```bash
  aws s3 ls s3://YOUR-BUCKET-NAME/
  ```
- [ ] 📡 Connected to Terra Classic RPC
- [ ] ⚡ Reasonable gas consumption
- [ ] 📈 Prometheus metrics working

### Relayer
- [ ] 🔗 Connected to all chains (Terra + BSC/Solana)
- [ ] 📨 Processing cross-chain messages
- [ ] ⚡ Sufficient gas on all chains
- [ ] 📈 Prometheus metrics working

---

## 📚 Phase 7: Documentation and Backup (Recommended)

### Documentation Read
- [ ] 📖 `README.md` - Project overview
- [ ] 📖 `QUICKSTART.md` - Quick start guide
- [ ] 📖 `SETUP-AWS-KMS.md` - Complete setup guide
- [ ] 📖 `SECURITY-HEXKEY.md` - Key security guide
- [ ] 📖 `RELAYER-CONFIG-GUIDE.md` - Relayer configuration

### Information Saved
- [ ] 💾 AWS credentials securely saved
- [ ] 💾 KMS key ARNs noted (if using)
- [ ] 💾 Wallet addresses saved
- [ ] 💾 S3 bucket name noted
- [ ] 💾 Private keys backed up securely (for Terra)

### Scripts Tested
- [ ] 🧪 `get-address-from-hexkey.py` tested and working
- [ ] 🧪 `eth-to-terra.py` tested and working
- [ ] 🧪 `get-kms-addresses.sh` tested (if using KMS)

---

## 🔐 Phase 8: Security (Critical)

### Credential Protection
- [ ] ✅ `.env` file not committed to git
- [ ] ✅ `.gitignore` protecting sensitive files
- [ ] ✅ Private key files (600 permissions)
  ```bash
  chmod 600 hyperlane/validator.terraclassic.json
  chmod 600 hyperlane/relayer.json
  ```
- [ ] 🔒 AWS credentials securely stored
- [ ] 🔒 Backup of credentials in secure location
- [ ] 🔒 Private keys backed up (encrypted)

### AWS Permissions
- [ ] ✅ IAM user has only necessary permissions
- [ ] ✅ KMS keys accessible only by IAM user (if using)
- [ ] ✅ S3 bucket with appropriate access policy

### Monitoring
- [ ] 📊 CloudWatch configured (optional)
- [ ] 🚨 Low balance alerts configured (optional)
- [ ] 📧 Error notifications configured (optional)

---

## 🎓 Phase 9: Daily Operations (Optional)

### Verification Routine
- [ ] 🔄 Check wallet balances (daily)
- [ ] 🔄 Check container logs (daily)
- [ ] 🔄 Check Prometheus metrics (daily)
- [ ] 🔄 Check S3 signatures (weekly)

### Maintenance
- [ ] 🔧 Update Docker images (monthly)
- [ ] 🔧 Review old logs (monthly)
- [ ] 🔧 Test recovery procedure (monthly)
- [ ] 🔧 Backup configurations (monthly)

---

## 📊 Overall Project Status

### Summary
- **AWS IAM**: Status: ___________
- **AWS S3**: Status: ___________
- **AWS KMS**: Status: ___________ (optional for EVM)
- **Local Config**: Status: ___________
- **Validator**: Status: ___________
- **Relayer**: Status: ___________

### Next Steps
1. ⏳ Create KMS keys (optional, for BSC/Solana)
2. ⏳ Discover wallet addresses
3. ⏳ Fund wallets with LUNC (and BNB/SOL if using relayer)
4. ⏳ Start validator
5. ⏳ Start relayer

---

## 🆘 Need Help?

### Resources
- 📖 Complete documentation in `SETUP-AWS-KMS.md`
- 📖 Quick start in `QUICKSTART.md`
- 🔐 Security guide in `SECURITY-HEXKEY.md`
- 🔄 Relayer configuration in `RELAYER-CONFIG-GUIDE.md`
- 🐛 Troubleshooting in `README.md`

### Diagnostic Commands
```bash
# Check container status
docker-compose ps

# View logs
docker logs hpl-validator-terraclassic --tail 50
docker logs hpl-relayer --tail 50

# Check configuration
cat .env
cat hyperlane/validator.terraclassic.json
cat hyperlane/relayer.json

# Test AWS connection
aws sts get-caller-identity
aws s3 ls s3://YOUR-BUCKET-NAME/

# Check balances
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/terra1..."
```

---

**📅 Last updated:** Dec 2, 2025  
**✅ Complete checklist!**

Check off each item as you complete it. Good luck! 🚀

