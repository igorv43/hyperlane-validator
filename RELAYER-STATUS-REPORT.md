# 📊 Relayer Status Report

**Date**: 2025-12-04  
**Time**: 19:15 UTC

---

## ✅ **Blockchains Status**

### 🌍 **Terra Classic** ⚠️ **PROBLEMA ENCONTRADO**

**Status**: ⚠️ **Warnings constantes (não crítico)**

**Problema Identificado**:
- O relayer está tentando acessar blocos antigos (height 1, 2, 3, etc.)
- O RPC do Terra Classic testnet só tem blocos disponíveis a partir da altura **28276100**
- A configuração atual tem `index.from: 1`, o que causa tentativas de acessar blocos inexistentes

**Erro nos Logs**:
```
WARN: Got error from inner fallback provider, error: Other(CometbftRpcError(response error
Internal error: height 1 is not available, lowest height is 28276100 (code: -32603)
```

**Solução**: Ajustar `index.from` para um valor próximo da altura atual ou remover para começar do bloco atual.

**Altura Atual do Bloco**: 28,344,891  
**Configuração Atual**: `index.from: 1` ❌  
**Recomendação**: Remover `from` ou usar `28276100`

---

### 🔷 **BSC Testnet** ✅ **FUNCIONANDO**

**Status**: ✅ **Operacional**

**Logs**:
- Sincronização normal
- Encontrados logs nos ranges esperados
- Sequence: 12746-12762
- Block range: 76587746-76590129

**Sem erros ou warnings críticos.**

---

### ☀️ **Solana Testnet** ✅ **FUNCIONANDO**

**Status**: ✅ **Operacional**

**Logs**:
- Sincronização normal
- Encontrados logs nos ranges esperados
- Sequence: 637-659
- Block range: 373822127-374301610

**Sem erros ou warnings críticos.**

---

## 📋 **Resumo**

| Blockchain | Status | Problema | Ação Necessária |
|------------|--------|----------|-----------------|
| **Terra Classic** | ⚠️ Warnings | `index.from: 1` muito antigo | Ajustar configuração |
| **BSC Testnet** | ✅ OK | Nenhum | Nenhuma |
| **Solana Testnet** | ✅ OK | Nenhum | Nenhuma |

---

## 🔧 **Correção Recomendada**

Ajustar a configuração do Terra Classic em `agent-config.docker-testnet.json`:

**Antes**:
```json
"index": {
  "from": 1,
  "chunk": 20
}
```

**Depois** (opção 1 - remover `from`):
```json
"index": {
  "chunk": 20
}
```

**Depois** (opção 2 - usar altura recente):
```json
"index": {
  "from": 28276100,
  "chunk": 20
}
```

---

## 📝 **Observações**

- Os warnings do Terra Classic não impedem o funcionamento do relayer
- O sistema de fallback está funcionando corretamente (deprioritizing providers com erros)
- BSC e Solana estão sincronizando normalmente
- Recomenda-se corrigir a configuração do Terra Classic para eliminar os warnings

---

**Próximos Passos**:
1. Ajustar `index.from` do Terra Classic
2. Reiniciar o relayer
3. Monitorar logs para confirmar que os warnings desapareceram

