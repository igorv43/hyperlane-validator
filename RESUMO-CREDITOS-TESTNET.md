# 💰 Resumo - Créditos Testnet

## ✅ **Endereços Obtidos**

### 🌐 **Solana Testnet**
- **Endereço:** `2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9`
- **Saldo Atual:** 0.0 SOL ❌
- **Explorer:** https://explorer.solana.com/address/2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9?cluster=testnet

### 🌐 **BSC Testnet**
- **Endereço:** Não disponível (requer configuração AWS KMS)
- **Status:** ⚠️ Configure AWS KMS primeiro

---

## 🚀 **Como Obter Créditos**

### **1. Solana Testnet**

#### Método 1: Faucet Web (Recomendado)
1. Acesse: **https://faucet.solana.com/**
2. Cole o endereço: `2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9`
3. Clique em **"Airdrop"**
4. Aguarde alguns segundos
5. Verifique o saldo executando: `./verificar-saldos.sh`

#### Método 2: Solana CLI
```bash
# Se o Solana CLI estiver instalado
solana airdrop 2 2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9 --url https://api.testnet.solana.com
```

#### Método 3: Outros Faucets
- **QuickNode:** https://faucet.quicknode.com/solana/devnet
- **SolFaucet:** https://solfaucet.com/ (selecione Testnet)

**Quantidade Recomendada:** 2-5 SOL de teste

---

### **2. BSC Testnet**

#### Passo 1: Obter Endereço BSC
Primeiro, você precisa obter o endereço BSC da sua chave AWS KMS:

```bash
# Opção 1: Usar o script (requer AWS configurado)
./get-kms-addresses.sh

# Opção 2: Usar cast diretamente (requer Foundry instalado)
cast wallet address --aws alias/hyperlane-relayer-signer-bsc
```

**⚠️ Se você ainda não configurou AWS KMS:**
1. Siga o guia: `SETUP-AWS-KMS.md`
2. Crie a chave KMS com alias: `hyperlane-relayer-signer-bsc`
3. Configure credenciais AWS no arquivo `.env`

#### Passo 2: Obter Tokens BSC
1. Acesse: **https://testnet.bnbchain.org/faucet-smart**
2. Cole o endereço BSC obtido no Passo 1
3. Complete o captcha
4. Clique em **"Give me BNB"**
5. Aguarde confirmação

**Outros Faucets BSC:**
- **QuickNode:** https://faucet.quicknode.com/binance-smart-chain/bnb-testnet
- **Chainlink:** https://faucets.chain.link/bnb-chain-testnet

**Quantidade Recomendada:** 0.5-1 BNB de teste

---

## 📊 **Verificar Saldos**

Execute o script de verificação:

```bash
./verificar-saldos.sh
```

Este script mostra:
- ✅ Saldo atual em cada rede
- 🔗 Links para exploradores
- ⚠️ Avisos se os saldos estão baixos

---

## 🔧 **Scripts Disponíveis**

| Script | Descrição |
|--------|-----------|
| `get-solana-address.py` | Obtém endereço Solana da chave privada |
| `get-kms-addresses.sh` | Obtém endereços de chaves AWS KMS |
| `obter-creditos-testnet.sh` | Tenta obter créditos automaticamente |
| `verificar-saldos.sh` | Verifica saldos atuais |

---

## ⚠️ **Problemas Comuns**

### **"Rate limit reached" (Solana)**
- **Solução:** Aguarde algumas horas ou use outro faucet
- **Alternativa:** Use o faucet web manual

### **"AWS KMS não configurado" (BSC)**
- **Solução:** Configure AWS KMS seguindo `SETUP-AWS-KMS.md`
- **Verifique:** Credenciais AWS no arquivo `.env`

### **"Endereço não encontrado"**
- **Solução:** Verifique se a chave KMS foi criada com o alias correto
- **Alias necessário:** `hyperlane-relayer-signer-bsc`

---

## ✅ **Checklist**

- [x] Endereço Solana obtido: `2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9`
- [ ] Tokens Solana obtidos (via faucet)
- [ ] AWS KMS configurado para BSC
- [ ] Endereço BSC obtido
- [ ] Tokens BSC obtidos (via faucet)
- [ ] Saldos verificados com `./verificar-saldos.sh`

---

## 📚 **Documentação Adicional**

- **Guia Completo:** `OBTER-TOKENS-TESTNET.md`
- **Configuração AWS KMS:** `SETUP-AWS-KMS.md`
- **Configuração Relayer:** `RELAYER-CONFIG-GUIDE.md`

---

**Última atualização:** $(date)

