# 🏗️ Arquitetura Hyperlane com AWS S3 - Análise Completa

Este documento explica a arquitetura completa do projeto usando AWS S3, mostrando o fluxo de dados e por que cada componente é necessário.

## 🎯 Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                    HYPERLANE VALIDATOR + RELAYER                │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────┐              ┌──────────────────────┐
│   VALIDATOR          │              │     RELAYER          │
│  (terraclassic)      │              │  (terra ↔ bsc)       │
├──────────────────────┤              ├──────────────────────┤
│                      │              │                      │
│  ┌────────────────┐  │              │  ┌────────────────┐  │
│  │ Configurations │  │              │  │ Configurations │  │
│  │ /etc/hyperlane │◄─┼─────┐        │  │ /etc/hyperlane │◄─┼─────┐
│  └────────────────┘  │     │        │  └────────────────┘  │     │
│                      │     │        │                      │     │
│  ┌────────────────┐  │     │        │  ┌────────────────┐  │     │
│  │ Database       │  │     │        │  │ Database       │  │     │
│  │ /etc/data/db   │◄─┼──┐  │        │  │ /etc/data/db   │◄─┼──┐  │
│  └────────────────┘  │  │  │        │  └────────────────┘  │  │  │
│                      │  │  │        │                      │  │  │
│  ┌────────────────┐  │  │  │        │  ┌────────────────┐  │  │  │
│  │ Checkpoints    │  │  │  │        │  │ Checkpoints    │  │  │  │
│  │   AWS S3 ☁️    │◄─┼──┼──┼────┐   │  │   AWS S3 ☁️    │◄─┼──┼──┼──┐
│  └────────────────┘  │  │  │    │   │  └────────────────┘  │  │  │  │
│         ▲            │  │  │    │   │         ▲            │  │  │  │
│         │ write      │  │  │    │   │         │ read       │  │  │  │
│         └────────────┼──┼──┼────┤   │         └────────────┼──┼──┼──┤
│                      │  │  │    │   │                      │  │  │  │
│  ┌────────────────┐  │  │  │    │   │  ┌────────────────┐  │  │  │  │
│  │ AWS KMS        │  │  │  │    │   │  │ AWS KMS        │  │  │  │  │
│  │ Signing Key    │◄─┼──┼──┼────┤   │  │ Signing Keys   │◄─┼──┼──┼──┤
│  └────────────────┘  │  │  │    │   │  └────────────────┘  │  │  │  │
│                      │  │  │    │   │                      │  │  │  │
└──────────────────────┘  │  │    │   └──────────────────────┘  │  │  │
                          │  │    │                              │  │  │
                          │  │    │                              │  │  │
                    [Volume] │    │                        [Volume] │  │
                 ./hyperlane │    │                     ./hyperlane │  │
                          │  │    │                              │  │  │
                    [Volume] │    │                        [Volume] │  │
                 ./validator │    │                      ./relayer  │  │
                             │    │                                 │  │
                             │    └─────────────────────────────────┘  │
                             │                                          │
                             │          [AWS S3 Bucket]                │
                             │  hyperlane-validator-signatures-...     │
                             └──────────────────────────────────────────┘
```

## 📊 Separação de Responsabilidades

### 🔐 Validator (terraclassic)

**Função:** Assinar checkpoints de mensagens da chain Terra Classic

**Armazena:**
- ✅ **Configurações** → Volume local: `./hyperlane:/etc/hyperlane`
- ✅ **Database** → Volume local: `./validator:/etc/data`
- ✅ **Checkpoints** → AWS S3 (bucket público para leitura)

**NÃO precisa:**
- ❌ Acesso ao database do relayer
- ❌ Volume local para checkpoints (vai para S3)

**Configuração:**
```json
{
  "db": "/etc/data/db",                    // ← Volume: ./validator
  "checkpointSyncer": {
    "type": "s3",                          // ← Vai para S3
    "bucket": "hyperlane-validator-...",
    "region": "us-east-1"
  }
}
```

**Volumes necessários:**
```yaml
volumes:
  - ./hyperlane:/etc/hyperlane   # Config
  - ./validator:/etc/data        # Database
  # SEM volume para checkpoints!
```

---

### 🔄 Relayer (terra ↔ bsc)

**Função:** Transmitir mensagens entre Terra Classic e BSC

**Armazena:**
- ✅ **Configurações** → Volume local: `./hyperlane:/etc/hyperlane`
- ✅ **Database** → Volume local: `./relayer:/etc/data`
- ✅ **Lê checkpoints** → AWS S3 (do validator)

**NÃO precisa:**
- ❌ Acesso ao database do validator
- ❌ Volume para checkpoints (lê do S3)
- ❌ Volume `./validator` (não faz sentido!)

**Configuração:**
```json
{
  "db": "/etc/data/db",                    // ← Volume: ./relayer
  "allowLocalCheckpointSyncers": "false",  // ← Lê do S3, não local
  "relayChains": "terraclassic,bsc"
}
```

**Volumes necessários:**
```yaml
volumes:
  - ./hyperlane:/etc/hyperlane   # Config
  - ./relayer:/etc/data          # Database
  # SEM ./validator! Não precisa!
