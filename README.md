# 🌉 Hyperlane Validator & Relayer - Terra Classic ↔ BSC

Validador e relayer Hyperlane configurados para Terra Classic ↔ BSC.

---

## ⚠️ **IMPORTANTE: AWS KMS**

| Blockchain | Tipo | Gerenciamento de Chaves | Status |
|------------|------|-------------------------|--------|
| **Terra Classic** | Cosmos | **hexKey** (chaves locais) | ✅ Funcionando |
| **BSC** | EVM | **AWS KMS** | ✅ Suportado |

### ⚠️ **Terra Classic NÃO suporta AWS KMS**

O Hyperlane **não suporta AWS KMS** para blockchains Cosmos. Você **deve usar chaves privadas locais** (hexKey) para Terra Classic.

📖 **Leia**: [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md) para segurança das chaves

---

## 🚀 Quick Start

### **[📘 QUICKSTART.md](QUICKSTART.md) ← Comece aqui!**

Guia passo a passo completo em português com todos os comandos necessários.

### Resumo rápido:

```bash
# 1. Configurar credenciais AWS (apenas para BSC)
cp .env.example .env
nano .env

# 2. Configurar validator (Terra Classic)
cp hyperlane/validator.terraclassic.json.example hyperlane/validator.terraclassic.json
nano hyperlane/validator.terraclassic.json
# Substituir: bucket S3 e chave privada

# 3. Descobrir endereços
pip3 install eth-account bech32
./get-address-from-hexkey.py 0xSUA_CHAVE_PRIVADA

# 4. Enviar LUNC para o endereço Terra
# (100-500 LUNC recomendado)

# 5. Iniciar validator
docker-compose up -d validator-terraclassic
docker logs -f hpl-validator-terraclassic
```

---

## 📚 Documentação

### Guias

| Arquivo | Descrição |
|---------|-----------|
| **[QUICKSTART.md](QUICKSTART.md)** ⭐ | **Guia passo a passo completo** |
| [RELAYER-CONFIG-GUIDE.md](RELAYER-CONFIG-GUIDE.md) 🔄 | **Configurar relayer para outras blockchains** |
| [SECURITY-HEXKEY.md](SECURITY-HEXKEY.md) | Segurança de chaves locais |
| [SETUP-AWS-KMS.md](SETUP-AWS-KMS.md) | Configurar AWS KMS para BSC |
| [DOCKER-VOLUMES-EXPLAINED.md](DOCKER-VOLUMES-EXPLAINED.md) | Explicação dos volumes Docker |
| [CHECKLIST.md](CHECKLIST.md) | Checklist de configuração |

### Scripts

| Script | Uso |
|--------|-----|
| `get-address-from-hexkey.py` | Obter endereços ETH/Terra de chave privada |
| `get-kms-addresses.sh` | Obter endereços de chaves AWS KMS |
| `eth-to-terra.py` | Converter endereço ETH → Terra |

---

## 🏗️ Arquitetura

```
Terra Classic ←→ Hyperlane ←→ BSC
     ↓                           ↓
  Validator                  Relayer
     ↓                           ↓
  hexKey                     AWS KMS (BSC)
     ↓                       hexKey (Terra)
  AWS S3                         ↓
(signatures)              (transações)
```

### Componentes

- **Validator Terra Classic**: Assina checkpoints de mensagens cross-chain
- **Relayer**: Transmite mensagens entre Terra Classic e BSC
- **AWS S3**: Armazena assinaturas do validator (público)
- **AWS KMS**: Gerencia chave BSC do relayer (apenas para BSC)

---

## 🔑 Gerenciamento de Chaves

### Terra Classic (Cosmos)

```json
// ✅ CORRETO - hexKey
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
// ✅ CORRETO - AWS KMS
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

## 🐳 Comandos Docker

### Validator

```bash
# Iniciar
docker-compose up -d validator-terraclassic

# Ver logs
docker logs -f hpl-validator-terraclassic

# Parar
docker-compose stop validator-terraclassic

# Reiniciar
docker-compose restart validator-terraclassic

# Status
docker ps | grep validator
```

### Relayer

```bash
# Iniciar
docker-compose up -d relayer

# Ver logs
docker logs -f hpl-relayer

# Parar
docker-compose stop relayer

# Reiniciar
docker-compose restart relayer
```

### Todos os Serviços

```bash
# Iniciar tudo
docker-compose up -d

# Parar tudo
docker-compose down

# Ver status
docker ps

# Limpar e reiniciar
docker-compose down -v
docker-compose up -d
```

---

## 📊 Monitoramento

### APIs de Métricas

- **Validator**: http://localhost:9121/metrics
- **Relayer**: http://localhost:9110/metrics

### Verificar Saldo

```bash
# Terra Classic
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/SEU_ENDERECO_TERRA" | jq

