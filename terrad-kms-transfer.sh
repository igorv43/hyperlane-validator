#!/bin/bash

# ============================================================================
# terrad + AWS KMS Transfer Script
# ============================================================================
# 
# Este script integra o terrad CLI com AWS KMS para transferir LUNC de forma
# segura sem expor a chave privada.
#
# Uso:
#   ./terrad-kms-transfer.sh <destino> <quantidade_uluna> [memo]
#
# Exemplo:
#   ./terrad-kms-transfer.sh terra1abc...xyz 1000000 "Saque"
#
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
CHAIN_ID="columbus-5"
RPC_NODE="https://rpc.terra-classic.hexxagon.io:443"
LCD_API="https://terra-classic-lcd.publicnode.com"
GAS_ADJUSTMENT="1.5"
GAS_PRICES="28.325uluna"

# ============================================================================
# Funções Auxiliares
# ============================================================================

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  terrad + AWS KMS Transfer${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}❌ ERRO: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============================================================================
# Verificação de Dependências
# ============================================================================

check_dependencies() {
    echo -e "${BLUE}🔧 Verificando dependências...${NC}"
    
    # Verificar terrad
    if ! command -v terrad &> /dev/null; then
        print_error "terrad CLI não está instalado"
        echo ""
        echo "Instale com:"
        echo "  wget https://github.com/classic-terra/core/releases/download/v2.3.1/terra_2.3.1_Linux_x86_64.tar.gz"
        echo "  tar -xzf terra_2.3.1_Linux_x86_64.tar.gz"
        echo "  sudo mv terrad /usr/local/bin/"
        exit 1
    fi
    
    # Verificar cast (para obter endereço do KMS)
    if ! command -v cast &> /dev/null; then
        print_error "cast (Foundry) não está instalado"
        echo ""
        echo "Instale com:"
        echo "  curl -L https://foundry.paradigm.xyz | bash"
        echo "  foundryup"
        exit 1
    fi
    
    # Verificar Python e eth-to-terra.py
    if [ ! -f "./eth-to-terra.py" ]; then
        print_error "eth-to-terra.py não encontrado"
        echo "Certifique-se de estar no diretório correto"
        exit 1
    fi
    
    # Verificar jq
    if ! command -v jq &> /dev/null; then
        print_warning "jq não está instalado (recomendado para parsing JSON)"
        echo "Instale com: sudo apt install jq"
    fi
    
    print_success "Dependências verificadas"
    echo ""
}

# ============================================================================
# Carregar Configurações
# ============================================================================

load_env() {
    if [ -f ".env" ]; then
        export $(cat .env | grep -v '^#' | xargs)
    fi
    
    # Verificar credenciais AWS
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        print_error "Credenciais AWS não configuradas"
        echo ""
        echo "Configure no arquivo .env:"
        echo "  AWS_ACCESS_KEY_ID=sua_key"
        echo "  AWS_SECRET_ACCESS_KEY=sua_secret"
        exit 1
    fi
    
    # Configurar KMS key ID
    export KMS_KEY_ID="${KMS_KEY_ID:-alias/hyperlane-validator-signer-terraclassic}"
    export AWS_REGION="${AWS_REGION:-us-east-1}"
}

# ============================================================================
# Obter Endereço Terra do KMS
# ============================================================================

get_terra_address() {
    echo -e "${BLUE}🔑 Obtendo endereço Terra da chave KMS...${NC}"
    
    # Obter endereço Ethereum do KMS
    ETH_ADDR=$(cast wallet address --aws $KMS_KEY_ID 2>&1)
    
    if [ $? -ne 0 ]; then
        print_error "Falha ao obter endereço do KMS"
        echo "$ETH_ADDR"
        exit 1
    fi
    
    echo "   Ethereum: $ETH_ADDR"
    
    # Converter para Terra
    TERRA_ADDR=$(./eth-to-terra.py $ETH_ADDR 2>/dev/null | grep "Terra:" | awk '{print $2}')
    
    if [ -z "$TERRA_ADDR" ]; then
        print_error "Falha ao converter endereço para formato Terra"
        exit 1
    fi
    
    echo "   Terra:    $TERRA_ADDR"
    echo ""
    
    echo "$TERRA_ADDR"
}

# ============================================================================
# Verificar Saldo
# ============================================================================

check_balance() {
    local address=$1
    
    echo -e "${BLUE}💰 Verificando saldo...${NC}"
    
    # Consultar saldo via REST API (mais confiável)
    BALANCE_JSON=$(curl -s "$LCD_API/cosmos/bank/v1beta1/balances/$address/uluna")
    
    if echo "$BALANCE_JSON" | grep -q "error"; then
        print_error "Falha ao consultar saldo"
        echo "$BALANCE_JSON"
        exit 1
    fi
    
    # Extrair quantidade
    if command -v jq &> /dev/null; then
        BALANCE=$(echo "$BALANCE_JSON" | jq -r '.balance.amount // "0"')
    else
        # Fallback sem jq
        BALANCE=$(echo "$BALANCE_JSON" | grep -o '"amount":"[0-9]*"' | grep -o '[0-9]*')
    fi
    
    if [ -z "$BALANCE" ] || [ "$BALANCE" = "null" ]; then
        BALANCE="0"
    fi
    
    echo "   Saldo: $(echo "scale=6; $BALANCE / 1000000" | bc) LUNC ($BALANCE uluna)"
    echo ""
    
    echo "$BALANCE"
}

# ============================================================================
# Criar Transação Não Assinada
# ============================================================================

