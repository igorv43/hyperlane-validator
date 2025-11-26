# 🚀 Guia Rápido - Hyperlane Validator & Relayer

## ⚡ Quick Start em 5 Passos

### 📋 Pré-requisitos

- Docker & Docker Compose instalados
- Conta AWS com KMS e S3 configurados (apenas para BSC)
- Chave privada para Terra Classic (hexadecimal)

---

## 🔧 PASSO 1: Configurar Credenciais AWS

Apenas necessário se for usar **BSC** (o relayer).

```bash
# 1. Copiar template
cp .env.example .env

# 2. Editar com suas credenciais
nano .env
```

**Conteúdo do `.env`:**
```bash
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

---

## 🔑 PASSO 2: Configurar Chaves

### ⚠️ **IMPORTANTE: Terra Classic NÃO suporta AWS KMS**

Terra Classic é uma blockchain **Cosmos**, e o Hyperlane **não suporta AWS KMS** para Cosmos. Você deve usar **chaves privadas locais (hexKey)**.

### Opção A: Gerar Nova Chave

```bash
# Instalar Foundry (se não tiver)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Gerar nova carteira
cast wallet new

# Salvar a chave privada mostrada
```

### Opção B: Usar Chave Existente

Se já tem uma chave privada, pule para o próximo passo.

### Descobrir Endereços da Chave

```bash
# Instalar dependências
pip3 install eth-account bech32

# Obter endereços
./get-address-from-hexkey.py 0xSUA_CHAVE_PRIVADA
```

**Exemplo de saída:**
```
Ethereum: 0x6109b140b7165a4584e4ab09a93ccfb2d7be6b0f
Terra:    terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
```

---

## 📝 PASSO 3: Configurar Arquivos

### 3.1 Validator (Terra Classic)

```bash
# Copiar template
cp hyperlane/validator.terraclassic.json.example hyperlane/validator.terraclassic.json

# Editar
nano hyperlane/validator.terraclassic.json
```

**Substituir:**
- `YOUR-BUCKET-NAME` → Nome do seu bucket S3
- `0xYOUR_PRIVATE_KEY_HERE` → Sua chave privada (ambos os lugares)

**Exemplo:**
```json
{
  "db": "/etc/data/db",
  "checkpointSyncer": {
    "type": "s3",
    "bucket": "hyperlane-validator-signatures-meu-bucket",
    "region": "us-east-1"
  },
  "originChainName": "terraclassic",
  "validator": {
    "type": "hexKey",
    "key": "0xe45624f7aca7eb9e964eddbfbdb230a369a6dcc26d508778ae8dfc928bafe6c9"
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xe45624f7aca7eb9e964eddbfbdb230a369a6dcc26d508778ae8dfc928bafe6c9",
        "prefix": "terra"
      }
    }
  }
}
```

**Proteger arquivo:**
```bash
chmod 600 hyperlane/validator.terraclassic.json
```

### 3.2 Relayer (Opcional)

Se for rodar o relayer:

```bash
# Copiar template
cp hyperlane/relayer.json.example hyperlane/relayer.json

# Editar
nano hyperlane/relayer.json
```

**Substituir:**
- Para **Terra Classic**: `0xYOUR_PRIVATE_KEY_HERE` → Sua chave privada
- Para **BSC**: Manter AWS KMS ou criar chave KMS primeiro

**Proteger arquivo:**
```bash
chmod 600 hyperlane/relayer.json
```

---

## 💰 PASSO 4: Financiar Carteiras

### Validator/Relayer Terra Classic

```bash
# Enviar LUNC para o endereço Terra
# Endereço: (obtido no Passo 2)
# Quantidade: 100-500 LUNC

# Verificar saldo
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/SEU_ENDERECO_TERRA"
```

**Ou ver no explorer:**
```
https://finder.terraclassic.community/mainnet/address/SEU_ENDERECO_TERRA
```

### Relayer BSC (Opcional)

Se configurou KMS para BSC:

```bash
# Descobrir endereço
cast wallet address --aws alias/hyperlane-relayer-signer-bsc

# Enviar 0.1-0.5 BNB para esse endereço
```

---

## 🐳 PASSO 5: Executar Docker

### 5.1 Iniciar Validator

```bash
# Subir apenas o validator
docker-compose up -d validator-terraclassic

# Ver logs em tempo real
docker logs -f hpl-validator-terraclassic
```

**Aguardar mensagem:**
```
✅ Successfully announced validator
```

**Parar logs:** `Ctrl+C`

### 5.2 Iniciar Relayer (Opcional)

Apenas se tiver configurado BSC:

```bash
# Subir relayer
docker-compose up -d relayer

# Ver logs
docker logs -f hpl-relayer
```

### 5.3 Comandos Úteis Docker

```bash
# Ver containers rodando
docker ps

# Parar validator
docker-compose stop validator-terraclassic

# Parar tudo
docker-compose down

# Reiniciar validator
docker-compose restart validator-terraclassic

