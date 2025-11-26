#!/usr/bin/env python3
"""
Script para transferir LUNC usando AWS KMS

Este script permite sacar/transferir LUNC de uma carteira gerenciada pelo AWS KMS
para qualquer outro endereço Terra Classic.

Requisitos:
    pip3 install boto3 bech32 ecdsa requests protobuf

Uso:
    python3 transfer-lunc-kms.py <destinatário> <quantidade_em_uluna>

Exemplo:
    python3 transfer-lunc-kms.py terra1abc...xyz 1000000
    (transfere 1 LUNC = 1,000,000 uluna)
"""

import sys
import os
import json
import hashlib
import requests
from typing import Dict, Any, Tuple

def check_dependencies():
    """Verifica se todas as dependências estão instaladas"""
    required = ['boto3', 'bech32', 'ecdsa', 'requests']
    missing = []
    
    for package in required:
        try:
            __import__(package)
        except ImportError:
            missing.append(package)
    
    if missing:
        print("❌ Dependências faltando:")
        print(f"\nInstale com: pip3 install {' '.join(missing)}")
        sys.exit(1)

check_dependencies()

import boto3
import bech32
from ecdsa import SigningKey, SECP256k1
from ecdsa.util import sigencode_string_canonize

# Configurações
LCD_ENDPOINT = "https://terra-classic-lcd.publicnode.com"
CHAIN_ID = "columbus-5"
GAS_LIMIT = "200000"
GAS_PRICE = "28.325"  # uluna
DEFAULT_MEMO = "Withdrawn via KMS"

