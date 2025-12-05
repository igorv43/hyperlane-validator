#!/bin/bash
# Script interativo para obter tokens Solana manualmente

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOLANA_ADDRESS="2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9"

clear
echo "============================================================"
echo "  💰 OBTENDO TOKENS SOLANA TESTNET"
echo "============================================================"
echo ""
echo -e "${BLUE}Seu endereço Solana:${NC}"
echo "   $SOLANA_ADDRESS"
echo ""
echo "============================================================"
echo "  📋 OPÇÕES DISPONÍVEIS"
echo "============================================================"
echo ""
echo "1. Faucet Oficial Solana (Recomendado)"
echo "   URL: https://faucet.solana.com/"
echo "   Limite: 2 requests a cada 8 horas"
echo ""
echo "2. QuickNode Faucet"
echo "   URL: https://faucet.quicknode.com/solana/devnet"
echo ""
echo "3. SolFaucet"
echo "   URL: https://solfaucet.com/"
echo "   (Selecione 'Testnet' no dropdown)"
echo ""
echo "4. Tentar via Solana CLI (se instalado)"
echo ""
echo "============================================================"
echo ""

# Tentar via Solana CLI primeiro
if command -v solana &> /dev/null; then
    echo -e "${BLUE}Tentando via Solana CLI...${NC}"
    solana config set --url https://api.testnet.solana.com > /dev/null 2>&1
    
    # Tentar com diferentes valores e intervalos
    for amount in 1 0.5 0.1; do
        echo -e "   Tentando ${amount} SOL..."
        if solana airdrop $amount $SOLANA_ADDRESS 2>&1 | grep -q "Signature"; then
            echo -e "   ${GREEN}✅ Airdrop solicitado!${NC}"
            echo "   Aguardando confirmação (15 segundos)..."
            sleep 15
            
            # Verificar saldo
            BALANCE=$(curl -s -X POST "https://api.testnet.solana.com" \
                -H "Content-Type: application/json" \
                -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOLANA_ADDRESS\"]}" \
                | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 0) / 1000000000)" 2>/dev/null || echo "0")
            
            if (( $(awk "BEGIN {print ($BALANCE > 0)}") )); then
                echo -e "   ${GREEN}✅ Sucesso! Saldo: ${BALANCE} SOL${NC}"
                exit 0
            fi
            break
        else
            echo -e "   ${YELLOW}⚠️  Falhou (rate limit ou rede indisponível)${NC}"
        fi
        sleep 5
    done
    echo ""
fi

# Mostrar instruções manuais
echo -e "${YELLOW}⚠️  Métodos automáticos não funcionaram${NC}"
echo ""
echo "============================================================"
echo "  📝 INSTRUÇÕES MANUAIS"
echo "============================================================"
echo ""
echo "OPÇÃO 1: Faucet Oficial (Mais Confiável)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Abra seu navegador e acesse:"
echo -e "   ${BLUE}https://faucet.solana.com/${NC}"
echo ""
echo "2. No dropdown, selecione: ${GREEN}testnet${NC}"
echo ""
echo "3. Cole este endereço no campo:"
echo -e "   ${GREEN}$SOLANA_ADDRESS${NC}"
echo ""
echo "4. Clique em 'Confirm Airdrop'"
echo ""
echo "5. Aguarde alguns segundos"
echo ""
echo "6. Verifique o saldo executando:"
echo "   ./verificar-saldos.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "OPÇÃO 2: QuickNode Faucet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Acesse: ${BLUE}https://faucet.quicknode.com/solana/devnet${NC}"
echo ""
echo "2. Cole o endereço: ${GREEN}$SOLANA_ADDRESS${NC}"
echo ""
echo "3. Complete o captcha e solicite tokens"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "OPÇÃO 3: SolFaucet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Acesse: ${BLUE}https://solfaucet.com/${NC}"
echo ""
echo "2. Selecione 'Testnet' no dropdown"
echo ""
echo "3. Cole o endereço: ${GREEN}$SOLANA_ADDRESS${NC}"
echo ""
echo "============================================================"
echo ""
echo "Após obter tokens, execute para verificar:"
echo "   ./verificar-saldos.sh"
echo ""