```

---

## 🔄 Fluxo de Dados Completo

### Passo 1: Mensagem Enviada em Terra Classic

```
Terra Classic
     ↓
Hyperlane Mailbox Contract
     ↓
Event emitido
     ↓
VALIDATOR detecta evento
     ↓
VALIDATOR cria checkpoint
     ↓
AWS KMS assina checkpoint
     ↓
✅ VALIDATOR escreve no S3
```

### Passo 2: Relayer Processa Mensagem

```
✅ S3 Bucket (checkpoint disponível)
     ↓
RELAYER lê checkpoint do S3
     ↓
RELAYER verifica assinatura
     ↓
AWS KMS assina transação de entrega
     ↓
RELAYER envia para BSC
     ↓
Mensagem entregue em BSC
```

## 📁 Estrutura de Diretórios Correta

```
hyperlane-validator/
├── docker-compose.yml
├── .env                              # Credenciais AWS
│
├── hyperlane/                        # Volume compartilhado (read-only)
│   ├── agent-config.docker.json     # Configuração das chains
│   ├── validator.terraclassic.json  # Config do validator
│   └── relayer.json                 # Config do relayer
│
├── validator/                        # Volume EXCLUSIVO do validator
│   └── db/                           # Database do validator
│       ├── CURRENT
│       ├── LOCK
│       └── *.sst
│
└── relayer/                          # Volume EXCLUSIVO do relayer
    └── db/                           # Database do relayer
        ├── CURRENT
        ├── LOCK
        └── *.sst

AWS S3 (remoto):
└── hyperlane-validator-signatures-igorverasvalidador-terraclassic/
    ├── checkpoint_0x1234...json      # Escrito pelo validator
    ├── checkpoint_0x5678...json      # Lido pelo relayer
    └── checkpoint_0xabcd...json
```

## ⚠️ Configurações INCORRETAS (Evitar)

### ❌ Relayer com Volume do Validator

```yaml
# ERRADO!
relayer:
  volumes:
    - ./hyperlane:/etc/hyperlane
    - ./relayer:/etc/data
    - ./validator:/etc/validator    # ❌ POR QUÊ?!
```

**Problemas:**
1. Relayer não usa dados do validator
2. Cria acoplamento desnecessário
3. Pode causar conflitos de acesso
4. Desperdiça recursos

### ❌ Checkpoints em Volume Local

```yaml
# ERRADO!
validator:
  volumes:
    - ./hyperlane:/etc/hyperlane
    - ./validator:/etc/data
    - ./validator/checkpoint:/etc/checkpoint  # ❌ Não precisa!
```

**Problemas:**
1. Checkpoints vão para S3
2. Volume local desperdiçado
3. Não está disponível para outros agentes
4. Sem redundância

### ❌ Databases Compartilhados

```yaml
# ERRADO!
validator:
  volumes:
    - ./data:/etc/data    # ❌ Compartilhado

relayer:
  volumes:
    - ./data:/etc/data    # ❌ Mesmo volume!
```

**Problemas:**
1. Conflitos de escrita
2. Corrupção de dados
3. Problemas de lock
4. Impossível debugar

## ✅ Configuração CORRETA Final

### docker-compose.yml

```yaml
version: '2'
services:
  relayer:
    container_name: hpl-relayer
    image: gcr.io/abacus-labs-dev/hyperlane-agent:latest
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${AWS_REGION:-us-east-1}
    volumes:
      - ./hyperlane:/etc/hyperlane    # ✅ Config (compartilhado read-only)
      - ./relayer:/etc/data           # ✅ Database próprio
      # ✅ SEM ./validator! Não precisa!
      # ✅ Checkpoints lidos do S3

  validator-terraclassic:
    container_name: hpl-validator-terraclassic
    image: gcr.io/abacus-labs-dev/hyperlane-agent:latest
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${AWS_REGION:-us-east-1}
    volumes:
      - ./hyperlane:/etc/hyperlane    # ✅ Config (compartilhado read-only)
      - ./validator:/etc/data         # ✅ Database próprio
      # ✅ Checkpoints escritos no S3
```

## 🔐 Fluxo de Autenticação AWS

### Validator

```
Container validator-terraclassic
         ↓
AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY
         ↓
