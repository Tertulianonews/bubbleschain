#!/bin/bash

# ====================================
# SCRIPT RÁPIDO: Adicionar Bolha Social do Nubank
# ====================================
# Execute: ./quick_nubank_setup.sh

echo "🟣 Configurando bolha social do Nubank..."

# Verificar se o Supabase CLI está instalado
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI não encontrado. Instale com:"
    echo "npm install -g supabase"
    exit 1
fi

# Criar script SQL temporário
cat > temp_nubank.sql << 'EOF'
-- Criar tabela se não existir
CREATE TABLE IF NOT EXISTS socialBubbles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    avatar_url TEXT,
    link_url TEXT,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir Nubank
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'nubank',
    'Nubank',
    'https://logodownload.org/wp-content/uploads/2019/08/nubank-logo-6.png',
    'https://nubank.com.br/',
    '#820AD1'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- Habilitar RLS
ALTER TABLE socialBubbles ENABLE ROW LEVEL SECURITY;

-- Política de leitura pública
DROP POLICY IF EXISTS "Todos podem ler bolhas sociais" ON socialBubbles;
CREATE POLICY "Todos podem ler bolhas sociais" 
ON socialBubbles FOR SELECT 
USING (true);

-- Verificar inserção
SELECT 'Nubank configurado com sucesso!' as status, id, name, color 
FROM socialBubbles WHERE id = 'nubank';
EOF

# Executar no Supabase
echo "📡 Executando no Supabase..."
supabase db push --db-url="$SUPABASE_DB_URL" --file=temp_nubank.sql

# Verificar resultado
if [ $? -eq 0 ]; then
    echo "✅ Bolha do Nubank configurada com sucesso!"
    echo "🟣 A bolha aparecerá automaticamente no app"
    echo "🔗 Clique abrirá: https://nubank.com.br/"
    echo "🎨 Cor: #820AD1 (roxo oficial)"
else
    echo "❌ Erro na configuração. Verifique:"
    echo "   - SUPABASE_DB_URL está definida"
    echo "   - Supabase CLI está autenticado"
    echo "   - Conexão com o banco está funcionando"
fi

# Limpar arquivo temporário
rm -f temp_nubank.sql

echo "🫧 BubblesChain - Nubank Social Bubble"