# Ver logs das últimas 100 linhas
docker logs hpl-validator-terraclassic --tail 100

# Limpar e reiniciar (se necessário)
docker-compose down
docker-compose up -d validator-terraclassic
```

---

## ✅ Verificar que Está Funcionando

### Validator

```bash
# 1. Ver logs
docker logs hpl-validator-terraclassic --tail 50

# Procurar por:
# ✅ "Successfully announced validator"
# ✅ "Validator has announced signature storage location"

# 2. Verificar checkpoints no S3 (quando houver mensagens Hyperlane)
aws s3 ls s3://SEU-BUCKET/us-east-1/ --recursive

# 3. Verificar API do validator
curl http://localhost:9121/metrics
```

### Relayer (se estiver rodando)

```bash
# Ver logs
docker logs hpl-relayer --tail 50

# Verificar API
curl http://localhost:9110/metrics
```

---

## 🚨 Troubleshooting

### Erro: "Cannot announce validator without a signer"

**Causa:** Carteira sem fundos LUNC

**Solução:**
```bash
# 1. Obter endereço
./get-address-from-hexkey.py 0xSUA_CHAVE

# 2. Enviar LUNC para o endereço Terra

# 3. Reiniciar
docker-compose restart validator-terraclassic
```

### Erro: "Expected key `key` to be defined"

**Causa:** Tentando usar AWS KMS para Terra Classic (não suportado)

**Solução:** Usar `hexKey` conforme este guia

### Erro: "Permission denied" ao ler arquivos

**Solução:**
```bash
# Ajustar permissões
chmod 600 hyperlane/validator.terraclassic.json
chmod 600 hyperlane/relayer.json
```

### Container não inicia

```bash
# Ver logs completos
docker logs hpl-validator-terraclassic

# Reiniciar do zero
docker-compose down
docker rm -f hpl-validator-terraclassic
docker-compose up -d validator-terraclassic
```

### Rate limit (429 Too Many Requests)

**Causa:** RPCs públicos têm limite de requisições

**Solução:** Aguardar alguns segundos. O validator usa múltiplos RPCs como fallback.

---

## 📊 Monitoramento

### Verificar Status

```bash
# Containers rodando
docker ps

# Uso de recursos
docker stats

# Logs em tempo real
docker logs -f hpl-validator-terraclassic
```

### Verificar Saldo da Carteira

```bash
# Via curl
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/SEU_ENDERECO_TERRA" | jq

# Via explorer
# https://finder.terraclassic.community/mainnet/address/SEU_ENDERECO_TERRA
```

### Alertas de Saldo Baixo

Criar script para monitorar:

```bash
#!/bin/bash
TERRA_ADDR="terra1..."
MIN_BALANCE=10000000  # 10 LUNC em uluna

BALANCE=$(curl -s "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/$TERRA_ADDR" | jq -r '.balances[] | select(.denom=="uluna") | .amount')

if [ "$BALANCE" -lt "$MIN_BALANCE" ]; then
  echo "⚠️ Saldo baixo! $((BALANCE/1000000)) LUNC"
  # Enviar notificação
fi
```

---

## 🔐 Segurança

### ⚠️ IMPORTANTE

1. **Nunca commite** os arquivos com chaves privadas no Git
   - ✅ Já estão no `.gitignore`

2. **Fazer backup** das chaves em local seguro
   - Ver: `SECURITY-HEXKEY.md` para guia completo

3. **Permissões restritas** nos arquivos:
   ```bash
   chmod 600 hyperlane/validator.terraclassic.json
   chmod 600 hyperlane/relayer.json
   ```

4. **Rotação de chaves**: Considerar trocar a cada 3-6 meses

---

## 📚 Documentação Completa

Para mais detalhes:

- **`SECURITY-HEXKEY.md`** - Segurança e backup de chaves
- **`SETUP-AWS-KMS.md`** - Configurar AWS KMS para BSC
- **`DOCKER-VOLUMES-EXPLAINED.md`** - Entender volumes Docker
- **`README.md`** - Visão geral completa

---

## 🆘 Precisa de Ajuda?

1. Verificar logs: `docker logs hpl-validator-terraclassic`
2. Consultar `SECURITY-HEXKEY.md` para questões de segurança
3. Verificar issues no GitHub Hyperlane

---

## ✅ Checklist

- [ ] AWS credenciais configuradas (`.env`) - **apenas para BSC**
- [ ] Chave privada gerada ou obtida
- [ ] Endereços descobertos (ETH + Terra)
- [ ] Arquivos configurados (`validator.terraclassic.json`)
- [ ] Permissões corretas (600)
- [ ] Carteira financiada com LUNC
- [ ] Validator rodando (`docker ps`)
- [ ] Announcement bem-sucedido (logs)
- [ ] Backup das chaves feito

---

**🎉 Pronto! Seu validator está rodando!**

Para rodar o relayer, siga os mesmos passos mas inicie com:
```bash
docker-compose up -d relayer
```

