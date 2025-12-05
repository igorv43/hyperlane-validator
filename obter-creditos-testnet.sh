#!/bin/bash
# Script para obter créditos (tokens de teste) nas redes Solana e BSC Testnet

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "============================================================"
echo "  💰 OBTENDO CRÉDITOS NAS REDES TESTNET"
echo "============================================================"
echo ""

# Verificar dependências
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 não está instalado${NC}"
    exit 1
fi

# Obter endereço Solana
echo -e "${BLUE}🔍 Obtendo endereço Solana...${NC}"
SOLANA_ADDRESS=$(python3 get-solana-address.py 2>/dev/null | grep "Endereço Solana:" | cut -d: -f2 | xargs)

if [ -z "$SOLANA_ADDRESS" ]; then
    echo -e "${RED}❌ Não foi possível obter endereço Solana${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Endereço Solana: ${SOLANA_ADDRESS}${NC}"
echo ""

# Verificar saldo Solana atual
echo -e "${BLUE}📊 Verificando saldo Solana atual...${NC}"
SOLANA_BALANCE=$(curl -s -X POST "https://api.testnet.solana.com" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOLANA_ADDRESS\"]}" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 0) / 1000000000)" 2>/dev/null || echo "0")

echo -e "Saldo atual: ${YELLOW}${SOLANA_BALANCE} SOL${NC}"
echo ""

# Tentar obter tokens Solana via airdrop
SOLANA_BALANCE_FLOAT=$(echo "$SOLANA_BALANCE" | awk '{print $1+0}')
if (( $(awk "BEGIN {print ($SOLANA_BALANCE_FLOAT < 0.1)}") )); then
    echo -e "${YELLOW}⚠️  Saldo baixo. Tentando obter tokens via airdrop...${NC}"
    
    # Tentar múltiplos valores de airdrop
    for amount in 2000000000 1000000000 500000000; do
        echo -e "${BLUE}Tentando airdrop de $((amount / 1000000000)) SOL...${NC}"
        RESULT=$(curl -s -X POST "https://api.testnet.solana.com" \
            -H "Content-Type: application/json" \
            -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"requestAirdrop\",\"params\":[\"$SOLANA_ADDRESS\",$amount]}" \
            | python3 -c "import sys, json; data=json.load(sys.stdin); print('SUCCESS' if 'result' in data else 'ERROR')" 2>/dev/null || echo "ERROR")
        
        if [ "$RESULT" == "SUCCESS" ]; then
            echo -e "${GREEN}✅ Airdrop solicitado com sucesso!${NC}"
            echo "Aguardando confirmação (10 segundos)..."
            sleep 10
            break
        else
            echo -e "${YELLOW}⚠️  Airdrop falhou, tentando próximo método...${NC}"
        fi
    done
    
    # Verificar novo saldo
    sleep 5
    NEW_BALANCE=$(curl -s -X POST "https://api.testnet.solana.com" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOLANA_ADDRESS\"]}" \
        | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 0) / 1000000000)" 2>/dev/null || echo "0")
    
    NEW_BALANCE_FLOAT=$(echo "$NEW_BALANCE" | awk '{print $1+0}')
    OLD_BALANCE_FLOAT=$(echo "$SOLANA_BALANCE" | awk '{print $1+0}')
    if (( $(awk "BEGIN {print ($NEW_BALANCE_FLOAT > $OLD_BALANCE_FLOAT)}") )); then
        echo -e "${GREEN}✅ Saldo atualizado: ${NEW_BALANCE} SOL${NC}"
        SOLANA_BALANCE=$NEW_BALANCE
    else
        echo -e "${YELLOW}⚠️  Airdrop automático não funcionou. Use o faucet manual:${NC}"
        echo "   https://faucet.solana.com/"
        echo "   Endereço: $SOLANA_ADDRESS"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Obter endereço BSC
echo -e "${BLUE}🔍 Obtendo endereço BSC...${NC}"
BSC_ADDRESS=""

# Tentar via AWS KMS
if command -v cast &> /dev/null && [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs) 2>/dev/null || true
    BSC_ADDRESS=$(cast wallet address --aws alias/hyperlane-relayer-signer-bsc 2>/dev/null || echo "")
fi

if [ -z "$BSC_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️  Não foi possível obter endereço BSC automaticamente${NC}"
    echo "   Motivos possíveis:"
    echo "   - AWS KMS não configurado"
    echo "   - Credenciais AWS não definidas"
    echo "   - Chave KMS não criada"
    echo ""
    echo "   Para obter manualmente:"
    echo "   1. Configure AWS CLI"
    echo "   2. Execute: ./get-kms-addresses.sh"
    echo ""
    BSC_ADDRESS="NÃO_DISPONÍVEL"
else
    echo -e "${GREEN}✅ Endereço BSC: ${BSC_ADDRESS}${NC}"
    echo ""
    
    # Verificar saldo BSC atual
    echo -e "${BLUE}📊 Verificando saldo BSC atual...${NC}"
    BSC_BALANCE=$(curl -s "https://api-testnet.bscscan.com/api?module=account&action=balance&address=${BSC_ADDRESS}&tag=latest" \
        | python3 -c "import sys, json; data=json.load(sys.stdin); print(int(data.get('result', 0)) / 1000000000000000000)" 2>/dev/null || echo "0")
    
    echo -e "Saldo atual: ${YELLOW}${BSC_BALANCE} BNB${NC}"
    echo ""
    
    BSC_BALANCE_FLOAT=$(echo "$BSC_BALANCE" | awk '{print $1+0}')
    if (( $(awk "BEGIN {print ($BSC_BALANCE_FLOAT < 0.01)}") )); then
        echo -e "${YELLOW}⚠️  Saldo BSC baixo. Use o faucet manual:${NC}"
        echo "   https://testnet.bnbchain.org/faucet-smart"
        echo "   Endereço: $BSC_ADDRESS"
        echo ""
    fi
fi

# Resumo final
echo "============================================================"
echo "  📋 RESUMO DOS SALDOS"
echo "============================================================"
echo ""
echo -e "${GREEN}🌐 SOLANA TESTNET${NC}"
echo "   Endereço: $SOLANA_ADDRESS"
echo -e "   Saldo: ${YELLOW}${SOLANA_BALANCE} SOL${NC}"
echo "   Explorer: https://explorer.solana.com/address/$SOLANA_ADDRESS?cluster=testnet"
echo ""

if [ "$BSC_ADDRESS" != "NÃO_DISPONÍVEL" ]; then
    echo -e "${GREEN}🌐 BSC TESTNET${NC}"
    echo "   Endereço: $BSC_ADDRESS"
    echo -e "   Saldo: ${YELLOW}${BSC_BALANCE} BNB${NC}"
    echo "   Explorer: https://testnet.bscscan.com/address/$BSC_ADDRESS"
    echo ""
else
    echo -e "${YELLOW}🌐 BSC TESTNET${NC}"
    echo "   Endereço: Não disponível (configure AWS KMS)"
    echo ""
fi

echo "============================================================"
echo "  🔗 FAUCETS MANUAIS (se necessário)"
echo "============================================================"
echo ""
echo "Solana Testnet:"
echo "  https://faucet.solana.com/"
echo "  Endereço: $SOLANA_ADDRESS"
echo ""
if [ "$BSC_ADDRESS" != "NÃO_DISPONÍVEL" ]; then
    echo "BSC Testnet:"
    echo "  https://testnet.bnbchain.org/faucet-smart"
    echo "  Endereço: $BSC_ADDRESS"
    echo ""
fi

echo -e "${GREEN}✅ Verificação concluída!${NC}"
echo ""

