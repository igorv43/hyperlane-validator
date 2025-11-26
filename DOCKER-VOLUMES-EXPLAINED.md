# 📦 Explicação dos Volumes Docker - Hyperlane com S3

Este documento explica a configuração correta de volumes quando usando AWS S3 para checkpoints.

## 🎯 Entendendo a Diferença

### ❌ Configuração Antiga (localStorage)

Quando usávamos `localStorage` para checkpoints:

```json
"checkpointSyncer": {
  "type": "localStorage",
  "path": "/etc/validator/terraclassic/checkpoint"
}
```

**Volumes necessários:**
```yaml
volumes:
  - ./hyperlane:/etc/hyperlane          # Arquivos de configuração
  - ./validator:/etc/validator          # Checkpoints locais + database
```

### ✅ Configuração Nova (S3)

Com AWS S3 para checkpoints:

```json
"checkpointSyncer": {
  "type": "s3",
  "bucket": "hyperlane-validator-signatures-igorverasvalidador-terraclassic",
  "region": "us-east-1"
}
```

**Volumes necessários:**
```yaml
volumes:
  - ./hyperlane:/etc/hyperlane          # Arquivos de configuração
  - ./validator:/etc/data               # Apenas database local
```

## 📊 Comparação Detalhada

| Componente | Armazenamento | Volume Necessário | Motivo |
|------------|---------------|-------------------|--------|
| **Configurações** | Local | `./hyperlane:/etc/hyperlane` | ✅ Arquivos JSON de config |
| **Database** | Local | `./validator:/etc/data` | ✅ Estado interno do agente |
| **Checkpoints** | S3 Bucket | ❌ Nenhum | Armazenado na AWS |

## 🔍 O que Cada Componente Faz

### 1. Configurações (`./hyperlane:/etc/hyperlane`)

**O que contém:**
- `agent-config.docker.json` - Configuração das chains
- `validator.terraclassic.json` - Configuração do validador
- `relayer.json` - Configuração do relayer

**Por que precisa de volume:**
- Arquivos são lidos na inicialização
- Permitem atualizar configurações sem rebuild da imagem

**Exemplo de conteúdo:**
```bash
./hyperlane/
├── agent-config.docker.json
├── validator.terraclassic.json
└── relayer.json
```

### 2. Database (`./validator:/etc/data`)

**O que contém:**
- Estado interno do validador
- Últimas mensagens processadas
- Índices de sincronização
- Metadados operacionais

**Por que precisa de volume:**
- Persistência entre reinicializações
- Performance (não precisa resincronizar)
- Histórico de operações

**Caminho no código:**
```json
"db": "/etc/data/db"
```

**Exemplo de estrutura:**
```bash
./validator/
└── db/
    ├── CURRENT
    ├── LOCK
    ├── LOG
    ├── MANIFEST-000001
    └── *.sst files
```

### 3. Checkpoints (AWS S3)

**O que contém:**
- Assinaturas dos checkpoints de mensagens
- Merkle roots assinados
- Metadados de validação

**Por que NÃO precisa de volume:**
- ✅ Armazenado diretamente no S3
- ✅ Acessível publicamente para outros agentes
- ✅ Redundância e durabilidade da AWS
- ✅ Não ocupa espaço local

**Exemplo no S3:**
```
s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/
├── checkpoint_0x1234...json
├── checkpoint_0x5678...json
└── checkpoint_0xabcd...json
```

## 🛠️ Configuração Correta

### docker-compose.yml

```yaml
services:
  relayer:
    container_name: hpl-relayer
    image: gcr.io/abacus-labs-dev/hyperlane-agent:latest
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${AWS_REGION:-us-east-1}
    volumes:
      - ./hyperlane:/etc/hyperlane    # Configurações
      - ./relayer:/etc/data           # Database do relayer
    # Relayer lê checkpoints do S3 (allowLocalCheckpointSyncers: false)

  validator-terraclassic:
    container_name: hpl-validator-terraclassic
    image: gcr.io/abacus-labs-dev/hyperlane-agent:latest
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${AWS_REGION:-us-east-1}
    volumes:
      - ./hyperlane:/etc/hyperlane    # Configurações
      - ./validator:/etc/data         # Database do validator
    # Checkpoints vão direto para S3, não precisam de volume!
```

### validator.terraclassic.json

```json
{
  "db": "/etc/data/db",              // Volume: ./validator
  "checkpointSyncer": {
    "type": "s3",                    // Vai para S3, não precisa volume
    "bucket": "...",
    "region": "us-east-1"
  }
}
```

## 🔄 Migração de localStorage para S3

Se você já estava usando localStorage e quer migrar para S3:

### Passo 1: Backup dos Checkpoints Locais (Opcional)

```bash
# Fazer backup dos checkpoints antigos
tar -czf validator-checkpoints-backup.tar.gz ./validator/terraclassic/checkpoint/
```

### Passo 2: Atualizar Configurações

