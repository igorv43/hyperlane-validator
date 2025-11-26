# 🔧 Solução: Erro de Parsing do Validator

## 🚨 Erro Atual

```
error: Expected key `key` to be defined

Caused by:
    ParsingError
    
    config_path: `chains.terraclassic.signer.key`
    env_path: `HYP_CHAINS_TERRACLASSIC_SIGNER_KEY`
    arg_key: `--chains.terraclassic.signer.key`
    error: Expected key `key` to be defined
```

## 🎯 Causa do Erro

A seção `chains.terraclassic.signer` **não deve existir** no arquivo de configuração do **validador**.

### ✅ Configuração Correta

Para validadores Cosmos com AWS KMS, use apenas:

```json
{
  "db": "/etc/data/db",
  "checkpointSyncer": {
    "type": "s3",
    "bucket": "hyperlane-validator-signatures-igorverasvalidador-terraclassic",
    "region": "us-east-1"
  },
  "originChainName": "terraclassic",
  "validator": {
    "type": "aws",
    "id": "alias/hyperlane-validator-signer-terraclassic",
    "region": "us-east-1"
  }
}
```

### ❌ Configuração Incorreta

**NÃO adicione** a seção `chains`:

```json
{
  ...,
  "chains": {
    "terraclassic": {
      "signer": { ... }  // ❌ REMOVE ISSO DO VALIDADOR
    }
  }
}
```

## 📋 Diferença: Validator vs Relayer

| Aspecto | Validator | Relayer |
|---------|-----------|---------|
| **Propósito** | Assinar checkpoints | Enviar mensagens |
| **Signer** | Campo `validator` | Campo `chains.{chain}.signer` |
| **On-chain TX** | Apenas announcement | Muitas transações |
| **Seção `chains`** | ❌ NÃO necessária | ✅ Necessária |

## 🔍 Por Que o Erro?

### Para Validadores:
- O campo `validator` já define o signer para **assinar checkpoints**
- A seção `chains.terraclassic.signer` é **apenas para relayers**
- Adicionar `chains` no validador causa erro de parsing

### Para Relayers:
- Precisa de `chains.{chain}.signer` para **enviar transações on-chain**
- Usa diferentes signers para diferentes chains

## ⚠️ Aviso: "Cannot announce validator without a signer"

Se você ver este aviso **após corrigir o erro de parsing**, significa:

```
WARN validator::validator: Cannot announce validator without a signer; 
make sure a signer is set for the origin chain, origin_chain: terraclassic
```

**Causa:** A carteira KMS **não tem fundos LUNC** para pagar o gas do announcement!

**Solução:** Envie LUNC para o endereço Terra:

```bash
# 1. Obter endereço Terra
./get-terra-address-from-kms.py

# 2. Enviar 50-100 LUNC para o endereço mostrado
# Exemplo: terra1avet9au6nnjakqlffgegkcckxmtcanm9a6wpnc

# 3. Verificar saldo
curl "https://terra-classic-lcd.publicnode.com/cosmos/bank/v1beta1/balances/terra1avet9au6nnjakqlffgegkcckxmtcanm9a6wpnc/uluna"

# 4. Reiniciar validador
docker-compose restart validator-terraclassic
```

## 📊 Fluxo de Correção

```
Erro de Parsing
     ↓
Remover seção chains do validator.terraclassic.json
     ↓
Reiniciar validador
     ↓
Validador inicia OK
     ↓
Verifica se já fez announcement
     ↓
Se NÃO tem fundos LUNC:
     ├─→ ⚠️ WARN: Cannot announce validator without a signer
     ├─→ Enviar LUNC para endereço KMS
     └─→ Reiniciar validador
     ↓
Se TEM fundos LUNC:
     ├─→ Cria transação de announcement
     ├─→ Assina com AWS KMS
     ├─→ Envia para ValidatorAnnounce contract
     └─→ ✅ Announcement registrado on-chain
     ↓
Validador começa a assinar checkpoints
     ↓
✅ Checkpoints aparecem no S3
```

## 🛠️ Comandos de Diagnóstico

```bash
# 1. Verificar configuração do validador
cat /home/lunc/hyperlane-validator/hyperlane/validator.terraclassic.json

# 2. Obter endereço Terra da chave KMS
cd /home/lunc/hyperlane-validator
./get-terra-address-from-kms.py

# 3. Verificar saldo da carteira
curl "https://terra-classic-lcd.publicnode.com/cosmos/bank/v1beta1/balances/ENDEREÇO_TERRA/uluna"

# 4. Testar validador
docker-compose restart validator-terraclassic
docker logs -f hpl-validator-terraclassic

# 5. Verificar checkpoints no S3 (após announcement)
aws s3 ls s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/ --region us-east-1
```

## 📚 Referências

- [Hyperlane Validator Setup](https://docs.hyperlane.xyz/docs/operate/validators/run-validators)
- [AWS KMS Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#cast-cli)
- [Validator Signatures AWS](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)
- [Cosmos Signer Configuration](https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/rust/main/hyperlane-base/src/settings/signers.rs)

## ✅ Correção Aplicada

A seção `chains.terraclassic.signer` foi **removida** de `validator.terraclassic.json`.

**Próximos passos:**
1. ✅ Configuração corrigida
2. ⏳ Reiniciar validador
3. ⏳ Enviar LUNC para o endereço KMS
4. ⏳ Verificar announcement on-chain
5. ⏳ Monitorar checkpoints no S3
