-- Script simples para adicionar Nubank às bolhas sociais
-- Copie e cole no Supabase Dashboard > SQL Editor

INSERT INTO socialBubbles (id, avatar_url, link_url, color)
VALUES (
    'nubank',
    'https://i.ibb.co/pBbXftcV/nubank.png',
    'https://nubank.com.br/',
    '#820AD1'
);

-- Verificar se foi inserido
SELECT * FROM socialBubbles WHERE id = 'nubank';