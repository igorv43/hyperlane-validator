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

### Recursos AWS Criados

✅ **Usuário IAM:**
- Nome: `hyperlane-validator-terraclassic`
- ARN: `arn:aws:iam::435929993977:user/hyperlane-validator-terraclassic`
- Access Key ID: (configurado no arquivo `.env`)

✅ **Bucket S3:**
- Nome: `hyperlane-validator-signatures-igorverasvalidador-terraclassic`
- Região: `us-east-1`
- Uso: Armazenar assinaturas do validador

✅ **Chave KMS Criada:**
- Alias: `hyperlane-validator-signer-terraclassic`
- ID: `e04c688d-f13a-4031-99ad-8c7095f8c461`
- Uso: Validador Terra Classic + Relayer Terra Classic

⏳ **Chave KMS Pendente:**
- Alias: `hyperlane-relayer-signer-bsc`
- Uso: Relayer BSC (Binance Smart Chain)

---

## 🔑 Configuração AWS

### 1. Criar Chave KMS para BSC (Pendente)

Acesse o AWS Console → KMS → Chaves gerenciadas pelo cliente:

1. **Criar chave**
2. Configurações:
   - Tipo: **Asymmetric**
   - Uso: **Sign and verify**
   - Spec: **ECC_SECG_P256K1**
3. Alias: `hyperlane-relayer-signer-bsc`
4. Permissões: Adicionar usuário `hyperlane-validator-terraclassic`
5. Finalizar criação

### 2. Verificar Permissões IAM

Certifique-se que o usuário IAM tem permissões para:
- Usar as chaves KMS (kms:GetPublicKey, kms:Sign)
- Acessar o bucket S3 (s3:GetObject, s3:PutObject, s3:DeleteObject)

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

- [Documentação Oficial Hyperlane](https://docs.hyperlane.xyz)
- [Configuração de Chaves AWS](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)
- [Configuração de Validadores](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)
- [AWS KMS Developer Guide](https://docs.aws.amazon.com/kms/)

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

