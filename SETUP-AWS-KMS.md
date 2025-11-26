# 🚀 Guia de Configuração Hyperlane com AWS KMS

Este guia detalha como configurar e executar o validador e relayer Hyperlane usando AWS KMS para gerenciamento seguro de chaves.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração AWS](#configuração-aws)
3. [Descobrir Endereços das Carteiras](#descobrir-endereços-das-carteiras)
4. [Financiar Carteiras](#financiar-carteiras)
5. [Iniciar Serviços](#iniciar-serviços)
6. [Monitoramento](#monitoramento)
7. [Solução de Problemas](#solução-de-problemas)

---

## 🔧 Pré-requisitos

### Ferramentas Necessárias

```bash
# Docker e Docker Compose
docker --version
docker-compose --version

# Foundry (cast)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Python 3 e pip
python3 --version
pip3 install bech32
```

### 📚 Documentação Oficial de Referência

Antes de começar, consulte a documentação oficial do Hyperlane:

- **[Agent Keys Setup](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)** - Configuração de chaves para agentes
- **[Cast CLI Method](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#cast-cli)** - Gerar chaves com Foundry
- **[AWS Signatures Bucket](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)** - Configuração de bucket S3 para validadores
- **[Validator Operations](https://docs.hyperlane.xyz/docs/operate/validators/validator-guide)** - Guia completo de operação de validadores

### Recursos AWS Criados

✅ **Usuário IAM:**
- Nome: `hyperlane-validator-terraclassic`
- ARN: `arn:aws:iam::435929993977:user/hyperlane-validator-terraclassic`
- Access Key ID: (configurado no arquivo `.env`)

✅ **Bucket S3:**
- Nome: `hyperlane-validator-signatures-igorverasvalidador-terraclassic`
- Região: `us-east-1`
- Uso: Armazenar assinaturas do validador
- **📖 Referência:** [AWS Signatures Bucket Setup](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)

✅ **Chave KMS Criada:**
- Alias: `hyperlane-validator-signer-terraclassic`
- ID: `e04c688d-f13a-4031-99ad-8c7095f8c461`
- Uso: Validador Terra Classic + Relayer Terra Classic

⏳ **Chave KMS Pendente:**
- Alias: `hyperlane-relayer-signer-bsc`
- Uso: Relayer BSC (Binance Smart Chain)

---

## 🔑 Configuração AWS Completa

**📖 Referências Oficiais:**
- [Agent Keys Setup](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)
- [AWS KMS Configuration](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#2-aws-kms)
- [AWS Signatures Bucket](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)

---

## 📋 PASSO 1: Criar Usuário IAM

**Referência:** [Create an IAM user](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#create-an-iam-user)

Este usuário IAM terá permissões para usar as chaves KMS e acessar o bucket S3.

### 1.1 Acessar AWS IAM Console

1. Acesse: https://us-east-1.console.aws.amazon.com/iamv2/home
2. No menu lateral esquerdo, clique em **"Users"** (Usuários)
3. Clique no botão laranja **"Add users"** (Adicionar usuários)

### 1.2 Configurar Usuário

1. **Username** (Nome de usuário):
   ```
   hyperlane-validator-terraclassic
   ```
   ou use o formato: `hyperlane-validator-${chain_name}`

2. Clique em **"Next"** (Próximo)

3. **NÃO** selecione nenhuma permissão por enquanto
   - As permissões serão dadas via políticas de KMS e S3

4. Clique em **"Next"** novamente

5. Clique em **"Create user"** (Criar usuário)

### 1.3 Criar Access Keys

1. Clique no usuário recém-criado para abrir seus detalhes

2. Clique na aba **"Security credentials"** (Credenciais de segurança)

3. Role para baixo até **"Access keys"** (Chaves de acesso)

4. Clique em **"Create access key"** (Criar chave de acesso)

5. Selecione **"Application running outside AWS"** (Aplicação executando fora da AWS)
   - Marque a caixa de confirmação

6. Clique em **"Next"**

7. (Opcional) Adicione uma descrição, exemplo: "Hyperlane Validator Keys"

8. Clique em **"Create access key"**

9. **⚠️ IMPORTANTE**: Copie e guarde com segurança:
   ```
   Access key ID: AKIAIOSFODNN7EXAMPLE
   Secret access key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```

10. Clique em **"Done"**

✅ **Usuário IAM criado com sucesso!**

---

## 🔐 PASSO 2: Criar Chaves KMS

**Referência:** [Create a KMS key](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#create-a-kms-key)

Você precisa criar **2 chaves KMS**:
- 1 para o Validator/Relayer Terra Classic (já criada: ✅)
- 1 para o Relayer BSC (ainda não criada: ⏳)

### 2.1 Acessar AWS KMS Console

1. Acesse: https://console.aws.amazon.com/kms
2. **⚠️ IMPORTANTE**: Verifique a região no canto superior direito
   - Use: **US East (N. Virginia) us-east-1**
   - A URL deve começar com: `us-east-1.console.aws.amazon.com`

### 2.2 Criar Chave KMS para BSC

#### 2.2.1 Iniciar Criação

1. No menu lateral, clique em **"Customer managed keys"** (Chaves gerenciadas pelo cliente)

2. Clique no botão **"Create key"** (Criar chave)

#### 2.2.2 Configurar Tipo de Chave

1. **Key type** (Tipo de chave):
   - Selecione: ⚪ **Asymmetric** (Assimétrica)

2. **Key usage** (Uso da chave):
   - Selecione: ⚪ **Sign and verify** (Assinar e verificar)

3. **Key spec** (Especificação da chave):
   - Selecione: **ECC_SECG_P256K1**
   - ⚠️ Este é o padrão usado por Ethereum/BSC

4. Clique em **"Next"** (Próximo)

#### 2.2.3 Configurar Alias e Descrição

1. **Alias**:
   ```
   hyperlane-relayer-signer-bsc
   ```

2. **Description** (Descrição) - Opcional:
   ```
   Chave para assinar transações do Hyperlane Relayer na BSC
   ```

3. **Tags** (Etiquetas) - Opcional:
   ```
   Key: Project    Value: Hyperlane
   Key: Chain      Value: BSC
   Key: Service    Value: Relayer
   ```

4. Clique em **"Next"**

#### 2.2.4 Definir Administradores

1. **Key administrators** (Administradores da chave) - Opcional
   - Você pode selecionar sua conta de usuário principal
   - Ou deixar vazio

2. Clique em **"Next"**

#### 2.2.5 Definir Permissões de Uso

1. **This account** (Esta conta):
   - Procure e selecione: ☑️ **hyperlane-validator-terraclassic**
   - Este é o usuário IAM que você criou no Passo 1

2. **⚠️ IMPORTANTE**: Certifique-se de que o usuário está selecionado!

3. Clique em **"Next"**

#### 2.2.6 Revisar Key Policy

1. A política gerada deve parecer com:
   ```json
   {
     "Sid": "Allow use of the key",
     "Effect": "Allow",
     "Principal": {
       "AWS": "arn:aws:iam::435929993977:user/hyperlane-validator-terraclassic"
     },
     "Action": [
       "kms:GetPublicKey",
       "kms:Sign"
     ],
     "Resource": "*"
   }
   ```

2. **Opcional** - Para maior segurança, você pode:
   - Remover `kms:DescribeKey` e `kms:Verify` (não são necessários)
   - Remover a seção "Allow attachment of persistent resources"

3. Clique em **"Finish"** (Concluir)

#### 2.2.7 Anotar Informações

Após a criação, anote:

```
Alias: hyperlane-relayer-signer-bsc
Key ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ARN: arn:aws:kms:us-east-1:435929993977:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Region: us-east-1
```

✅ **Chave KMS para BSC criada com sucesso!**

### 2.3 Verificar Chaves KMS Criadas

Liste suas chaves para confirmar:

```bash
# Via AWS CLI
aws kms list-aliases --region us-east-1 | grep hyperlane

# Ou via Console
# https://console.aws.amazon.com/kms → Customer managed keys
```

Você deve ver:
- ✅ `hyperlane-validator-signer-terraclassic` (já existente)
- ✅ `hyperlane-relayer-signer-bsc` (recém-criada)

---

## 🪣 PASSO 3: Criar e Configurar Bucket S3

**Referência:** [AWS Signatures Bucket Setup](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)

⚠️ **NOTA**: Você já criou o bucket! Esta seção documenta como foi feito.

### 3.1 Criar Bucket S3

#### 3.1.1 Acessar S3 Console

1. Acesse: https://s3.console.aws.amazon.com/s3
2. Clique em **"Create bucket"** (Criar bucket)

#### 3.1.2 Configurar Bucket

1. **Bucket name** (Nome do bucket):
   ```
   hyperlane-validator-signatures-igorverasvalidador-terraclassic
   ```
   
   **Formato recomendado:**
   ```
   hyperlane-validator-signatures-${seu_nome}-${chain_name}
   ```

2. **AWS Region** (Região):
   - Selecione: **US East (N. Virginia) us-east-1**
   - ⚠️ Deve ser a mesma região das chaves KMS!

3. **Object Ownership** (Propriedade de objetos):
   - Mantenha: **ACLs disabled** (ACLs desabilitadas)

4. **Block Public Access settings** (Configurações de acesso público):
   - ⚠️ **DESMARQUE** "Block all public access"
   - Marque a caixa de confirmação:
     ☑️ "I acknowledge that the current settings might result in this bucket..."
   
   **Por quê?** Outros agentes Hyperlane precisam ler os checkpoints publicamente.

5. **Bucket Versioning** (Versionamento):
   - Mantenha: **Disable** (Desabilitado)

6. **Tags** (Etiquetas) - Opcional:
   ```
   Key: Project    Value: Hyperlane
   Key: Chain      Value: TerraClassic
   Key: Service    Value: Validator
   ```

7. **Default encryption** (Criptografia padrão):
   - Mantenha: **Server-side encryption with Amazon S3 managed keys (SSE-S3)**

8. Clique em **"Create bucket"** (Criar bucket)

✅ **Bucket S3 criado com sucesso!**

### 3.2 Configurar Bucket Policy (Política de Acesso)

**Referência:** [Bucket Policy](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws#bucket-policy)

Esta política permite:
- ✅ Leitura pública (qualquer agente Hyperlane)
- ✅ Escrita apenas pelo seu usuário IAM

#### 3.2.1 Acessar Permissões do Bucket

1. No S3 Console, clique no bucket recém-criado

2. Clique na aba **"Permissions"** (Permissões)

3. Role até **"Bucket policy"** (Política do bucket)

4. Clique em **"Edit"** (Editar)

#### 3.2.2 Adicionar Policy

Cole esta política (substituindo os valores):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadAccess",
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
      "Sid": "ValidatorWriteAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::435929993977:user/hyperlane-validator-terraclassic"
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

**⚠️ Substitua:**
- Nome do bucket: `hyperlane-validator-signatures-igorverasvalidador-terraclassic`
- ARN do usuário: `arn:aws:iam::435929993977:user/hyperlane-validator-terraclassic`

#### 3.2.3 Salvar Policy

1. Clique em **"Save changes"** (Salvar alterações)

2. Você verá um aviso sobre acesso público - isso é esperado!

✅ **Política do bucket configurada com sucesso!**

### 3.3 Testar Acesso ao Bucket

```bash
# Configurar credenciais
export AWS_ACCESS_KEY_ID=sua_access_key
export AWS_SECRET_ACCESS_KEY=sua_secret_key
export AWS_REGION=us-east-1

# Testar listagem
aws s3 ls s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/

# Testar escrita (upload)
echo "test" > test.txt
aws s3 cp test.txt s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/
rm test.txt

# Testar leitura pública (sem credenciais)
curl https://hyperlane-validator-signatures-igorverasvalidador-terraclassic.s3.us-east-1.amazonaws.com/test.txt

# Limpar
aws s3 rm s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/test.txt
```

Se todos os comandos funcionarem, está configurado corretamente! ✅

---

## ✅ PASSO 4: Verificar Configuração Completa

### 4.1 Checklist de Recursos AWS

- [ ] ✅ Usuário IAM criado: `hyperlane-validator-terraclassic`
- [ ] ✅ Access Key ID e Secret obtidos e guardados no `.env`
- [ ] ✅ Chave KMS 1: `hyperlane-validator-signer-terraclassic` (Terra)
- [ ] ✅ Chave KMS 2: `hyperlane-relayer-signer-bsc` (BSC)
- [ ] ✅ Bucket S3: `hyperlane-validator-signatures-igorverasvalidador-terraclassic`
- [ ] ✅ Bucket Policy configurada (leitura pública + escrita IAM)
- [ ] ✅ Todas na mesma região: `us-east-1`

### 4.2 Testar Permissões KMS

```bash
# Configurar ambiente
export AWS_ACCESS_KEY_ID=sua_access_key
export AWS_SECRET_ACCESS_KEY=sua_secret_key
export AWS_REGION=us-east-1

# Testar chave Terra Classic
aws kms describe-key \
  --key-id alias/hyperlane-validator-signer-terraclassic \
  --region us-east-1

# Testar chave BSC
aws kms describe-key \
  --key-id alias/hyperlane-relayer-signer-bsc \
  --region us-east-1

# Obter chaves públicas
aws kms get-public-key \
  --key-id alias/hyperlane-validator-signer-terraclassic \
  --region us-east-1

aws kms get-public-key \
  --key-id alias/hyperlane-relayer-signer-bsc \
  --region us-east-1
```

Se todos funcionarem sem erros, as permissões estão corretas! ✅

### 4.3 Documentar Informações

Crie um arquivo seguro com todas as informações:

```bash
# criar arquivo (somente você pode ler)
touch ~/hyperlane-aws-info.txt
chmod 600 ~/hyperlane-aws-info.txt

# Adicionar informações
cat >> ~/hyperlane-aws-info.txt << 'EOF'
=== HYPERLANE AWS CONFIGURATION ===

IAM User:
- Username: hyperlane-validator-terraclassic
- ARN: arn:aws:iam::435929993977:user/hyperlane-validator-terraclassic
- Access Key ID: AKIAWK73T2L43T4Y46WJ
- Secret Access Key: (no arquivo .env)

KMS Keys:
1. Validator/Relayer Terra Classic
   - Alias: hyperlane-validator-signer-terraclassic
   - Key ID: e04c688d-f13a-4031-99ad-8c7095f8c461
   - ARN: arn:aws:kms:us-east-1:435929993977:key/e04c688d-f13a-4031-99ad-8c7095f8c461

2. Relayer BSC
   - Alias: hyperlane-relayer-signer-bsc
   - Key ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   - ARN: arn:aws:kms:us-east-1:435929993977:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

S3 Bucket:
- Name: hyperlane-validator-signatures-igorverasvalidador-terraclassic
- Region: us-east-1
- URL: https://hyperlane-validator-signatures-igorverasvalidador-terraclassic.s3.us-east-1.amazonaws.com/

Region: us-east-1
EOF
```

✅ **Configuração AWS completa e documentada!**

---

## 🔍 Descobrir Endereços das Carteiras

### Configurar Credenciais AWS

Primeiro, crie o arquivo `.env` com suas credenciais:

```bash
# Copiar o template
cp .env.example .env

# Editar com suas credenciais reais
nano .env
```

No arquivo `.env`, preencha:
```
AWS_ACCESS_KEY_ID=sua_access_key_aqui
AWS_SECRET_ACCESS_KEY=sua_secret_key_aqui
AWS_REGION=us-east-1
```

⚠️ **IMPORTANTE**: O arquivo `.env` está no `.gitignore` e nunca será commitado!

### Usando o Script Automatizado

```bash
cd /home/lunc/hyperlane-validator
./get-kms-addresses.sh
```

Este script irá:
- ✅ Verificar se as ferramentas necessárias estão instaladas
- ✅ Consultar os endereços das chaves KMS
- ✅ Mostrar instruções de conversão para formato Terra
- ✅ Fornecer comandos úteis

### Conversão Manual Ethereum → Terra

**Opção 1: Script Python (Recomendado)**

```bash
# Instalar dependência (apenas uma vez)
pip3 install bech32

# Converter endereço
./eth-to-terra.py 0xSEU_ENDERECO_ETHEREUM
```

**Opção 2: Online**

1. Acesse: https://www.mintscan.io/cosmos/address-converter
2. Cole o endereço Ethereum
3. Selecione prefix: `terra`
4. Copie o endereço `terra1...`

---

## 💰 Financiar Carteiras

Você precisará enviar fundos para 2 carteiras diferentes:

### 1. Validador/Relayer Terra Classic

**Endereço:** (use `./get-kms-addresses.sh` para descobrir)

**Moeda:** LUNC (Terra Classic)

**Quantidade Sugerida:** 100-500 LUNC

**Propósito:**
- Assinar checkpoints do validador (baixo gas)
- Enviar mensagens cross-chain na Terra Classic

**Como enviar:**
```bash
# Usando Terra Station ou qualquer wallet Terra Classic
# Envie LUNC para o endereço terra1... gerado
```

### 2. Relayer BSC

**Endereço:** (use `./get-kms-addresses.sh` para descobrir)

**Moeda:** BNB

**Quantidade Sugerida:** 0.1-0.5 BNB

**Propósito:**
- Enviar mensagens cross-chain na Binance Smart Chain

**Como enviar:**
```bash
# Usando MetaMask, Trust Wallet ou qualquer wallet BSC
# Envie BNB para o endereço 0x... gerado
```

---

## 🚀 Iniciar Serviços

### Verificar Configurações

```bash
cd /home/lunc/hyperlane-validator

# Verificar arquivos de configuração
cat hyperlane/validator.terraclassic.json
cat hyperlane/relayer.json
cat docker-compose.yml
```

### Iniciar Validador Primeiro

```bash
# Parar containers antigos (se existirem)
docker-compose down

# Iniciar apenas o validador
docker-compose up -d validator-terraclassic

# Verificar logs
docker logs -f hpl-validator-terraclassic
```

**O que esperar nos logs:**
- ✅ Conexão com AWS KMS estabelecida
- ✅ Conexão com S3 estabelecida
- ✅ Sincronização com a rede Terra Classic
- ✅ Checkpoints sendo assinados
- ⚠️ Erros de "insufficient funds" indicam que a carteira precisa de LUNC

### Iniciar Relayer (Após criar chave BSC)

```bash
# Iniciar o relayer
docker-compose up -d relayer

# Verificar logs
docker logs -f hpl-relayer
```

### Iniciar Todos os Serviços

```bash
# Iniciar tudo de uma vez
docker-compose up -d

# Ver status
docker-compose ps

# Ver logs combinados
docker-compose logs -f
```

---

## 📊 Monitoramento

### Métricas Prometheus

**Validador Terra Classic:**
```
http://localhost:9121
```

**Relayer:**
```
http://localhost:9110
```

### Comandos Úteis

```bash
# Ver logs do validador
docker logs hpl-validator-terraclassic --tail 100 -f

# Ver logs do relayer
docker logs hpl-relayer --tail 100 -f

# Verificar se está assinando checkpoints
docker logs hpl-validator-terraclassic | grep "signed checkpoint"

# Verificar se está enviando mensagens
docker logs hpl-relayer | grep "delivered message"

# Verificar saldo Terra Classic
terrad query bank balances ENDERECO_TERRA \
  --node https://rpc.terra-classic.hexxagon.io:443

# Verificar saldo BSC
cast balance ENDERECO_BSC --rpc-url https://bsc.drpc.org

# Listar assinaturas no S3
aws s3 ls s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/ \
  --profile default --region us-east-1
```

### Verificar Saúde dos Serviços

```bash
# Status dos containers
docker-compose ps

# Recursos usados
docker stats

# Reiniciar serviço específico
docker-compose restart validator-terraclassic
docker-compose restart relayer

# Ver logs de erro
docker logs hpl-validator-terraclassic 2>&1 | grep -i error
docker logs hpl-relayer 2>&1 | grep -i error
```

---

## 🔧 Solução de Problemas

### Erro: "AWS KMS key not found"

**Problema:** A chave KMS não existe ou não tem permissões corretas.

**Solução:**
```bash
# Verificar se a chave existe
aws kms describe-key --key-id alias/hyperlane-validator-signer-terraclassic --region us-east-1

# Verificar permissões
aws kms get-key-policy --key-id alias/hyperlane-validator-signer-terraclassic \
  --policy-name default --region us-east-1
```

### Erro: "Insufficient funds"

**Problema:** A carteira não tem fundos suficientes para pagar gas.

**Solução:**
```bash
# Descobrir o endereço
./get-kms-addresses.sh

# Verificar saldo
# Para Terra Classic:
terrad query bank balances ENDERECO_TERRA \
  --node https://rpc.terra-classic.hexxagon.io:443

# Para BSC:
cast balance ENDERECO_BSC --rpc-url https://bsc.drpc.org

# Enviar mais fundos se necessário
```

### Erro: "S3 bucket access denied"

**Problema:** O usuário IAM não tem permissões no bucket S3.

**Solução:**
Verifique a política do bucket S3 no AWS Console e certifique-se que o usuário `hyperlane-validator-terraclassic` tem permissões de leitura/escrita.

### Erro: "Failed to connect to RPC"

**Problema:** Problemas de conectividade com os nós RPC.

**Solução:**
Os arquivos de configuração já incluem múltiplos RPC endpoints com fallback automático. Se persistir, verifique sua conexão de internet.

### Container não inicia

**Problema:** O container sai logo após iniciar.

**Solução:**
```bash
# Ver logs completos
docker logs hpl-validator-terraclassic

# Ver último erro
docker logs hpl-validator-terraclassic 2>&1 | tail -50

# Verificar variáveis de ambiente
docker inspect hpl-validator-terraclassic | grep -A 20 Env

# Reiniciar do zero
docker-compose down -v
docker-compose up -d
```

---

## 📁 Estrutura de Arquivos

```
/home/lunc/hyperlane-validator/
├── docker-compose.yml                # Configuração dos containers
├── get-kms-addresses.sh             # Script para descobrir endereços KMS
├── eth-to-terra.py                  # Script de conversão de endereços
├── SETUP-AWS-KMS.md                 # Este arquivo
├── hyperlane/
│   ├── agent-config.docker.json     # Configuração das chains
│   ├── validator.terraclassic.json  # Configuração do validador
│   └── relayer.json                 # Configuração do relayer
├── validator/                       # Dados do validador
└── relayer/                         # Dados do relayer
```

---

## 💸 Como Sacar Comissões

### Para BNB (BSC) - Mais Fácil

```bash
# Carregar credenciais do .env
export $(cat .env | grep -v '^#' | xargs)

# Transferir BNB
cast send SEU_ENDERECO_DESTINO \
  --value 0.1ether \
  --aws alias/hyperlane-relayer-signer-bsc \
  --rpc-url https://bsc.drpc.org
```

### Para LUNC (Terra Classic) - Script Completo Disponível

**📚 GUIA COMPLETO:** Consulte `TRANSFER-GUIDE.md` para instruções detalhadas!

#### Método Rápido

```bash
# 1. Instalar dependências
pip3 install boto3 bech32 ecdsa requests

# 2. Transferir LUNC
./transfer-lunc-kms.py <destino> <quantidade_uluna> [memo]

# Exemplo: Transferir 10 LUNC (10,000,000 uluna)
./transfer-lunc-kms.py terra1destinatario... 10000000 "Saque"
```

**Nota:** 1 LUNC = 1,000,000 uluna

#### O que o script faz

1. ✅ Verifica o saldo da sua carteira KMS
2. ✅ Calcula automaticamente as taxas de gas
3. ✅ Cria a transação de transferência
4. ✅ Assina com AWS KMS (sua chave nunca sai do HSM)
5. ✅ Transmite para a rede Terra Classic
6. ✅ Retorna o hash da transação

#### Exemplo de Uso Completo

```bash
# Descobrir seu endereço
./get-kms-addresses.sh

# Verificar saldo
terrad query bank balances terra1SEU_ENDERECO \
  --node https://rpc.terra-classic.hexxagon.io:443

# Transferir 50 LUNC para sua carteira pessoal
./transfer-lunc-kms.py terra1sua_carteira_pessoal 50000000 "Saque mensal"
```

**📖 Para mais detalhes, troubleshooting e métodos alternativos:**
- Veja `TRANSFER-GUIDE.md` - Guia completo com exemplos
- Método usando CosmPy (biblioteca oficial Cosmos)
- Exemplos de scripts de verificação rápida
- Calculadora de conversão LUNC ↔ uluna

---

## 🔐 Segurança

### Boas Práticas

✅ **Nunca compartilhe:**
- Access Key ID e Secret Access Key
- Key IDs do KMS
- Endereços das carteiras publicamente (até que estejam em produção)

✅ **Monitore:**
- Uso das chaves KMS no CloudWatch
- Saldos das carteiras regularmente
- Logs dos containers para atividades suspeitas

✅ **Backup:**
- Configurações dos arquivos JSON
- IDs e ARNs dos recursos AWS
- Documentação de acesso

---

## 📚 Recursos Adicionais

### Documentação Oficial Hyperlane

- **[Hyperlane Documentation](https://docs.hyperlane.xyz)** - Documentação principal
- **[Set up Agent Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)** - Guia completo de configuração de chaves
- **[Cast CLI Method](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#cast-cli)** - Gerar chaves com Foundry cast
- **[AWS KMS Setup](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#2-aws-kms)** - Configuração AWS KMS
- **[Validator Signatures AWS](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)** - Bucket S3 para assinaturas
- **[Validator Operations Guide](https://docs.hyperlane.xyz/docs/operate/validators/validator-guide)** - Guia operacional completo
- **[Relayer Operations](https://docs.hyperlane.xyz/docs/operate/relayer/run-relayer)** - Como operar relayers
- **[Config Reference](https://docs.hyperlane.xyz/docs/operate/config/config-reference)** - Referência de configuração

### AWS Documentation

- **[AWS KMS Developer Guide](https://docs.aws.amazon.com/kms/)** - Guia do KMS
- **[AWS S3 User Guide](https://docs.aws.amazon.com/s3/)** - Guia do S3
- **[AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)** - Melhores práticas IAM

### Comunidade

- **[Hyperlane Discord](https://discord.gg/hyperlane)** - Suporte da comunidade
- **[Hyperlane GitHub](https://github.com/hyperlane-xyz/hyperlane-monorepo)** - Código fonte
- **[Hyperlane Twitter](https://twitter.com/Hyperlane_xyz)** - Atualizações

---

## 📞 Suporte

Se precisar de ajuda:
1. Verifique os logs primeiro: `docker logs <container>`
2. Consulte a seção de solução de problemas
3. Verifique a documentação oficial do Hyperlane
4. Entre em contato com a comunidade Hyperlane no Discord

---

**✅ Configuração concluída em:** 26 Nov 2025

**🔐 Método de segurança:** AWS KMS com S3

**🌐 Redes suportadas:** Terra Classic ↔ Binance Smart Chain

