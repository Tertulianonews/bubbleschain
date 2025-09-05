# Como Adicionar a Bolha Social do Nubank

## 📋 Passo a Passo Simples

### 1. Executar o Script SQL no Supabase

1. Acesse seu **Supabase Dashboard**
2. Vá para **SQL Editor**
3. Execute o script `NUBANK_SOCIAL_BUBBLE_SETUP.sql`
4. A bolha aparecerá automaticamente no app! 🟣

### 2. Script SQL Completo:

```sql
INSERT INTO socialBubbles (id, avatar_url, link_url, color)
VALUES (
    'nubank',
    'https://i.ibb.co/pBbXftcV/nubank.png',
    'https://nubank.com.br/',
    '#820AD1'
) ON CONFLICT (id) DO UPDATE SET
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;
```

## 🎨 Resultado Visual:

A bolha do Nubank terá:

- 🟣 **Cor roxa oficial** (#820AD1)
- 💫 **Animações especiais** exclusivas do Nubank
- 🏦 **Logo oficial** do Nubank
- 🔗 **Clique abre** https://nubank.com.br/
- 📱 **Nome "Nubank"** (gerado automaticamente pelo ID)

## ✅ Funcionalidades Automáticas:

- ✅ **Aparece automaticamente** na área das bolhas sociais
- ✅ **Sistema de busca** funciona (digite "nubank")
- ✅ **Posicionamento automático** como as outras bolhas
- ✅ **Efeitos visuais especiais** já implementados:
    - Anel roxo gradiente rotativo
    - Partículas roxas orbitando
    - Emoji de cartão flutuando
    - Ondas de energia roxas

## 🔧 Estrutura Técnica:

### Padrão da Tabela:

```sql
socialBubbles {
  id: 'nubank'              -- Identificador único
  avatar_url: 'https://...' -- Link direto da imagem
  link_url: 'https://...'   -- URL do site oficial  
  color: '#820AD1'          -- Cor em hexadecimal
}
```

### Como funciona no Flutter:

1. **Carregamento automático** da tabela `socialBubbles`
2. **Nome gerado** usando `id.capitalize()` = "Nubank"
3. **Posicionamento** em linha com outras bolhas sociais
4. **Efeitos especiais** detectados por `bubble.id == 'nubank'`

## 📊 Comparação com Outras Bolhas:

| Bolha      | ID         | Cor         | Efeitos Especiais |
|------------|------------|-------------|-------------------|
| Binance    | binance    | #F3BA2F     | ❌                 |
| Bitcoin    | bitcoin    | #F7931A     | Cubos blockchain  |
| Chrome     | chrome     | #FFC107     | ❌                 |
| **Nubank** | **nubank** | **#820AD1** | **✅ Exclusivos**  |

## 🎯 Vantagens da Implementação:

1. **Seguiu o padrão** existente das outras bolhas
2. **Efeitos visuais únicos** para destacar o Nubank
3. **Integração perfeita** com o sistema atual
4. **Fácil manutenção** - apenas 1 linha SQL
5. **Performance otimizada** - mesmo sistema das outras

## 🚨 Troubleshooting:

### Problema: Bolha não aparece

- ✅ Verifique se o script SQL executou sem erros
- ✅ Reinicie o app Flutter
- ✅ Verifique se está conectado ao Supabase correto

### Problema: Imagem não carrega

- ✅ O link `https://i.ibb.co/pBbXftcV/nubank.png` está funcionando
- ✅ Se necessário, pode usar outro link de imagem

### Problema: Efeitos não aparecem

- ✅ Os efeitos especiais já estão no código Flutter
- ✅ Funciona automaticamente quando `id = 'nubank'`

---

## 🎉 PRONTO!

Após executar o script SQL, a bolha do Nubank aparecerá automaticamente com:

- 🟣 Cor oficial roxa
- 🏦 Logo do Nubank
- ✨ Efeitos visuais exclusivos
- 🔗 Link para site oficial

**Total de tempo para implementar: < 2 minutos** ⚡

---

**🟣 BubblesChain + Nubank = Perfeição!** 🚀