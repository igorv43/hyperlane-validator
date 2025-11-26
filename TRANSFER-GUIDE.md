# 💸 Guia Completo: Como Transferir/Sacar LUNC com AWS KMS

Este guia detalha passo a passo como transferir LUNC de uma carteira gerenciada pelo AWS KMS para qualquer outro endereço Terra Classic.

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Instalação das Dependências](#instalação-das-dependências)
4. [Método 1: Script Python Simplificado](#método-1-script-python-simplificado)
5. [Método 2: Usando CosmPy (Recomendado para Produção)](#método-2-usando-cosmpy-recomendado-para-produção)
6. [Método 3: Transferência Manual com cast](#método-3-transferência-manual-com-cast)
7. [Solução de Problemas](#solução-de-problemas)

---

## 🎯 Visão Geral

Quando você usa AWS KMS para gerenciar suas chaves, a chave privada nunca sai do Hardware Security Module (HSM) da AWS. Para transferir fundos, você precisa:

1. **Criar** uma transação de transferência
2. **Pedir ao KMS** para assinar a transação
3. **Transmitir** a transação assinada para a rede

---

## 🔧 Pré-requisitos

### Informações Necessárias

- ✅ Chave KMS configurada (`alias/hyperlane-validator-signer-terraclassic`)
- ✅ Credenciais AWS no arquivo `.env`
- ✅ Endereço Terra de destino (`terra1...`)
- ✅ Saldo suficiente de LUNC (incluindo gas)

### Arquivo `.env` Configurado

```bash
AWS_ACCESS_KEY_ID=sua_access_key
AWS_SECRET_ACCESS_KEY=sua_secret_key
AWS_REGION=us-east-1
KMS_KEY_ID=alias/hyperlane-validator-signer-terraclassic
```

---

## 📦 Instalação das Dependências

### Opção 1: Dependências Básicas

```bash
pip3 install boto3 bech32 ecdsa requests
```

### Opção 2: CosmPy (Recomendado)

```bash
pip3 install cosmpy boto3
```

### Opção 3: Instalar Tudo

```bash
pip3 install boto3 bech32 ecdsa requests cosmpy protobuf
```

---

## 🐍 Método 1: Script Python Simplificado

### Passo 1: Verificar Saldo

Primeiro, descubra seu endereço e verifique o saldo:

```bash
cd /home/lunc/hyperlane-validator

# Descobrir seu endereço
./get-kms-addresses.sh

# Ou diretamente
./eth-to-terra.py $(cast wallet address --aws alias/hyperlane-validator-signer-terraclassic)
```

Você verá algo como:
```
Terra:    terra1abc123def456...
```

Agora verifique o saldo:

```bash
# Método 1: Usando terrad (se instalado)
terrad query bank balances terra1SUA_CARTEIRA \
  --node https://rpc.terra-classic.hexxagon.io:443

# Método 2: Usando API REST
curl "https://terra-classic-lcd.publicnode.com/cosmos/bank/v1beta1/balances/terra1SUA_CARTEIRA/uluna"
```

### Passo 2: Executar o Script de Transferência

```bash
# Sintaxe
./transfer-lunc-kms.py <endereço_destino> <quantidade_em_uluna> [memo]

# Exemplo: Transferir 10 LUNC (10,000,000 uluna)
./transfer-lunc-kms.py terra1destinatario... 10000000 "Saque para wallet pessoal"

# Exemplo: Transferir 0.5 LUNC (500,000 uluna)
./transfer-lunc-kms.py terra1destinatario... 500000
```

**Importante:** 
- 1 LUNC = 1,000,000 uluna
- O script verifica o saldo antes de transferir
- A taxa de gas é calculada automaticamente (~5-10 LUNC)

### Passo 3: Confirmar a Transação

O script mostrará:

```
📤 De:        terra1abc... (sua carteira KMS)
📥 Para:      terra1xyz... (destino)
💰 Quantidade: 10.000000 LUNC
💼 Saldo atual: 150.523421 LUNC
📊 Taxa de gas: 5.665000 LUNC
📊 Total necessário: 15.665000 LUNC

⚠️  ATENÇÃO: Esta operação transferirá LUNC permanentemente!

Deseja continuar? (sim/não):
```

Digite `sim` para confirmar.

---

## 🚀 Método 2: Usando CosmPy (Recomendado para Produção)

O CosmPy é uma biblioteca oficial do Cosmos que implementa corretamente todo o protocolo.

### Passo 1: Criar Script com CosmPy

Crie um arquivo `transfer-cosmpy.py`:

```python
#!/usr/bin/env python3
"""
Transferência LUNC usando CosmPy + AWS KMS
"""
import os
import sys
import boto3
import hashlib
from cosmpy.aerial.client import LedgerClient, NetworkConfig
from cosmpy.aerial.wallet import LocalWallet
from cosmpy.crypto.keypairs import PrivateKey

# Configuração Terra Classic
terra_config = NetworkConfig(
    chain_id="columbus-5",
    url="https://rpc.terra-classic.hexxagon.io:443",
    fee_minimum_gas_price=28.325,
    fee_denomination="uluna",
    staking_denomination="uluna",
)

class KMSWallet:
    """Wallet que usa AWS KMS para assinatura"""
    
    def __init__(self, kms_key_id, region='us-east-1'):
        self.kms = boto3.client('kms', region_name=region)
        self.kms_key_id = kms_key_id
        
    def sign(self, message: bytes) -> bytes:
        """Assina mensagem com KMS"""
        response = self.kms.sign(
            KeyId=self.kms_key_id,
            Message=hashlib.sha256(message).digest(),
            MessageType='DIGEST',
            SigningAlgorithm='ECDSA_SHA_256'
        )
        return response['Signature']
    
    def get_address(self) -> str:
        """Obtém endereço Terra da chave KMS"""
        # Implementar conversão de chave pública KMS -> endereço Terra
        # Ver script transfer-lunc-kms.py para implementação
        pass

def main():
    # Carregar variáveis de ambiente
    if os.path.exists('.env'):
        from dotenv import load_dotenv
        load_dotenv()
    
    # Conectar à rede
    client = LedgerClient(terra_config)
    
    # Criar wallet KMS
    kms_wallet = KMSWallet(
        os.getenv('KMS_KEY_ID', 'alias/hyperlane-validator-signer-terraclassic')
    )
    
    # Obter endereço de origem
    from_address = kms_wallet.get_address()
    
    # Destinatário e quantidade
    to_address = sys.argv[1]
    amount = int(sys.argv[2])
    
    print(f"Transferindo {amount/1000000} LUNC")
    print(f"De:   {from_address}")
    print(f"Para: {to_address}")
    
    # Criar e enviar transação
    # ... (implementação completa disponível na documentação CosmPy)
    
if __name__ == '__main__':
    main()
```

### Passo 2: Executar

```bash
chmod +x transfer-cosmpy.py
./transfer-cosmpy.py terra1destinatario... 10000000
```

---

## 💻 Método 3: Transferência Manual com cast

Para BSC (BNB), é muito mais simples usar o `cast`:

```bash
# Carregar variáveis de ambiente
export $(cat .env | grep -v '^#' | xargs)

# Transferir BNB
cast send ENDERECO_DESTINO \
  --value 0.1ether \
  --aws alias/hyperlane-relayer-signer-bsc \
  --rpc-url https://bsc.drpc.org
```

**Nota:** Infelizmente, `cast` não suporta Cosmos/Terra, apenas chains EVM.

---

## 🔧 Solução de Problemas

### Erro: "Credenciais AWS não configuradas"

**Solução:**
```bash
# Verificar se .env existe
cat .env

# Se não existir, criar
cp .env.example .env
nano .env
```

### Erro: "Dependências faltando"

**Solução:**
```bash
pip3 install boto3 bech32 ecdsa requests protobuf
```

### Erro: "Saldo insuficiente"

**Problema:** Não há LUNC suficiente para cobrir transferência + gas.

**Solução:**
```bash
# Verificar saldo exato
curl "https://terra-classic-lcd.publicnode.com/cosmos/bank/v1beta1/balances/SEU_ENDERECO/uluna"

# Enviar mais LUNC se necessário
```

### Erro: "KMS key not found"

**Solução:**
```bash
# Verificar se a chave existe
aws kms describe-key --key-id alias/hyperlane-validator-signer-terraclassic --region us-east-1

# Verificar permissões
aws kms get-key-policy --key-id alias/hyperlane-validator-signer-terraclassic \
  --policy-name default --region us-east-1
```

### Erro: "Transaction failed"

**Causas comuns:**
1. Gas insuficiente
2. Sequência de conta incorreta
3. Endereço de destino inválido
4. Saldo insuficiente

**Solução:**
- Verifique os logs da transação
- Aumente o gas limit
- Verifique o endereço de destino

---

## 📊 Calculadora de Conversão

### LUNC ↔ uluna

| LUNC | uluna |
|------|-------|
| 1 LUNC | 1,000,000 uluna |
| 0.1 LUNC | 100,000 uluna |
| 10 LUNC | 10,000,000 uluna |
| 100 LUNC | 100,000,000 uluna |

### Exemplo de Cálculo

Se você quer transferir **15 LUNC**:

```bash
# Quantidade em uluna
15 * 1,000,000 = 15,000,000 uluna

# Comando
./transfer-lunc-kms.py terra1destinatario... 15000000
```

---

## 🔐 Melhores Práticas de Segurança

### ✅ Sempre Faça

1. **Verifique o endereço de destino** duas vezes antes de confirmar
2. **Teste com quantidade pequena** primeiro (ex: 1 LUNC)
3. **Mantenha registro** de todas as transferências
4. **Verifique o saldo** antes e depois
5. **Use memo descritivo** para rastrear transações

### ❌ Nunca Faça

1. Não compartilhe suas credenciais AWS
2. Não transfira para endereços não verificados
3. Não ignore avisos de saldo insuficiente
4. Não execute scripts de fontes não confiáveis

---

## 📝 Exemplo Completo Passo a Passo

### Cenário: Sacar 50 LUNC para sua carteira pessoal

**Passo 1: Descobrir endereço de origem**
```bash
./get-kms-addresses.sh
# Resultado: terra1abc123...
```

**Passo 2: Verificar saldo**
```bash
terrad query bank balances terra1abc123... \
  --node https://rpc.terra-classic.hexxagon.io:443
# Resultado: 523.456789 LUNC
```

**Passo 3: Calcular quantidade em uluna**
```
50 LUNC = 50,000,000 uluna
```

**Passo 4: Executar transferência**
```bash
./transfer-lunc-kms.py terra1xyz789... 50000000 "Saque mensal"
```

**Passo 5: Confirmar**
```
Deseja continuar? (sim/não): sim
```

**Passo 6: Aguardar confirmação**
```
✅ Transação transmitida com sucesso!
TX Hash: 1234567890ABCDEF...
```

**Passo 7: Verificar na blockchain**
```
https://finder.terraclassic.community/mainnet/tx/1234567890ABCDEF
```

---

## 🌐 Recursos Adicionais

### Exploradores de Blocos Terra Classic

- [Terra Finder](https://finder.terraclassic.community)
- [Mintscan](https://www.mintscan.io/terra)

### APIs Terra Classic

- LCD: `https://terra-classic-lcd.publicnode.com`
- RPC: `https://rpc.terra-classic.hexxagon.io:443`
- gRPC: `https://terra-classic-grpc.publicnode.com:443`

### Documentação

- [CosmPy Docs](https://docs.fetch.ai/CosmPy/)
- [Cosmos SDK](https://docs.cosmos.network/)
- [AWS KMS API](https://docs.aws.amazon.com/kms/latest/APIReference/)

---

## ⚡ Scripts Rápidos

### Ver saldo rapidamente

```bash
#!/bin/bash
# save as: check-balance.sh
export $(cat .env | grep -v '^#' | xargs)
ADDR=$(./eth-to-terra.py $(cast wallet address --aws $KMS_KEY_ID) | grep "Terra:" | awk '{print $2}')
curl -s "https://terra-classic-lcd.publicnode.com/cosmos/bank/v1beta1/balances/$ADDR/uluna" | jq
```

### Transferir com um comando

```bash
#!/bin/bash
# save as: quick-transfer.sh
# Uso: ./quick-transfer.sh <destino> <quantidade_lunc>

DEST=$1
LUNC=$2
ULUNA=$(echo "$LUNC * 1000000" | bc)

./transfer-lunc-kms.py $DEST ${ULUNA%.*} "Transfer via quick-transfer.sh"
```

---

**✅ Guia completo criado!**

Para mais informações, consulte `SETUP-AWS-KMS.md` ou entre em contato com o suporte.

