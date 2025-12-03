# 🔄 Relayer Configuration Guide

## 📋 **What is the Relayer?**

The **Relayer** is the component that **transmits messages** between different blockchains. It reads messages from a source chain and delivers them to the destination chain.

### Message Flow:

```
Chain A (source)  →  Hyperlane Relayer  →  Chain B (destination)
     ↓                       ↓                     ↓
  Sends msg          Reads and validates       Delivers msg
```

---

## 🔑 **Main Fields in relayer.json**

### 1. `relayChains`

**Defines which chains the relayer will monitor.**

```json
"relayChains": "terraclassic,bsc"
```

**Format:** Comma-separated list, no spaces.

**Examples:**

```json
// Terra Classic and BSC only
"relayChains": "terraclassic,bsc"

// Add Ethereum
"relayChains": "terraclassic,bsc,ethereum"

// Add Polygon and Avalanche
"relayChains": "terraclassic,bsc,ethereum,polygon,avalanche"

// All supported chains
"relayChains": "*"
```

---

### 2. `whitelist`

**Defines which message routes are allowed.**

Each route specifies:
- **`originDomain`**: Source chain (where the message comes from)
- **`destinationDomain`**: Destination chain (where the message goes to)

```json
"whitelist": [
  {
    "originDomain": [1325],      // Terra Classic
    "destinationDomain": [56]     // BSC
  },
  {
    "originDomain": [56],         // BSC
    "destinationDomain": [1325]   // Terra Classic
  }
]
```

**⚠️ IMPORTANT:** 
- You need **2 entries** for bidirectional communication (A→B and B→A)
- Without whitelist, the relayer processes **all** messages (high gas cost!)

---

## 📊 **Blockchain Domain IDs**

| Blockchain | Domain ID | Type | KMS Supported? |
|------------|-----------|------|----------------|
| **Terra Classic** | 1325 | Cosmos | ❌ No (use hexKey) |
| **BSC** | 56 | EVM | ✅ Yes |
| **Ethereum** | 1 | EVM | ✅ Yes |
| **Polygon** | 137 | EVM | ✅ Yes |
| **Avalanche** | 43114 | EVM | ✅ Yes |
| **Arbitrum** | 42161 | EVM | ✅ Yes |
| **Optimism** | 10 | EVM | ✅ Yes |
| **Gnosis** | 100 | EVM | ✅ Yes |
| **Moonbeam** | 1284 | EVM | ✅ Yes |
| **Celo** | 42220 | EVM | ✅ Yes |
| **Solana** | 1399811150 | Sealevel | ✅ Yes |

**Complete reference:** https://docs.hyperlane.xyz/docs/reference/domains

---

## 📝 **Configuration Examples**

### Example 1: Terra Classic ↔ BSC (Current)

```json
{
  "relayChains": "terraclassic,bsc",
  "whitelist": [
    {
      "originDomain": [1325],      // Terra → BSC
      "destinationDomain": [56]
    },
    {
      "originDomain": [56],         // BSC → Terra
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
        "key": "0x...",
        "prefix": "terra"
      }
    }
  }
}
```

---

### Example 2: Terra Classic ↔ Ethereum

```json
{
  "relayChains": "terraclassic,ethereum",
  "whitelist": [
    {
      "originDomain": [1325],      // Terra → Ethereum
      "destinationDomain": [1]
    },
    {
      "originDomain": [1],          // Ethereum → Terra
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
        "key": "0x...",
        "prefix": "terra"
      }
    }
  }
}
```

---

### Example 3: Terra Classic ↔ BSC + Ethereum (3 chains)

```json
{
  "relayChains": "terraclassic,bsc,ethereum",
  "whitelist": [
    // Terra ↔ BSC
    {
      "originDomain": [1325],
      "destinationDomain": [56]
    },
    {
      "originDomain": [56],
      "destinationDomain": [1325]
    },
    // Terra ↔ Ethereum
    {
      "originDomain": [1325],
      "destinationDomain": [1]
    },
    {
      "originDomain": [1],
      "destinationDomain": [1325]
    },
    // BSC ↔ Ethereum (if needed)
    {
      "originDomain": [56],
      "destinationDomain": [1]
    },
    {
      "originDomain": [1],
      "destinationDomain": [56]
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
        "key": "0x...",
        "prefix": "terra"
      }
    }
  }
}
```

---

### Example 4: Multiple EVM Chains (without Cosmos)

