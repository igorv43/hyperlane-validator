#!/bin/bash
# Monitora saldo BSC continuamente

BSC_ADDRESS="0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"

echo "Monitorando saldo BSC Testnet..."
echo "Pressione Ctrl+C para parar"
echo ""

while true; do
    BALANCE=$(curl -s "https://api-testnet.bscscan.com/api?module=account&action=balance&address=${BSC_ADDRESS}&tag=latest" \
        | python3 -c "import sys, json; data=json.load(sys.stdin); result=data.get('result', '0'); print(int(result) / 1000000000000000000)" 2>/dev/null || echo "0")
    
    TIMESTAMP=$(date '+%H:%M:%S')
    if (( $(awk "BEGIN {print ($BALANCE > 0)}") )); then
        echo "[$TIMESTAMP] ✅ Saldo: $BALANCE BNB"
        echo ""
        echo "🎉 Tokens recebidos com sucesso!"
        break
    else
        echo "[$TIMESTAMP] ⏳ Saldo: $BALANCE BNB (aguardando...)"
    fi
    
    sleep 10
done
