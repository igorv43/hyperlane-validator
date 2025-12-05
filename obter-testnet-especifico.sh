#!/bin/bash
# Script específico para obter tokens na TESTNET (não devnet)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SOLANA_ADDRESS="2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9"

clear
echo "============================================================"
echo "  ⚠️  IMPORTANTE: DEVNET ≠ TESTNET"
echo "============================================================"
echo ""
echo -e "${YELLOW}❌ NÃO é possível transferir tokens entre devnet e testnet${NC}"
echo ""
echo "São redes completamente separadas:"
echo "  • Devnet: Rede de desenvolvimento"
echo "  • Testnet: Rede de testes (o que você precisa)"
echo ""
echo "============================================================"
echo "  💰 OBTER TOKENS NA TESTNET"
echo "============================================================"
echo ""
echo -e "${BLUE}Seu endereço:${NC} $SOLANA_ADDRESS"
echo ""

# Verificar saldo atual na testnet
echo -e "${BLUE}📊 Verificando saldo na TESTNET...${NC}"
BALANCE=$(curl -s -X POST "https://api.testnet.solana.com" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOLANA_ADDRESS\"]}" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 0) / 1000000000)" 2>/dev/null || echo "0")

if (( $(awk "BEGIN {print ($BALANCE > 0)}") )); then
    echo -e "   ${GREEN}✅ Saldo atual: ${BALANCE} SOL${NC}"
    echo ""
    echo -e "${GREEN}✅ Você já tem tokens na testnet!${NC}"
    exit 0
else
    echo -e "   ${RED}Saldo atual: ${BALANCE} SOL ❌${NC}"
    echo ""
fi

echo "============================================================"
echo "  🚀 MÉTODOS PARA OBTER TOKENS NA TESTNET"
echo "============================================================"
echo ""

# Método 1: Solana CLI com testnet específico
if command -v solana &> /dev/null; then
    echo -e "${BLUE}Método 1: Solana CLI (TESTNET)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Configurando para TESTNET..."
    solana config set --url https://api.testnet.solana.com > /dev/null 2>&1
    
    echo "Tentando airdrop na TESTNET..."
    for amount in 1 0.5 0.1; do
        echo -e "   Tentando ${amount} SOL..."
        RESULT=$(solana airdrop $amount $SOLANA_ADDRESS --url https://api.testnet.solana.com 2>&1)
        
        if echo "$RESULT" | grep -q "Signature"; then
            echo -e "   ${GREEN}✅ Airdrop solicitado!${NC}"
            echo "   Aguardando confirmação (15 segundos)..."
            sleep 15
            
            # Verificar novo saldo
            NEW_BALANCE=$(curl -s -X POST "https://api.testnet.solana.com" \
                -H "Content-Type: application/json" \
                -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOLANA_ADDRESS\"]}" \
                | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 0) / 1000000000)" 2>/dev/null || echo "0")
            
            if (( $(awk "BEGIN {print ($NEW_BALANCE > 0)}") )); then
                echo -e "   ${GREEN}✅ Sucesso! Novo saldo: ${NEW_BALANCE} SOL${NC}"
                echo ""
                echo "============================================================"
                echo -e "  ${GREEN}✅ TOKENS OBTIDOS COM SUCESSO NA TESTNET!${NC}"
                echo "============================================================"
                exit 0
            fi
            break
        elif echo "$RESULT" | grep -qi "rate limit"; then
            echo -e "   ${YELLOW}⚠️  Rate limit atingido${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Falhou${NC}"
        fi
        sleep 5
    done
    echo ""
fi

# Método 2: Faucet web oficial (TESTNET)
echo -e "${BLUE}Método 2: Faucet Web Oficial (TESTNET)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  IMPORTANTE: Selecione 'testnet' (não 'devnet')!"
echo ""
echo "1. Acesse: https://faucet.solana.com/"
echo ""
echo "2. No dropdown no topo, selecione: ${GREEN}testnet${NC}"
echo "   (NÃO selecione 'devnet')"
echo ""
echo "3. Cole este endereço:"
echo -e "   ${GREEN}$SOLANA_ADDRESS${NC}"
echo ""
echo "4. Clique em 'Confirm Airdrop'"
echo ""
echo "5. Aguarde 10-30 segundos"
echo ""

# Tentar abrir no navegador
if command -v xdg-open &> /dev/null; then
    echo "Abrindo faucet no navegador..."
    xdg-open "https://faucet.solana.com/" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
    echo ""
    echo "⚠️  LEMBRE-SE: Selecione 'testnet' no dropdown!"
    echo ""
elif command -v gnome-open &> /dev/null; then
    gnome-open "https://faucet.solana.com/" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
elif command -v open &> /dev/null; then
    open "https://faucet.solana.com/" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
fi

echo "============================================================"
echo "  📊 VERIFICAR SALDO APÓS OBTER TOKENS"
echo "============================================================"
echo ""
echo "Execute:"
echo "   ./verificar-saldos.sh"
echo ""
echo "Ou verifique diretamente:"
echo "   https://explorer.solana.com/address/$SOLANA_ADDRESS?cluster=testnet"
echo ""

