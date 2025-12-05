# 💰 Guia Completo - Obter Tokens BSC Testnet

## 🎯 **Situação Atual**

Você precisa de saldo na **BSC Testnet** para operar o relayer.

---

## 🔍 **Opções Disponíveis**

BSC suporta **duas formas** de gerenciar chaves:

| Opção | Vantagem | Desvantagem | Recomendação |
|-------|----------|-------------|--------------|
| **AWS KMS** | Mais seguro, chave na nuvem | Requer configuração AWS | ✅ Para produção |
| **hexKey** | Mais rápido, fácil de configurar | Chave local (menos seguro) | ✅ Para testes rápidos |

---

## 🚀 **Solução Rápida: Usar hexKey**

Se você quer obter tokens **rapidamente** sem configurar AWS KMS:

### **Passo 1: Gerar Chave Privada BSC**

```bash
# Gerar nova chave privada
cast wallet new

# Exemplo de saída:
# 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

### **Passo 2: Obter Endereço BSC**

```bash
# Obter endereço da chave privada
cast wallet address --private-key 0xSUA_CHAVE_PRIVADA

# Exemplo de saída:
# 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
```

### **Passo 3: Atualizar Configuração**

Edite `hyperlane/relayer-testnet.json`:

```json
{
  "chains": {
    "bsctestnet": {
      "signer": {
        "type": "hexKey",
        "key": "0xSUA_CHAVE_PRIVADA_AQUI"
      }
    }
  }
}
```

**⚠️ IMPORTANTE:** Substitua `"type": "aws"` por `"type": "hexKey"` e adicione o campo `"key"`.

### **Passo 4: Obter Tokens no Faucet**

1. Acesse: **https://testnet.bnbchain.org/faucet-smart**
2. Cole o endereço BSC obtido no Passo 2
3. Complete o captcha
4. Clique em "Give me BNB"
5. Aguarde confirmação

---

## 🔧 **Solução Completa: Configurar AWS KMS**

Se você prefere usar AWS KMS (mais seguro):

### **Passo 1: Criar Chave KMS**

1. Acesse: **https://console.aws.amazon.com/kms**
2. Clique em **"Create key"**
3. Configure:
   - **Tipo:** Asymmetric
   - **Uso:** Sign and verify
   - **Spec:** ECC_SECG_P256K1
   - **Alias:** `hyperlane-relayer-signer-bsc`
4. Clique em **"Create key"**

### **Passo 2: Configurar Credenciais AWS**

Edite o arquivo `.env`:

```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
```

### **Passo 3: Obter Endereço BSC**

```bash
# Obter endereço da chave KMS
cast wallet address --aws alias/hyperlane-relayer-signer-bsc

# Exemplo de saída:
# 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
```

### **Passo 4: Obter Tokens no Faucet**

1. Acesse: **https://testnet.bnbchain.org/faucet-smart**
2. Cole o endereço BSC obtido no Passo 3
3. Complete o captcha
4. Clique em "Give me BNB"

---

## 📋 **Scripts Disponíveis**

Execute estes scripts para facilitar o processo:

```bash
# Obter endereço BSC (tenta AWS KMS primeiro, depois oferece hexKey)
./obter-endereco-bsc.sh

# Obter tokens BSC testnet (requer endereço já configurado)
./obter-bsc-testnet.sh

# Verificar saldos
./verificar-saldos.sh
```

---

## 🔗 **Faucets BSC Testnet**

| Faucet | URL | Requisitos |
|--------|-----|------------|
| **Oficial BSC** | https://testnet.bnbchain.org/faucet-smart | Captcha |
| **QuickNode** | https://faucet.quicknode.com/binance-smart-chain/bnb-testnet | Captcha |
| **Chainlink** | https://faucets.chain.link/bnb-chain-testnet | Conectar carteira |
| **Tatum** | https://tatum.io/faucets/bsc | Captcha |

---

## ✅ **Checklist**

- [ ] Decidi qual método usar (AWS KMS ou hexKey)
- [ ] Gerei/configurei a chave
- [ ] Obtive o endereço BSC
- [ ] Atualizei `relayer-testnet.json` (se usar hexKey)
- [ ] Obtive tokens no faucet
- [ ] Verifiquei o saldo com `./verificar-saldos.sh`

---

## 🎯 **Recomendação Rápida**

Para obter tokens **o mais rápido possível**:

1. Execute: `./obter-endereco-bsc.sh`
2. Escolha gerar nova chave (hexKey)
3. Copie o endereço gerado
4. Acesse: https://testnet.bnbchain.org/faucet-smart
5. Cole o endereço e obtenha tokens
6. Atualize `relayer-testnet.json` com a chave privada

---

**Última atualização:** $(date)

