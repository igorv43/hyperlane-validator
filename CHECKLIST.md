# ✅ Checklist de Configuração Hyperlane

Use este checklist para garantir que tudo está configurado corretamente.

## 🎯 Fase 1: Configuração AWS (Obrigatório)

### AWS IAM User
- [x] ✅ Usuário IAM criado: `hyperlane-validator-terraclassic`
- [x] ✅ Access Key ID obtido: `AKIAWK73T2L43T4Y46WJ`
- [x] ✅ Secret Access Key obtido (guardado com segurança)

### AWS S3 Bucket
- [x] ✅ Bucket criado: `hyperlane-validator-signatures-igorverasvalidador-terraclassic`
- [x] ✅ Bucket policy configurada (público para leitura, IAM user para escrita)
- [x] ✅ Região: `us-east-1`

### AWS KMS Keys
- [x] ✅ Chave 1 criada: `hyperlane-validator-signer-terraclassic`
  - ID: `e04c688d-f13a-4031-99ad-8c7095f8c461`
  - Tipo: Asymmetric, ECC_SECG_P256K1
  - Uso: Validador + Relayer Terra Classic
- [ ] ⏳ Chave 2 pendente: `hyperlane-relayer-signer-bsc`
  - Tipo: Asymmetric, ECC_SECG_P256K1
  - Uso: Relayer BSC

---

## 🔧 Fase 2: Configuração Local (Obrigatório)

### Arquivos de Configuração
- [x] ✅ `.env` criado com credenciais AWS
- [x] ✅ `.gitignore` protegendo arquivos sensíveis
- [x] ✅ `docker-compose.yml` atualizado com variáveis de ambiente
- [x] ✅ `validator.terraclassic.json` configurado com KMS e S3
- [x] ✅ `relayer.json` configurado com KMS

### Dependências Instaladas
- [ ] 📦 Docker e Docker Compose
  ```bash
  docker --version
  docker-compose --version
  ```
- [ ] 📦 Foundry (cast)
  ```bash
  cast --version
  ```
- [ ] 📦 Python 3 e pip
  ```bash
  python3 --version
  pip3 --version
  ```
- [ ] 📦 Biblioteca bech32
  ```bash
  pip3 install bech32
  ```

---

## 🔍 Fase 3: Descobrir Endereços (Obrigatório)

### Endereços das Carteiras KMS
- [ ] 🔑 Endereço Validador/Relayer Terra Classic descoberto
  ```bash
  ./get-kms-addresses.sh
  ```
  - Formato Ethereum: `0x...`
  - Formato Terra: `terra1...`
  
- [ ] 🔑 Endereço Relayer BSC descoberto (após criar chave KMS)
  ```bash
  ./get-kms-addresses.sh
  ```
  - Formato: `0x...`

### Conversão de Endereços
- [ ] 🔄 Endereço Ethereum convertido para Terra
  ```bash
  ./eth-to-terra.py 0xSEU_ENDERECO
  ```

---

## 💰 Fase 4: Financiar Carteiras (Obrigatório)

### Validador/Relayer Terra Classic
- [ ] 💸 LUNC enviado para: `terra1...`
  - Quantidade recomendada: 100-500 LUNC
  - Status: _____ LUNC enviados
  - TX Hash: _________________

### Relayer BSC
- [ ] 💸 BNB enviado para: `0x...`
  - Quantidade recomendada: 0.1-0.5 BNB
  - Status: _____ BNB enviados
  - TX Hash: _________________

### Verificação de Saldos
- [ ] ✅ Saldo Terra verificado
  ```bash
  terrad query bank balances terra1... \
    --node https://rpc.terra-classic.hexxagon.io:443
  ```
- [ ] ✅ Saldo BSC verificado
  ```bash
  cast balance 0x... --rpc-url https://bsc.drpc.org
  ```

---

## 🚀 Fase 5: Iniciar Serviços (Obrigatório)

### Validador Terra Classic
- [ ] ▶️ Container iniciado
  ```bash
  docker-compose up -d validator-terraclassic
  ```
- [ ] 📋 Logs verificados (sem erros)
  ```bash
  docker logs -f hpl-validator-terraclassic
  ```
- [ ] ✅ Checkpoints sendo assinados
  ```bash
  docker logs hpl-validator-terraclassic | grep "signed checkpoint"
  ```
- [ ] 📊 Métricas acessíveis: http://localhost:9121

### Relayer (Após criar chave BSC)
- [ ] ▶️ Container iniciado
  ```bash
  docker-compose up -d relayer
  ```
- [ ] 📋 Logs verificados (sem erros)
  ```bash
  docker logs -f hpl-relayer
  ```
