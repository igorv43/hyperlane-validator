# 🔐 Segurança: Chaves Hexadecimais Locais

## ⚠️ **IMPORTANTE: Limitação AWS KMS para Cosmos**

**AWS KMS NÃO é suportado** para blockchains Cosmos (incluindo Terra Classic) no Hyperlane validator/relayer.

### Por Quê?

O parser do Hyperlane (`hyperlane-base`) **não aceita** a configuração AWS KMS para signers do tipo `cosmosKey`:

```json
// ❌ NÃO FUNCIONA para Cosmos
"chains": {
  "terraclassic": {
    "signer": {
      "type": "cosmosKey",
      "aws": { ... }  // ❌ Parser exige campo "key"
    }
  }
}
```

**Solução:** Usar chaves hexadecimais locais (`hexKey`)

---

## 📋 **Configuração Atual**

### Validator (`validator.terraclassic.json`)

```json
{
  "originChainName": "terraclassic",
  "validator": {
    "type": "hexKey",
    "key": "0x..."  // ← Chave privada local
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0x...",  // ← Mesma chave
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
        "type": "aws",  // ✅ AWS KMS funciona para EVM chains
        "id": "alias/hyperlane-relayer-signer-bsc"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0x...",  // ← Chave privada local
        "prefix": "terra"
      }
    }
  }
}
```

---

## 🔒 **Medidas de Segurança Implementadas**

### 1. Permissões de Arquivo

```bash
# Permissões restritas (apenas owner pode ler/escrever)
-rw------- (600) validator.terraclassic.json
-rw------- (600) relayer.json
```

**Comando:**
```bash
chmod 600 hyperlane/validator.terraclassic.json
chmod 600 hyperlane/relayer.json
```

### 2. Git Ignore

Os arquivos com chaves estão **excluídos do Git**:

```gitignore
# Arquivos de configuração com chaves privadas
hyperlane/validator.*.json
hyperlane/relayer.json
```

**Verificar:**
```bash
git check-ignore hyperlane/validator.terraclassic.json
# Deve retornar: hyperlane/validator.terraclassic.json
```

### 3. Arquivos de Exemplo

Criados arquivos `.example` (sem chaves reais) para documentação:
- `validator.terraclassic.json.example`
- `relayer.json.example`

---

## 📝 **Como Obter o Endereço da Carteira**

### Método 1: Via `cast` (Foundry)

```bash
# Instalar Foundry (se não tiver)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Obter endereço Ethereum
cast wallet address --private-key "0xSUA_CHAVE_PRIVADA"

# Converter para Terra
./eth-to-terra.py "0xENDERECO_ETH"
```

### Método 2: Via Python

```python
#!/usr/bin/env python3
from eth_account import Account
import bech32

# Sua chave privada
private_key = "0xe45624f7aca7eb9e...."

# Obter endereço ETH
account = Account.from_key(private_key)
eth_address = account.address
print(f"Ethereum: {eth_address}")

# Converter para Terra
addr_bytes = bytes.fromhex(eth_address[2:])
five_bit = bech32.convertbits(addr_bytes, 8, 5)
terra_address = bech32.bech32_encode('terra', five_bit)
print(f"Terra:    {terra_address}")
```

**Resultado:**
```
Ethereum: 0x6109b140b7165a4584e4ab09a93ccfb2d7be6b0f
Terra:    terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
```

---

## 💰 **Enviar Fundos para a Carteira**

### Para Validator (Announcement)

```bash
# Endereço Terra
terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7

# Quantidade recomendada
50-100 LUNC (50,000,000 - 100,000,000 uluna)

# Propósito
Gas para announcement + validação
```

### Para Relayer (Transações)

```bash
# Mesma carteira (Terra)
terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7

# Quantidade recomendada
1000-5000 LUNC (dependendo do volume de mensagens)

# Propósito
Gas para relaying de mensagens
```

---

## 🔄 **Backup das Chaves**

### ⚠️ **CRÍTICO: Faça Backup Seguro**