```json
{
  "relayChains": "ethereum,polygon,avalanche,arbitrum",
  "whitelist": [
    // Ethereum ↔ Polygon
    {"originDomain": [1], "destinationDomain": [137]},
    {"originDomain": [137], "destinationDomain": [1]},
    
    // Ethereum ↔ Avalanche
    {"originDomain": [1], "destinationDomain": [43114]},
    {"originDomain": [43114], "destinationDomain": [1]},
    
    // Polygon ↔ Avalanche
    {"originDomain": [137], "destinationDomain": [43114]},
    {"originDomain": [43114], "destinationDomain": [137]}
  ],
  "chains": {
    "ethereum": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-ethereum",
        "region": "us-east-1"
      }
    },
    "polygon": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-polygon",
        "region": "us-east-1"
      }
    },
    "avalanche": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-avalanche",
        "region": "us-east-1"
      }
    }
  }
}
```

---

### Example 5: All Chains (No Whitelist)

**⚠️ Warning:** High gas cost!

```json
{
  "relayChains": "*",
  "whitelist": null,  // No restriction - processes ALL messages
  "chains": {
    // Configure ALL chains here
    // Each chain needs a signer
  }
}
```

---

### Example 6: Whitelist with Multiple Destinations

One origin can send to multiple destinations:

```json
{
  "whitelist": [
    {
      "originDomain": [1325],                    // Terra Classic
      "destinationDomain": [56, 1, 137, 43114]   // → BSC, ETH, Polygon, Avalanche
    },
    {
      "originDomain": [56],                      // BSC
      "destinationDomain": [1325]                 // → Terra Classic
    },
    {
      "originDomain": [1],                       // Ethereum
      "destinationDomain": [1325]                 // → Terra Classic
    }
    // ... other routes
  ]
}
```

---

## 🔧 **Configure Signers for Each Chain**

### EVM Chains (AWS KMS) ✅

```json
"chainName": {
  "signer": {
    "type": "aws",
    "id": "alias/hyperlane-relayer-signer-CHAINNAME",
    "region": "us-east-1"
  }
}
```

**BSC Example:**
```json
"bsc": {
  "signer": {
    "type": "aws",
    "id": "alias/hyperlane-relayer-signer-bsc",
    "region": "us-east-1"
  }
}
```

### Sealevel Chains (hexKey) ❌

**⚠️ AWS KMS is NOT supported for Solana (sealevel).**

```json
"solanatestnet": {
  "signer": {
    "type": "hexKey",
    "key": "0xYOUR_SOLANA_PRIVATE_KEY"
  }
}
```

**Solana Example:**
```json
"solanatestnet": {
  "signer": {
    "type": "hexKey",
    "key": "0x1234567890abcdef..."
  }
}
```

### Cosmos Chains (hexKey) ❌

```json
"chainName": {
  "signer": {
    "type": "cosmosKey",
    "key": "0xYOUR_PRIVATE_KEY",
    "prefix": "PREFIX"
  }
}
```

**Terra Classic Example:**
```json
"terraclassic": {
  "signer": {
    "type": "cosmosKey",
    "key": "0xe45624f7aca7eb9e....",
    "prefix": "terra"
  }
}
```

**Other Cosmos chains:**
```json
"osmosis": {
  "signer": {
    "type": "cosmosKey",
    "key": "0x...",
    "prefix": "osmo"
  }
}
```

---

## 💰 **Fund Wallets**

Each chain needs **gas funds**:

### EVM Chains (AWS KMS):

```bash
# Discover address
cast wallet address --aws alias/hyperlane-relayer-signer-CHAINNAME

# Or use script
./get-kms-addresses.sh
```

**Recommended amounts:**
- **Ethereum**: 0.5-1 ETH
- **BSC**: 0.5-1 BNB
- **Polygon**: 100-500 MATIC
- **Avalanche**: 5-10 AVAX
- **Arbitrum**: 0.1-0.5 ETH

### Sealevel Chains (hexKey):

```bash
# Discover Solana address from hex key
# Use Solana CLI or a script to derive address from private key
```

**Recommended amounts:**
- **Solana**: 1-5 SOL

### Cosmos Chains (hexKey):

```bash
# Discover address
./get-address-from-hexkey.py 0xYOUR_PRIVATE_KEY
```

**Recommended amounts:**
- **Terra Classic**: 500-1000 LUNC
- **Osmosis**: 10-50 OSMO

---

## 📊 **Calculate Number of Routes**

For **N chains**, with bidirectional communication:

```
Number of routes = N × (N - 1)
```