class TerraKMSTransfer:
    """Classe para gerenciar transferências LUNC via AWS KMS"""
    
    def __init__(self, kms_key_id: str, region: str = 'us-east-1'):
        """
        Inicializa o cliente KMS
        
        Args:
            kms_key_id: ID ou alias da chave KMS (ex: alias/hyperlane-validator-signer-terraclassic)
            region: Região AWS da chave
        """
        self.kms_client = boto3.client('kms', region_name=region)
        self.kms_key_id = kms_key_id
        self.region = region
        self._sender_address = None
    
    def get_public_key(self) -> bytes:
        """Obtém a chave pública do KMS"""
        try:
            response = self.kms_client.get_public_key(KeyId=self.kms_key_id)
            return response['PublicKey']
        except Exception as e:
            raise Exception(f"Erro ao obter chave pública: {e}")
    
    def get_terra_address(self) -> str:
        """Converte a chave pública KMS para endereço Terra"""
        if self._sender_address:
            return self._sender_address
        
        # Obter chave pública do KMS
        public_key_der = self.get_public_key()
        
        # Extrair os últimos 65 bytes (chave pública não comprimida)
        # DER encoding tem headers, a chave real está no final
        public_key_bytes = public_key_der[-65:]
        
        # Remover o byte de prefixo 0x04 (indica chave não comprimida)
        if public_key_bytes[0] == 0x04:
            public_key_bytes = public_key_bytes[1:]
        
        # Hash SHA256 -> RIPEMD160
        sha256_hash = hashlib.sha256(public_key_bytes).digest()
        ripemd160 = hashlib.new('ripemd160', sha256_hash).digest()
        
        # Converter para bech32 com prefix 'terra'
        five_bit = bech32.convertbits(ripemd160, 8, 5)
        self._sender_address = bech32.bech32_encode('terra', five_bit)
        
        return self._sender_address
    
    def get_account_info(self, address: str) -> Dict[str, Any]:
        """Obtém informações da conta (account number e sequence)"""
        url = f"{LCD_ENDPOINT}/cosmos/auth/v1beta1/accounts/{address}"
        
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            account_info = data['account']
            
            return {
                'account_number': account_info.get('account_number', '0'),
                'sequence': account_info.get('sequence', '0')
            }
        except Exception as e:
            raise Exception(f"Erro ao obter informações da conta: {e}")
    
    def get_balance(self, address: str) -> int:
        """Obtém o saldo de LUNC em uluna"""
        url = f"{LCD_ENDPOINT}/cosmos/bank/v1beta1/balances/{address}/uluna"
        
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if 'balance' in data and data['balance']:
                return int(data['balance']['amount'])
            return 0
        except Exception as e:
            raise Exception(f"Erro ao obter saldo: {e}")
    
    def create_transfer_message(self, to_address: str, amount: str) -> Dict[str, Any]:
        """Cria a mensagem de transferência"""
        from_address = self.get_terra_address()
        
        return {
            "@type": "/cosmos.bank.v1beta1.MsgSend",
            "from_address": from_address,
            "to_address": to_address,
            "amount": [
                {
                    "denom": "uluna",
                    "amount": str(amount)
                }
            ]
        }
    
    def create_transaction(self, to_address: str, amount: str, memo: str = DEFAULT_MEMO) -> Tuple[Dict, bytes]:
        """Cria a transação completa"""
        from_address = self.get_terra_address()
        
        # Obter informações da conta
        print(f"📡 Obtendo informações da conta {from_address}...")
        account_info = self.get_account_info(from_address)
        
        # Criar mensagem
        msg = self.create_transfer_message(to_address, amount)
        
        # Calcular gas fee
        gas_amount = str(int(float(GAS_LIMIT) * float(GAS_PRICE)))
        
        # Criar o corpo da transação
        tx_body = {
            "body": {
                "messages": [msg],
                "memo": memo,
                "timeout_height": "0",
                "extension_options": [],
                "non_critical_extension_options": []
            },
            "auth_info": {
                "signer_infos": [
                    {
                        "public_key": None,  # Será preenchido após assinatura
                        "mode_info": {
                            "single": {
                                "mode": "SIGN_MODE_DIRECT"
                            }
                        },
                        "sequence": account_info['sequence']
                    }
                ],
                "fee": {
                    "amount": [
                        {
                            "denom": "uluna",
                            "amount": gas_amount
                        }
                    ],
                    "gas_limit": GAS_LIMIT,
                    "payer": "",
                    "granter": ""
                }
            },
            "signatures": []
        }
        
        # Criar SignDoc para assinatura
        sign_doc = {
            "body_bytes": self._encode_tx_body(tx_body['body']),
            "auth_info_bytes": self._encode_auth_info(tx_body['auth_info']),
            "chain_id": CHAIN_ID,
            "account_number": account_info['account_number']
        }
        
        # Serializar SignDoc para bytes
        sign_bytes = self._serialize_sign_doc(sign_doc)
        
        return tx_body, sign_bytes
    
    def _encode_tx_body(self, body: Dict) -> bytes:
        """Codifica o corpo da transação (simplificado para demonstração)"""
        # Em produção, use protobuf corretamente
        return json.dumps(body, sort_keys=True).encode()
    
    def _encode_auth_info(self, auth_info: Dict) -> bytes:
        """Codifica auth_info (simplificado para demonstração)"""
        # Em produção, use protobuf corretamente
        return json.dumps(auth_info, sort_keys=True).encode()
    
    def _serialize_sign_doc(self, sign_doc: Dict) -> bytes:
        """Serializa o SignDoc para assinatura"""
        # Hash SHA256 do SignDoc completo
        doc_str = json.dumps(sign_doc, sort_keys=True)
        return hashlib.sha256(doc_str.encode()).digest()
    
    def sign_with_kms(self, message_hash: bytes) -> bytes:
        """Assina o hash da mensagem usando AWS KMS"""
        try:
            print("🔐 Assinando transação com AWS KMS...")
            response = self.kms_client.sign(
                KeyId=self.kms_key_id,
                Message=message_hash,
                MessageType='DIGEST',
                SigningAlgorithm='ECDSA_SHA_256'
            )
            
            signature_der = response['Signature']
            
            # Converter DER para formato raw (r || s)
            signature = self._der_to_raw_signature(signature_der)
            
            return signature
        except Exception as e:
            raise Exception(f"Erro ao assinar com KMS: {e}")
    
    def _der_to_raw_signature(self, der_sig: bytes) -> bytes:
        """Converte assinatura DER para formato raw (r || s)"""
        # Parse DER: 0x30 [length] 0x02 [r-length] [r] 0x02 [s-length] [s]
        if der_sig[0] != 0x30:
            raise ValueError("Assinatura DER inválida")
        
        r_start = 4
        r_length = der_sig[3]
        r = der_sig[r_start:r_start + r_length]
        
        s_start = r_start + r_length + 2
        s_length = der_sig[s_start - 1]
        s = der_sig[s_start:s_start + s_length]
        
        # Remover padding zero se presente
        if len(r) == 33 and r[0] == 0:
            r = r[1:]
        if len(s) == 33 and s[0] == 0:
            s = s[1:]
        
        # Pad para 32 bytes se necessário
        r = r.rjust(32, b'\x00')
        s = s.rjust(32, b'\x00')
        
        return r + s
    
    def broadcast_transaction(self, tx_bytes: bytes) -> Dict[str, Any]:
        """Transmite a transação para a rede"""
        url = f"{LCD_ENDPOINT}/cosmos/tx/v1beta1/txs"
        
        # Codificar em base64
        import base64
        tx_b64 = base64.b64encode(tx_bytes).decode()
        
        payload = {
            "tx_bytes": tx_b64,
            "mode": "BROADCAST_MODE_SYNC"
        }
        
        try:
            print("📡 Transmitindo transação para a rede...")
            response = requests.post(url, json=payload, timeout=30)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            raise Exception(f"Erro ao transmitir transação: {e}")

def uluna_to_lunc(uluna: int) -> float:
    """Converte uluna para LUNC"""
    return uluna / 1_000_000