create_unsigned_tx() {
    local from_addr=$1
    local to_addr=$2
    local amount=$3
    local memo=$4
    
    echo -e "${BLUE}📝 Criando transação não assinada...${NC}"
    
    # Criar transação
    terrad tx bank send \
        $from_addr \
        $to_addr \
        ${amount}uluna \
        --chain-id $CHAIN_ID \
        --node $RPC_NODE \
        --gas auto \
        --gas-adjustment $GAS_ADJUSTMENT \
        --gas-prices $GAS_PRICES \
        --memo "$memo" \
        --generate-only > /tmp/tx_unsigned.json 2>&1
    
    if [ $? -ne 0 ]; then
        print_error "Falha ao criar transação"
        cat /tmp/tx_unsigned.json
        exit 1
    fi
    
    print_success "Transação criada: /tmp/tx_unsigned.json"
    echo ""
}

# ============================================================================
# Assinar com AWS KMS (Placeholder)
# ============================================================================

sign_with_kms() {
    print_warning "Assinatura com AWS KMS"
    echo ""
    echo "⚠️  NOTA IMPORTANTE:"
    echo ""
    echo "A assinatura direta de transações Cosmos com AWS KMS requer"
    echo "implementação específica do protocolo de assinatura Cosmos."
    echo ""
    echo "Atualmente, o terrad CLI não suporta nativamente AWS KMS."
    echo ""
    echo "ALTERNATIVAS:"
    echo ""
    echo "1. Use o script Python: ./transfer-lunc-kms.py"
    echo "   - Implementa assinatura KMS corretamente"
    echo "   - Recomendado para produção"
    echo ""
    echo "2. Use uma chave local temporária para testes:"
    echo "   - terrad keys add test-key"
    echo "   - Transfira pequena quantidade para esta carteira"
    echo "   - Use para testes, depois descarte"
    echo ""
    echo "3. Implemente um plugin customizado para terrad"
    echo "   - Requer desenvolvimento em Go"
    echo "   - Ver: github.com/cosmos/cosmos-sdk"
    echo ""
    
    exit 1
}

# ============================================================================
# Função Principal
# ============================================================================

main() {
    print_header
    
    # Verificar argumentos
    if [ $# -lt 2 ]; then
        print_error "Uso incorreto"
        echo ""
        echo "Uso:"
        echo "  $0 <endereço_destino> <quantidade_uluna> [memo]"
        echo ""
        echo "Exemplo:"
        echo "  $0 terra1abc...xyz 1000000 'Saque'"
        echo ""
        echo "Nota: 1 LUNC = 1,000,000 uluna"
        exit 1
    fi
    
    TO_ADDRESS=$1
    AMOUNT=$2
    MEMO=${3:-"Transfer via terrad-kms"}
    
    # Validar endereço de destino
    if [[ ! $TO_ADDRESS =~ ^terra1[a-z0-9]{38}$ ]]; then
        print_error "Endereço de destino inválido"
        echo "Deve começar com 'terra1' e ter 44 caracteres"
        exit 1
    fi
    
    # Validar quantidade
    if ! [[ $AMOUNT =~ ^[0-9]+$ ]] || [ $AMOUNT -le 0 ]; then
        print_error "Quantidade inválida"
        echo "Deve ser um número inteiro positivo (em uluna)"
        exit 1
    fi
    
    # Verificar dependências
    check_dependencies
    
    # Carregar configurações
    load_env
    
    # Obter endereço de origem
    FROM_ADDRESS=$(get_terra_address)
    
    # Verificar saldo
    BALANCE=$(check_balance $FROM_ADDRESS)
    
    # Calcular total necessário (amount + gas estimado)
    GAS_ESTIMATE=200000
    GAS_PRICE_NUM=$(echo $GAS_PRICES | sed 's/uluna//')
    FEE_ESTIMATE=$(echo "$GAS_ESTIMATE * $GAS_PRICE_NUM" | bc | cut -d'.' -f1)
    TOTAL_NEEDED=$(($AMOUNT + $FEE_ESTIMATE))
    
    echo -e "${BLUE}📊 Resumo da Transferência:${NC}"
    echo "   De:        $FROM_ADDRESS"
    echo "   Para:      $TO_ADDRESS"
    echo "   Quantidade: $(echo "scale=6; $AMOUNT / 1000000" | bc) LUNC ($AMOUNT uluna)"
    echo "   Memo:      $MEMO"
    echo "   Gas (est): $(echo "scale=6; $FEE_ESTIMATE / 1000000" | bc) LUNC ($FEE_ESTIMATE uluna)"
    echo "   Total:     $(echo "scale=6; $TOTAL_NEEDED / 1000000" | bc) LUNC ($TOTAL_NEEDED uluna)"
    echo ""
    
    # Verificar se há saldo suficiente
    if [ $BALANCE -lt $TOTAL_NEEDED ]; then
        print_error "Saldo insuficiente"
        echo ""
        echo "   Necessário: $(echo "scale=6; $TOTAL_NEEDED / 1000000" | bc) LUNC"
        echo "   Disponível: $(echo "scale=6; $BALANCE / 1000000" | bc) LUNC"
        echo "   Faltam:     $(echo "scale=6; ($TOTAL_NEEDED - $BALANCE) / 1000000" | bc) LUNC"
        exit 1
    fi
    
    print_success "Saldo suficiente"
    echo ""
    
    # Criar transação não assinada
    create_unsigned_tx $FROM_ADDRESS $TO_ADDRESS $AMOUNT "$MEMO"
    
    # Tentar assinar com KMS (vai mostrar mensagem de alternativas)
    sign_with_kms
}

# Executar
main "$@"