**Examples:**
- 2 chains (Terra + BSC): 2 × 1 = **2 routes**
- 3 chains: 3 × 2 = **6 routes**
- 4 chains: 4 × 3 = **12 routes**
- 5 chains: 5 × 4 = **20 routes**

**JSON formula:**
```json
// For N chains, need N×(N-1) entries in whitelist
```

---

## 🚀 **Steps to Add New Chain**

### 1. Verify Chain is Supported

Check: https://docs.hyperlane.xyz/docs/reference/domains

### 2. Add to `relayChains`

```json
"relayChains": "terraclassic,bsc,NEW_CHAIN"
```

### 3. Add to `whitelist`

```json
{
  "originDomain": [1325],           // Terra
  "destinationDomain": [DOMAIN_ID]  // New chain
},
{
  "originDomain": [DOMAIN_ID],      // New chain
  "destinationDomain": [1325]       // Terra
}
```

### 4. Configure Signer

**If EVM/Sealevel:**
```bash
# Create KMS key
# See: SETUP-AWS-KMS.md - Step 3

# Add to relayer.json:
"new_chain": {
  "signer": {
    "type": "aws",
    "id": "alias/hyperlane-relayer-signer-new-chain",
    "region": "us-east-1"
  }
}
```

**If Cosmos:**
```json
"new_chain": {
  "signer": {
    "type": "cosmosKey",
    "key": "0x...",
    "prefix": "prefix"
  }
}
```

### 5. Fund Wallet

```bash
# Get address and send funds
```

### 6. Restart Relayer

```bash
docker-compose restart relayer
docker logs -f hpl-relayer
```

---

## 🛠️ **Test Configuration**

### Validate JSON

```bash
# Test JSON syntax
cat hyperlane/relayer.json | python3 -m json.tool
```

### View Logs

```bash
# View initialization
docker logs hpl-relayer --tail 100

# Monitor real-time
docker logs -f hpl-relayer

# Search for errors
docker logs hpl-relayer 2>&1 | grep -i error
```

### Verify Active Routes

```bash
# Relayer shows configured routes on startup
docker logs hpl-relayer | grep -i "whitelist\|route"
```

---

## 📈 **Estimated Costs**

### Per Message (Gas):

| Chain | Cost per Message | Currency |
|-------|------------------|----------|
| Ethereum | $5-$50 | ETH |
| BSC | $0.10-$1 | BNB |
| Polygon | $0.01-$0.10 | MATIC |
| Avalanche | $0.10-$1 | AVAX |
| Terra Classic | $0.001-$0.01 | LUNC |
| Solana | $0.0001-$0.001 | SOL |

### Per Month (Estimate):

```
Monthly cost = (Messages/day) × (Cost/message) × 30 days

Example:
- 100 messages/day
- Terra → BSC ($0.20/msg)
- Cost: 100 × $0.20 × 30 = $600/month
```

---

## 🚨 **Troubleshooting**

### Error: "Chain not configured"

**Cause:** Chain in `relayChains` but no signer in `chains`

**Solution:** Add signer configuration

### Error: "Route not whitelisted"

**Cause:** Message route not included in whitelist

**Solution:** Add entry to whitelist

### Relayer not processing messages

**Cause:** Wallet has no funds or incorrect permissions

**Solution:**
```bash
# Check balance
# EVM:
cast balance 0xYOUR_ADDRESS --rpc-url RPC_URL

# Cosmos:
curl "LCD_URL/cosmos/bank/v1beta1/balances/ADDRESS"
```

---

## 📚 **References**

- [Hyperlane Domains](https://docs.hyperlane.xyz/docs/reference/domains)
- [Relayer Configuration](https://docs.hyperlane.xyz/docs/operate/relayer/run-relayer)
- [Gas Payment](https://docs.hyperlane.xyz/docs/protocol/interchain-gas-payments)
- [Whitelist Configuration](https://docs.hyperlane.xyz/docs/operate/relayer/configuration#whitelisting)

---

## ✅ **Checklist for New Chain**

- [ ] Chain supported by Hyperlane
- [ ] Domain ID obtained
- [ ] Added to `relayChains`
- [ ] Routes added to `whitelist` (bidirectional)
- [ ] Signer configured (KMS or hexKey)
- [ ] Wallet created and funded
- [ ] Relayer restarted
- [ ] Logs verified
- [ ] Message test performed

---

**🎯 Ready to configure new routes!** 🚀

For more details, see the [official Hyperlane documentation](https://docs.hyperlane.xyz).