```bash
# 1. Criar diretório seguro de backup
mkdir -p ~/hyperlane-backup-CONFIDENCIAL
chmod 700 ~/hyperlane-backup-CONFIDENCIAL

# 2. Copiar arquivos de configuração
cp hyperlane/validator.terraclassic.json ~/hyperlane-backup-CONFIDENCIAL/
cp hyperlane/relayer.json ~/hyperlane-backup-CONFIDENCIAL/
cp .env ~/hyperlane-backup-CONFIDENCIAL/

# 3. Criar arquivo com chaves privadas
cat > ~/hyperlane-backup-CONFIDENCIAL/KEYS.txt << 'EOF'
TERRA CLASSIC PRIVATE KEY:
0xSUA_CHAVE_PRIVADA_AQUI

ETHEREUM ADDRESS (derivado):
0xSEU_ENDERECO_ETH_AQUI

TERRA ADDRESS (derivado):
terra1SEU_ENDERECO_TERRA_AQUI

AWS ACCESS KEY ID:
AKIAXXXXXXXXXXXXXXXXXXXX

AWS SECRET ACCESS KEY:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

S3 BUCKET:
hyperlane-validator-signatures-NOME-DO-SEU-BUCKET
EOF

# 4. Proteger arquivo
chmod 400 ~/hyperlane-backup-CONFIDENCIAL/KEYS.txt

# 5. Criar backup criptografado (opcional mas recomendado)
tar czf - ~/hyperlane-backup-CONFIDENCIAL | \
  gpg --symmetric --cipher-algo AES256 -o ~/hyperlane-backup-$(date +%Y%m%d).tar.gz.gpg

# 6. Guardar em local seguro
# - USB criptografado
# - Password manager (1Password, Bitwarden)
# - Cloud storage criptografado (Cryptomator + Dropbox)
```

---

## 🚨 **Em Caso de Comprometimento**

### Se a Chave For Exposta:

1. **Parar Imediatamente:**
   ```bash
   docker-compose down
   ```

2. **Transferir Fundos:**
   ```bash
   # Usar script de transferência para mover fundos para nova carteira
   ./transfer-lunc-kms.py terra1NOVA_CARTEIRA 99900000
   ```

3. **Gerar Nova Chave:**
   ```bash
   cast wallet new
   # Salvar nova chave com segurança
   ```

4. **Atualizar Configurações:**
   ```bash
   # Editar validator.terraclassic.json
   # Editar relayer.json
   # Atualizar com nova chave
   ```

5. **Reconfigurar AWS S3:**
   - Se necessário, criar novo bucket
   - Atualizar políticas de acesso

6. **Reiniciar Serviços:**
   ```bash
   docker-compose up -d
   ```

---

## 📊 **Monitoramento**

### Verificar Saldo

```bash
# Via curl
curl -s "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7" | jq

# Via explorer
https://finder.terraclassic.community/mainnet/address/terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7
```

### Alertas de Saldo Baixo

```bash
# Script de monitoramento (executar via cron)
#!/bin/bash
TERRA_ADDR="terra1j0paqg235l7fhjkez8z55kg83snant95jqq0z7"
MIN_BALANCE=10000000  # 10 LUNC

BALANCE=$(curl -s "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/$TERRA_ADDR" | jq -r '.balances[] | select(.denom=="uluna") | .amount')

if [ "$BALANCE" -lt "$MIN_BALANCE" ]; then
  echo "⚠️ ALERTA: Saldo baixo! $((BALANCE/1000000)) LUNC"
  # Enviar notificação (email, telegram, etc)
fi
```

---

## 🔐 **Melhores Práticas**

1. **Nunca Compartilhe:**
   - ❌ Não envie chaves por email
   - ❌ Não poste em chat/slack
   - ❌ Não commit no Git

2. **Rotação de Chaves:**
   - 🔄 Considere trocar chaves a cada 3-6 meses
   - 🔄 Após qualquer suspeita de comprometimento

3. **Ambiente de Produção:**
   - 🔒 Use servidor dedicado (não compartilhado)
   - 🔒 Firewall configurado
   - 🔒 Acesso SSH apenas por chave
   - 🔒 Atualizações de segurança automáticas

4. **Backup Redundante:**
   - 💾 Mínimo 3 cópias
   - 💾 Em locais diferentes
   - 💾 Pelo menos 1 offline

5. **Teste de Recuperação:**
   - ✅ Teste restaurar backup a cada 3 meses
   - ✅ Documente o processo
   - ✅ Treine equipe

---

## 📚 **Referências**

- [Hyperlane Agent Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)
- [Terra Classic Security](https://docs.terra.money/docs/learn/security/)
- [Ethereum Key Management](https://ethereum.org/en/developers/docs/accounts/)
- [OWASP Key Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html)

---

## ✅ **Checklist de Segurança**

- [x] Permissões de arquivo (600)
- [x] Arquivos no `.gitignore`
- [x] Backup criado
- [x] Backup testado
- [x] Endereços documentados
- [ ] Monitoramento de saldo configurado
- [ ] Plano de recuperação documentado
- [ ] Equipe treinada

---

**⚠️ LEMBRE-SE:** A segurança das suas chaves é sua responsabilidade!

