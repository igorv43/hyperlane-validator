#!/bin/bash
# Script para obter tokens BSC Testnet

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "============================================================"
echo "  💰 OBTER TOKENS BSC TESTNET"
echo "============================================================"
echo ""

# Verificar dependências
if ! command -v cast &> /dev/null; then
    echo -e "${RED}❌ 'cast' não está instalado${NC}"
    echo ""
    echo "Instale Foundry:"
    echo "  curl -L https://foundry.paradigm.xyz | bash"
    echo "  foundryup"
    exit 1
fi

# Carregar variáveis de ambiente
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs) 2>/dev/null
else
    echo -e "${YELLOW}⚠️  Arquivo .env não encontrado${NC}"
    echo "Certifique-se de ter as credenciais AWS configuradas"
    echo ""
fi

# Obter endereço BSC
echo -e "${BLUE}🔍 Obtendo endereço BSC da chave AWS KMS...${NC}"
echo ""

BSC_ADDRESS=$(cast wallet address --aws alias/hyperlane-relayer-signer-bsc 2>&1)

if echo "$BSC_ADDRESS" | grep -qi "error\|failed\|not found\|NAO_CRIADA"; then
    echo -e "${RED}❌ Erro ao obter endereço BSC${NC}"
    echo ""
    echo "Possíveis causas:"
    echo "  1. Chave AWS KMS não criada"
    echo "  2. Credenciais AWS não configuradas"
    echo "  3. Alias da chave incorreto"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔧 CONFIGURAR AWS KMS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Acesse: https://console.aws.amazon.com/kms"
    echo ""
    echo "2. Clique em 'Create key'"
    echo ""
    echo "3. Configure:"
    echo "   • Tipo: Asymmetric"
    echo "   • Uso: Sign and verify"
    echo "   • Spec: ECC_SECG_P256K1"
    echo "   • Alias: hyperlane-relayer-signer-bsc"
    echo ""
    echo "4. Configure credenciais AWS no arquivo .env:"
    echo "   AWS_ACCESS_KEY_ID=..."
    echo "   AWS_SECRET_ACCESS_KEY=..."
    echo "   AWS_REGION=us-east-1"
    echo ""
    echo "5. Execute novamente: ./obter-bsc-testnet.sh"
    echo ""
    echo "📖 Guia completo: SETUP-AWS-KMS.md"
    exit 1
fi

# Remover possíveis mensagens de erro e pegar apenas o endereço
BSC_ADDRESS=$(echo "$BSC_ADDRESS" | grep -E "^0x[a-fA-F0-9]{40}$" | head -1)

if [ -z "$BSC_ADDRESS" ]; then
    echo -e "${RED}❌ Não foi possível extrair o endereço BSC${NC}"
    echo "Saída: $BSC_ADDRESS"
    exit 1
fi

echo -e "${GREEN}✅ Endereço BSC obtido:${NC}"
echo "   $BSC_ADDRESS"
echo ""

# Verificar saldo atual
echo -e "${BLUE}📊 Verificando saldo atual na BSC Testnet...${NC}"
BSC_BALANCE=$(curl -s "https://api-testnet.bscscan.com/api?module=account&action=balance&address=${BSC_ADDRESS}&tag=latest" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); result=data.get('result', '0'); print(int(result) / 1000000000000000000)" 2>/dev/null || echo "0")

echo -e "   Saldo atual: ${YELLOW}${BSC_BALANCE} BNB${NC}"
echo ""

if (( $(awk "BEGIN {print ($BSC_BALANCE > 0.01)}") )); then
    echo -e "${GREEN}✅ Você já tem saldo suficiente na BSC Testnet!${NC}"
    echo ""
    echo "Explorer: https://testnet.bscscan.com/address/$BSC_ADDRESS"
    exit 0
fi

echo "============================================================"
echo "  🚀 OBTER TOKENS BSC TESTNET"
echo "============================================================"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC} BSC Testnet requer obtenção manual via faucet"
echo ""

# Tentar abrir faucet no navegador
echo -e "${BLUE}🌐 Abrindo faucet BSC Testnet no navegador...${NC}"

if command -v xdg-open &> /dev/null; then
    xdg-open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
elif command -v gnome-open &> /dev/null; then
    gnome-open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
elif command -v open &> /dev/null; then
    open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
else
    echo -e "${YELLOW}⚠️  Não foi possível abrir automaticamente${NC}"
    echo ""
    echo "Acesse manualmente: https://testnet.bnbchain.org/faucet-smart"
fi

echo ""
echo "============================================================"
echo "  📝 INSTRUÇÕES PASSO A PASSO"
echo "============================================================"
echo ""
echo "1. No site do faucet:"
echo ""
echo "   Opção A - Conectar Carteira:"
echo "   • Clique em 'Connect Wallet'"
echo "   • Conecte sua MetaMask ou outra carteira"
echo "   • Certifique-se de estar na rede BSC Testnet"
echo ""
echo "   Opção B - Inserir Endereço Diretamente:"
echo "   • Cole este endereço:"
echo -e "     ${GREEN}$BSC_ADDRESS${NC}"
echo ""
echo "2. Complete o captcha (se solicitado)"
echo ""
echo "3. Clique em 'Give me BNB' ou 'Request BNB'"
echo ""
echo "4. Aguarde confirmação (pode levar alguns minutos)"
echo ""
echo "5. Verifique o saldo:"
echo "   ./verificar-saldos.sh"
echo ""
echo "============================================================"
echo "  🔗 FAUCETS ALTERNATIVOS"
echo "============================================================"
echo ""
echo "Se o faucet oficial não funcionar, tente:"
echo ""
echo "1. QuickNode BSC Faucet:"
echo "   https://faucet.quicknode.com/binance-smart-chain/bnb-testnet"
echo ""
echo "2. Chainlink Faucet:"
echo "   https://faucets.chain.link/bnb-chain-testnet"
echo ""
echo "3. Tatum Faucet:"
echo "   https://tatum.io/faucets/bsc"
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

