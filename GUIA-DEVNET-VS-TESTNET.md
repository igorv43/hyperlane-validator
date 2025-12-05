# ⚠️ DEVNET vs TESTNET - Guia Importante

## ❌ **NÃO é possível transferir entre redes**

**Devnet** e **Testnet** são redes **completamente separadas**. Não é possível transferir tokens entre elas.

```
Devnet (desenvolvimento)  ❌  Testnet (testes)
     ↓                           ↓
  Tokens SOL                Tokens SOL
  (rede separada)           (rede separada)
```

---

## 🔍 **Diferenças**

| Característica | Devnet | Testnet |
|----------------|--------|---------|
| **Propósito** | Desenvolvimento | Testes |
| **RPC URL** | `https://api.devnet.solana.com` | `https://api.testnet.solana.com` |
| **Explorer** | `?cluster=devnet` | `?cluster=testnet` |
| **Tokens** | SOL de devnet | SOL de testnet |
| **Transferência** | ❌ Não pode transferir para testnet | ❌ Não pode transferir para devnet |

---

## ✅ **Solução: Obter Tokens na Testnet**

Como você já tem tokens na **devnet**, agora precisa obter tokens na **testnet** separadamente.

### **Seu Endereço (mesmo em ambas as redes):**
```
2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9
```

**Nota:** O mesmo endereço funciona em ambas as redes, mas os saldos são independentes.

---

## 🚀 **Como Obter Tokens na Testnet**

### **Método 1: Faucet Web (Recomendado)**

1. **Acesse:** https://faucet.solana.com/

2. **⚠️ IMPORTANTE:** No dropdown no topo da página, selecione:
   - ✅ **"testnet"** (o que você precisa)
   - ❌ **NÃO** selecione "devnet"

3. **Cole seu endereço:**
   ```
   2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9
   ```

4. **Clique em "Confirm Airdrop"**

5. **Aguarde 10-30 segundos**

6. **Verifique o saldo:**
   ```bash
   ./verificar-saldos.sh
   ```

---

### **Método 2: Solana CLI (Testnet)**

```bash
# Configurar para TESTNET (não devnet!)
solana config set --url https://api.testnet.solana.com

# Solicitar airdrop na TESTNET
solana airdrop 1 2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9

# Verificar saldo na TESTNET
solana balance 2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9 --url https://api.testnet.solana.com
```

**⚠️ Atenção:** Se você configurou para devnet antes, precisa mudar para testnet!

---

## 📊 **Verificar Saldos em Cada Rede**

### **Testnet:**
```bash
# Via script
./verificar-saldos.sh

# Via CLI
solana balance 2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9 --url https://api.testnet.solana.com

# Via Explorer
https://explorer.solana.com/address/2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9?cluster=testnet
```

### **Devnet:**
```bash
# Via CLI
solana balance 2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9 --url https://api.devnet.solana.com

# Via Explorer
https://explorer.solana.com/address/2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9?cluster=devnet
```

---

## ⚠️ **Erros Comuns**

### **"Rate limit reached"**
- **Causa:** Você já solicitou tokens recentemente
- **Solução:** Aguarde algumas horas ou use outro faucet

### **"Tokens não aparecem"**
- **Causa:** Você pode estar verificando a rede errada
- **Solução:** Certifique-se de verificar na **testnet**, não na devnet

### **"Faucet mostra devnet"**
- **Causa:** O dropdown está em "devnet" por padrão
- **Solução:** Mude manualmente para **"testnet"** no dropdown

---

## ✅ **Checklist**

- [ ] Entendi que devnet ≠ testnet (redes separadas)
- [ ] Tenho tokens na devnet (já feito ✅)
- [ ] Preciso obter tokens na testnet
- [ ] Vou usar o faucet e selecionar **"testnet"** (não devnet)
- [ ] Vou verificar o saldo na testnet após obter tokens

---

## 🎯 **Resumo Rápido**

1. **Devnet** = Rede de desenvolvimento (você já tem tokens aqui ✅)
2. **Testnet** = Rede de testes (você precisa de tokens aqui ❌)
3. **Não pode transferir** entre elas
4. **Solução:** Obter tokens na testnet separadamente
5. **Faucet:** https://faucet.solana.com/ → Selecione **"testnet"**

---

**Última atualização:** $(date)