```bash
# Editar validator.terraclassic.json
nano hyperlane/validator.terraclassic.json

# Mudar de:
"checkpointSyncer": {
  "type": "localStorage",
  "path": "/etc/validator/terraclassic/checkpoint"
}

# Para:
"checkpointSyncer": {
  "type": "s3",
  "bucket": "seu-bucket-s3",
  "region": "us-east-1"
}
```

### Passo 3: Atualizar docker-compose.yml

```bash
# Editar volumes
nano docker-compose.yml

# Mudar de:
volumes:
  - ./validator:/etc/validator

# Para:
volumes:
  - ./validator:/etc/data
```

### Passo 4: Reiniciar Validador

```bash
# Parar container
docker-compose stop validator-terraclassic

# Remover container antigo
docker-compose rm -f validator-terraclassic

# Iniciar com nova configuração
docker-compose up -d validator-terraclassic

# Verificar logs
docker logs -f hpl-validator-terraclassic
```

### Passo 5: Verificar S3

```bash
# Verificar se checkpoints estão sendo enviados para S3
aws s3 ls s3://seu-bucket-s3/ --region us-east-1

# Ou via browser
# https://s3.console.aws.amazon.com/s3/buckets/seu-bucket-s3
```

## 📈 Benefícios do S3 vs localStorage

| Aspecto | localStorage | S3 |
|---------|--------------|-----|
| **Disponibilidade** | Local apenas | Global (qualquer agente) |
| **Durabilidade** | Depende do disco | 99.999999999% (11 noves) |
| **Redundância** | Nenhuma | Multi-AZ automática |
| **Backup** | Manual | Automático |
| **Espaço em disco** | Consome local | Não consome |
| **Performance** | Rápido (local) | Rápido (rede AWS) |
| **Custo** | Gratuito | ~$0.023/GB/mês |
| **Escalabilidade** | Limitada | Ilimitada |

## 🔧 Troubleshooting

### Erro: "Failed to write checkpoint to S3"

**Causa:** Credenciais AWS incorretas ou sem permissões.

**Solução:**
```bash
# Verificar credenciais
aws sts get-caller-identity

# Verificar permissões do bucket
aws s3api get-bucket-policy --bucket seu-bucket --region us-east-1
```

### Erro: "Database already in use"

**Causa:** Volume montado incorretamente ou container duplicado.

**Solução:**
```bash
# Parar todos os containers
docker-compose down

# Verificar se não há containers órfãos
docker ps -a | grep validator

# Reiniciar
docker-compose up -d validator-terraclassic
```

### Checkpoints não aparecem no S3

**Causa:** Validador ainda não processou mensagens ou bucket incorreto.

**Solução:**
```bash
# Verificar logs do validador
docker logs hpl-validator-terraclassic | grep -i checkpoint

# Verificar configuração do bucket
cat hyperlane/validator.terraclassic.json | grep -A 3 checkpointSyncer

# Testar acesso ao S3
aws s3 ls s3://seu-bucket/ --region us-east-1
```

## 📁 Estrutura de Diretórios Recomendada

```
hyperlane-validator/
├── docker-compose.yml
├── .env                           # Credenciais AWS
├── hyperlane/                     # Volume: /etc/hyperlane
│   ├── agent-config.docker.json
│   ├── validator.terraclassic.json
│   └── relayer.json
├── validator/                     # Volume: /etc/data
│   └── db/                        # Database do validador
│       ├── CURRENT
│       └── *.sst
└── relayer/                       # Volume: /etc/data (relayer)
    └── db/                        # Database do relayer
```

**Nota:** Não há mais pasta `validator/terraclassic/checkpoint/` porque os checkpoints estão no S3!

## 🔐 Segurança

### Checkpoints no S3

✅ **Público para leitura** - Outros agentes precisam ler
❌ **Público para escrita** - Apenas seu validador deve escrever

**Política de Bucket Recomendada:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::seu-bucket",
        "arn:aws:s3:::seu-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789:user/seu-usuario-iam"
      },
      "Action": ["s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::seu-bucket/*"
    }
  ]
}
```

### Database Local

✅ **Privado** - Apenas no servidor
🔒 **Backup recomendado** - Copiar periodicamente

**Script de Backup:**
```bash
#!/bin/bash
# backup-validator-db.sh

DATE=$(date +%Y%m%d_%H%M%S)
tar -czf validator-db-backup-${DATE}.tar.gz ./validator/db/
echo "Backup criado: validator-db-backup-${DATE}.tar.gz"
```

## 📚 Referências

- [Hyperlane Validator Docs](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Docker Volumes Guide](https://docs.docker.com/storage/volumes/)

---

**✅ Resumo:**

Com S3, você precisa de **2 volumes** apenas:
1. `./hyperlane:/etc/hyperlane` - Configurações ✅
2. `./validator:/etc/data` - Database ✅

Checkpoints vão para S3, não precisam de volume local! 🚀

