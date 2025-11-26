# 🔧 Solução: Erro de Announcement do Validator

## 🚨 Erro Atual

```
WARN validator::validator: Cannot announce validator without a signer; 
make sure a signer is set for the origin chain, origin_chain: terraclassic
```

## 🎯 O Que é o "Announcement"?

O **validator announcement** é uma transação on-chain que informa a outros agentes Hyperlane onde encontrar suas assinaturas de checkpoints.

**Referência:** [Validator Signatures AWS](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)

### Fluxo do Announcement

```
Validator inicia
     ↓
Verifica se já fez announcement
     ↓
Se NÃO anunciou:
     ├─→ Cria transação de announcement
     ├─→ Assina com signer da chain
     ├─→ Envia para ValidatorAnnounce contract
     └─→ ✅ Announcement registrado on-chain
```

## 🔍 Diagnóstico do Problema

### Problema 1: Formato do Signer para Cosmos + AWS KMS

O Hyperlane pode não suportar completamente AWS KMS para `cosmosKey` nesta versão.

**Teste:**
```bash
# 1. Instalar AWS CLI (se não tiver)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 2. Verificar se a chave KMS existe
aws kms describe-key \
  --key-id alias/hyperlane-validator-signer-terraclassic \
  --region us-east-1
```

### Problema 2: Falta de Fundos

O announcement é uma transação que requer **gas (LUNC)** para ser enviada.

**Teste:**
```bash
# Descobrir endereço (requer cast funcional)
cast wallet address --aws alias/hyperlane-validator-signer-terraclassic

# Ou usar Python script
python3 << EOF
import boto3
import hashlib

kms = boto3.client('kms', region_name='us-east-1')
response = kms.get_public_key(KeyId='alias/hyperlane-validator-signer-terraclassic')
pub_key = response['PublicKey']
print("Chave pública obtida com sucesso!")
print(f"Tamanho: {len(pub_key)} bytes")
EOF
```

## ✅ Soluções

### Solução 1: Usar hexKey Temporário para Announcement (Recomendado)

Use uma chave hex temporária APENAS para o announcement, mantendo AWS KMS para checkpoints.

**Passo 1:** Gerar chave temporária para announcement
```bash
# Gerar chave
cast wallet new

# Output:
# Address: 0x1234...
# Private Key: 0xabcd...
```

**Passo 2:** Converter para formato Terra
```bash
./eth-to-terra.py 0x1234...

# Output:
# Terra: terra1abc...
```

**Passo 3:** Enviar pequena quantidade de LUNC (5-10 LUNC)
```
Envie para: terra1abc...
Quantidade: 10 LUNC (10,000,000 uluna)
Propósito: Apenas para announcement (transação única)
```

**Passo 4:** Atualizar configuração

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
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xSUA_CHAVE_TEMPORARIA_HEX",
        "prefix": "terra"
      }
    }
  }
}
```

**Passo 5:** Reiniciar validador
```bash
docker-compose restart validator-terraclassic
docker logs -f hpl-validator-terraclassic
```

**O que vai acontecer:**
1. ✅ Validator assina checkpoints com AWS KMS
2. ✅ Validator faz announcement com hexKey temporária
3. ✅ Após announcement, os checkpoints assinados são públicos no S3
4. ⚠️ A hexKey fica exposta no arquivo

### Solução 2: Financiar a Carteira KMS (Ideal)

Se conseguir obter o endereço Terra da chave KMS:

**Passo 1:** Instalar AWS CLI
```bash
# Método 1: Via pip
pip3 install awscli

# Método 2: Download oficial
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Passo 2:** Obter endereço
```bash
# Via Python (não precisa de cast)
python3 << 'EOF'
import boto3
import hashlib
import bech32

kms = boto3.client('kms', region_name='us-east-1')
response = kms.get_public_key(KeyId='alias/hyperlane-validator-signer-terraclassic')
pub_key_der = response['PublicKey']

# Extrair chave pública (últimos 65 bytes)
pub_key_bytes = pub_key_der[-65:]
if pub_key_bytes[0] == 0x04:
    pub_key_bytes = pub_key_bytes[1:]

# Hash
sha256_hash = hashlib.sha256(pub_key_bytes).digest()
ripemd160 = hashlib.new('ripemd160', sha256_hash).digest()

# Bech32
five_bit = bech32.convertbits(ripemd160, 8, 5)
terra_addr = bech32.bech32_encode('terra', five_bit)

print(f"Endereço Terra: {terra_addr}")
EOF
```

