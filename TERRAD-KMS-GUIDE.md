# 🌍 Guia Completo: Transferências LUNC com terrad CLI + AWS KMS

Este guia mostra como transferir LUNC usando o `terrad` CLI integrado com AWS KMS para assinar transações.

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Instalação do terrad](#instalação-do-terrad)
3. [Método 1: terrad com Chave Local (Temporária)](#método-1-terrad-com-chave-local-temporária)
4. [Método 2: terrad + AWS KMS (Produção)](#método-2-terrad--aws-kms-produção)
5. [Exemplos Práticos](#exemplos-práticos)
6. [Comandos Úteis](#comandos-úteis)
7. [Solução de Problemas](#solução-de-problemas)

---

## 🎯 Visão Geral

### Arquitetura

```
terrad CLI → Cria transação → AWS KMS assina → Transmite para rede
```

### Duas Abordagens

1. **Chave Local Temporária**: Exportar chave do KMS (não recomendado para produção)
2. **Integração KMS**: Script que integra terrad com KMS (recomendado)

---

## 📦 Instalação do terrad

### Opção 1: Download Binário (Mais Rápido)

```bash
# Baixar a versão mais recente (Classic v2.x)
cd /tmp
wget https://github.com/classic-terra/core/releases/download/v2.3.1/terra_2.3.1_Linux_x86_64.tar.gz

# Extrair
tar -xzf terra_2.3.1_Linux_x86_64.tar.gz

# Mover para local do sistema
sudo mv terrad /usr/local/bin/

# Verificar instalação
terrad version
```

### Opção 2: Compilar do Código Fonte

```bash
# Instalar Go 1.21+
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clonar repositório
git clone https://github.com/classic-terra/core terra-classic
cd terra-classic
git checkout v2.3.1

# Compilar
make install

# Verificar
terrad version
```

### Configuração Inicial

```bash
# Criar diretório de configuração
terrad init meu-node --chain-id columbus-5

# Configurar RPCs
terrad config node https://rpc.terra-classic.hexxagon.io:443
terrad config chain-id columbus-5
terrad config broadcast-mode sync

# Verificar conectividade
terrad status
```

---

## 🔑 Método 1: terrad com Chave Local (Temporária)

⚠️ **ATENÇÃO**: Este método expõe a chave privada temporariamente. Use apenas para testes!

### Passo 1: Exportar Chave Pública do KMS

```bash
# Carregar variáveis
export $(cat .env | grep -v '^#' | xargs)

# Obter chave pública
aws kms get-public-key \
  --key-id alias/hyperlane-validator-signer-terraclassic \
  --region us-east-1 \
  --output json > kms-public-key.json
```

### Passo 2: Converter para Formato Terra

Este método não é prático porque você não pode extrair a chave privada do KMS (essa é a segurança!).

**Conclusão**: Método 1 não é viável com KMS. Use o Método 2.

---

## 🚀 Método 2: terrad + AWS KMS (Produção)

Este é o método correto: criar a transação com terrad, assinar com KMS, e transmitir.

### Passo 1: Instalar Dependências

```bash
# Python e bibliotecas
pip3 install boto3 bech32 ecdsa requests protobuf base64

# terrad CLI
# (usar instalação da seção anterior)
```

### Passo 2: Script de Integração

Vou criar um script que faz a integração completa!

---

## 📝 Exemplos Práticos

### Exemplo 1: Consultar Saldo

```bash
# Descobrir seu endereço Terra
./eth-to-terra.py $(cast wallet address --aws alias/hyperlane-validator-signer-terraclassic)
# Resultado: terra1abc123...

# Consultar saldo
terrad query bank balances terra1abc123... \
  --node https://rpc.terra-classic.hexxagon.io:443
```

**Output esperado:**
```yaml
balances:
- amount: "523456789"
  denom: uluna
pagination:
  next_key: null
  total: "0"
```

### Exemplo 2: Verificar Detalhes da Conta

```bash
terrad query auth account terra1abc123... \
  --node https://rpc.terra-classic.hexxagon.io:443
```

**Output:**
```yaml
'@type': /cosmos.auth.v1beta1.BaseAccount
account_number: "12345"
address: terra1abc123...
sequence: "42"
```

### Exemplo 3: Simular Transferência (Dry Run)

```bash
# Criar transação sem assinar
terrad tx bank send \
  terra1origem... \
  terra1destino... \
  1000000uluna \
  --chain-id columbus-5 \
  --node https://rpc.terra-classic.hexxagon.io:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.325uluna \
  --generate-only > tx_unsigned.json

# Ver conteúdo
cat tx_unsigned.json
```

### Exemplo 4: Transferência Completa com KMS

Use o script de integração (próxima seção):

```bash
./terrad-kms-transfer.sh terra1destino... 10000000 "Saque mensal"
```

---

## 🛠️ Script de Integração: terrad-kms-transfer.sh

Vou criar este script agora!

---

## 💡 Comandos Úteis do terrad

### Consultas (Queries)

```bash
# Saldo
terrad query bank balances ENDERECO --node https://rpc.terra-classic.hexxagon.io:443

# Informações da conta
terrad query auth account ENDERECO --node https://rpc.terra-classic.hexxagon.io:443

# Histórico de transações
terrad query txs --events transfer.recipient=ENDERECO \
  --node https://rpc.terra-classic.hexxagon.io:443 \
  --limit 10

# Detalhes de uma transação
terrad query tx TX_HASH --node https://rpc.terra-classic.hexxagon.io:443

# Status da rede
terrad status --node https://rpc.terra-classic.hexxagon.io:443

# Último bloco
terrad query block --node https://rpc.terra-classic.hexxagon.io:443
```

### Transações (Transactions)

```bash
# Enviar LUNC (precisa de chave)
terrad tx bank send ORIGEM DESTINO 1000000uluna \
  --chain-id columbus-5 \
  --node https://rpc.terra-classic.hexxagon.io:443 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 28.325uluna \
  --from minha-carteira

# Gerar transação sem assinar
terrad tx bank send ORIGEM DESTINO 1000000uluna \
  --chain-id columbus-5 \
  --generate-only > tx.json

# Assinar transação (com chave local)
terrad tx sign tx.json \
  --from minha-carteira \
  --chain-id columbus-5 \
  --output-document tx_signed.json

# Transmitir transação assinada
terrad tx broadcast tx_signed.json \
  --node https://rpc.terra-classic.hexxagon.io:443
```

### Gerenciamento de Chaves (Keyring Local)

```bash
# Listar chaves
terrad keys list

# Adicionar chave existente
terrad keys add minha-carteira --recover

# Ver endereço de uma chave
terrad keys show minha-carteira --address

# Exportar chave (cuidado!)
terrad keys export minha-carteira
```

---

## 🔧 Solução de Problemas

### Erro: "connection refused"

**Problema**: Não consegue conectar ao RPC.

**Solução**:
```bash
# Testar conectividade
curl https://rpc.terra-classic.hexxagon.io:443/status

# Usar RPC alternativo
terrad config node https://terra-classic-rpc.publicnode.com
```

### Erro: "account sequence mismatch"

**Problema**: Sequência da conta desatualizada.

**Solução**:
```bash
# Consultar sequência atual
terrad query auth account terra1abc... \
  --node https://rpc.terra-classic.hexxagon.io:443 | grep sequence

# Usar a sequência correta na próxima transação
```

### Erro: "insufficient fees"

**Problema**: Gas price muito baixo.

**Solução**:
```bash
# Aumentar gas price
--gas-prices 50uluna  # ao invés de 28.325uluna
```

### Erro: "tx not found"

**Problema**: Transação ainda não foi incluída em um bloco.

**Solução**:
```bash
# Aguarde alguns segundos e tente novamente
sleep 10
terrad query tx TX_HASH --node https://rpc.terra-classic.hexxagon.io:443
```

---

## 📊 Calculadora de Gas

### Gas Típico para Transferências

| Operação | Gas Estimado | Custo (28.325 uluna/gas) |
|----------|--------------|--------------------------|
| Transferência simples | 100,000 | 2.8 LUNC |
| Transferência com memo | 120,000 | 3.4 LUNC |
| Multi-send | 200,000+ | 5.6+ LUNC |

### Cálculo Manual

```bash
# Fórmula
custo_gas = gas_usado × gas_price

# Exemplo
# Gas usado: 100,000
# Gas price: 28.325 uluna
# Custo: 100,000 × 28.325 = 2,832,500 uluna = 2.83 LUNC
```

---

## 🔐 Boas Práticas

### ✅ Sempre Faça

1. **Use --generate-only** para preview antes de assinar
2. **Verifique o endereço** de destino duas vezes
3. **Teste com valor pequeno** primeiro
4. **Monitore as taxas** de gas na rede
5. **Salve TX hashes** para referência

### ❌ Nunca Faça

1. Não compartilhe mnemonics ou chaves privadas
2. Não ignore erros de sequência
3. Não use gas muito baixo (transação pode falhar)
4. Não execute comandos sem entender o que fazem

---

## 📈 Monitoramento de Transações

### Verificar Status

```bash
# Método 1: terrad CLI
terrad query tx TX_HASH --node https://rpc.terra-classic.hexxagon.io:443

# Método 2: API REST
curl "https://terra-classic-lcd.publicnode.com/cosmos/tx/v1beta1/txs/TX_HASH"

# Método 3: Explorer
# Abra no navegador:
echo "https://finder.terraclassic.community/mainnet/tx/TX_HASH"
```

### Parsear Resultado

```bash
# Extrair código de resultado (0 = sucesso)
terrad query tx TX_HASH --node https://rpc.terra-classic.hexxagon.io:443 \
  --output json | jq '.code'

# Extrair gas usado
terrad query tx TX_HASH --node https://rpc.terra-classic.hexxagon.io:443 \
  --output json | jq '.gas_used'

# Ver eventos
terrad query tx TX_HASH --node https://rpc.terra-classic.hexxagon.io:443 \
  --output json | jq '.events'
```

---

## 🌐 Endpoints Úteis

### RPC Nodes

```bash
# Primário
https://rpc.terra-classic.hexxagon.io:443

# Alternativos
https://terra-classic-rpc.publicnode.com
https://rpc.terrarebels.net:443
https://terra-classic-rpc.polkachu.com
```

### LCD/REST APIs

```bash
# Primário
https://terra-classic-lcd.publicnode.com

# Alternativos
https://lcd.terraclassic.community
https://terra-classic-lcd.polkachu.com
```

### gRPC Endpoints

```bash
# Primário
terra-classic-grpc.publicnode.com:443

# Alternativos
terra-classic-grpc.polkachu.com:20290
```

---

## 📚 Referências

### Documentação Oficial

- [Terra Classic Docs](https://docs.terra.money)
- [Cosmos SDK Docs](https://docs.cosmos.network)
- [terrad CLI Reference](https://docs.terra.money/docs/develop/terrad/commands.html)

### Exploradores

- [Terra Finder](https://finder.terraclassic.community)
- [Mintscan](https://www.mintscan.io/terra)

### Repositórios

- [Terra Classic Core](https://github.com/classic-terra/core)
- [Terra Classic Faucet](https://faucet.terra.money)

---

## 🎓 Exemplos Avançados

### Multi-Send (Enviar para Múltiplos Endereços)

```bash
# Criar arquivo de destinatários
cat > recipients.json << EOF
{
  "body": {
    "messages": [
      {
        "@type": "/cosmos.bank.v1beta1.MsgMultiSend",
        "inputs": [
          {
            "address": "terra1origem...",
            "coins": [{"denom": "uluna", "amount": "3000000"}]
          }
        ],
        "outputs": [
          {
            "address": "terra1dest1...",
            "coins": [{"denom": "uluna", "amount": "1000000"}]
          },
          {
            "address": "terra1dest2...",
            "coins": [{"denom": "uluna", "amount": "1000000"}]
          },
          {
            "address": "terra1dest3...",
            "coins": [{"denom": "uluna", "amount": "1000000"}]
          }
        ]
      }
    ]
  }
}
EOF

# Assinar e transmitir (requer integração KMS)
```

### Agendar Transferência

```bash
#!/bin/bash
# scheduled-transfer.sh

# Agendar para executar às 10:00 todo dia
# Adicionar ao crontab: 0 10 * * * /path/to/scheduled-transfer.sh

DEST="terra1destino..."
AMOUNT="1000000"  # 1 LUNC

# Verificar saldo antes
BALANCE=$(terrad query bank balances terra1origem... \
  --node https://rpc.terra-classic.hexxagon.io:443 \
  --output json | jq -r '.balances[0].amount')

if [ "$BALANCE" -gt "$AMOUNT" ]; then
  # Executar transferência
  ./terrad-kms-transfer.sh $DEST $AMOUNT "Transferência agendada"
else
  echo "Saldo insuficiente: $BALANCE uluna"
fi
```

---

**✅ Guia completo do terrad CLI criado!**

**Próximo arquivo**: Vou criar o script `terrad-kms-transfer.sh` agora!

