#!/bin/bash
# Monitora a transação BSC e verifica quando o saldo chegar

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BSC_ADDRESS="0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"
TX_HASH="0x408d06acd4247789e82b6ffb6bbda2f7e69fba4e03975e6b92bf755619f81613"

echo "============================================================"
echo "  📊 MONITORANDO TRANSAÇÃO BSC TESTNET"
echo "============================================================"
echo ""
echo "Endereço: $BSC_ADDRESS"
echo "Transaction Hash: $TX_HASH"
echo ""
echo "Explorer: https://testnet.bscscan.com/tx/$TX_HASH"
echo ""
echo "Monitorando saldo... (Pressione Ctrl+C para parar)"
echo ""

while true; do
    BALANCE=$(curl -s "https://api-testnet.bscscan.com/api?module=account&action=balance&address=${BSC_ADDRESS}&tag=latest" \
        | python3 -c "import sys, json; data=json.load(sys.stdin); result=data.get('result', '0'); print(int(result) / 1000000000000000000)" 2>/dev/null || echo "0")
    
    TIMESTAMP=$(date '+%H:%M:%S')
    
    if (( $(awk "BEGIN {print ($BALANCE > 0)}") )); then
        echo -e "[$TIMESTAMP] ${GREEN}✅ Saldo recebido: ${BALANCE} BNB${NC}"
        echo ""
        echo "============================================================"
        echo -e "  ${GREEN}🎉 SUCESSO! TOKENS RECEBIDOS!${NC}"
        echo "============================================================"
        echo ""
        echo "Seu saldo atual: $BALANCE BNB"
        echo ""
        echo "Explorer: https://testnet.bscscan.com/address/$BSC_ADDRESS"
        echo ""
        break
    else
        echo -e "[$TIMESTAMP] ${YELLOW}⏳ Saldo: ${BALANCE} BNB (aguardando confirmação...)${NC}"
    fi
    
    sleep 10
done

