#!/bin/bash
# Script para verificar saldos atuais nas redes testnet

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "============================================================"
echo "  📊 VERIFICANDO SALDOS NAS REDES TESTNET"
echo "============================================================"
echo ""

# Solana Testnet
echo -e "${BLUE}🌐 SOLANA TESTNET${NC}"
SOLANA_ADDRESS="2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9"
SOLANA_BALANCE=$(curl -s -X POST "https://api.testnet.solana.com" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOLANA_ADDRESS\"]}" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 0) / 1000000000)" 2>/dev/null || echo "0")

echo "   Endereço: $SOLANA_ADDRESS"
if (( $(awk "BEGIN {print ($SOLANA_BALANCE > 0)}") )); then
    echo -e "   Saldo: ${GREEN}${SOLANA_BALANCE} SOL ✅${NC}"
else
    echo -e "   Saldo: ${RED}${SOLANA_BALANCE} SOL ❌${NC}"
    echo -e "   ${YELLOW}⚠️  Obtenha tokens em: https://faucet.solana.com/${NC}"
fi
echo "   Explorer: https://explorer.solana.com/address/$SOLANA_ADDRESS?cluster=testnet"
echo ""

# BSC Testnet
echo -e "${BLUE}🌐 BSC TESTNET${NC}"
BSC_ADDRESS=""

# Tentar obter via cast se disponível
if command -v cast &> /dev/null && [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs) 2>/dev/null || true
    BSC_ADDRESS=$(cast wallet address --aws alias/hyperlane-relayer-signer-bsc 2>/dev/null || echo "")
fi

if [ -z "$BSC_ADDRESS" ]; then
    echo -e "   ${YELLOW}⚠️  Endereço não disponível${NC}"
    echo "   Configure AWS KMS e execute: ./get-kms-addresses.sh"
    echo ""
else
    echo "   Endereço: $BSC_ADDRESS"
    BSC_BALANCE=$(curl -s "https://api-testnet.bscscan.com/api?module=account&action=balance&address=${BSC_ADDRESS}&tag=latest" \
        | python3 -c "import sys, json; data=json.load(sys.stdin); print(int(data.get('result', 0)) / 1000000000000000000)" 2>/dev/null || echo "0")
    
    if (( $(awk "BEGIN {print ($BSC_BALANCE > 0)}") )); then
        echo -e "   Saldo: ${GREEN}${BSC_BALANCE} BNB ✅${NC}"
    else
        echo -e "   Saldo: ${RED}${BSC_BALANCE} BNB ❌${NC}"
        echo -e "   ${YELLOW}⚠️  Obtenha tokens em: https://testnet.bnbchain.org/faucet-smart${NC}"
    fi
    echo "   Explorer: https://testnet.bscscan.com/address/$BSC_ADDRESS"
    echo ""
fi

echo "============================================================"
echo ""