- [ ] ✅ Mensagens sendo processadas
  ```bash
  docker logs hpl-relayer | grep "delivered message"
  ```
- [ ] 📊 Métricas acessíveis: http://localhost:9110

---

## 🔍 Fase 6: Verificação de Funcionamento (Recomendado)

### Validador
- [ ] 🔐 Assinaturas aparecendo no S3
  ```bash
  aws s3 ls s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/
  ```
- [ ] 📡 Conectado ao RPC Terra Classic
- [ ] ⚡ Consumo de gas razoável
- [ ] 📈 Métricas Prometheus funcionando

### Relayer
- [ ] 🔗 Conectado a ambas as chains (Terra + BSC)
- [ ] 📨 Processando mensagens cross-chain
- [ ] ⚡ Gas suficiente em ambas as chains
- [ ] 📈 Métricas Prometheus funcionando

---

## 📚 Fase 7: Documentação e Backup (Recomendado)

### Documentação Lida
- [ ] 📖 `README.md` - Visão geral do projeto
- [ ] 📖 `SETUP-AWS-KMS.md` - Guia de configuração completo
- [ ] 📖 `TRANSFER-GUIDE.md` - Como transferir fundos

### Informações Salvas
- [ ] 💾 Credenciais AWS salvas com segurança
- [ ] 💾 ARNs das chaves KMS anotados
- [ ] 💾 Endereços das carteiras salvos
- [ ] 💾 Nome do bucket S3 anotado

### Scripts Testados
- [ ] 🧪 `get-kms-addresses.sh` testado e funcionando
- [ ] 🧪 `eth-to-terra.py` testado e funcionando
- [ ] 🧪 `transfer-lunc-kms.py` testado (opcional)

---

## 🔐 Fase 8: Segurança (Crítico)

### Proteção de Credenciais
- [x] ✅ Arquivo `.env` não commitado no git
- [x] ✅ `.gitignore` protegendo arquivos sensíveis
- [ ] 🔒 Credenciais AWS armazenadas com segurança
- [ ] 🔒 Backup das credenciais em local seguro

### Permissões AWS
- [x] ✅ IAM user tem apenas permissões necessárias
- [x] ✅ KMS keys acessíveis apenas pelo IAM user
- [x] ✅ S3 bucket com política de acesso adequada

### Monitoramento
- [ ] 📊 CloudWatch configurado (opcional)
- [ ] 🚨 Alertas de saldo baixo configurados (opcional)
- [ ] 📧 Notificações de erro configuradas (opcional)

---

## 🎓 Fase 9: Operação Diária (Opcional)

### Rotina de Verificação
- [ ] 🔄 Verificar saldos das carteiras (diário)
- [ ] 🔄 Verificar logs dos containers (diário)
- [ ] 🔄 Verificar métricas Prometheus (diário)
- [ ] 🔄 Verificar assinaturas no S3 (semanal)

### Manutenção
- [ ] 🔧 Atualizar imagens Docker (mensal)
- [ ] 🔧 Revisar logs antigos (mensal)
- [ ] 🔧 Testar procedure de transferência (mensal)
- [ ] 🔧 Backup das configurações (mensal)

---

## 📊 Status Geral do Projeto

### Resumo
- **AWS IAM**: ✅ Configurado
- **AWS S3**: ✅ Configurado
- **AWS KMS**: 🟡 Parcial (1 de 2 chaves)
- **Configuração Local**: ✅ Completo
- **Validador**: ⏳ Pendente inicialização
- **Relayer**: ⏳ Pendente chave BSC

### Próximos Passos
1. ⏳ Criar chave KMS para BSC
2. ⏳ Descobrir endereços das carteiras
3. ⏳ Financiar carteiras com LUNC e BNB
4. ⏳ Iniciar validador
5. ⏳ Iniciar relayer

---

## 🆘 Precisa de Ajuda?

### Recursos
- 📖 Documentação completa em `SETUP-AWS-KMS.md`
- 💸 Guia de transferências em `TRANSFER-GUIDE.md`
- 🐛 Solução de problemas em ambos os guias

### Comandos de Diagnóstico
```bash
# Verificar status dos containers
docker-compose ps

# Ver logs
docker logs hpl-validator-terraclassic --tail 50
docker logs hpl-relayer --tail 50

# Verificar configuração
cat .env
cat hyperlane/validator.terraclassic.json
cat hyperlane/relayer.json

# Testar conexão AWS
aws sts get-caller-identity
aws kms describe-key --key-id alias/hyperlane-validator-signer-terraclassic --region us-east-1
```

---

**📅 Última atualização:** 26 Nov 2025  
**✅ Checklist completo!**

Marque cada item conforme você completar. Boa sorte! 🚀

