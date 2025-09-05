-- ====================================
-- CONFIGURAÇÃO: Bolhas Sociais - Fintechs Brasileiras
-- ====================================
-- Execute este script no Supabase Dashboard > SQL Editor
-- Adiciona as principais fintechs do Brasil ao BubblesChain

-- 1. Verificar se a tabela socialBubbles existe, se não, criar
CREATE TABLE IF NOT EXISTS socialBubbles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    avatar_url TEXT,
    link_url TEXT,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Inserir Fintechs Brasileiras

-- Nubank - Principal fintech brasileira
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

-- Inter - Banco digital laranja
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'inter',
    'Inter',
    'https://logoeps.com/wp-content/uploads/2013/09/banco-inter-vector-logo.png',
    'https://www.bancointer.com.br/',
    '#FF7A00'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- C6 Bank - Banco do futuro
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'c6bank',
    'C6 Bank',
    'https://logoeps.com/wp-content/uploads/2014/06/c6-bank-vector-logo.png',
    'https://www.c6bank.com.br/',
    '#000000'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- PicPay - Super app de pagamentos
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'picpay',
    'PicPay',
    'https://logoeps.com/wp-content/uploads/2013/09/picpay-vector-logo.png',
    'https://www.picpay.com/',
    '#21C25E'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- 99Pay - Carteira digital da 99
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    '99pay',
    '99Pay',
    'https://logoeps.com/wp-content/uploads/2013/03/99-vector-logo.png',
    'https://www.99.co/',
    '#FCE100'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- BTG Pactual - Banco de investimentos digital
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'btg',
    'BTG',
    'https://logoeps.com/wp-content/uploads/2013/03/btg-pactual-vector-logo.png',
    'https://www.btgpactual.com/',
    '#1E3A8A'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- Mercado Pago - Fintech do Mercado Livre
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'mercadopago',
    'Mercado Pago',
    'https://logoeps.com/wp-content/uploads/2013/03/mercado-pago-vector-logo.png',
    'https://www.mercadopago.com.br/',
    '#00B1EA'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- Stone - Fintech de pagamentos
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'stone',
    'Stone',
    'https://logoeps.com/wp-content/uploads/2013/03/stone-co-vector-logo.png',
    'https://www.stone.co/',
    '#00D924'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- Will Bank - Banco digital para jovens
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'willbank',
    'Will Bank',
    'https://logoeps.com/wp-content/uploads/2014/06/will-bank-vector-logo.png',
    'https://www.willbank.com.br/',
    '#8B5CF6'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- Neon - Conta digital gratuita
INSERT INTO socialBubbles (id, name, avatar_url, link_url, color)
VALUES (
    'neon',
    'Neon',
    'https://logoeps.com/wp-content/uploads/2013/03/neon-vector-logo.png',
    'https://www.neon.com.br/',
    '#00D4FF'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url,
    link_url = EXCLUDED.link_url,
    color = EXCLUDED.color;

-- 3. Habilitar RLS (Row Level Security)
ALTER TABLE socialBubbles ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas RLS para acesso público de leitura
DROP POLICY IF EXISTS "Todos podem ler bolhas sociais" ON socialBubbles;
CREATE POLICY "Todos podem ler bolhas sociais" 
ON socialBubbles FOR SELECT 
USING (true);

-- 5. Política para admins (opcional)
DROP POLICY IF EXISTS "Apenas admins podem modificar bolhas sociais" ON socialBubbles;
CREATE POLICY "Apenas admins podem modificar bolhas sociais" 
ON socialBubbles FOR ALL 
USING (
    auth.uid() IN (
        SELECT id FROM users WHERE email LIKE '%@admin.com'
    )
);

-- ====================================
-- VERIFICAÇÃO
-- ====================================

-- Verificar todas as fintechs inseridas
SELECT id, name, color, link_url FROM socialBubbles 
WHERE id IN ('nubank', 'inter', 'c6bank', 'picpay', '99pay', 'btg', 'mercadopago', 'stone', 'willbank', 'neon')
ORDER BY name;

-- Contar total de bolhas sociais
SELECT COUNT(*) as total_bolhas_sociais FROM socialBubbles;

-- ====================================
-- SCRIPT DE LIMPEZA (se necessário)
-- ====================================

-- Para remover todas as fintechs (descomente se necessário):
/*
DELETE FROM socialBubbles 
WHERE id IN ('nubank', 'inter', 'c6bank', 'picpay', '99pay', 'btg', 'mercadopago', 'stone', 'willbank', 'neon');
*/

-- ====================================
-- NOTAS IMPORTANTES
-- ====================================

/*
FINTECHS BRASILEIRAS ADICIONADAS:
✅ Nubank - Roxo (#820AD1) - Principal fintech
✅ Inter - Laranja (#FF7A00) - Banco digital
✅ C6 Bank - Preto (#000000) - Banco do futuro
✅ PicPay - Verde (#21C25E) - Super app
✅ 99Pay - Amarelo (#FCE100) - Carteira digital
✅ BTG Pactual - Azul (#1E3A8A) - Investimentos
✅ Mercado Pago - Azul claro (#00B1EA) - Pagamentos
✅ Stone - Verde (#00D924) - Maquininhas
✅ Will Bank - Roxo (#8B5CF6) - Jovens
✅ Neon - Ciano (#00D4FF) - Conta gratuita

FUNCIONALIDADES:
- Todas aparecem automaticamente na tela de bolhas
- Clique abre o site oficial de cada fintech
- Cores oficiais das marcas
- Logos oficiais (quando disponíveis)

PERSONALIZAÇÃO:
- Modifique as cores conforme necessário
- Substitua URLs de logos por versões locais se preferir
- Adicione/remova fintechs conforme desejado
- Ajuste posicionamento no código Flutter se necessário

PRÓXIMOS PASSOS:
1. Testar todas as bolhas no app
2. Verificar se todos os logos carregam corretamente
3. Ajustar cores se necessário
4. Considerar adicionar mais fintechs regionais
*/