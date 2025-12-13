-- ============================================
-- SKYDOGE BLOCKCHAIN - CANAL EDUCACIONAL
-- ============================================
-- Execute este SQL no editor SQL do Supabase (SQL Editor)
-- Este canal mostra informações educacionais sobre a blockchain Skydoge

-- Obter um usuário existente para ser dono do canal (usar o primeiro usuário do sistema)
DO $$
DECLARE
    first_user_id UUID;
    skydoge_channel_id UUID;
BEGIN
    -- Buscar primeiro usuário do sistema
    SELECT id INTO first_user_id 
    FROM users 
    LIMIT 1;
    
    -- Se não houver usuários, usar UUID genérico
    IF first_user_id IS NULL THEN
        first_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    -- Gerar UUID para o canal Skydoge
    skydoge_channel_id := gen_random_uuid();
    
    -- Deletar canal se já existir (por nome, já que UUID será sempre novo)
    DELETE FROM channels 
    WHERE name = 'Skydoge Blockchain';
    
    -- Inserir o canal especial Skydoge Blockchain
    INSERT INTO channels (
        id,
        name,
        description,
        owner_id,
        image_url,
        banner_url,
        subscriber_count,
        is_live,
        live_channel_name,
        created_at
    ) VALUES (
        skydoge_channel_id,
        'Skydoge Blockchain',
        '🔗 Aprenda sobre blockchain Drivechain! Veja blocos sendo minerados, explore sidechains e descubra a tecnologia revolucionária da Skydoge Network.',
        first_user_id,
        null,  -- Pode adicionar URL de imagem depois
        null,  -- Pode adicionar URL de banner depois
        0,
        false,
        null,
        NOW()
    );
    
    -- Retornar informações do canal criado
    RAISE NOTICE '✅ Canal Skydoge Blockchain criado com sucesso!';
    RAISE NOTICE '📱 ID do canal: %', skydoge_channel_id;
    RAISE NOTICE '👤 Owner ID: %', first_user_id;
END $$;

-- Verificar o canal criado
SELECT 
    c.id,
    c.name,
    c.description,
    c.owner_id,
    COALESCE(u.nickname, 'Sistema') as owner_name,
    c.subscriber_count,
    c.is_live,
    c.created_at
FROM channels c
LEFT JOIN users u ON c.owner_id = u.id
WHERE c.name = 'Skydoge Blockchain'
ORDER BY c.created_at DESC
LIMIT 1;

-- ============================================
-- NOTA IMPORTANTE
-- ============================================
-- O ID do canal será um UUID gerado automaticamente.
-- No código do app (channels_screen.dart), você precisa verificar
-- por 'skydoge_blockchain' no ID do canal.
-- 
-- Para fazer isso funcionar, precisamos criar uma entrada especial
-- com ID fixo. Veja a próxima seção.
-- ============================================

-- ALTERNATIVA: Criar com ID fixo para facilitar verificação no código
DO $$
DECLARE
    first_user_id UUID;
    fixed_channel_id UUID := 'a0a0a0a0-b0b0-c0c0-d0d0-e0e0e0e0e0e0';
BEGIN
    -- Buscar primeiro usuário
    SELECT id INTO first_user_id FROM users LIMIT 1;
    IF first_user_id IS NULL THEN
        first_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    -- Deletar se existir
    DELETE FROM channels WHERE id = fixed_channel_id;
    
    -- Inserir com ID fixo
    INSERT INTO channels (
        id,
        name,
        description,
        owner_id,
        image_url,
        banner_url,
        subscriber_count,
        is_live,
        live_channel_name,
        created_at
    ) VALUES (
        fixed_channel_id,
        'Skydoge Blockchain',
        '🔗 Aprenda sobre blockchain Drivechain! Veja blocos sendo minerados, explore sidechains e descubra a tecnologia revolucionária da Skydoge Network.',
        first_user_id,
        null,
        null,
        0,
        false,
        null,
        NOW()
    );
    
    RAISE NOTICE '✅ Canal Skydoge criado com ID fixo: %', fixed_channel_id;
END $$;

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================
SELECT 
    '✅ Setup completo!' as status,
    COUNT(*) as total_channels,
    SUM(CASE WHEN name = 'Skydoge Blockchain' THEN 1 ELSE 0 END) as skydoge_channels
FROM channels;
