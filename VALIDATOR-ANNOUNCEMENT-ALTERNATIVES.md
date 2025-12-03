# ⚠️ AWS KMS does not work for Cosmos (Terra Classic)

## 🚨 **Direct Conclusion**

**AWS KMS is NOT supported for Cosmos blockchains** (including Terra Classic) in Hyperlane.

**Solution**: Use **hexKey** (local private keys) as shown in [`QUICKSTART.md`](QUICKSTART.md).

---

## 🔍 **Why Doesn't It Work?**

Hyperlane validator/relayer **requires TWO operations** for Cosmos chains:

| Operation | Signer | AWS KMS Support | Status |
|-----------|--------|-----------------|--------|
| **Sign Checkpoints** | `validator.type` | ✅ Yes | ✅ Works |
| **On-Chain Transactions** | `chains.{chain}.signer` | ❌ **NO** | ❌ Doesn't work |

### Technical Problem

Hyperlane parser (`hyperlane-base/src/settings/parser`) **requires** a `key` field (hexadecimal key) for `cosmosKey` type signers:

```json
// ❌ DOESN'T WORK
{
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "aws": {
          "keyId": "alias/...",  // ❌ Parser doesn't accept
          "region": "us-east-1"
        }
      }
    }
  }
}
```

**Resulting error:**
```
error: Expected key `key` to be defined

config_path: `chains.terraclassic.signer.key`
error: Expected key `key` to be defined
```

---

## ✅ **Solution: hexKey**

Use local private keys:

```json
// ✅ WORKS
{
  "validator": {
    "type": "hexKey",
    "key": "0x..."
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0x...",  // ✅ Required field
        "prefix": "terra"
      }
    }
  }
}
```

📖 **Complete guide**: [`QUICKSTART.md`](QUICKSTART.md)  
🔐 **Security**: [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md)

---

## 🔐 **Comparison: Protocol Support for AWS KMS**

| Aspect | EVM (BSC, Ethereum) | Sealevel (Solana) | Cosmos (Terra Classic) |
|---------|---------------------|-------------------|------------------------|
| **AWS KMS** | ✅ Supported | ❌ NOT supported | ❌ NOT supported |
| **Signer Type** | `"type": "aws"` | `"type": "hexKey"` | `"type": "cosmosKey"` + `"key"` |
| **Example** | `{"type": "aws", "id": "alias/..."}` | `{"type": "hexKey", "key": "0x..."}` | `{"type": "cosmosKey", "key": "0x..."}` |
| **Security** | KMS (CloudHSM) | Local key (file 600) | Local key (file 600) |

---

## 🎯 **What Works**

### ✅ Operational Validator

Even using hexKey, validator **works perfectly**:

```bash
# Validator status
docker logs hpl-validator-terraclassic --tail 20

# Look for:
# ✅ "Successfully announced validator"
# ✅ "Validator has announced signature storage location"
# ✅ "s3://hyperlane-validator-signatures-.../us-east-1"
```

### ✅ Features

- ✅ Signs message checkpoints
- ✅ Saves signatures to AWS S3
- ✅ Makes announcement on-chain
- ✅ Validates cross-chain messages
- ✅ Metrics API available

---

## 🔄 **Future Alternatives**

### Option 1: Wait for Official Support

Hyperlane may add AWS KMS support for Cosmos in the future.

**Reference**: https://github.com/hyperlane-xyz/hyperlane-monorepo

### Option 2: Hardware Wallet

Use hardware wallets (Ledger, Trezor) for Cosmos:
- Keys never exposed
- Requires manual integration
- High complexity

### Option 3: Third-Party Custody

Services like Fireblocks, Anchorage offer Cosmos custody:
- Requires commercial contract
- High costs
- For enterprise operators

---

## 📊 **Security Impact**

### hexKey (Local) vs AWS KMS

| Aspect | hexKey | AWS KMS |
|---------|--------|---------|
| **Key exposed** | ⚠️ Local file | ✅ CloudHSM |
| **Backup** | 📝 Manual | ✅ Automatic |
| **Audit** | ❌ Limited | ✅ CloudTrail |
| **Cost** | ✅ Free | 💰 ~$1/month |
| **Complexity** | ✅ Simple | ⚠️ AWS setup |

### Implemented Mitigations

✅ **Permissions 600** (owner read only)  
✅ **`.gitignore`** (not committed to Git)  
✅ **`.example` files** (documentation without keys)  
✅ **Backup guide** ([`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md))

---

## 🛡️ **Production Security Recommendations**

### For Production with hexKey

1. **Dedicated Server**
   - Not shared
   - Restricted access (SSH key-only)
   - Configured firewall

2. **Redundant Backup**
   - Minimum 3 copies
   - Different locations
   - 1 offline (encrypted USB)

3. **Monitoring**
   - Low balance alerts
   - Centralized logs
   - Audited transactions

4. **Key Rotation**
   - Every 3-6 months
   - After suspected compromise
   - Documented process

📖 **Complete guide**: [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md)

---

## 📚 **References**

- [Hyperlane Validator Setup](https://docs.hyperlane.xyz/docs/operate/validators/run-validators)
- [AWS KMS Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)
- [Cosmos Security Best Practices](https://docs.cosmos.network/main/user/run-node/keyring)
- [Hyperlane GitHub](https://github.com/hyperlane-xyz/hyperlane-monorepo)

---

## ✅ **Next Steps**

1. **Follow**: [`QUICKSTART.md`](QUICKSTART.md)
2. **Configure**: hexKey for Terra Classic
3. **Secure**: Follow [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md)
4. **Start**: `docker-compose up -d validator-terraclassic`
5. **Monitor**: `docker logs -f hpl-validator-terraclassic`

---

**🎯 Conclusion**: Use hexKey as documented. Works perfectly! ✅
