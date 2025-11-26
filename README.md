# 🌉 Hyperlane Validator & Relayer - Terra Classic ↔ BSC

Configuração completa de validador e relayer Hyperlane para Terra Classic ↔ BSC.

## ⚠️ **IMPORTANTE: Gerenciamento de Chaves**

- **Terra Classic (Cosmos)**: Usa **hexKey** (chaves privadas locais)
  - AWS KMS **NÃO é suportado** para chains Cosmos
- **BSC (EVM)**: Usa **AWS KMS** (recomendado para produção)

📖 **Leia**: [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md) para detalhes completos de segurança

## 🚀 Quick Start

### 1. Configurar Credenciais

```bash
# Copiar template
cp .env.example .env

# Editar com suas credenciais AWS (para BSC)
nano .env
```

### 2. Configurar Chaves

#### Para Terra Classic (hexKey):

```bash
# Gerar nova chave (Foundry)
cast wallet new

# Ou usar chave existente
# Editar hyperlane/validator.terraclassic.json
# Editar hyperlane/relayer.json

# Descobrir endereços da chave
./get-address-from-hexkey.py 0xSUA_CHAVE_PRIVADA
```

#### Para BSC (AWS KMS):

```bash
# Descobrir endereços KMS
./get-kms-addresses.sh
```

### 3. Financiar Carteiras

- **Validador/Relayer Terra**: Envie 100-500 LUNC
- **Relayer BSC**: Envie 0.1-0.5 BNB

### 4. Iniciar Serviços

```bash
# Iniciar validador
docker-compose up -d validator-terraclassic

# Ver logs
docker logs -f hpl-validator-terraclassic

# Iniciar relayer (após criar chave KMS para BSC)
docker-compose up -d relayer
```

### 3. Financiar Carteiras

- **Terra Classic**: Envie 100-500 LUNC para o endereço Terra
- **BSC**: Envie 0.1-0.5 BNB para o endereço BSC (KMS)

### 4. Iniciar Serviços

```bash
# Iniciar validador
docker-compose up -d validator-terraclassic

# Ver logs
docker logs -f hpl-validator-terraclassic

# Aguardar announcement bem-sucedido
# Procurar por: "Successfully announced validator"

# Iniciar relayer (opcional)
docker-compose up -d relayer
```

## 📚 Documentação

### 🔐 Segurança

- **[SECURITY-HEXKEY.md](SECURITY-HEXKEY.md)** - Guia completo de segurança para chaves locais
  - Por que AWS KMS não funciona para Cosmos
  - Medidas de segurança implementadas
  - Backup e recuperação de chaves
  - Monitoramento e alertas

### Guias Principais

- **[SETUP-AWS-KMS.md](SETUP-AWS-KMS.md)** - Configuração completa do validador e relayer
- **[TRANSFER-GUIDE.md](TRANSFER-GUIDE.md)** - Como transferir/sacar LUNC usando AWS KMS
- **[TERRAD-KMS-GUIDE.md](TERRAD-KMS-GUIDE.md)** - Guia completo do terrad CLI + AWS KMS
- **[CHECKLIST.md](CHECKLIST.md)** - Checklist interativo de configuração
- **[.env.example](.env.example)** - Template de configuração

### Scripts Utilitários

- **`get-kms-addresses.sh`** - Descobre endereços das chaves KMS
- **`eth-to-terra.py`** - Converte endereços Ethereum → Terra bech32
- **`transfer-lunc-kms.py`** - Transfere LUNC usando AWS KMS (Python)
- **`terrad-kms-transfer.sh`** - Integração terrad CLI + AWS KMS

## 🏗️ Arquitetura

```
Terra Classic ←→ Hyperlane ←→ BSC
      ↓                            ↓
   Validador                   Relayer
      ↓                            ↓
  AWS KMS                      AWS KMS
      ↓                            ↓
   AWS S3                     (signatures)
```

### Componentes

- **Validador Terra Classic**: Assina checkpoints de mensagens
- **Relayer**: Transmite mensagens entre chains
- **AWS KMS**: Gerencia chaves privadas com segurança
- **AWS S3**: Armazena assinaturas do validador

## 🔑 Chaves KMS Necessárias

| Alias | Uso | Status |
|-------|-----|--------|
| `hyperlane-validator-signer-terraclassic` | Validador + Relayer Terra | ✅ Criada |
| `hyperlane-relayer-signer-bsc` | Relayer BSC | ⏳ Pendente |

**Configuração da chave:**
- Tipo: **Asymmetric**
- Uso: **Sign and verify**
- Spec: **ECC_SECG_P256K1**

## 🌐 Redes Configuradas

### Terra Classic
- Chain ID: `columbus-5`
- RPC: `https://rpc.terra-classic.hexxagon.io:443`
- LCD: `https://terra-classic-lcd.publicnode.com`
- Explorer: https://finder.terraclassic.community

### Binance Smart Chain
- Chain ID: `56`
- RPC: `https://bsc.drpc.org`
- Explorer: https://bscscan.com

