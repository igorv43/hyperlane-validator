#!/bin/bash
# Script para obter endereço BSC - oferece opções: AWS KMS ou hexKey

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "============================================================"
echo "  🔍 OBTER ENDEREÇO BSC TESTNET"
echo "============================================================"
echo ""
echo "BSC suporta duas opções de signer:"
echo "  1. AWS KMS (mais seguro, requer configuração)"
echo "  2. hexKey (mais rápido, chave privada local)"
echo ""

# Verificar configuração atual
if [ -f "hyperlane/relayer-testnet.json" ]; then
    CURRENT_TYPE=$(python3 -c "import json; f=open('hyperlane/relayer-testnet.json'); c=json.load(f); print(c.get('chains', {}).get('bsctestnet', {}).get('signer', {}).get('type', 'unknown'))" 2>/dev/null || echo "unknown")
    echo -e "${BLUE}Configuração atual:${NC} $CURRENT_TYPE"
    echo ""
fi

# Opção 1: Tentar AWS KMS
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}OPÇÃO 1: AWS KMS${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs) 2>/dev/null
fi

if command -v cast &> /dev/null; then
    BSC_ADDRESS_KMS=$(cast wallet address --aws alias/hyperlane-relayer-signer-bsc 2>&1)
    
    if echo "$BSC_ADDRESS_KMS" | grep -qE "^0x[a-fA-F0-9]{40}$"; then
        echo -e "${GREEN}✅ Endereço BSC (AWS KMS):${NC}"
        echo "   $BSC_ADDRESS_KMS"
        echo ""
        echo "Use este endereço para obter tokens no faucet!"
        exit 0
    else
        echo -e "${YELLOW}⚠️  AWS KMS não configurado${NC}"
        echo ""
        echo "Para configurar AWS KMS:"
        echo "  1. Siga: SETUP-AWS-KMS.md"
        echo "  2. Crie chave KMS com alias: hyperlane-relayer-signer-bsc"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  'cast' não está instalado${NC}"
    echo ""
fi

# Opção 2: Usar hexKey
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}OPÇÃO 2: hexKey (Mais Rápido)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v cast &> /dev/null; then
    echo "Para usar hexKey, você precisa:"
    echo ""
    echo "1. Gerar ou usar uma chave privada existente"
    echo ""
    echo "2. Obter o endereço:"
    echo "   cast wallet address --private-key 0xSUA_CHAVE_PRIVADA"
    echo ""
    echo "3. Atualizar relayer-testnet.json para usar hexKey:"
    echo '   "bsctestnet": {'
    echo '     "signer": {'
    echo '       "type": "hexKey",'
    echo '       "key": "0xSUA_CHAVE_PRIVADA"'
    echo '     }'
    echo '   }'
    echo ""
    
    # Perguntar se quer gerar nova chave
    echo "Deseja gerar uma nova chave privada para BSC? (s/n)"
    read -t 10 -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo "Gerando nova chave privada..."
        NEW_KEY=$(cast wallet new 2>&1 | grep -E "^0x[a-fA-F0-9]{64}$" | head -1)
        
        if [ ! -z "$NEW_KEY" ]; then
            echo -e "${GREEN}✅ Nova chave gerada:${NC}"
            echo "   $NEW_KEY"
            echo ""
            
            # Obter endereço
            BSC_ADDRESS_HEX=$(cast wallet address --private-key "$NEW_KEY" 2>&1 | grep -E "^0x[a-fA-F0-9]{40}$" | head -1)
            
            if [ ! -z "$BSC_ADDRESS_HEX" ]; then
                echo -e "${GREEN}✅ Endereço BSC:${NC}"
                echo "   $BSC_ADDRESS_HEX"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  📝 PRÓXIMOS PASSOS"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "1. Atualize hyperlane/relayer-testnet.json:"
                echo ""
                echo '   "bsctestnet": {'
                echo '     "signer": {'
                echo '       "type": "hexKey",'
                echo "       \"key\": \"$NEW_KEY\""
                echo '     }'
                echo '   }'
                echo ""
                echo "2. Use este endereço para obter tokens:"
                echo "   $BSC_ADDRESS_HEX"
                echo ""
                echo "3. Execute: ./obter-bsc-testnet.sh"
                echo ""
            fi
        else
            echo -e "${RED}❌ Erro ao gerar chave${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  'cast' não está instalado${NC}"
    echo ""
    echo "Instale Foundry:"
    echo "  curl -L https://foundry.paradigm.xyz | bash"
    echo "  foundryup"
fi

echo ""

