#!/bin/bash
# Script agressivo para obter tokens de teste - tenta múltiplos métodos

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SOLANA_ADDRESS="2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9"

echo "============================================================"
echo "  🚀 OBTENDO TOKENS DE TESTE - MÉTODO AGRESSIVO"
echo "============================================================"
echo ""

# Função para verificar saldo Solana
check_solana_balance() {
    curl -s -X POST "https://api.testnet.solana.com" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOLANA_ADDRESS\"]}" \
        | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 0) / 1000000000)" 2>/dev/null || echo "0"
}

echo -e "${BLUE}📊 Saldo inicial:${NC}"
INITIAL_BALANCE=$(check_solana_balance)
echo -e "   ${YELLOW}${INITIAL_BALANCE} SOL${NC}"
echo ""

# Método 1: Solana CLI airdrop (múltiplas tentativas)
if command -v solana &> /dev/null; then
    echo -e "${BLUE}🔄 Método 1: Solana CLI Airdrop${NC}"
    solana config set --url https://api.testnet.solana.com > /dev/null 2>&1
    
    for amount in 1 0.5 0.1; do
        echo -e "   Tentando airdrop de ${amount} SOL..."
        if solana airdrop $amount $SOLANA_ADDRESS --url https://api.testnet.solana.com 2>/dev/null; then
            echo -e "   ${GREEN}✅ Airdrop de ${amount} SOL solicitado!${NC}"
            sleep 15
            NEW_BALANCE=$(check_solana_balance)
            if (( $(awk "BEGIN {print ($NEW_BALANCE > $INITIAL_BALANCE)}") )); then
                echo -e "   ${GREEN}✅ Sucesso! Novo saldo: ${NEW_BALANCE} SOL${NC}"
                INITIAL_BALANCE=$NEW_BALANCE
                break
            fi
        else
            echo -e "   ${YELLOW}⚠️  Falhou, tentando próximo valor...${NC}"
        fi
        sleep 5
    done
    echo ""
fi

# Método 2: API direta do Solana (múltiplos valores)
echo -e "${BLUE}🔄 Método 2: API Solana Direta${NC}"
for amount in 2000000000 1000000000 500000000 100000000; do
    echo -e "   Tentando airdrop de $((amount / 1000000000)) SOL via API..."
    RESULT=$(curl -s -X POST "https://api.testnet.solana.com" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"requestAirdrop\",\"params\":[\"$SOLANA_ADDRESS\",$amount]}" \
        | python3 -c "import sys, json; data=json.load(sys.stdin); print('SUCCESS' if 'result' in data and data['result'] else 'ERROR')" 2>/dev/null || echo "ERROR")
    
    if [ "$RESULT" == "SUCCESS" ]; then
        echo -e "   ${GREEN}✅ Airdrop solicitado!${NC}"
        sleep 15
        NEW_BALANCE=$(check_solana_balance)
        if (( $(awk "BEGIN {print ($NEW_BALANCE > $INITIAL_BALANCE)}") )); then
            echo -e "   ${GREEN}✅ Sucesso! Novo saldo: ${NEW_BALANCE} SOL${NC}"
            INITIAL_BALANCE=$NEW_BALANCE
            break
        fi
    else
        echo -e "   ${YELLOW}⚠️  Falhou${NC}"
    fi
    sleep 3
done
echo ""

# Método 3: Tentar diferentes RPC endpoints
echo -e "${BLUE}🔄 Método 3: Endpoints RPC Alternativos${NC}"
RPC_ENDPOINTS=(
    "https://api.testnet.solana.com"
    "https://testnet.sonic.game"
    "https://rpc.testnet.sonic.game"
)

for rpc in "${RPC_ENDPOINTS[@]}"; do
    echo -e "   Tentando via: $rpc"
    RESULT=$(curl -s -X POST "$rpc" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"requestAirdrop\",\"params\":[\"$SOLANA_ADDRESS\",1000000000]}" \
        | python3 -c "import sys, json; data=json.load(sys.stdin); print('SUCCESS' if 'result' in data and data['result'] else 'ERROR')" 2>/dev/null || echo "ERROR")
    
    if [ "$RESULT" == "SUCCESS" ]; then
        echo -e "   ${GREEN}✅ Airdrop solicitado!${NC}"
        sleep 15
        NEW_BALANCE=$(check_solana_balance)
        if (( $(awk "BEGIN {print ($NEW_BALANCE > $INITIAL_BALANCE)}") )); then
            echo -e "   ${GREEN}✅ Sucesso! Novo saldo: ${NEW_BALANCE} SOL${NC}"
            INITIAL_BALANCE=$NEW_BALANCE
            break
        fi
    else
        echo -e "   ${YELLOW}⚠️  Falhou${NC}"
    fi
    sleep 3
done
echo ""

# Verificar saldo final
echo -e "${BLUE}📊 Verificando saldo final...${NC}"
FINAL_BALANCE=$(check_solana_balance)
echo ""

echo "============================================================"
echo "  📋 RESULTADO FINAL"
echo "============================================================"
echo ""
echo -e "Saldo inicial: ${YELLOW}${INITIAL_BALANCE} SOL${NC}"
echo -e "Saldo final:   ${GREEN}${FINAL_BALANCE} SOL${NC}"
echo ""

if (( $(awk "BEGIN {print ($FINAL_BALANCE > 0)}") )); then
    echo -e "${GREEN}✅ SUCESSO! Você tem ${FINAL_BALANCE} SOL na carteira!${NC}"
    echo ""
    echo "Explorer: https://explorer.solana.com/address/$SOLANA_ADDRESS?cluster=testnet"
else
    echo -e "${RED}❌ Não foi possível obter tokens automaticamente${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  SOLUÇÃO MANUAL:${NC}"
    echo ""
    echo "1. Acesse o faucet web:"
    echo "   https://faucet.solana.com/"
    echo ""
    echo "2. Cole este endereço:"
    echo "   $SOLANA_ADDRESS"
    echo ""
    echo "3. Clique em 'Airdrop'"
    echo ""
    echo "4. Aguarde alguns segundos"
    echo ""
    echo "5. Verifique o saldo:"
    echo "   ./verificar-saldos.sh"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Outros faucets alternativos:"
    echo "• https://faucet.quicknode.com/solana/devnet"
    echo "• https://solfaucet.com/ (selecione Testnet)"
    echo ""
fi

echo ""

