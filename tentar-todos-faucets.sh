#!/bin/bash
# Script para tentar todos os faucets BSC testnet disponíveis

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

BSC_ADDRESS="0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"

clear
echo "============================================================"
echo "  🔄 TENTAR TODOS OS FAUCETS BSC TESTNET"
echo "============================================================"
echo ""
echo -e "${BLUE}📍 Endereço:${NC} $BSC_ADDRESS"
echo ""

# Lista de faucets
declare -a FAUCETS=(
    "https://testnet.bnbchain.org/faucet-smart|Faucet Oficial BSC"
    "https://faucet.quicknode.com/binance-smart-chain/bnb-testnet|QuickNode Faucet"
    "https://faucets.chain.link/bnb-chain-testnet|Chainlink Faucet"
    "https://tatum.io/faucets/bsc|Tatum Faucet"
    "https://www.bnbchain.org/en/testnet-faucet|BNB Chain Faucet"
)

echo "Abrindo todos os faucets disponíveis..."
echo ""

for faucet_info in "${FAUCETS[@]}"; do
    IFS='|' read -r url name <<< "$faucet_info"
    echo -e "${BLUE}🌐 Abrindo:${NC} $name"
    echo "   URL: $url"
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "$url" 2>/dev/null &
    elif command -v gnome-open &> /dev/null; then
        gnome-open "$url" 2>/dev/null &
    elif command -v open &> /dev/null; then
        open "$url" 2>/dev/null &
    fi
    
    sleep 2
done

echo ""
echo "============================================================"
echo "  📋 INSTRUÇÕES PARA CADA FAUCET"
echo "============================================================"
echo ""

echo "1. FAUCET OFICIAL BSC:"
echo "   https://testnet.bnbchain.org/faucet-smart"
echo "   • Cole: $BSC_ADDRESS"
echo "   • Complete captcha"
echo "   • Clique em 'Give me BNB'"
echo ""

echo "2. QUICKNODE FAUCET:"
echo "   https://faucet.quicknode.com/binance-smart-chain/bnb-testnet"
echo "   • Cole: $BSC_ADDRESS"
echo "   • Complete captcha"
echo "   • Solicite tokens"
echo ""

echo "3. CHAINLINK FAUCET:"
echo "   https://faucets.chain.link/bnb-chain-testnet"
echo "   • Conecte carteira OU cole: $BSC_ADDRESS"
echo "   • Solicite tokens"
echo ""

echo "4. TATUM FAUCET:"
echo "   https://tatum.io/faucets/bsc"
echo "   • Cole: $BSC_ADDRESS"
echo "   • Complete captcha"
echo "   • Solicite tokens"
echo ""

echo "5. BNB CHAIN FAUCET:"
echo "   https://www.bnbchain.org/en/testnet-faucet"
echo "   • Cole: $BSC_ADDRESS"
echo "   • Complete verificação"
echo "   • Solicite tokens"
echo ""

echo "============================================================"
echo "  💡 DICAS IMPORTANTES"
echo "============================================================"
echo ""
echo "• Tente TODOS os faucets - alguns podem ter rate limits"
echo "• Alguns faucets podem exigir login/conexão de carteira"
echo "• Aguarde alguns minutos entre tentativas"
echo "• Verifique o saldo após cada tentativa:"
echo "   ./verificar-saldos.sh"
echo ""
echo "• Se NENHUM funcionar, pode ser necessário:"
echo "   - Aguardar algumas horas (rate limits)"
echo "   - Usar uma conta/carteira diferente"
echo "   - Verificar se a rede BSC testnet está operacional"
echo ""

echo "============================================================"
echo "  📊 MONITORAR SALDO"
echo "============================================================"
echo ""
echo "Execute em outro terminal para monitorar:"
echo "   ./verificar-bnb-continuo.sh"
echo ""
echo "Ou verifique manualmente:"
echo "   ./verificar-saldos.sh"
echo ""