# BSC (se usando KMS)
cast balance 0xSEU_ENDERECO_BSC --rpc-url https://bsc.drpc.org
```

### Verificar Checkpoints no S3

```bash
# Listar checkpoints
aws s3 ls s3://SEU-BUCKET/us-east-1/ --recursive

# Ver último checkpoint
aws s3 ls s3://SEU-BUCKET/us-east-1/ --recursive | tail -1
```

---

## 🌐 Redes

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

### Container não inicia

```bash
# Ver erro completo
docker logs hpl-validator-terraclassic

# Reiniciar
docker-compose restart validator-terraclassic

# Limpar e recomeçar
docker-compose down
docker rm -f hpl-validator-terraclassic
docker-compose up -d validator-terraclassic
```

### "Cannot announce validator without a signer"

**Causa**: Carteira sem fundos LUNC

**Solução**:
1. Descobrir endereço: `./get-address-from-hexkey.py 0xSUA_CHAVE`
2. Enviar 100-500 LUNC para o endereço Terra
3. Reiniciar: `docker-compose restart validator-terraclassic`

### "Expected key `key` to be defined"

**Causa**: Tentando usar AWS KMS para Terra Classic (não suportado)

**Solução**: Ver [`QUICKSTART.md`](QUICKSTART.md) para configuração correta com hexKey

### Permission denied

```bash
# Ajustar permissões
chmod 600 hyperlane/validator.terraclassic.json
chmod 600 hyperlane/relayer.json
```

### Rate limit (429 Too Many Requests)

**Causa**: RPCs públicos têm limites

**Solução**: Aguardar. O validator usa múltiplos RPCs como fallback.

---

## 🔐 Segurança

### ⚠️ Arquivos Confidenciais

Estes arquivos **NÃO** devem ser commitados no Git:

- `.env` - Credenciais AWS
- `hyperlane/validator.terraclassic.json` - Chave privada Terra
- `hyperlane/relayer.json` - Chaves privadas
- `validator/` - Dados do validator
- `relayer/` - Dados do relayer

✅ **Todos já estão no `.gitignore`**

### Proteções Implementadas

```bash
# Permissões restritas (apenas owner pode ler)
-rw------- (600) validator.terraclassic.json
-rw------- (600) relayer.json

# Verificar
chmod 600 hyperlane/validator.terraclassic.json
chmod 600 hyperlane/relayer.json
```

### Backup

**IMPORTANTE**: Faça backup das chaves privadas em local seguro!

Ver [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md) para guia completo de backup.

---

## 🛠️ Requisitos

### Software Necessário

- **Docker & Docker Compose** (obrigatório)
- **Python 3.8+** (obrigatório)
- **Foundry (cast)** (opcional, para gerar chaves)
- **AWS CLI** (opcional, para gerenciar S3)

### Instalação

```bash
# Docker
curl -fsSL https://get.docker.com | sh

# Python packages
pip3 install eth-account bech32

# Foundry (opcional)
curl -L https://foundry.paradigm.xyz | bash && foundryup

# AWS CLI (opcional)
pip3 install awscli
```

---

## 📁 Estrutura do Projeto

```
hyperlane-validator/
├── docker-compose.yml                 # Configuração Docker
├── .env                               # Credenciais AWS (não commitado)
├── .env.example                       # Template
├── .gitignore                         # Arquivos ignorados
├── README.md                          # Este arquivo
├── QUICKSTART.md                      # ⭐ Guia passo a passo
├── SECURITY-HEXKEY.md                 # Guia de segurança
├── SETUP-AWS-KMS.md                   # Setup AWS
├── get-address-from-hexkey.py         # Script: obter endereços
├── get-kms-addresses.sh               # Script: endereços KMS
├── eth-to-terra.py                    # Script: converter endereços
├── hyperlane/
│   ├── agent-config.docker.json       # Config das chains
│   ├── validator.terraclassic.json    # Config validator (local)
│   ├── validator.terraclassic.json.example  # Template
│   ├── relayer.json                   # Config relayer (local)
│   └── relayer.json.example           # Template
├── validator/                          # Dados validator (local)
└── relayer/                            # Dados relayer (local)
```

---

## 📞 Recursos

- [Documentação Hyperlane](https://docs.hyperlane.xyz)
- [Hyperlane Discord](https://discord.gg/hyperlane)
- [Terra Classic Docs](https://docs.terra.money)
- [AWS KMS Guide](https://docs.aws.amazon.com/kms/)

---

## ✅ Status do Projeto

**Configurado em**: 26 Nov 2025  
**Validator**: ✅ Funcionando (hexKey)  
**Relayer**: ⏳ Opcional (configurar BSC KMS)  
**Redes**: Terra Classic ↔ BSC  

---

**🎉 Comece agora:** [`QUICKSTART.md`](QUICKSTART.md)
