#!/usr/bin/env python3
"""
Obtém o endereço Terra Classic de uma chave AWS KMS

Este script não requer cast ou AWS CLI instalados,
apenas Python e boto3.

Uso:
    python3 get-terra-address-from-kms.py

Requisitos:
    pip3 install boto3 bech32
"""

import boto3
import hashlib
import os
import sys

# Carregar credenciais do .env
if os.path.exists('.env'):
    with open('.env') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()

# Verificar dependências
try:
    import bech32
except ImportError:
    print("❌ Dependência faltando!")
    print("\nInstale com:")
    print("  pip3 install bech32")
    sys.exit(1)

# Verificar credenciais
if not os.getenv('AWS_ACCESS_KEY_ID') or not os.getenv('AWS_SECRET_ACCESS_KEY'):
    print("❌ Credenciais AWS não configuradas!")
    print("\nConfigure no arquivo .env:")
    print("  AWS_ACCESS_KEY_ID=sua_key")
    print("  AWS_SECRET_ACCESS_KEY=sua_secret")
    sys.exit(1)

# Configuração
KMS_KEY_ID = os.getenv('KMS_KEY_ID', 'alias/hyperlane-validator-signer-terraclassic')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')

print("=" * 70)
print("  OBTER ENDEREÇO TERRA DA CHAVE AWS KMS")
print("=" * 70)
print()
print(f"🔑 Chave KMS: {KMS_KEY_ID}")
print(f"🌍 Região: {AWS_REGION}")
print()

try:
    # Criar cliente KMS
    print("📡 Conectando ao AWS KMS...")
    kms = boto3.client('kms', region_name=AWS_REGION)
    
    # Obter chave pública
    print("🔍 Obtendo chave pública...")
    response = kms.get_public_key(KeyId=KMS_KEY_ID)
    pub_key_der = response['PublicKey']
    
    print(f"✅ Chave pública obtida ({len(pub_key_der)} bytes)")
    print()
    
    # Extrair chave pública dos últimos 65 bytes do DER encoding
    pub_key_bytes = pub_key_der[-65:]
    
    # Remover prefixo 0x04 (indica chave não comprimida)
    if pub_key_bytes[0] == 0x04:
        pub_key_bytes = pub_key_bytes[1:]
    
    # Calcular endereço Ethereum (para referência)
    print("🔄 Calculando endereços...")
    keccak_hash = hashlib.sha3_256(pub_key_bytes).digest()
    eth_address = "0x" + keccak_hash[-20:].hex()
    
    # Calcular endereço Terra (SHA256 -> RIPEMD160 -> bech32)
    sha256_hash = hashlib.sha256(pub_key_bytes).digest()
    ripemd160 = hashlib.new('ripemd160', sha256_hash).digest()
    
    # Converter para bech32
    five_bit = bech32.convertbits(ripemd160, 8, 5)
    terra_addr = bech32.bech32_encode('terra', five_bit)
    
    print("=" * 70)
    print("  ✅ ENDEREÇOS OBTIDOS COM SUCESSO")
    print("=" * 70)
    print()
    print(f"Ethereum: {eth_address}")
    print(f"Terra:    {terra_addr}")
    print()
    print("=" * 70)
    print("  📋 PRÓXIMOS PASSOS")
    print("=" * 70)
    print()
    print(f"1. 💰 Envie LUNC para este endereço Terra:")
    print(f"   {terra_addr}")
    print()
    print("   Quantidade recomendada: 50-100 LUNC")
    print("   Propósito: Gas para announcement + validação")
    print()
    print("2. ⏳ Aguarde confirmação (3-6 segundos)")
    print()
    print("3. ✅ Verifique o saldo:")
    print(f"   curl \"https://terra-classic-lcd.publicnode.com/cosmos/bank/v1beta1/balances/{terra_addr}/uluna\"")
    print()
    print("4. 🔄 Reinicie o validador:")
    print("   docker-compose restart validator-terraclassic")
    print()
    print("5. 📊 Monitore os logs:")
    print("   docker logs -f hpl-validator-terraclassic")
    print()
    print("   Aguarde ver: \"Successfully announced validator\"")
    print()
    
except Exception as e:
    print(f"❌ ERRO: {e}")
    print()
    print("🔧 Possíveis soluções:")
    print()
    print("1. Verificar credenciais no .env:")
    print("   cat .env")
    print()
    print("2. Verificar se a chave KMS existe:")
    print("   - Acesse: https://console.aws.amazon.com/kms")
    print("   - Região: us-east-1")
    print("   - Procure: hyperlane-validator-signer-terraclassic")
    print()
    print("3. Verificar permissões do usuário IAM:")
    print("   - O usuário precisa de kms:GetPublicKey")
    print("   - Verifique a key policy da chave KMS")
    print()
    print("4. Se o erro persistir, use a Solução 1:")
    print("   - Ver arquivo: TROUBLESHOOTING-VALIDATOR-ANNOUNCEMENT.md")
    print()
    sys.exit(1)