## 📊 Monitoramento

### Métricas

- **Validador**: http://localhost:9121
- **Relayer**: http://localhost:9110

### Comandos Úteis

```bash
# Ver logs do validador
docker logs hpl-validator-terraclassic --tail 100 -f

# Ver logs do relayer
docker logs hpl-relayer --tail 100 -f

# Verificar saldo Terra
terrad query bank balances ENDERECO_TERRA \
  --node https://rpc.terra-classic.hexxagon.io:443

# Verificar saldo BSC
cast balance ENDERECO_BSC --rpc-url https://bsc.drpc.org

# Ver assinaturas no S3
aws s3 ls s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/
```

## 💸 Transferir Fundos

### Para BSC (BNB)

```bash
cast send ENDERECO_DESTINO \
  --value 0.1ether \
  --aws alias/hyperlane-relayer-signer-bsc \
  --rpc-url https://bsc.drpc.org
```

### Para Terra Classic (LUNC)

**Método 1: Script Python (Recomendado)**
```bash
# Instalar dependências
pip3 install boto3 bech32 ecdsa requests

# Transferir 10 LUNC (10,000,000 uluna)
./transfer-lunc-kms.py terra1destinatario... 10000000 "Saque"
```

**Método 2: terrad CLI**
```bash
# Instalar terrad
wget https://github.com/classic-terra/core/releases/download/v2.3.1/terra_2.3.1_Linux_x86_64.tar.gz
tar -xzf terra_2.3.1_Linux_x86_64.tar.gz
sudo mv terrad /usr/local/bin/

# Consultar saldo
terrad query bank balances terra1abc... --node https://rpc.terra-classic.hexxagon.io:443

# Ver guia completo do terrad
cat TERRAD-KMS-GUIDE.md
```

**📖 Guias completos:** 
- [TRANSFER-GUIDE.md](TRANSFER-GUIDE.md) - Transferências com Python
- [TERRAD-KMS-GUIDE.md](TERRAD-KMS-GUIDE.md) - Usando terrad CLI

## 🔐 Segurança

### Arquivos Protegidos (`.gitignore`)

- `.env` - Credenciais AWS (nunca commitado)
- `validator/` - Dados do validador
- `relayer/` - Dados do relayer

### Boas Práticas

✅ Credenciais apenas no arquivo `.env`  
✅ Chaves privadas gerenciadas pelo AWS KMS  
✅ Assinaturas públicas no S3  
✅ Logs monitorados regularmente  

## 🛠️ Requisitos

### Software

- Docker & Docker Compose
- Python 3.8+
- Foundry (cast)
- AWS CLI (opcional)

### Instalação

```bash
# Docker
curl -fsSL https://get.docker.com | sh

# Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Python packages
pip3 install boto3 bech32 ecdsa requests
```

## 📁 Estrutura do Projeto

```
hyperlane-validator/
├── docker-compose.yml              # Configuração dos containers
├── .env                            # Credenciais AWS (não commitado)
├── .env.example                    # Template de credenciais
├── .gitignore                      # Arquivos ignorados
├── README.md                       # Este arquivo
├── SETUP-AWS-KMS.md               # Guia de configuração
├── TRANSFER-GUIDE.md              # Guia de transferências
├── get-kms-addresses.sh           # Script: descobrir endereços
├── eth-to-terra.py                # Script: converter endereços
├── transfer-lunc-kms.py           # Script: transferir LUNC
├── hyperlane/
│   ├── agent-config.docker.json   # Configuração das chains
│   ├── validator.terraclassic.json # Config do validador
│   └── relayer.json               # Config do relayer
├── validator/                      # Dados do validador (local)
└── relayer/                        # Dados do relayer (local)
```

## 🐛 Solução de Problemas

### Container não inicia

```bash
# Ver logs completos
docker logs hpl-validator-terraclassic

# Reiniciar do zero
docker-compose down -v
docker-compose up -d
```

### Erro de credenciais AWS

```bash
# Verificar .env
cat .env

# Recarregar variáveis
export $(cat .env | grep -v '^#' | xargs)
```

### Saldo insuficiente

```bash
# Verificar saldo
./get-kms-addresses.sh

# Enviar mais fundos para as carteiras
```

## 📞 Recursos

- [Documentação Hyperlane](https://docs.hyperlane.xyz)
- [Hyperlane Discord](https://discord.gg/hyperlane)
- [Terra Classic Docs](https://docs.terra.money)
- [AWS KMS Guide](https://docs.aws.amazon.com/kms/)

## 📝 Licença

Este projeto é uma configuração para uso com Hyperlane. Consulte a [licença do Hyperlane](https://github.com/hyperlane-xyz/hyperlane-monorepo) para mais detalhes.

## 🤝 Contribuindo

Melhorias e sugestões são bem-vindas! Abra uma issue ou pull request.

---

**✅ Configurado em:** 26 Nov 2025  
**🔐 Método:** AWS KMS + S3  
**🌐 Redes:** Terra Classic ↔ BSC  
**👤 Operador:** igorv43

