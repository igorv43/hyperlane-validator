#!/bin/bash
# Script para configurar BSC com hexKey e obter endereço

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "============================================================"
echo "  🔧 CONFIGURAR BSC COM hexKey"
echo "============================================================"
echo ""

# Chave privada gerada anteriormente
BSC_PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"

if ! command -v cast &> /dev/null; then
    echo -e "${RED}❌ 'cast' não está instalado${NC}"
    exit 1
fi

# Obter endereço BSC
echo -e "${BLUE}🔍 Obtendo endereço BSC da chave privada...${NC}"
BSC_ADDRESS=$(cast wallet address --private-key "$BSC_PRIVATE_KEY" 2>&1 | grep -E "^0x[a-fA-F0-9]{40}$" | head -1)

if [ -z "$BSC_ADDRESS" ]; then
    echo -e "${RED}❌ Erro ao obter endereço${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Endereço BSC obtido:${NC}"
echo "   $BSC_ADDRESS"
echo ""

# Verificar saldo atual
echo -e "${BLUE}📊 Verificando saldo atual...${NC}"
BSC_BALANCE=$(curl -s "https://api-testnet.bscscan.com/api?module=account&action=balance&address=${BSC_ADDRESS}&tag=latest" \
    | python3 -c "import sys, json; data=json.load(sys.stdin); result=data.get('result', '0'); print(int(result) / 1000000000000000000)" 2>/dev/null || echo "0")

echo -e "   Saldo atual: ${YELLOW}${BSC_BALANCE} BNB${NC}"
echo ""

if (( $(awk "BEGIN {print ($BSC_BALANCE > 0.01)}") )); then
    echo -e "${GREEN}✅ Você já tem saldo suficiente!${NC}"
    echo ""
    echo "Explorer: https://testnet.bscscan.com/address/$BSC_ADDRESS"
    exit 0
fi

echo "============================================================"
echo "  📝 ATUALIZAR CONFIGURAÇÃO"
echo "============================================================"
echo ""
echo "Para usar esta chave no relayer, atualize:"
echo "   hyperlane/relayer-testnet.json"
echo ""
echo "Altere de:"
echo '   "bsctestnet": {'
echo '     "signer": {'
echo '       "type": "aws",'
echo '       "id": "alias/hyperlane-relayer-signer-bsc"'
echo '     }'
echo '   }'
echo ""
echo "Para:"
echo '   "bsctestnet": {'
echo '     "signer": {'
echo '       "type": "hexKey",'
echo "       \"key\": \"$BSC_PRIVATE_KEY\""
echo '     }'
echo '   }'
echo ""

# Perguntar se quer atualizar automaticamente
echo "Deseja atualizar o arquivo automaticamente? (s/n)"
read -t 10 -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    if [ -f "hyperlane/relayer-testnet.json" ]; then
        # Fazer backup
        cp hyperlane/relayer-testnet.json hyperlane/relayer-testnet.json.backup
        
        # Atualizar usando Python
        python3 << EOF
import json

# Ler arquivo
with open('hyperlane/relayer-testnet.json', 'r') as f:
    config = json.load(f)

# Atualizar configuração BSC
if 'chains' in config and 'bsctestnet' in config['chains']:
    config['chains']['bsctestnet'] = {
        "signer": {
            "type": "hexKey",
            "key": "$BSC_PRIVATE_KEY"
        }
    }
    
    # Salvar
    with open('hyperlane/relayer-testnet.json', 'w') as f:
        json.dump(config, f, indent=2)
    
    print("✅ Arquivo atualizado com sucesso!")
else:
    print("❌ Estrutura do arquivo não encontrada")
EOF
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Configuração atualizada!${NC}"
            echo ""
            echo "Backup salvo em: hyperlane/relayer-testnet.json.backup"
        fi
    fi
fi

echo ""
echo "============================================================"
echo "  💰 OBTER TOKENS NO FAUCET"
echo "============================================================"
echo ""

# Tentar abrir faucet
if command -v xdg-open &> /dev/null; then
    xdg-open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
elif command -v gnome-open &> /dev/null; then
    gnome-open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
elif command -v open &> /dev/null; then
    open "https://testnet.bnbchain.org/faucet-smart" 2>/dev/null &
    echo -e "${GREEN}✅ Navegador aberto!${NC}"
fi

echo ""
echo "1. No site do faucet, cole este endereço:"
echo -e "   ${GREEN}$BSC_ADDRESS${NC}"
echo ""
echo "2. Complete o captcha"
echo ""
echo "3. Clique em 'Give me BNB'"
echo ""
echo "4. Aguarde confirmação (pode levar alguns minutos)"
echo ""
echo "5. Verifique o saldo:"
echo "   ./verificar-saldos.sh"
echo ""
echo "============================================================"
echo "  📊 INFORMAÇÕES"
echo "============================================================"
echo ""
echo "Endereço BSC: $BSC_ADDRESS"
echo "Explorer: https://testnet.bscscan.com/address/$BSC_ADDRESS"
echo ""
echo "⚠️  IMPORTANTE: Mantenha a chave privada segura!"
echo "   Chave: $BSC_PRIVATE_KEY"
echo ""

