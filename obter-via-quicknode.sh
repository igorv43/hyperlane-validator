#!/bin/bash
# Tentar obter tokens via QuickNode faucet

SOLANA_ADDRESS="2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9"

echo "Tentando obter tokens via QuickNode faucet..."
echo "Endereço: $SOLANA_ADDRESS"
echo ""

# QuickNode faucet API (pode requerer API key)
echo "Método 1: QuickNode Faucet API"
curl -s -X POST "https://api.quicknode.com/solana/devnet/faucet" \
    -H "Content-Type: application/json" \
    -d "{\"address\":\"$SOLANA_ADDRESS\"}" \
    | python3 -m json.tool 2>/dev/null || echo "Falhou - requer API key ou não disponível"
echo ""

# Verificar saldo após tentativa
sleep 5
BALANCE=$(curl -s -X POST "https://api.testnet.solana.com" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$SOLANA_ADDRESS\"]}" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('result', {}).get('value', 0) / 1000000000)" 2>/dev/null || echo "0")

echo "Saldo atual: $BALANCE SOL"
echo ""

if (( $(awk "BEGIN {print ($BALANCE > 0)}") )); then
    echo "✅ Sucesso! Saldo obtido!"
else
    echo "⚠️  Método automático não funcionou."
    echo ""
    echo "Por favor, use o faucet web manualmente:"
    echo "https://faucet.quicknode.com/solana/devnet"
    echo ""
    echo "Ou o faucet oficial:"
    echo "https://faucet.solana.com/"
fi