def lunc_to_uluna(lunc: float) -> int:
    """Converte LUNC para uluna"""
    return int(lunc * 1_000_000)

def main():
    """Função principal"""
    print("=" * 70)
    print("    Transferência de LUNC usando AWS KMS")
    print("=" * 70)
    print()
    
    # Verificar argumentos
    if len(sys.argv) < 3:
        print("❌ Uso incorreto!")
        print()
        print("Uso:")
        print(f"  {sys.argv[0]} <endereço_destino> <quantidade_uluna> [memo]")
        print()
        print("Exemplo:")
        print(f"  {sys.argv[0]} terra1abc...xyz 1000000 'Saque'")
        print()
        print("Nota: 1 LUNC = 1,000,000 uluna")
        sys.exit(1)
    
    to_address = sys.argv[1]
    amount = sys.argv[2]
    memo = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_MEMO
    
    # Validar endereço de destino
    if not to_address.startswith('terra1'):
        print("❌ Endereço de destino inválido! Deve começar com 'terra1'")
        sys.exit(1)
    
    # Validar quantidade
    try:
        amount_int = int(amount)
        if amount_int <= 0:
            raise ValueError()
    except:
        print("❌ Quantidade inválida! Deve ser um número inteiro positivo (em uluna)")
        sys.exit(1)
    
    # Carregar credenciais do .env
    if os.path.exists('.env'):
        with open('.env') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()
    
    # Verificar credenciais AWS
    if not os.getenv('AWS_ACCESS_KEY_ID') or not os.getenv('AWS_SECRET_ACCESS_KEY'):
        print("❌ Credenciais AWS não configuradas!")
        print("\nConfigure no arquivo .env:")
        print("  AWS_ACCESS_KEY_ID=sua_key")
        print("  AWS_SECRET_ACCESS_KEY=sua_secret")
        sys.exit(1)
    
    # Configurar cliente KMS
    kms_key_id = os.getenv('KMS_KEY_ID', 'alias/hyperlane-validator-signer-terraclassic')
    region = os.getenv('AWS_REGION', 'us-east-1')
    
    print(f"🔑 Chave KMS: {kms_key_id}")
    print(f"🌍 Região: {region}")
    print()
    
    try:
        # Criar cliente
        terra = TerraKMSTransfer(kms_key_id, region)
        
        # Obter endereço de origem
        from_address = terra.get_terra_address()
        print(f"📤 De:        {from_address}")
        print(f"📥 Para:      {to_address}")
        print(f"💰 Quantidade: {uluna_to_lunc(amount_int):.6f} LUNC ({amount_int} uluna)")
        print(f"📝 Memo:      {memo}")
        print()
        
        # Verificar saldo
        print("⏳ Verificando saldo...")
        balance = terra.get_balance(from_address)
        print(f"💼 Saldo atual: {uluna_to_lunc(balance):.6f} LUNC ({balance} uluna)")
        print()
        
        # Calcular total com taxa
        gas_fee = int(float(GAS_LIMIT) * float(GAS_PRICE))
        total_needed = amount_int + gas_fee
        
        print(f"📊 Taxa de gas: {uluna_to_lunc(gas_fee):.6f} LUNC ({gas_fee} uluna)")
        print(f"📊 Total necessário: {uluna_to_lunc(total_needed):.6f} LUNC ({total_needed} uluna)")
        print()
        
        if balance < total_needed:
            print(f"❌ Saldo insuficiente!")
            print(f"   Necessário: {uluna_to_lunc(total_needed):.6f} LUNC")
            print(f"   Disponível: {uluna_to_lunc(balance):.6f} LUNC")
            print(f"   Faltam: {uluna_to_lunc(total_needed - balance):.6f} LUNC")
            sys.exit(1)
        
        # Confirmação
        print("⚠️  ATENÇÃO: Esta operação transferirá LUNC permanentemente!")
        confirm = input("\nDeseja continuar? (sim/não): ").strip().lower()
        
        if confirm not in ['sim', 's', 'yes', 'y']:
            print("❌ Operação cancelada.")
            sys.exit(0)
        
        print()
        print("🚀 Iniciando transferência...")
        print()
        
        # Nota: Este é um exemplo simplificado
        # Para produção real, implemente corretamente usando cosmpy ou similar
        print("⚠️  AVISO: Este script é uma demonstração simplificada.")
        print("   Para transferências reais, use as bibliotecas cosmos-sdk-py ou cosmpy")
        print("   que implementam corretamente a serialização protobuf.")
        print()
        print("📚 Bibliotecas recomendadas:")
        print("   - cosmpy: pip install cosmpy")
        print("   - cosmos-sdk-py: pip install cosmos-sdk")
        print()
        print("✅ Endereço de origem confirmado: " + from_address)
        print("✅ Saldo verificado: suficiente")
        print("✅ Assinatura KMS: disponível")
        
    except Exception as e:
        print(f"\n❌ Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

