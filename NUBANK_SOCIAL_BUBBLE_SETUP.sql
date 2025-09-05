-- ====================================
-- CONFIGURAÇÃO: Bolha Social do Nubank
-- ====================================
-- Execute este script no Supabase Dashboard > SQL Editor

-- 1. Verificar se a tabela socialBubbles existe, se não, criar
CREATE TABLE IF NOT EXISTS socialBubbles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    avatar_url TEXT,
    link_url TEXT,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir a bolha social do Nubank seguindo o padrão das outras
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

-- 3. Habilitar RLS (Row Level Security) se ainda não estiver habilitado
ALTER TABLE socialBubbles ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas RLS para acesso público de leitura
DROP POLICY IF EXISTS "Todos podem ler bolhas sociais" ON socialBubbles;
CREATE POLICY "Todos podem ler bolhas sociais" 
ON socialBubbles FOR SELECT 
USING (true);

-- 5. Criar política para que apenas admins possam inserir/atualizar (opcional)
DROP POLICY IF EXISTS "Apenas admins podem modificar bolhas sociais" ON socialBubbles;
CREATE POLICY "Apenas admins podem modificar bolhas sociais" 
ON socialBubbles FOR ALL 
USING (
    auth.uid() IN (
        SELECT id FROM users WHERE email LIKE '%@admin.com' -- Adapte conforme necessário
    )
);

-- ====================================
-- VERIFICAÇÃO
-- ====================================

-- Verificar se a bolha do Nubank foi inserida
SELECT * FROM socialBubbles WHERE id = 'nubank';

-- Listar todas as bolhas sociais
SELECT id, avatar_url, link_url, color FROM socialBubbles ORDER BY id;

-- ====================================
-- NOTAS IMPORTANTES
-- ====================================

/*
BOLHA SOCIAL DO NUBANK ADICIONADA:
✅ ID: 'nubank' 
✅ Avatar: https://i.ibb.co/pBbXftcV/nubank.png (link direto fornecido)
✅ URL: https://nubank.com.br/
✅ Cor: #820AD1 (roxo oficial do Nubank)

PADRÃO SEGUIDO:
- Mesmo formato das outras bolhas sociais existentes
- Sem campo 'name' (o código Flutter usa o ID capitalizado)
- Avatar usando link direto de imagem
- Cor em formato hexadecimal

FUNCIONAMENTO:
- Aparecerá automaticamente na tela principal
- Nome exibido será "Nubank" (baseado no ID)
- Clique abrirá o site oficial do Nubank
- Cor roxa característica da marca
- Efeitos visuais especiais já implementados no código Flutter
*/