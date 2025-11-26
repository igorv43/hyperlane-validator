# 🔑 Setup AWS: KMS + S3

## ⚠️ **IMPORTANTE: AWS KMS e Cosmos**

**AWS KMS funciona APENAS para blockchains EVM (BSC).**

**Terra Classic (Cosmos) usa hexKey (chaves privadas locais).**

---

## 📋 **O Que Você Precisa Configurar**

| Recurso | Uso | Chain |
|---------|-----|-------|
| **IAM User** | Credenciais AWS | Todas |
| **S3 Bucket** | Armazenar assinaturas validator | Terra Classic |
| **KMS Key (BSC)** | Assinar transações relayer | BSC (opcional) |
| ~~KMS Key (Terra)~~ | ~~Não funciona~~ | ❌ Não usar |

---

## 🚀 **Configuração Rápida**

### Para Validator Terra Classic:

- ✅ **S3 Bucket** (assinaturas públicas)
- ✅ **hexKey** (chave privada local)
- ❌ **NÃO usar KMS**

### Para Relayer BSC (Opcional):

- ✅ **KMS Key** (assinar transações BSC)
- ✅ **hexKey** para Terra Classic

---

## 📚 **Passos de Configuração**

### PASSO 1: Criar Usuário IAM

**Referência:** [Create an IAM user](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#create-an-iam-user)

#### 1.1 Acessar AWS IAM Console

1. Acesse: https://us-east-1.console.aws.amazon.com/iamv2/home
2. No menu lateral esquerdo, clique em **"Users"** (Usuários)
3. Clique no botão laranja **"Add users"** (Adicionar usuários)

#### 1.2 Configurar Usuário

1. **Username** (Nome de usuário):
   ```
   hyperlane-validator
   ```

2. Clique em **"Next"** (Próximo)
3. **NÃO** selecione nenhuma permissão por enquanto
4. Clique em **"Next"** novamente
5. Clique em **"Create user"** (Criar usuário)

#### 1.3 Criar Access Keys

1. Clique no usuário recém-criado para abrir seus detalhes
2. Clique na aba **"Security credentials"** (Credenciais de segurança)
3. Role para baixo até **"Access keys"** (Chaves de acesso)
4. Clique em **"Create access key"** (Criar chave de acesso)
5. Selecione **"Application running outside AWS"** (Aplicação executando fora da AWS)
6. Clique em **"Next"**
7. (Opcional) Adicione uma descrição, exemplo: "Hyperlane Validator Keys"
8. Clique em **"Create access key"**
9. **⚠️ IMPORTANTE**: Copie e guarde com segurança: `Access key ID` e `Secret access key`.
10. Clique em **"Done"**

#### 1.4 Salvar no .env

```bash
cd /home/lunc/hyperlane-validator
cp .env.example .env
nano .env
```

**Conteúdo:**
```bash
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

**Proteger arquivo:**
```bash
chmod 600 .env
```

---

### PASSO 2: Criar Bucket S3

**Referência:** [AWS Signatures Bucket Setup](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)

#### 2.1 Acessar S3 Console

1. Acesse: https://s3.console.aws.amazon.com/s3/home?region=us-east-1
2. Clique em **"Create bucket"** (Criar bucket)

#### 2.2 Configurar Bucket

1. **Bucket name** (Nome do bucket):
   ```
   hyperlane-validator-signatures-SEU-NOME
   ```
   
   **Exemplo:**
   ```
   hyperlane-validator-signatures-igorverasvalidador-terraclassic
   ```

2. **AWS Region**: `US East (N. Virginia) us-east-1`

3. **Object Ownership**: `ACLs disabled (recommended)`

4. **Block Public Access settings**:
   - ⚠️ **DESMARQUE** "Block all public access"
   - ✅ **Marque** o checkbox "I acknowledge..."

5. **Bucket Versioning**: `Disable`

6. **Default encryption**: `Server-side encryption with Amazon S3 managed keys (SSE-S3)`

7. Clique em **"Create bucket"**

#### 2.3 Configurar Bucket Policy

1. Clique no bucket criado
2. Vá para a aba **"Permissions"**
3. Role até **"Bucket policy"**
4. Clique em **"Edit"**

**Cole esta policy** (substitua os valores):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::SEU-BUCKET-NAME",
        "arn:aws:s3:::SEU-BUCKET-NAME/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::SEU-ACCOUNT-ID:user/hyperlane-validator"
      },
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::SEU-BUCKET-NAME/*"
    }
  ]
}
```

**⚠️ Substitua:**
- `SEU-BUCKET-NAME` → Nome do seu bucket
- `SEU-ACCOUNT-ID` → ID da sua conta AWS (12 dígitos)

**Exemplo:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::hyperlane-validator-signatures-igorverasvalidador-terraclassic",
        "arn:aws:s3:::hyperlane-validator-signatures-igorverasvalidador-terraclassic/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::435929993977:user/hyperlane-validator"
      },
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::hyperlane-validator-signatures-igorverasvalidador-terraclassic/*"
    }
  ]
}
```

5. Clique em **"Save changes"**

#### 2.4 Testar Acesso

```bash
# Testar listagem
aws s3 ls s3://SEU-BUCKET-NAME/

# Testar escrita
echo "test" > test.txt
aws s3 cp test.txt s3://SEU-BUCKET-NAME/
rm test.txt

# Testar leitura pública (sem credenciais)
curl https://SEU-BUCKET-NAME.s3.us-east-1.amazonaws.com/test.txt

# Limpar
aws s3 rm s3://SEU-BUCKET-NAME/test.txt
```

---

### PASSO 3: Criar Chave KMS para BSC (Opcional)

**⚠️ APENAS se for rodar o relayer com BSC!**

**Referência:** [AWS KMS Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#cast-cli)

#### 3.1 Acessar KMS Console

1. Acesse: https://console.aws.amazon.com/kms
2. Certifique-se que está na região **US East (N. Virginia) us-east-1**
3. Clique em **"Create key"**

#### 3.2 Configurar Chave

**Step 1: Configure key**

1. **Key type**: `Asymmetric`
2. **Key usage**: `Sign and verify`
3. **Key spec**: `ECC_SECG_P256K1`
4. Clique em **"Next"**

**Step 2: Add labels**

1. **Alias**: `hyperlane-relayer-signer-bsc`
2. **Description** (opcional): `Hyperlane Relayer signer key for BSC`
3. Clique em **"Next"**

**Step 3: Define key administrative permissions**

1. Selecione seu usuário (opcional)
2. Clique em **"Next"**

**Step 4: Define key usage permissions**

1. **This account**: Procure e selecione ☑️ `hyperlane-validator`
2. Clique em **"Next"**

**Step 5: Review**

1. Revisar configurações
2. Clique em **"Finish"**

#### 3.3 Anotar Informações

Após criação, anote:

```
Alias: hyperlane-relayer-signer-bsc
Key ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ARN: arn:aws:kms:us-east-1:ACCOUNT-ID:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Region: us-east-1
```

#### 3.4 Verificar Endereço

```bash
# Obter endereço BSC
cast wallet address --aws alias/hyperlane-relayer-signer-bsc

# Ou usar script
./get-kms-addresses.sh
```

---

## ✅ **Checklist de Recursos AWS**

### Obrigatório (Validator):

- [ ] ✅ Usuário IAM criado: `hyperlane-validator`
- [ ] ✅ Access Key ID e Secret obtidos e guardados no `.env`
- [ ] ✅ Bucket S3 criado e configurado
- [ ] ✅ Bucket Policy configurada (leitura pública + escrita IAM)

### Opcional (Relayer BSC):

- [ ] ⏳ Chave KMS para BSC: `hyperlane-relayer-signer-bsc`
- [ ] ⏳ Endereço BSC obtido e financiado

### ❌ NÃO Criar:

- [ ] ~~Chave KMS para Terra Classic~~ (Cosmos não suporta KMS)

---

## 🔧 **Configurar Validator (Terra Classic)**

### validator.terraclassic.json

```bash
cp hyperlane/validator.terraclassic.json.example hyperlane/validator.terraclassic.json
nano hyperlane/validator.terraclassic.json
```

**Configuração:**

```json
{
  "db": "/etc/data/db",
  "checkpointSyncer": {
    "type": "s3",
    "bucket": "SEU-BUCKET-NAME",  // ← Substituir
    "region": "us-east-1"
  },
  "originChainName": "terraclassic",
  "validator": {
    "type": "hexKey",  // ← hexKey, NÃO aws
    "key": "0xSUA_CHAVE_PRIVADA"  // ← Sua chave privada
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xSUA_CHAVE_PRIVADA",  // ← Mesma chave
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

---

## 🔧 **Configurar Relayer (Opcional)**

### relayer.json

```bash
cp hyperlane/relayer.json.example hyperlane/relayer.json
nano hyperlane/relayer.json
```

**Configuração:**

```json
{
  "db": "/etc/data/db",
  "relayChains": "terraclassic,bsc",
  "allowLocalCheckpointSyncers": "false",
  "gasPaymentEnforcement": [{ "type": "none" }],
  
  "whitelist": [
    {"originDomain": [1325], "destinationDomain": [56]},
    {"originDomain": [56], "destinationDomain": [1325]}
  ],
  
  "chains": {
    "bsc": {
      "signer": {
        "type": "aws",  // ← AWS KMS para BSC (EVM)
        "id": "alias/hyperlane-relayer-signer-bsc",
        "region": "us-east-1"
      }
    },
    
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",  // ← hexKey para Terra (Cosmos)
        "key": "0xSUA_CHAVE_PRIVADA",
        "prefix": "terra"
      }
    }
  }
}
```

**Proteger arquivo:**
```bash
chmod 600 hyperlane/relayer.json
```

---

## 🐳 **Executar Docker**

### Iniciar Validator

```bash
# Iniciar validator
docker-compose up -d validator-terraclassic

# Ver logs
docker logs -f hpl-validator-terraclassic

# Aguardar: "Successfully announced validator"
```

### Iniciar Relayer (Opcional)

```bash
# Iniciar relayer
docker-compose up -d relayer

# Ver logs
docker logs -f hpl-relayer
```

---

## 📊 **Monitoramento**

### Verificar Logs

```bash
# Logs do validator
docker logs hpl-validator-terraclassic --tail 100

# Logs do relayer
docker logs hpl-relayer --tail 100
```

### Verificar Checkpoints no S3

```bash
# Listar checkpoints
aws s3 ls s3://SEU-BUCKET-NAME/ --recursive

# Verificar último checkpoint
aws s3 ls s3://SEU-BUCKET-NAME/ --recursive | tail -1
```

### Verificar Saldos

```bash
# Terra Classic (hexKey)
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/SEU_ENDERECO_TERRA"

# BSC (KMS)
cast balance SEU_ENDERECO_BSC --rpc-url https://bsc.drpc.org
```

---

## 🚨 **Troubleshooting**

### Erro: "AccessDenied" no S3

**Causa:** Bucket policy incorreta ou credenciais AWS inválidas

**Solução:**
1. Verificar bucket policy no AWS Console
2. Verificar `.env` com credenciais corretas
3. Verificar ARN do usuário IAM na policy

### Erro: "InvalidSignatureException" no KMS

**Causa:** Chave KMS não existe ou sem permissões

**Solução:**
```bash
# Verificar se a chave existe
aws kms describe-key --key-id alias/hyperlane-relayer-signer-bsc --region us-east-1

# Verificar permissões
aws kms get-key-policy \
  --key-id alias/hyperlane-relayer-signer-bsc \
  --policy-name default \
  --region us-east-1
```

### Container não inicia

```bash
# Ver logs completos
docker logs hpl-validator-terraclassic

# Reiniciar
docker-compose down
docker-compose up -d validator-terraclassic
```

---

## 📚 **Referências**

- [Hyperlane Validator Setup](https://docs.hyperlane.xyz/docs/operate/validators/run-validators)
- [AWS KMS Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)
- [AWS S3 Bucket Setup](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)
- [IAM User Creation](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#create-an-iam-user)

---

## 📝 **Resumo**

### ✅ Para Validator (Terra Classic):

1. Criar IAM User
2. Criar S3 Bucket
3. Usar **hexKey** (chave privada local)
4. ❌ **NÃO usar AWS KMS**

### ✅ Para Relayer (Opcional):

1. Criar chave KMS para **BSC** (EVM)
2. Usar **hexKey** para **Terra Classic** (Cosmos)
3. Configurar ambas chains no `relayer.json`

---

**🎯 Próximo passo:** Seguir [`QUICKSTART.md`](QUICKSTART.md) para executar!
