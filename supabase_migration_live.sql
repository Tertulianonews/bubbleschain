-- Migration para adicionar campos de live video na tabela users
-- Execute este script no SQL Editor do seu Supabase Dashboard

-- Primeiro, vamos verificar se a tabela users existe e adicionar os campos
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_live BOOLEAN DEFAULT FALSE;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS live_channel TEXT DEFAULT NULL;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS live_started_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- Criar índice para melhor performance nas consultas de live
CREATE INDEX IF NOT EXISTS idx_users_is_live ON users(is_live);

-- Atualizar todos os usuários existentes para garantir que tenham os valores padrão
UPDATE users 
SET is_live = FALSE 
WHERE is_live IS NULL;

UPDATE users 
SET live_channel = NULL 
WHERE live_channel IS NULL;

UPDATE users 
SET live_started_at = NULL 
WHERE live_started_at IS NULL;

-- Verificar se os campos foram criados corretamente
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('is_live', 'live_channel', 'live_started_at');

-- Script para limpar lives antigas (opcional - executar se necessário)
-- UPDATE users SET is_live = FALSE, live_channel = NULL, live_started_at = NULL;