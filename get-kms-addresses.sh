#!/bin/bash

# Script para descobrir endereços das carteiras AWS KMS
# Autor: Configuração Hyperlane Validator
# Data: 2025-11-26

set -e

echo "============================================"
echo "   DESCOBRINDO ENDEREÇOS DAS CHAVES KMS"
echo "============================================"
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurar credenciais AWS
# Carrega do arquivo .env se existir
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Verificar se as credenciais estão definidas
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}❌ ERRO: Credenciais AWS não configuradas${NC}"
    echo ""
    echo "Crie um arquivo .env baseado no .env.example:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    echo ""
    exit 1
fi

export AWS_REGION="${AWS_REGION:-us-east-1}"

echo -e "${BLUE}🔧 Verificando ferramentas necessárias...${NC}"

# Verificar se cast está instalado
if ! command -v cast &> /dev/null; then
    echo -e "${RED}❌ ERRO: 'cast' não está instalado${NC}"
    echo "Instale Foundry: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi

echo -e "${GREEN}✅ Ferramentas verificadas${NC}"
echo ""

# Descobrir endereços
echo -e "${BLUE}🔍 Descobrindo endereços...${NC}"
echo ""

# 1. Validador/Relayer Terra Classic
echo -e "${YELLOW}1️⃣  VALIDADOR + RELAYER TERRA CLASSIC${NC}"
echo "Chave KMS: alias/hyperlane-validator-signer-terraclassic"
VALIDATOR_TERRA_ETH=$(cast wallet address --aws alias/hyperlane-validator-signer-terraclassic 2>/dev/null || echo "ERRO")

if [ "$VALIDATOR_TERRA_ETH" != "ERRO" ]; then
    echo -e "   Formato Ethereum: ${GREEN}$VALIDATOR_TERRA_ETH${NC}"
    echo "   ⚠️  Conversão para Terra bech32 necessária"
    echo "   Use: https://www.mintscan.io/cosmos/address-converter"
    echo "   Ou use o script: ./eth-to-terra.py $VALIDATOR_TERRA_ETH"
    echo ""
else
    echo -e "   ${RED}❌ Erro ao obter endereço${NC}"
    echo "   Verifique se a chave KMS existe e tem as permissões corretas"
    echo ""
fi

# 2. Relayer BSC (verificar se existe)
echo -e "${YELLOW}2️⃣  RELAYER BSC${NC}"
echo "Chave KMS: alias/hyperlane-relayer-signer-bsc"
RELAYER_BSC=$(cast wallet address --aws alias/hyperlane-relayer-signer-bsc 2>/dev/null || echo "NAO_CRIADA")

if [ "$RELAYER_BSC" == "NAO_CRIADA" ]; then
    echo -e "   ${RED}⏳ Chave ainda não criada${NC}"
    echo "   Esta chave será necessária para o Relayer funcionar com BSC"
    echo ""
else
    echo -e "   Endereço: ${GREEN}$RELAYER_BSC${NC}"
    echo ""
fi

# Resumo
echo ""
echo "============================================"
echo "             📋 RESUMO"
echo "============================================"
echo ""

if [ "$VALIDATOR_TERRA_ETH" != "ERRO" ]; then
    echo -e "${GREEN}✅ Validador Terra Classic:${NC}"
    echo "   Ethereum: $VALIDATOR_TERRA_ETH"
    echo "   Terra:    (converter manualmente)"
    echo ""
    echo "   💰 Envie LUNC para esta carteira Terra!"
    echo "   Sugestão: 50-100 LUNC para começar"
    echo ""
fi

if [ "$RELAYER_BSC" != "NAO_CRIADA" ]; then
    echo -e "${GREEN}✅ Relayer BSC:${NC}"
    echo "   Endereço: $RELAYER_BSC"
    echo ""
    echo "   💰 Envie BNB para esta carteira!"
    echo "   Sugestão: 0.1-0.5 BNB para começar"
    echo ""
else
    echo -e "${YELLOW}⏳ Pendente:${NC}"
    echo "   - Criar chave KMS: hyperlane-relayer-signer-bsc"
    echo "   - Especificações: Asymmetric, Sign/Verify, ECC_SECG_P256K1"
    echo ""
fi

# Instruções de conversão
echo "============================================"
echo "      🔄 CONVERTER PARA FORMATO TERRA"
echo "============================================"
echo ""
echo "Para converter o endereço Ethereum para Terra:"
echo ""
echo "Opção 1 - Script Python (recomendado):"
if [ -f "./eth-to-terra.py" ]; then
    echo "   ./eth-to-terra.py $VALIDATOR_TERRA_ETH"
else
    echo "   (Script não encontrado - crie com o conteúdo fornecido)"
fi
echo ""
echo "Opção 2 - Online:"
echo "   1. Acesse: https://www.mintscan.io/cosmos/address-converter"
echo "   2. Cole o endereço Ethereum: $VALIDATOR_TERRA_ETH"
echo "   3. Selecione 'terra' como prefix"
echo "   4. Copie o endereço 'terra1...'"
echo ""

# Gerar comandos úteis
echo "============================================"
echo "         📝 COMANDOS ÚTEIS"
echo "============================================"
echo ""
echo "# Verificar saldo Terra Classic:"
echo "terrad query bank balances <ENDEREÇO_TERRA> \\"
echo "  --node https://rpc.terra-classic.hexxagon.io:443"
echo ""
echo "# Verificar saldo BSC:"
if [ "$RELAYER_BSC" != "NAO_CRIADA" ]; then
echo "cast balance $RELAYER_BSC --rpc-url https://bsc.drpc.org"
else
echo "cast balance <ENDEREÇO> --rpc-url https://bsc.drpc.org"
fi
echo ""
echo "# Iniciar apenas o validador:"
echo "docker-compose up -d validator-terraclassic"
echo ""
echo "# Ver logs do validador:"
echo "docker logs -f hpl-validator-terraclassic"
echo ""
echo "# Iniciar o relayer (após criar chave BSC):"
echo "docker-compose up -d relayer"
echo ""

echo -e "${GREEN}✅ Script concluído!${NC}"

