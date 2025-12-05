#!/bin/bash
# Script para obter BNB na BSC testnet - guia completo

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

BSC_ADDRESS="0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"

clear
echo "============================================================"
echo "  💰 OBTER BNB NA BSC TESTNET - GUIA COMPLETO"
echo "============================================================"
echo ""
echo -e "${BLUE}📍 Seu endereço BSC:${NC}"
echo "   $BSC_ADDRESS"
echo ""

# Verificar saldo
echo -e "${BLUE}📊 Verificando saldo atual...${NC}"
BALANCE=$(curl -s "https://api-testnet.bscscan.com/api?module=account&action=balance&address=${BSC_ADDRESS}&tag=latest" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); result=data.get('result', '0'); print(int(result) / 1000000000000000000)" 2>/dev/null || echo "0")

if (( $(awk "BEGIN {print ($BALANCE > 0.01)}") )); then
    echo -e "   ${GREEN}Saldo: ${BALANCE} BNB ✅${NC}"
    echo ""
    echo -e "${GREEN}✅ Você já tem saldo suficiente!${NC}"
    exit 0
else
    echo -e "   ${RED}Saldo: ${BALANCE} BNB ❌${NC}"
    echo ""
fi

echo "============================================================"
echo "  🚀 MÉTODO 1: FAUCET OFICIAL BSC (RECOMENDADO)"
echo "============================================================"
echo ""

# Abrir faucet oficial
if command -v xdg-open &> /dev/null; then
    echo "Abrindo faucet oficial..."
    xdg-open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
elif command -v gnome-open &> /dev/null; then
    gnome-open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
elif command -v open &> /dev/null; then
    open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
else
    echo "Acesse manualmente: https://testnet.bnbchain.org/faucet-smart"
fi

echo ""
echo "📝 INSTRUÇÕES:"
echo ""
echo "1. No site do faucet:"
echo ""
echo "   Opção A - Conectar Carteira:"
echo "   • Clique em 'Connect Wallet'"
echo "   • Conecte MetaMask ou outra carteira"
echo "   • Certifique-se de estar na rede BSC Testnet"
echo ""
echo "   Opção B - Inserir Endereço:"
echo "   • Cole este endereço no campo:"
echo -e "     ${GREEN}$BSC_ADDRESS${NC}"
echo ""
echo "2. Complete o captcha (se solicitado)"
echo ""
echo "3. Clique em 'Give me BNB' ou 'Request BNB'"
echo ""
echo "4. Aguarde confirmação (pode levar 1-5 minutos)"
echo ""
echo "5. Verifique o saldo:"
echo "   ./verificar-saldos.sh"
echo ""

echo "============================================================"
echo "  🔄 MÉTODO 2: FAUCETS ALTERNATIVOS"
echo "============================================================"
echo ""

echo "Se o faucet oficial não funcionar, tente estes:"
echo ""
echo "1. QuickNode BSC Faucet:"
echo "   https://faucet.quicknode.com/binance-smart-chain/bnb-testnet"
echo "   • Cole o endereço: $BSC_ADDRESS"
echo ""
echo "2. Chainlink Faucet:"
echo "   https://faucets.chain.link/bnb-chain-testnet"
echo "   • Conecte sua carteira ou cole o endereço"
echo ""
echo "3. Tatum Faucet:"
echo "   https://tatum.io/faucets/bsc"
echo "   • Cole o endereço: $BSC_ADDRESS"
echo ""

echo "============================================================"
echo "  📊 VERIFICAR SALDO"
echo "============================================================"
echo ""
echo "Explorer BSC Testnet:"
echo "   https://testnet.bscscan.com/address/$BSC_ADDRESS"
echo ""
echo "Ou execute:"
echo "   ./verificar-saldos.sh"
echo ""
echo "============================================================"
echo ""

# Criar script de monitoramento
cat > verificar-bnb-continuo.sh << 'EOFSCRIPT'
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
EOFSCRIPT

chmod +x verificar-bnb-continuo.sh

echo "💡 DICA: Execute este comando para monitorar o saldo automaticamente:"
echo "   ./verificar-bnb-continuo.sh"
echo ""

