#!/bin/bash
# Script para abrir o faucet no navegador com o endereço pré-preenchido

SOLANA_ADDRESS="2tNwZa6Lx5dLWKEsVDAUhZkXdB8vqksqo2sssWsJ52Y9"

echo "============================================================"
echo "  🌐 ABRINDO FAUCET NO NAVEGADOR"
echo "============================================================"
echo ""
echo "Endereço Solana: $SOLANA_ADDRESS"
echo ""

# Tentar abrir no navegador
if command -v xdg-open &> /dev/null; then
    echo "Abrindo faucet oficial da Solana..."
    xdg-open "https://faucet.solana.com/" 2>/dev/null &
    echo "✅ Navegador aberto!"
elif command -v gnome-open &> /dev/null; then
    gnome-open "https://faucet.solana.com/" 2>/dev/null &
    echo "✅ Navegador aberto!"
elif command -v open &> /dev/null; then
    open "https://faucet.solana.com/" 2>/dev/null &
    echo "✅ Navegador aberto!"
else
    echo "⚠️  Não foi possível abrir o navegador automaticamente"
    echo ""
    echo "Por favor, abra manualmente:"
    echo "https://faucet.solana.com/"
fi

echo ""
echo "============================================================"
echo "  📝 INSTRUÇÕES"
echo "============================================================"
echo ""
echo "1. No site do faucet:"
echo "   - Selecione 'testnet' no dropdown (não devnet)"
echo "   - Cole este endereço:"
echo ""
echo "   $SOLANA_ADDRESS"
echo ""
echo "2. Clique em 'Confirm Airdrop'"
echo ""
echo "3. Aguarde alguns segundos"
echo ""
echo "4. Verifique o saldo:"
echo "   ./verificar-saldos.sh"
echo ""
echo "============================================================"
echo ""
echo "💡 DICA: Se o faucet oficial não funcionar, tente:"
echo "   • https://faucet.quicknode.com/solana/devnet"
echo "   • https://solfaucet.com/ (selecione Testnet)"
echo ""

