# 🔄 Guia de Configuração do Relayer

## 📋 **O Que é o Relayer?**

O **Relayer** é o componente que **transmite mensagens** entre blockchains diferentes. Ele lê mensagens de uma chain origem e as entrega na chain destino.

### Fluxo de Mensagens:

```
Chain A (origem)  →  Hyperlane Relayer  →  Chain B (destino)
     ↓                       ↓                     ↓
  Envia msg            Lê e valida            Entrega msg
```

---

## 🔑 **Campos Principais do relayer.json**

### 1. `relayChains`

**Define quais chains o relayer irá monitorar.**

```json
"relayChains": "terraclassic,bsc"
```

**Formato:** Lista separada por vírgulas, sem espaços.

**Exemplos:**

```json
// Apenas Terra Classic e BSC
"relayChains": "terraclassic,bsc"

// Adicionar Ethereum
"relayChains": "terraclassic,bsc,ethereum"

// Adicionar Polygon e Avalanche
"relayChains": "terraclassic,bsc,ethereum,polygon,avalanche"

// Todas as chains suportadas
"relayChains": "*"
```

---

### 2. `whitelist`

**Define quais rotas de mensagens são permitidas.**

Cada rota especifica:
- **`originDomain`**: Chain de origem (de onde a mensagem vem)
- **`destinationDomain`**: Chain de destino (para onde a mensagem vai)

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

**⚠️ IMPORTANTE:** 
- Você precisa de **2 entradas** para comunicação bidirecional (A→B e B→A)
- Sem whitelist, o relayer processa **todas** as mensagens (alto custo de gas!)

---

## 📊 **Domain IDs das Blockchains**

| Blockchain | Domain ID | Tipo | KMS Suportado? |
|------------|-----------|------|----------------|
| **Terra Classic** | 1325 | Cosmos | ❌ Não (usar hexKey) |
| **BSC** | 56 | EVM | ✅ Sim |
| **Ethereum** | 1 | EVM | ✅ Sim |
| **Polygon** | 137 | EVM | ✅ Sim |
| **Avalanche** | 43114 | EVM | ✅ Sim |
| **Arbitrum** | 42161 | EVM | ✅ Sim |
| **Optimism** | 10 | EVM | ✅ Sim |
| **Gnosis** | 100 | EVM | ✅ Sim |
| **Moonbeam** | 1284 | EVM | ✅ Sim |
| **Celo** | 42220 | EVM | ✅ Sim |

**Referência completa:** https://docs.hyperlane.xyz/docs/reference/domains

---

## 📝 **Exemplos de Configuração**

### Exemplo 1: Terra Classic ↔ BSC (Atual)

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

### Exemplo 2: Terra Classic ↔ Ethereum

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

### Exemplo 3: Terra Classic ↔ BSC + Ethereum (3 chains)

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
    // BSC ↔ Ethereum (se necessário)
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

### Exemplo 4: Múltiplas Chains EVM (sem Cosmos)

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

### Exemplo 5: Todas as Chains (Sem Whitelist)

**⚠️ Cuidado:** Alto custo de gas!

```json
{
  "relayChains": "*",
  "whitelist": null,  // Sem restrição - processa TODAS as mensagens
  "chains": {
    // Configurar TODAS as chains aqui
    // Cada chain precisa de um signer
  }
}
```

---

### Exemplo 6: Whitelist com Múltiplos Destinos

Uma origem pode enviar para múltiplos destinos:

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
    // ... outras rotas
  ]
}
```

---

## 🔧 **Configurar Signers para Cada Chain**

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

**Exemplo BSC:**
```json
"bsc": {
  "signer": {
    "type": "aws",
    "id": "alias/hyperlane-relayer-signer-bsc",
    "region": "us-east-1"
  }
}
```

### Cosmos Chains (hexKey) ❌

```json
"chainName": {
  "signer": {
    "type": "cosmosKey",
    "key": "0xSUA_CHAVE_PRIVADA",
    "prefix": "PREFIXO"
  }
}
```

**Exemplo Terra Classic:**
```json
"terraclassic": {
  "signer": {
    "type": "cosmosKey",
    "key": "0xe45624f7aca7eb9e964eddbfbdb230a369a6dcc26d508778ae8dfc928bafe6c9",
    "prefix": "terra"
  }
}
```

**Outros Cosmos chains:**
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

## 💰 **Financiar Carteiras**

Cada chain precisa de **fundos para gas**:

### EVM Chains (AWS KMS):

```bash
# Descobrir endereço
cast wallet address --aws alias/hyperlane-relayer-signer-CHAINNAME