**Passo 3:** Enviar LUNC
```
Envie 50-100 LUNC para o endereço Terra obtido
```

**Passo 4:** Manter configuração AWS KMS
```json
{
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "aws": {
          "keyId": "alias/hyperlane-validator-signer-terraclassic",
          "region": "us-east-1"
        },
        "prefix": "terra"
      }
    }
  }
}
```

### Solução 3: Desabilitar Announcement (Temporário)

O announcement pode ser feito depois. O validator pode funcionar sem announcement, mas você precisará anunciar manualmente depois.

**Configuração:**
```json
{
  "validator": {
    "type": "aws",
    "id": "alias/hyperlane-validator-signer-terraclassic",
    "region": "us-east-1"
  }
  // Sem seção chains - validator funcionará mas não anunciará
}
```

**⚠️ Consequência:** Outros agentes não saberão automaticamente onde encontrar suas assinaturas.

## 🎯 Recomendação

**Para começar rapidamente:**
1. Use **Solução 1** (hexKey temporária)
2. Faça o announcement
3. Depois migre para AWS KMS completo

**Para produção segura:**
1. Use **Solução 2** (financiar carteira KMS)
2. Tudo gerenciado pelo AWS KMS
3. Mais seguro, sem exposição de chaves

## 📊 Comparação

| Solução | Segurança | Complexidade | Tempo | Recomendado |
|---------|-----------|--------------|-------|-------------|
| **1. hexKey temporária** | ⚠️ Média | Baixa | 10 min | ✅ Teste |
| **2. Financiar KMS** | ✅ Alta | Média | 30 min | ✅ Produção |
| **3. Sem announcement** | ✅ Alta | Baixa | 5 min | ⚠️ Temporário |

## 🛠️ Script para Obter Endereço Terra do KMS

Salve como `get-terra-address-from-kms.py`:

```python
#!/usr/bin/env python3
import boto3
import hashlib
import os

# Carregar credenciais
if os.path.exists('.env'):
    with open('.env') as f:
        for line in f:
            if line.strip() and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()

try:
    import bech32
except ImportError:
    print("Instale: pip3 install bech32")
    exit(1)

kms = boto3.client('kms', region_name='us-east-1')

try:
    response = kms.get_public_key(KeyId='alias/hyperlane-validator-signer-terraclassic')
    pub_key_der = response['PublicKey']
    
    # Extrair chave pública (últimos 65 bytes do DER)
    pub_key_bytes = pub_key_der[-65:]
    
    # Remover prefixo 0x04 se presente
    if pub_key_bytes[0] == 0x04:
        pub_key_bytes = pub_key_bytes[1:]
    
    # Hash SHA256 -> RIPEMD160
    sha256_hash = hashlib.sha256(pub_key_bytes).digest()
    ripemd160 = hashlib.new('ripemd160', sha256_hash).digest()
    
    # Converter para bech32 Terra
    five_bit = bech32.convertbits(ripemd160, 8, 5)
    terra_addr = bech32.bech32_encode('terra', five_bit)
    
    print("=" * 60)
    print("  ENDEREÇO TERRA DA CHAVE KMS")
    print("=" * 60)
    print()
    print(f"Endereço Terra: {terra_addr}")
    print()
    print("📋 Próximos passos:")
    print(f"1. Envie 50-100 LUNC para: {terra_addr}")
    print("2. Aguarde confirmação na blockchain")
    print("3. Reinicie o validador: docker-compose restart validator-terraclassic")
    print()
    
except Exception as e:
    print(f"❌ Erro: {e}")
    print()
    print("Possíveis causas:")
    print("1. AWS CLI não configurado")
    print("2. Credenciais no .env incorretas")
    print("3. Chave KMS não existe ou sem permissões")
    print()
    print("Solução:")
    print("- Verifique o arquivo .env")
    print("- Confirme que a chave KMS existe no AWS Console")
```

---

**Execute:**
```bash
chmod +x get-terra-address-from-kms.py
./get-terra-address-from-kms.py
```

## 📞 Precisa de Ajuda?

Se continuar com problemas:

1. **Instale AWS CLI:**
   ```bash
   pip3 install awscli --user
   # Ou
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. **Verifique a chave KMS no AWS Console:**
   - https://console.aws.amazon.com/kms
   - Procure por: `hyperlane-validator-signer-terraclassic`

3. **Use a Solução 1** (hexKey temporária) se tiver urgência

---

**✅ Próximo passo:** Escolha uma solução e execute!

