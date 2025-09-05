-- ====================================
-- MIGRATION: Live Video Support
-- ====================================
-- Execute este script no Supabase Dashboard > SQL Editor

-- 1. Adicionar campos de live video na tabela users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_live BOOLEAN DEFAULT FALSE;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS live_channel TEXT DEFAULT NULL;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS live_started_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- 2. Criar índice para melhor performance nas consultas de lives ativas
CREATE INDEX IF NOT EXISTS idx_users_is_live ON users(is_live);

-- 3. Criar tabela opcional para tracking de sessões de live (para estatísticas)
CREATE TABLE IF NOT EXISTS live_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    channel_name TEXT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    max_viewers INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Criar tabela opcional para tracking de viewers (para estatísticas)
CREATE TABLE IF NOT EXISTS live_viewers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES live_sessions(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(session_id, viewer_id)
);

-- 5. Política de RLS (Row Level Security) para live_sessions
ALTER TABLE live_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários podem ler todas as sessões de live" 
ON live_sessions FOR SELECT 
USING (true);

CREATE POLICY "Usuários podem inserir suas próprias sessões de live" 
ON live_sessions FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias sessões de live" 
ON live_sessions FOR UPDATE 
USING (auth.uid() = user_id);

-- 6. Política de RLS para live_viewers
ALTER TABLE live_viewers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários podem ler todos os viewers" 
ON live_viewers FOR SELECT 
USING (true);

CREATE POLICY "Usuários podem inserir como viewers" 
ON live_viewers FOR INSERT 
WITH CHECK (auth.uid() = viewer_id);

CREATE POLICY "Usuários podem atualizar seus próprios registros de viewing" 
ON live_viewers FOR UPDATE 
USING (auth.uid() = viewer_id);

-- 7. Função para limpar automaticamente lives abandonadas (opcional)
CREATE OR REPLACE FUNCTION cleanup_abandoned_lives()
RETURNS void AS $$
BEGIN
    -- Marcar como não-live usuários que iniciaram há mais de 4 horas
    UPDATE users 
    SET is_live = FALSE, 
        live_channel = NULL, 
        live_started_at = NULL
    WHERE is_live = TRUE 
    AND live_started_at < NOW() - INTERVAL '4 hours';
END;
$$ LANGUAGE plpgsql;

-- ====================================
-- VERIFICAÇÃO: Execute para confirmar
-- ====================================
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('is_live', 'live_channel', 'live_started_at')
ORDER BY column_name;

-- ====================================
-- EXEMPLO DE USO
-- ====================================
-- Para testar, execute:
-- UPDATE users SET is_live = TRUE, live_channel = 'live_test_123', live_started_at = NOW() WHERE id = 'SEU_USER_ID';
-- SELECT nickname, is_live, live_channel FROM users WHERE is_live = TRUE;