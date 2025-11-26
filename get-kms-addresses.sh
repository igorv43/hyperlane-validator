#!/bin/bash

# Script para descobrir endereços das chaves AWS KMS
# ⚠️ APENAS PARA BSC (EVM) - Terra Classic usa hexKey
# Autor: Configuração Hyperlane Validator
# Data: 2025-11-26

set -e

echo "============================================"
echo "   DESCOBRIR ENDEREÇOS AWS KMS (BSC)"
echo "============================================"
echo ""
echo "⚠️  IMPORTANTE: Este script é APENAS para BSC!"
echo "    Terra Classic NÃO suporta AWS KMS."
echo "    Use hexKey para Terra Classic."
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
echo -e "${BLUE}🔍 Descobrindo endereço KMS para BSC...${NC}"
echo ""

# Relayer BSC
echo -e "${YELLOW}📍 RELAYER BSC (EVM)${NC}"
echo "Chave KMS: alias/hyperlane-relayer-signer-bsc"
RELAYER_BSC=$(cast wallet address --aws alias/hyperlane-relayer-signer-bsc 2>/dev/null || echo "NAO_CRIADA")

if [ "$RELAYER_BSC" == "NAO_CRIADA" ]; then
    echo -e "   ${RED}⏳ Chave ainda não criada${NC}"
    echo ""
    echo "   Para criar:"
    echo "   1. Acesse: https://console.aws.amazon.com/kms"
    echo "   2. Clique em 'Create key'"
    echo "   3. Tipo: Asymmetric"
    echo "   4. Uso: Sign and verify"
    echo "   5. Spec: ECC_SECG_P256K1"
    echo "   6. Alias: hyperlane-relayer-signer-bsc"
    echo ""
    echo "   Ou siga: SETUP-AWS-KMS.md - Passo 2.2"
    echo ""
else
    echo -e "   ✅ Endereço: ${GREEN}$RELAYER_BSC${NC}"
    echo ""
fi

# Resumo
echo ""
echo "============================================"
echo "             📋 RESUMO"
echo "============================================"
echo ""

if [ "$RELAYER_BSC" != "NAO_CRIADA" ]; then
    echo -e "${GREEN}✅ Relayer BSC (AWS KMS):${NC}"
    echo "   Endereço: $RELAYER_BSC"
    echo ""
    echo "   💰 Envie BNB para esta carteira!"
    echo "   Sugestão: 0.1-0.5 BNB para começar"
    echo ""
    echo "   Verificar saldo:"
    echo "   cast balance $RELAYER_BSC --rpc-url https://bsc.drpc.org"
    echo ""
else
    echo -e "${YELLOW}⏳ Pendente:${NC}"
    echo "   - Criar chave KMS: hyperlane-relayer-signer-bsc"
    echo "   - Seguir: SETUP-AWS-KMS.md - Passo 2.2"
    echo ""
fi

# Lembrete sobre Terra Classic
echo "============================================"
echo "      ⚠️  TERRA CLASSIC (COSMOS)"
echo "============================================"
echo ""
echo -e "${RED}Terra Classic NÃO usa AWS KMS!${NC}"
echo ""
echo "Para Terra Classic, use hexKey (chave privada local):"
echo ""
echo "1. Gerar nova chave:"
echo "   cast wallet new"
echo ""
echo "2. Ou usar chave existente"
echo ""
echo "3. Descobrir endereços:"
echo "   ./get-address-from-hexkey.py 0xSUA_CHAVE_PRIVADA"
echo ""
echo "4. Configurar em:"
echo "   - hyperlane/validator.terraclassic.json"
echo "   - hyperlane/relayer.json"
echo ""
echo "📖 Ver guia completo: QUICKSTART.md"
echo ""

# Comandos úteis
echo "============================================"
echo "         📝 COMANDOS ÚTEIS"
echo "============================================"
echo ""

if [ "$RELAYER_BSC" != "NAO_CRIADA" ]; then
    echo "# Verificar saldo BSC:"
    echo "cast balance $RELAYER_BSC --rpc-url https://bsc.drpc.org"
    echo ""
    echo "# Enviar BNB (exemplo):"
    echo "cast send <DESTINO> \\"
    echo "  --value 0.1ether \\"
    echo "  --aws alias/hyperlane-relayer-signer-bsc \\"
    echo "  --rpc-url https://bsc.drpc.org"
    echo ""
fi

echo "# Iniciar relayer:"
echo "docker-compose up -d relayer"
echo ""
echo "# Ver logs do relayer:"
echo "docker logs -f hpl-relayer"
echo ""

echo -e "${GREEN}✅ Script concluído!${NC}"
