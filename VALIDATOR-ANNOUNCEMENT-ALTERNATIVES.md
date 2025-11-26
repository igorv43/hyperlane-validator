# ⚠️ AWS KMS não funciona para Cosmos (Terra Classic)

## 🚨 **Conclusão Direta**

**AWS KMS NÃO é suportado para blockchains Cosmos** (incluindo Terra Classic) no Hyperlane.

**Solução**: Use **hexKey** (chaves privadas locais) conforme o guia [`QUICKSTART.md`](QUICKSTART.md).

---

## 🔍 **Por Que Não Funciona?**

O Hyperlane validator/relayer **requer DUAS operações** para chains Cosmos:

| Operação | Signer | Suporte AWS KMS | Status |
|----------|--------|-----------------|--------|
| **Assinar Checkpoints** | `validator.type` | ✅ Sim | ✅ Funciona |
| **Transações On-Chain** | `chains.{chain}.signer` | ❌ **NÃO** | ❌ Não funciona |

### Problema Técnico

O parser do Hyperlane (`hyperlane-base/src/settings/parser`) **exige** um campo `key` (chave hexadecimal) para signers do tipo `cosmosKey`:

```json
// ❌ NÃO FUNCIONA
{
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "aws": {
          "keyId": "alias/...",  // ❌ Parser não aceita
          "region": "us-east-1"
        }
      }
    }
  }
}
```

**Erro resultante:**
```
error: Expected key `key` to be defined

config_path: `chains.terraclassic.signer.key`
error: Expected key `key` to be defined
```

---

## ✅ **Solução: hexKey**

Use chaves privadas locais:

```json
// ✅ FUNCIONA
{
  "validator": {
    "type": "hexKey",
    "key": "0x..."
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0x...",  // ✅ Campo obrigatório
        "prefix": "terra"
      }
    }
  }
}
```

📖 **Guia completo**: [`QUICKSTART.md`](QUICKSTART.md)  
🔐 **Segurança**: [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md)

---

## 🔐 **Comparação: EVM vs Cosmos**

| Aspecto | EVM (BSC) | Cosmos (Terra Classic) |
|---------|-----------|------------------------|
| **AWS KMS** | ✅ Suportado | ❌ NÃO suportado |
| **Signer Type** | `"type": "aws"` | `"type": "cosmosKey"` + `"key"` |
| **Exemplo** | `{"type": "aws", "id": "alias/..."}` | `{"type": "cosmosKey", "key": "0x..."}` |
| **Segurança** | KMS (CloudHSM) | Chave local (arquivo 600) |

---

## 🎯 **O Que Funciona**

### ✅ Validator Operacional

Mesmo usando hexKey, o validator **funciona perfeitamente**:

```bash
# Status do validator
docker logs hpl-validator-terraclassic --tail 20

# Procurar por:
# ✅ "Successfully announced validator"
# ✅ "Validator has announced signature storage location"
# ✅ "s3://hyperlane-validator-signatures-.../us-east-1"
```

### ✅ Funcionalidades

- ✅ Assina checkpoints de mensagens
- ✅ Salva assinaturas no AWS S3
- ✅ Faz announcement on-chain
- ✅ Valida mensagens cross-chain
- ✅ API de métricas disponível

---

## 🔄 **Alternativas Futuras**

### Opção 1: Aguardar Suporte Oficial

Hyperlane pode adicionar suporte AWS KMS para Cosmos no futuro.

**Referência**: https://github.com/hyperlane-xyz/hyperlane-monorepo

### Opção 2: Hardware Wallet

Use hardware wallets (Ledger, Trezor) para Cosmos:
- Chaves nunca expostas
- Requer integração manual
- Complexidade elevada

### Opção 3: Custódia Terceirizada

Serviços como Fireblocks, Anchorage oferecem custódia para Cosmos:
- Requer contrato comercial
- Custos elevados
- Para operadores enterprise

---

## 📊 **Impacto na Segurança**

### hexKey (Local) vs AWS KMS

| Aspecto | hexKey | AWS KMS |
|---------|--------|---------|
| **Chave exposta** | ⚠️ Arquivo local | ✅ CloudHSM |
| **Backup** | 📝 Manual | ✅ Automático |
| **Auditoria** | ❌ Limitada | ✅ CloudTrail |
| **Custo** | ✅ Grátis | 💰 ~$1/mês |
| **Complexidade** | ✅ Simples | ⚠️ Configuração AWS |

### Mitigações Implementadas

✅ **Permissões 600** (apenas owner lê)  
✅ **`.gitignore`** (não vai para Git)  
✅ **Arquivos .example** (documentação sem chaves)  
✅ **Guia de backup** ([`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md))

---

## 🛡️ **Recomendações de Segurança**

### Para Produção com hexKey

1. **Servidor Dedicado**
   - Não compartilhado
   - Acesso restrito (SSH key-only)
   - Firewall configurado

2. **Backup Redundante**
   - Mínimo 3 cópias
   - Locais diferentes
   - 1 offline (USB criptografado)

3. **Monitoramento**
   - Alertas de saldo baixo
   - Logs centralizados
   - Transações auditadas

4. **Rotação de Chaves**
   - A cada 3-6 meses
   - Após suspeita de comprometimento
   - Processo documentado

📖 **Guia completo**: [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md)

---

## 📚 **Referências**

- [Hyperlane Validator Setup](https://docs.hyperlane.xyz/docs/operate/validators/run-validators)
- [AWS KMS Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)
- [Cosmos Security Best Practices](https://docs.cosmos.network/main/user/run-node/keyring)
- [Hyperlane GitHub](https://github.com/hyperlane-xyz/hyperlane-monorepo)

---

## ✅ **Próximos Passos**

1. **Seguir**: [`QUICKSTART.md`](QUICKSTART.md)
2. **Configurar**: hexKey para Terra Classic
3. **Proteger**: Seguir [`SECURITY-HEXKEY.md`](SECURITY-HEXKEY.md)
4. **Iniciar**: `docker-compose up -d validator-terraclassic`
5. **Monitorar**: `docker logs -f hpl-validator-terraclassic`

---

**🎯 Conclusão**: Use hexKey conforme documentado. Funciona perfeitamente! ✅
