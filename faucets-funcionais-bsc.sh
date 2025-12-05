#!/bin/bash
# Script para testar e abrir faucets BSC testnet que realmente funcionam

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

BSC_ADDRESS="0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"

clear
echo "============================================================"
echo "  🔄 FAUCETS BSC TESTNET - TESTANDO ALTERNATIVAS"
echo "============================================================"
echo ""
echo -e "${BLUE}📍 Endereço:${NC} $BSC_ADDRESS"
echo ""

# Lista atualizada de faucets que podem funcionar
declare -a FAUCETS=(
    "https://testnet.bnbchain.org/faucet-smart|Faucet Oficial BSC (Principal)"
    "https://faucet.quicknode.com/binance-smart-chain/bnb-testnet|QuickNode Faucet"
    "https://www.bnbchain.org/en/testnet-faucet|BNB Chain Faucet Oficial"
    "https://tatum.io/faucets/bsc|Tatum Faucet"
    "https://www.alchemy.com/faucets/bnb-chain-testnet|Alchemy Faucet (se disponível)"
)

echo "⚠️  Chainlink Faucet não está funcionando"
echo ""
echo "Testando outros faucets disponíveis..."
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
echo "  📋 INSTRUÇÕES DETALHADAS"
echo "============================================================"
echo ""

echo "1. FAUCET OFICIAL BSC (MAIS CONFIÁVEL):"
echo "   https://testnet.bnbchain.org/faucet-smart"
echo "   • Cole: $BSC_ADDRESS"
echo "   • Complete captcha"
echo "   • Clique em 'Give me BNB'"
echo "   • ⚠️  Pode exigir conexão de carteira (MetaMask)"
echo ""

echo "2. QUICKNODE FAUCET:"
echo "   https://faucet.quicknode.com/binance-smart-chain/bnb-testnet"
echo "   • Cole: $BSC_ADDRESS"
echo "   • Complete captcha"
echo "   • Pode exigir login GitHub"
echo ""

echo "3. BNB CHAIN FAUCET OFICIAL:"
echo "   https://www.bnbchain.org/en/testnet-faucet"
echo "   • Cole: $BSC_ADDRESS"
echo "   • Complete verificação"
echo "   • Pode exigir conta/login"
echo ""

echo "4. TATUM FAUCET:"
echo "   https://tatum.io/faucets/bsc"
echo "   • Cole: $BSC_ADDRESS"
echo "   • Complete captcha"
echo ""

echo "============================================================"
echo "  💡 DICAS IMPORTANTES"
echo "============================================================"
echo ""
echo "• Faucet Oficial pode exigir MetaMask conectado"
echo "  → Configure MetaMask para BSC Testnet:"
echo "    Network: BSC Testnet"
echo "    RPC: https://bsc-testnet.publicnode.com"
echo "    Chain ID: 97"
echo "    Symbol: BNB"
echo ""
echo "• Alguns faucets exigem:"
echo "  → Login GitHub"
echo "  → Verificação de email"
echo "  → Conta no serviço"
echo ""
echo "• Tente TODOS os faucets - cada um tem limites diferentes"
echo ""
echo "• Se nenhum funcionar:"
echo "  → Aguarde 24 horas"
echo "  → Peça ajuda na comunidade (veja MENSAGEM-PARA-COMUNIDADE.txt)"
echo ""

echo "============================================================"
echo "  📊 VERIFICAR SALDO"
echo "============================================================"
echo ""
echo "Após tentar os faucets, verifique:"
echo "   ./verificar-saldos.sh"
echo ""
echo "Ou monitore continuamente:"
echo "   ./verificar-bnb-continuo.sh"
echo ""

