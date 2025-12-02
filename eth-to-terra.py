#!/usr/bin/env python3
"""
Converte endereço Ethereum para formato Terra bech32

Uso:
    python3 eth-to-terra.py <endereço_ethereum>

Exemplo:
    python3 eth-to-terra.py 0x1234567890abcdef1234567890abcdef12345678

Requisitos:
    pip3 install bech32
"""

import sys

def eth_to_terra(eth_address):
    """Converte endereço Ethereum para Terra bech32"""
    try:
        import bech32
    except ImportError:
        print("❌ ERRO: Biblioteca 'bech32' não está instalada")
        print("\nInstale com:")
        print("  pip3 install bech32")
        print("\nOu use:")
        print("  python3 -m pip install bech32")
        sys.exit(1)
    
    # Remove 0x prefix se existir
    addr = eth_address.replace('0x', '').replace('0X', '').lower()
    
    # Validar tamanho
    if len(addr) != 40:
        raise ValueError(f"Endereço Ethereum inválido. Esperado 40 caracteres hex, recebido {len(addr)}")
    
    # Convert hex string to bytes
    try:
        addr_bytes = bytes.fromhex(addr)
    except ValueError:
        raise ValueError("Endereço Ethereum contém caracteres inválidos")
    
    # Convert to 5-bit groups para bech32
    five_bit = bech32.convertbits(addr_bytes, 8, 5)
    
    if five_bit is None:
        raise ValueError("Erro na conversão para formato bech32")
    
    # Encode com prefix 'terra'
    terra_addr = bech32.bech32_encode('terra', five_bit)
    
    if terra_addr is None:
        raise ValueError("Erro ao gerar endereço Terra")
    
    return terra_addr

def main():
    """Função principal"""
    print("=" * 60)
    print("    Conversor Ethereum → Terra Classic (bech32)")
    print("=" * 60)
    print()
    
    if len(sys.argv) != 2:
        print("❌ Uso incorreto!")
        print()
        print("Uso:")
        print(f"  {sys.argv[0]} <endereço_ethereum>")
        print()
        print("Exemplo:")
        print(f"  {sys.argv[0]} 0x1234567890abcdef1234567890abcdef12345678")
        sys.exit(1)
    
    eth_addr = sys.argv[1].strip()
    
    # Validação básica
    if not eth_addr:
        print("❌ Endereço vazio!")
        sys.exit(1)
    
    try:
        terra_addr = eth_to_terra(eth_addr)
        
        print("✅ Conversão realizada com sucesso!")
        print()
        print(f"Ethereum (hex):     {eth_addr}")
        print(f"Terra (bech32):     {terra_addr}")
        print()
        print("-" * 60)
        print()
        print("📋 Próximos passos:")
        print()
        print("1. Envie LUNC para este endereço Terra:")
        print(f"   {terra_addr}")
        print()
        print("2. Verifique o saldo com:")
        print(f"   terrad query bank balances {terra_addr} \\")
        print("     --node https://rpc.terra-classic.hexxagon.io:443")
        print()
        print("3. Inicie o validador:")
        print("   docker-compose up -d validator-terraclassic")
        print()
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()


