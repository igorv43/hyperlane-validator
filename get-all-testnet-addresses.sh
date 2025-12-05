#!/bin/bash
# Script para obter todos os endereços das redes testnet configuradas

echo "============================================================"
echo "  🔍 OBTENDO ENDEREÇOS DAS REDES TESTNET"
echo "============================================================"
echo ""

CONFIG_FILE="hyperlane/relayer-testnet.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

# Verificar se Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 não está instalado"
    exit 1
fi

echo "📋 Lendo configuração de: $CONFIG_FILE"
echo ""

# Solana Testnet
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌐 SOLANA TESTNET"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if python3 -c "import base58, nacl" 2>/dev/null; then
    if [ -f "get-solana-address.py" ]; then
        SOLANA_KEY=$(python3 -c "import json; f=open('$CONFIG_FILE'); c=json.load(f); print(c['chains']['solanatestnet']['signer']['key'] if 'solanatestnet' in c.get('chains', {}) and 'signer' in c['chains']['solanatestnet'] and 'key' in c['chains']['solanatestnet']['signer'] else '')")
        if [ ! -z "$SOLANA_KEY" ]; then
            python3 get-solana-address.py "$SOLANA_KEY" 2>/dev/null | grep "Endereço Solana:" | cut -d: -f2 | xargs
            echo ""
            echo "Faucet: https://faucet.solana.com/"
        else
            echo "⚠️  Chave Solana não encontrada na configuração"
        fi
    else
        echo "⚠️  Script get-solana-address.py não encontrado"
        echo "   Execute: python3 get-solana-address.py <chave_privada>"
    fi
else
    echo "⚠️  Dependências Python não instaladas"
    echo "   Execute: pip3 install base58 pynacl"
fi
echo ""

# BSC Testnet (AWS KMS)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌐 BSC TESTNET (AWS KMS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "get-kms-addresses.sh" ]; then
    echo "Executando get-kms-addresses.sh..."
    ./get-kms-addresses.sh 2>/dev/null | grep -A 5 "bsctestnet" || echo "⚠️  Execute manualmente: ./get-kms-addresses.sh"
else
    echo "⚠️  Script get-kms-addresses.sh não encontrado"
    echo "   Para obter o endereço BSC, você precisa:"
    echo "   1. Ter AWS CLI configurado"
    echo "   2. Executar: ./get-kms-addresses.sh"
fi
echo ""

# Terra Classic Testnet
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌐 TERRA CLASSIC TESTNET"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if python3 -c "import eth_account, bech32" 2>/dev/null; then
    TERRA_KEY=$(python3 -c "import json; f=open('$CONFIG_FILE'); c=json.load(f); print(c['chains']['terraclassictestnet']['signer']['key'] if 'terraclassictestnet' in c.get('chains', {}) and 'signer' in c['chains']['terraclassictestnet'] and 'key' in c['chains']['terraclassictestnet']['signer'] else '')")
    if [ ! -z "$TERRA_KEY" ]; then
        if [ -f "get-address-from-hexkey.py" ]; then
            python3 get-address-from-hexkey.py "$TERRA_KEY" 2>/dev/null | grep "Terra:" | cut -d: -f2 | xargs
        else
            echo "⚠️  Script get-address-from-hexkey.py não encontrado"
        fi
    else
        echo "⚠️  Chave Terra não encontrada na configuração"
    fi
else
    echo "⚠️  Dependências Python não instaladas"
    echo "   Execute: pip3 install eth-account bech32"
fi
echo ""

echo "============================================================"
echo "  📚 GUIA COMPLETO"
echo "============================================================"
echo ""
echo "Consulte o arquivo OBTER-TOKENS-TESTNET.md para:"
echo "  • Instruções detalhadas de como obter tokens"
echo "  • Links de faucets"
echo "  • Solução de problemas"
echo ""

