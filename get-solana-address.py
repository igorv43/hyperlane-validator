#!/usr/bin/env python3
"""
Obter endereço Solana a partir de uma chave privada hexadecimal.

Este script converte uma chave privada hex (formato usado no Hyperlane)
para o endereço Solana correspondente (formato base58).

Uso:
    python3 get-solana-address.py <chave_privada_hex>
    
Exemplo:
    python3 get-solana-address.py 0x7c2d098a2870db43d142c87586c62d1252c97aff002176a15d87940d41c79e27
"""

import sys
import os

def check_dependencies():
    """Verifica se as dependências estão instaladas"""
    try:
        import base58
        from nacl.signing import SigningKey
    except ImportError:
        print("❌ Erro: Dependências não instaladas")
        print("\nInstale com:")
        print("  pip3 install base58 pynacl")
        print("\nOu:")
        print("  pip3 install -r requirements.txt")
        sys.exit(1)

check_dependencies()

import base58
from nacl.signing import SigningKey

def get_solana_address_from_hex(private_key_hex: str):
    """
    Obtém o endereço Solana a partir de uma chave privada hexadecimal.
    
    Args:
        private_key_hex: Chave privada em formato hexadecimal (com ou sem 0x)
    
    Returns:
        str: Endereço Solana em formato base58
    """
    # Remover 0x se presente
    if private_key_hex.startswith('0x'):
        private_key_hex = private_key_hex[2:]
    
    # Verificar se tem 64 caracteres hex (32 bytes)
    if len(private_key_hex) != 64:
        raise ValueError(f"Chave privada deve ter 64 caracteres hex (32 bytes), recebido: {len(private_key_hex)}")
    
    try:
        # Converter hex para bytes
        private_key_bytes = bytes.fromhex(private_key_hex)
        
        # Criar SigningKey do Solana (ED25519)
        signing_key = SigningKey(private_key_bytes)
        
        # Obter a chave pública
        verify_key = signing_key.verify_key
        
        # Converter chave pública para endereço Solana (base58)
        public_key_bytes = bytes(verify_key)
        solana_address = base58.b58encode(public_key_bytes).decode('utf-8')
        
        return solana_address
    except Exception as e:
        raise ValueError(f"Erro ao processar chave privada: {e}")

def main():
    print("=" * 70)
    print("  🔑 OBTENDO ENDEREÇO SOLANA DA CHAVE PRIVADA")
    print("=" * 70)
    print()
    
    # Obter chave privada (de argumento ou do arquivo de configuração)
    if len(sys.argv) > 1:
        private_key = sys.argv[1]
    else:
        # Tentar ler do arquivo relayer-testnet.json
        config_file = "hyperlane/relayer-testnet.json"
        if os.path.exists(config_file):
            print(f"🔍 Procurando chave no arquivo {config_file}...")
            try:
                import json
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    if 'chains' in config and 'solanatestnet' in config['chains']:
                        signer = config['chains']['solanatestnet'].get('signer', {})
                        if signer.get('type') == 'hexKey':
                            private_key = signer.get('key')
                            if private_key:
                                print(f"✅ Chave encontrada no arquivo de configuração")
                            else:
                                print("❌ Chave não encontrada no arquivo de configuração")
                                sys.exit(1)
                        else:
                            print("❌ Tipo de signer não é hexKey")
                            sys.exit(1)
                    else:
                        print("❌ Configuração Solana não encontrada")
                        sys.exit(1)
            except Exception as e:
                print(f"❌ Erro ao ler arquivo de configuração: {e}")
                sys.exit(1)
        else:
            print("❌ Nenhuma chave fornecida")
            print("\nUso:")
            print("  python3 get-solana-address.py <chave_privada_hex>")
            print("\nExemplo:")
            print("  python3 get-solana-address.py 0x7c2d098a2870db43d142c87586c62d1252c97aff002176a15d87940d41c79e27")
            sys.exit(1)
    
    try:
        # Obter endereço Solana
        print("🔑 Processando chave privada...")
        solana_address = get_solana_address_from_hex(private_key)
        
        # Exibir resultados
        print()
        print("=" * 70)
        print("  ✅ ENDEREÇO SOLANA OBTIDO COM SUCESSO")
        print("=" * 70)
        print()
        print(f"Endereço Solana: {solana_address}")
        print()
        
        # Links úteis
        print("=" * 70)
        print("  📋 LINKS ÚTEIS - SOLANA TESTNET")
        print("=" * 70)
        print()
        print("Explorer:")
        print(f"https://explorer.solana.com/address/{solana_address}?cluster=testnet")
        print()
        print("Faucet (obter tokens de teste):")
        print(f"https://faucet.solana.com/")
        print("Cole o endereço acima no faucet para receber SOL de teste")
        print()
        print("Verificar saldo via CLI:")
        print(f"solana balance {solana_address} --url https://api.testnet.solana.com")
        print()
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

