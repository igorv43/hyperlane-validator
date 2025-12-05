# 💰 Como Obter Tokens de Teste (Testnet Faucets)

Este guia explica como obter tokens de teste para as redes **Solana Testnet** e **BSC Testnet** que você está usando no Hyperlane.

---

## 🔍 **1. Identificar o Endereço da Sua Carteira**

Primeiro, você precisa descobrir o endereço da sua carteira em cada rede.

### **Solana Testnet**

No seu arquivo `relayer-testnet.json`, você tem uma chave privada:
```json
"solanatestnet": {
  "signer": {
    "type": "hexKey",
    "key": "0x7c2d098a2870db43d142c87586c62d1252c97aff002176a15d87940d41c79e27"
  }
}
```

Para obter o endereço Solana a partir dessa chave privada, você pode usar:

```bash
# Instalar Solana CLI (se ainda não tiver)
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Converter a chave privada para formato Solana e obter o endereço
# (A chave privada precisa ser convertida do formato hex para o formato Solana)
```

**Alternativa mais simples:** Use uma ferramenta online ou script Python para converter a chave privada hex para o endereço Solana.

### **BSC Testnet**

Para BSC, você está usando AWS KMS. Para obter o endereço:

```bash
# Execute o script que já existe no projeto
./get-kms-addresses.sh
```

Ou use o script Python se disponível:
```bash
python3 get-address-from-kms.py
```

---

## 🌊 **2. Solana Testnet Faucet**

### **Método 1: Solana Faucet Oficial (Recomendado)**

1. **Acesse:** https://faucet.solana.com/
2. **Cole seu endereço Solana** (começa com letras/números, ex: `7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU`)
3. **Clique em "Airdrop"**
4. **Aguarde alguns segundos** - você receberá 1-2 SOL de teste

### **Método 2: Solana CLI (Linha de Comando)**

```bash
# Configure para testnet
solana config set --url https://api.testnet.solana.com

# Solicite airdrop (substitua SEU_ENDERECO)
solana airdrop 2 SEU_ENDERECO_SOLANA --url https://api.testnet.solana.com
```

### **Método 3: QuickNode Faucet**

1. **Acesse:** https://faucet.quicknode.com/solana/devnet
2. **Cole seu endereço**
3. **Complete o captcha**
4. **Receba tokens**

### **Método 4: SolFaucet**

1. **Acesse:** https://solfaucet.com/
2. **Selecione "Testnet"**
3. **Cole seu endereço**
4. **Receba tokens**

**⚠️ Nota:** Alguns faucets podem ter limites diários (ex: 1-2 SOL por dia).

---

## 🌊 **3. BSC Testnet Faucet**

### **Método 1: BSC Testnet Faucet Oficial (Recomendado)**

1. **Acesse:** https://testnet.bnbchain.org/faucet-smart
2. **Conecte sua carteira** (MetaMask, WalletConnect, etc.)
   - **OU** cole seu endereço BSC diretamente
3. **Complete o captcha**
4. **Clique em "Give me BNB"**
5. **Aguarde confirmação** - você receberá 0.1-1 BNB de teste

### **Método 2: QuickNode BSC Faucet**

1. **Acesse:** https://faucet.quicknode.com/binance-smart-chain/bnb-testnet
2. **Cole seu endereço BSC** (começa com `0x...`)
3. **Complete o captcha**
4. **Receba tokens**

### **Método 3: BNB Chain Faucet (Alternativo)**

1. **Acesse:** https://www.bnbchain.org/en/testnet-faucet
2. **Cole seu endereço**
3. **Complete a verificação**
4. **Receba BNB de teste**

### **Método 4: Chainlink Faucet (BSC Testnet)**

1. **Acesse:** https://faucets.chain.link/bnb-chain-testnet
2. **Conecte sua carteira ou cole o endereço**
3. **Receba tokens**

**⚠️ Nota:** BSC testnet faucets geralmente fornecem 0.1-1 BNB por solicitação, com limites diários.

---

## 🔧 **4. Verificar Saldo**

### **Solana Testnet**

```bash
# Via CLI
solana balance SEU_ENDERECO_SOLANA --url https://api.testnet.solana.com

# Via Explorer
# Acesse: https://explorer.solana.com/?cluster=testnet
# Cole seu endereço na busca
```

### **BSC Testnet**

```bash
# Via Explorer
# Acesse: https://testnet.bscscan.com/
# Cole seu endereço (0x...) na busca

# Ou via curl (se tiver acesso à API)
curl "https://api-testnet.bscscan.com/api?module=account&action=balance&address=SEU_ENDERECO&tag=latest&apikey=YourApiKeyToken"
```

---

## 📋 **5. Quantidade Recomendada**

Para operar o Hyperlane Relayer na testnet, recomenda-se:

- **Solana Testnet:** 2-5 SOL de teste
- **BSC Testnet:** 0.5-1 BNB de teste

Essas quantidades são suficientes para:
- ✅ Pagar taxas de transação (gas)
- ✅ Testar múltiplas operações
- ✅ Operar o relayer por alguns dias

---

## 🚨 **6. Problemas Comuns**

### **"Faucet temporariamente indisponível"**
- **Solução:** Tente outro faucet da lista acima
- **Aguarde algumas horas** e tente novamente

### **"Limite diário atingido"**
- **Solução:** Use outro faucet ou aguarde 24 horas
- **Alternativa:** Peça tokens para outro endereço de teste

### **"Endereço inválido"**
- **Solução:** Verifique se o endereço está correto
- **Solana:** Deve ter 32-44 caracteres (base58)
- **BSC:** Deve começar com `0x` e ter 42 caracteres

### **"Transação não confirmada"**
- **Solução:** Aguarde alguns minutos
- **Verifique no explorer** se a transação foi processada

---

## 🔐 **7. Segurança**

⚠️ **IMPORTANTE:**
- ✅ Use **APENAS** em redes de teste (testnet)
- ✅ **NUNCA** compartilhe sua chave privada
- ✅ **NUNCA** use a mesma chave privada em mainnet
- ✅ Tokens de teste **NÃO têm valor real**

---

## 📚 **8. Links Úteis**

### **Solana Testnet**
- Explorer: https://explorer.solana.com/?cluster=testnet
- RPC: https://api.testnet.solana.com
- Faucet Oficial: https://faucet.solana.com/

### **BSC Testnet**
- Explorer: https://testnet.bscscan.com/
- RPC: https://bsc-testnet.publicnode.com
- Faucet Oficial: https://testnet.bnbchain.org/faucet-smart

---

## 🛠️ **9. Scripts Úteis**

Se precisar de ajuda para extrair endereços das suas chaves, consulte:
- `get-kms-addresses.sh` - Para endereços de AWS KMS
- `get-address-from-hexkey.py` - Para converter chaves hex

---

## ✅ **Checklist**

- [ ] Identifiquei meu endereço Solana testnet
- [ ] Identifiquei meu endereço BSC testnet
- [ ] Solicitei tokens no faucet Solana
- [ ] Solicitei tokens no faucet BSC
- [ ] Verifiquei os saldos em ambos os exploradores
- [ ] Tenho saldo suficiente para operar o relayer

---

**Boa sorte com seus testes! 🚀**

