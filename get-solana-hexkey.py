#!/usr/bin/env python3
"""
Convert Solana keypair JSON file to hexadecimal private key format for Hyperlane.

Usage:
    python3 get-solana-hexkey.py <keypair.json>

Example:
    python3 get-solana-hexkey.py ./solana-keypair.json
    Output: 0x1234567890abcdef...
"""

import json
import sys

def solana_keypair_to_hex(keypair_file):
    """Convert Solana keypair JSON to hexadecimal private key."""
    try:
        with open(keypair_file, 'r') as f:
            keypair = json.load(f)
        
        # Solana keypair is a JSON array of 64 integers (bytes)
        if isinstance(keypair, list) and len(keypair) == 64:
            # Convert bytes to hex
            private_key_bytes = bytes(keypair)
            private_key_hex = private_key_bytes.hex()
            return f"0x{private_key_hex}"
        else:
            print(f"Error: Invalid keypair format in {keypair_file}", file=sys.stderr)
            print(f"Expected: JSON array with 64 integers", file=sys.stderr)
            print(f"Got: {type(keypair)} with length {len(keypair) if isinstance(keypair, list) else 'N/A'}", file=sys.stderr)
            return None
    except FileNotFoundError:
        print(f"Error: File not found: {keypair_file}", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {keypair_file}: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Error reading keypair file: {e}", file=sys.stderr)
        return None

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 get-solana-hexkey.py <keypair.json>", file=sys.stderr)
        print("", file=sys.stderr)
        print("Example:", file=sys.stderr)
        print("  python3 get-solana-hexkey.py ./solana-keypair.json", file=sys.stderr)
        sys.exit(1)
    
    keypair_file = sys.argv[1]
    hex_key = solana_keypair_to_hex(keypair_file)
    
    if hex_key:
        print(hex_key)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()

