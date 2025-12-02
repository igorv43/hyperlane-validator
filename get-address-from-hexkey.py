#!/usr/bin/env python3
"""
Obter endereços Ethereum e Terra a partir de uma chave privada hexadecimal
"""

import sys
import os

def check_dependencies():
    """Verifica se as dependências estão instaladas"""
    try:
        from eth_account import Account
        import bech32
    except ImportError as e:
        print("❌ Erro: Dependências não instaladas")
        print("\nInstale com:")
        print("pip3 install eth-account bech32")
        sys.exit(1)

check_dependencies()

from eth_account import Account
import bech32

def get_addresses_from_key(private_key: str):
    """
    Obtém endereços Ethereum e Terra de uma chave privada
    
    Args:
        private_key: Chave privada em formato hexadecimal (com ou sem 0x)
    
    Returns:
        tuple: (eth_address, terra_address)
    """
    # Garantir que a chave comece com 0x
    if not private_key.startswith('0x'):
        private_key = '0x' + private_key
    
    # Obter endereço Ethereum
    account = Account.from_key(private_key)
    eth_address = account.address
    
    # Converter para Terra bech32
    addr_bytes = bytes.fromhex(eth_address[2:])
    five_bit = bech32.convertbits(addr_bytes, 8, 5)
    if five_bit is None:
        raise ValueError("Erro na conversão para bech32")
    terra_address = bech32.bech32_encode('terra', five_bit)
    
    return eth_address, terra_address

def main():
    print("=" * 70)
    print("  OBTER ENDEREÇOS DE CHAVE PRIVADA HEXADECIMAL")
    print("=" * 70)
    print()
    
    # Obter chave privada (de argumento ou prompt)
    if len(sys.argv) > 1:
        private_key = sys.argv[1]
    else:
        # Tentar ler do .env
        if os.path.exists('.env'):
            print("🔍 Procurando chave no arquivo .env...")
            with open('.env', 'r') as f:
                for line in f:
                    if line.startswith('PRIVATE_KEY='):
                        private_key = line.split('=', 1)[1].strip()
                        break
                else:
                    print("❌ Chave não encontrada no .env")
                    print("\nUso:")
                    print("  python3 get-address-from-hexkey.py <chave_privada>")
                    print("\nOu adicione ao .env:")
                    print("  PRIVATE_KEY=0x...")
                    sys.exit(1)
        else:
            print("❌ Nenhuma chave fornecida")
            print("\nUso:")
            print("  python3 get-address-from-hexkey.py <chave_privada>")
            sys.exit(1)
    
    try:
        # Obter endereços
        print("🔑 Processando chave privada...")
        eth_address, terra_address = get_addresses_from_key(private_key)
        
        # Exibir resultados
        print()
        print("=" * 70)
        print("  ✅ ENDEREÇOS OBTIDOS COM SUCESSO")
        print("=" * 70)
        print()
        print(f"Ethereum: {eth_address}")
        print(f"Terra:    {terra_address}")
        print()
        
        # Links úteis
        print("=" * 70)
        print("  📋 LINKS ÚTEIS")
        print("=" * 70)
        print()
        print("Explorer Terra Classic:")
        print(f"https://finder.terraclassic.community/mainnet/address/{terra_address}")
        print()
        print("Verificar saldo:")
        print(f"curl -s \"https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/{terra_address}\"")
        print()
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()