# Ou usar script
./get-kms-addresses.sh
```

**Quantidades recomendadas:**
- **Ethereum**: 0.5-1 ETH
- **BSC**: 0.5-1 BNB
- **Polygon**: 100-500 MATIC
- **Avalanche**: 5-10 AVAX
- **Arbitrum**: 0.1-0.5 ETH

### Cosmos Chains (hexKey):

```bash
# Descobrir endereço
./get-address-from-hexkey.py 0xSUA_CHAVE_PRIVADA
```

**Quantidades recomendadas:**
- **Terra Classic**: 500-1000 LUNC
- **Osmosis**: 10-50 OSMO

---

## 📊 **Calcular Número de Rotas**

Para **N chains**, com comunicação bidirecional:

```
Número de rotas = N × (N - 1)
```

**Exemplos:**
- 2 chains (Terra + BSC): 2 × 1 = **2 rotas**
- 3 chains: 3 × 2 = **6 rotas**
- 4 chains: 4 × 3 = **12 rotas**
- 5 chains: 5 × 4 = **20 rotas**

**Fórmula JSON:**
```json
// Para N chains, precisa de N×(N-1) entradas na whitelist
```

---

## 🚀 **Passos para Adicionar Nova Chain**

### 1. Verificar Se Chain é Suportada

Consultar: https://docs.hyperlane.xyz/docs/reference/domains

### 2. Adicionar à `relayChains`

```json
"relayChains": "terraclassic,bsc,NOVA_CHAIN"
```

### 3. Adicionar ao `whitelist`

```json
{
  "originDomain": [1325],           // Terra
  "destinationDomain": [DOMAIN_ID]  // Nova chain
},
{
  "originDomain": [DOMAIN_ID],      // Nova chain
  "destinationDomain": [1325]       // Terra
}
```

### 4. Configurar Signer

**Se EVM:**
```bash
# Criar chave KMS
# Ver: SETUP-AWS-KMS.md - Passo 3

# Adicionar ao relayer.json:
"nova_chain": {
  "signer": {
    "type": "aws",
    "id": "alias/hyperlane-relayer-signer-nova-chain",
    "region": "us-east-1"
  }
}
```

**Se Cosmos:**
```json
"nova_chain": {
  "signer": {
    "type": "cosmosKey",
    "key": "0x...",
    "prefix": "prefixo"
  }
}
```

### 5. Financiar Carteira

```bash
# Obter endereço e enviar fundos
```

### 6. Reiniciar Relayer

```bash
docker-compose restart relayer
docker logs -f hpl-relayer
```

---

## 🛠️ **Testar Configuração**

### Validar JSON

```bash
# Testar sintaxe JSON
cat hyperlane/relayer.json | python3 -m json.tool
```

### Ver Logs

```bash
# Ver inicialização
docker logs hpl-relayer --tail 100

# Monitorar em tempo real
docker logs -f hpl-relayer

# Procurar por erros
docker logs hpl-relayer 2>&1 | grep -i error
```

### Verificar Rotas Ativas

```bash
# O relayer mostra rotas configuradas ao iniciar
docker logs hpl-relayer | grep -i "whitelist\|route"
```

---

## 📈 **Custos Estimados**

### Por Mensagem (Gas):

| Chain | Custo por Mensagem | Moeda |
|-------|-------------------|-------|
| Ethereum | $5-$50 | ETH |
| BSC | $0.10-$1 | BNB |
| Polygon | $0.01-$0.10 | MATIC |
| Avalanche | $0.10-$1 | AVAX |
| Terra Classic | $0.001-$0.01 | LUNC |

### Por Mês (Estimativa):

```
Custo mensal = (Mensagens/dia) × (Custo/mensagem) × 30 dias

Exemplo:
- 100 mensagens/dia
- Terra → BSC ($0.20/msg)
- Custo: 100 × $0.20 × 30 = $600/mês
```

---

## 🚨 **Troubleshooting**

### Erro: "Chain not configured"

**Causa:** Chain em `relayChains` mas sem signer em `chains`

**Solução:** Adicionar configuração do signer

### Erro: "Route not whitelisted"

**Causa:** Mensagem de rota não incluída no whitelist

**Solução:** Adicionar entrada no whitelist

### Relayer não processa mensagens

**Causa:** Carteira sem fundos ou permissões incorretas

**Solução:**
```bash
# Verificar saldo
# EVM:
cast balance 0xSEU_ENDERECO --rpc-url RPC_URL

# Cosmos:
curl "LCD_URL/cosmos/bank/v1beta1/balances/ENDERECO"
```

---

## 📚 **Referências**

- [Hyperlane Domains](https://docs.hyperlane.xyz/docs/reference/domains)
- [Relayer Configuration](https://docs.hyperlane.xyz/docs/operate/relayer/run-relayer)
- [Gas Payment](https://docs.hyperlane.xyz/docs/protocol/interchain-gas-payments)
- [Whitelist Configuration](https://docs.hyperlane.xyz/docs/operate/relayer/configuration#whitelisting)

---

## ✅ **Checklist para Nova Chain**

- [ ] Chain suportada pelo Hyperlane
- [ ] Domain ID obtido
- [ ] Adicionada a `relayChains`
- [ ] Rotas adicionadas ao `whitelist` (bidirecional)
- [ ] Signer configurado (KMS ou hexKey)
- [ ] Carteira criada e financiada
- [ ] Relayer reiniciado
- [ ] Logs verificados
- [ ] Teste de mensagem realizado

---

**🎯 Pronto para configurar novas rotas!** 🚀

Para mais detalhes, consulte a [documentação oficial do Hyperlane](https://docs.hyperlane.xyz).