AWS STS (verifica identidade)
         ↓
IAM Policy (verifica permissões)
         ↓
├─→ AWS KMS (sign checkpoints)
│   └─→ hyperlane-validator-signer-terraclassic
│
└─→ AWS S3 (write checkpoints)
    └─→ PutObject em hyperlane-validator-signatures-...
```

### Relayer

```
Container hpl-relayer
         ↓
AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY
         ↓
AWS STS (verifica identidade)
         ↓
IAM Policy (verifica permissões)
         ↓
├─→ AWS KMS (sign transactions)
│   ├─→ hyperlane-relayer-signer-bsc
│   └─→ hyperlane-validator-signer-terraclassic
│
└─→ AWS S3 (read checkpoints)
    └─→ GetObject em hyperlane-validator-signatures-...
```

## 📊 Comparação de Uso de Recursos

### Com S3 (Atual - Correto)

| Serviço | Volumes | Disk Usage | S3 Access |
|---------|---------|------------|-----------|
| Validator | 2 (config + db) | ~100 MB | Write |
| Relayer | 2 (config + db) | ~100 MB | Read |
| **Total** | **4 volumes** | **~200 MB** | ✅ |

### Com localStorage (Antigo - Incorreto)

| Serviço | Volumes | Disk Usage | S3 Access |
|---------|---------|------------|-----------|
| Validator | 3 (config + db + checkpoint) | ~500 MB+ | None |
| Relayer | 3 (config + db + validator?!) | ~500 MB+ | None |
| **Total** | **6 volumes** | **~1 GB+** | ❌ |

**Economia com S3:**
- 🟢 33% menos volumes
- 🟢 80% menos disk usage
- 🟢 Checkpoints disponíveis globalmente
- 🟢 Backup automático

## 🎯 Checklist de Verificação

Use este checklist para verificar se sua configuração está correta:

### Validator

- [ ] Volume `./hyperlane:/etc/hyperlane` existe
- [ ] Volume `./validator:/etc/data` existe
- [ ] **NÃO** tem volume para `/etc/validator/checkpoint`
- [ ] Config tem `"checkpointSyncer": { "type": "s3" }`
- [ ] Config tem `"db": "/etc/data/db"`
- [ ] Variáveis AWS configuradas
- [ ] Bucket S3 existe e é acessível

### Relayer

- [ ] Volume `./hyperlane:/etc/hyperlane` existe
- [ ] Volume `./relayer:/etc/data` existe
- [ ] **NÃO** tem volume `./validator`
- [ ] Config tem `"allowLocalCheckpointSyncers": "false"`
- [ ] Config tem `"db": "/etc/data/db"`
- [ ] Variáveis AWS configuradas
- [ ] Pode ler do bucket S3 do validator

### S3 Bucket

- [ ] Bucket criado na região correta
- [ ] Política permite leitura pública
- [ ] Política permite escrita apenas do IAM user
- [ ] Checkpoints aparecem após mensagens

## 🔧 Comandos de Verificação

```bash
# 1. Verificar estrutura de volumes
docker inspect hpl-validator-terraclassic | jq '.[0].Mounts'
docker inspect hpl-relayer | jq '.[0].Mounts'

# Deve mostrar apenas 2 volumes cada:
# - ./hyperlane:/etc/hyperlane
# - ./validator ou ./relayer:/etc/data

# 2. Verificar configurações
cat hyperlane/validator.terraclassic.json | jq '.checkpointSyncer'
# Deve mostrar: {"type": "s3", "bucket": "...", "region": "..."}

cat hyperlane/relayer.json | jq '.allowLocalCheckpointSyncers'
# Deve mostrar: "false"

# 3. Verificar checkpoints no S3
aws s3 ls s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/ \
  --region us-east-1

# 4. Verificar logs
docker logs hpl-validator-terraclassic | grep -i "checkpoint"
docker logs hpl-relayer | grep -i "checkpoint"

# 5. Verificar que relayer NÃO tem acesso a ./validator
docker exec hpl-relayer ls /etc/validator 2>&1
# Deve dar erro: "No such file or directory" ✅
```

## 📚 Recursos Adicionais

- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/best-practices.html)
- [Docker Volumes Guide](https://docs.docker.com/storage/volumes/)
- [Hyperlane Validator Setup](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)

---

**✅ Resumo da Arquitetura Correta:**

1. **Validator** = 2 volumes (config + database) + S3 write
2. **Relayer** = 2 volumes (config + database) + S3 read
3. **NÃO** compartilhar volumes entre serviços
4. **NÃO** ter volumes para checkpoints (estão no S3)
5. **SIM** usar AWS credentials para ambos os serviços

🚀 **Arquitetura limpa, eficiente e escalável!**


