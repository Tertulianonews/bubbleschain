-- ====================================
-- CONFIGURAÇÃO: Sistema de Canais Completo
-- ====================================
-- Execute este script no Supabase Dashboard > SQL Editor

-- 1. Criar tabela de canais
CREATE TABLE IF NOT EXISTS channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL CHECK (length(name) >= 3 AND length(name) <= 50),
    description TEXT CHECK (length(description) <= 500),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT,
    banner_url TEXT,
    subscriber_count INTEGER DEFAULT 0,
    is_live BOOLEAN DEFAULT FALSE,
    live_channel_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Criar tabela de inscrições em canais
CREATE TABLE IF NOT EXISTS channel_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    channel_id UUID REFERENCES channels(id) ON DELETE CASCADE NOT NULL,
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, channel_id)
);

-- 3. Criar tabela de posts dos canais
CREATE TABLE IF NOT EXISTS channel_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID REFERENCES channels(id) ON DELETE CASCADE NOT NULL,
    author_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    content TEXT CHECK (length(content) <= 2000),
    image_url TEXT,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Criar tabela de curtidas em posts
CREATE TABLE IF NOT EXISTS post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    post_id UUID REFERENCES channel_posts(id) ON DELETE CASCADE NOT NULL,
    liked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

-- 5. Criar tabela de comentários em posts (para futura implementação)
CREATE TABLE IF NOT EXISTS post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES channel_posts(id) ON DELETE CASCADE NOT NULL,
    author_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL CHECK (length(content) <= 500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ====================================
-- ÍNDICES PARA PERFORMANCE
-- ====================================

-- Índices para canais
CREATE INDEX IF NOT EXISTS idx_channels_owner_id ON channels(owner_id);
CREATE INDEX IF NOT EXISTS idx_channels_created_at ON channels(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_channels_is_live ON channels(is_live);

-- Índices para inscrições
CREATE INDEX IF NOT EXISTS idx_channel_subscriptions_user_id ON channel_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_channel_subscriptions_channel_id ON channel_subscriptions(channel_id);

-- Índices para posts
CREATE INDEX IF NOT EXISTS idx_channel_posts_channel_id ON channel_posts(channel_id);
CREATE INDEX IF NOT EXISTS idx_channel_posts_author_id ON channel_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_channel_posts_created_at ON channel_posts(created_at DESC);

-- Índices para curtidas
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);

-- Índices para comentários
CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_author_id ON post_comments(author_id);

-- ====================================
-- TRIGGERS PARA CONTADORES AUTOMÁTICOS
-- ====================================

-- Trigger para atualizar contador de seguidores
CREATE OR REPLACE FUNCTION update_channel_subscriber_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE channels 
        SET subscriber_count = subscriber_count + 1 
        WHERE id = NEW.channel_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE channels 
        SET subscriber_count = subscriber_count - 1 
        WHERE id = OLD.channel_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_channel_subscriber_count
    AFTER INSERT OR DELETE ON channel_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_channel_subscriber_count();

-- Trigger para atualizar contador de curtidas
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE channel_posts 
        SET likes_count = likes_count + 1 
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE channel_posts 
        SET likes_count = likes_count - 1 
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_likes_count
    AFTER INSERT OR DELETE ON post_likes
    FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Trigger para atualizar contador de comentários
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE channel_posts 
        SET comments_count = comments_count + 1 
        WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE channel_posts 
        SET comments_count = comments_count - 1 
        WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_comments_count
    AFTER INSERT OR DELETE ON post_comments
    FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_channels_updated_at
    BEFORE UPDATE ON channels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_channel_posts_updated_at
    BEFORE UPDATE ON channel_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_post_comments_updated_at
    BEFORE UPDATE ON post_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ====================================
-- POLÍTICAS RLS (ROW LEVEL SECURITY)
-- ====================================

-- Habilitar RLS para todas as tabelas
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE channel_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE channel_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

-- Políticas para canais
CREATE POLICY "Todos podem ler canais" 
ON channels FOR SELECT 
USING (true);

CREATE POLICY "Usuários podem criar canais" 
ON channels FOR INSERT 
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Donos podem atualizar seus canais" 
ON channels FOR UPDATE 
USING (auth.uid() = owner_id);

CREATE POLICY "Donos podem deletar seus canais" 
ON channels FOR DELETE 
USING (auth.uid() = owner_id);

-- Políticas para inscrições
CREATE POLICY "Todos podem ler inscrições" 
ON channel_subscriptions FOR SELECT 
USING (true);

CREATE POLICY "Usuários podem se inscrever" 
ON channel_subscriptions FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem cancelar suas inscrições" 
ON channel_subscriptions FOR DELETE 
USING (auth.uid() = user_id);

-- Políticas para posts
CREATE POLICY "Todos podem ler posts" 
ON channel_posts FOR SELECT 
USING (true);

CREATE POLICY "Usuários logados podem criar posts" 
ON channel_posts FOR INSERT 
WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Autores podem atualizar seus posts" 
ON channel_posts FOR UPDATE 
USING (auth.uid() = author_id);

CREATE POLICY "Autores podem deletar seus posts" 
ON channel_posts FOR DELETE 
USING (auth.uid() = author_id);

-- Políticas para curtidas
CREATE POLICY "Todos podem ler curtidas" 
ON post_likes FOR SELECT 
USING (true);

CREATE POLICY "Usuários podem curtir posts" 
ON post_likes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem remover suas curtidas" 
ON post_likes FOR DELETE 
USING (auth.uid() = user_id);

-- Políticas para comentários
CREATE POLICY "Todos podem ler comentários" 
ON post_comments FOR SELECT 
USING (true);

CREATE POLICY "Usuários logados podem comentar" 
ON post_comments FOR INSERT 
WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Autores podem atualizar seus comentários" 
ON post_comments FOR UPDATE 
USING (auth.uid() = author_id);

CREATE POLICY "Autores podem deletar seus comentários" 
ON post_comments FOR DELETE 
USING (auth.uid() = author_id);

-- ====================================
-- BUCKET DE ARMAZENAMENTO
-- ====================================

-- Criar bucket para imagens de canais
INSERT INTO storage.buckets (id, name, public)
VALUES ('channel_images', 'channel_images', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas para storage de imagens de canais
CREATE POLICY "Usuários podem fazer upload de imagens de canais"
ON storage.objects
FOR INSERT 
WITH CHECK (
  bucket_id = 'channel_images' 
  AND auth.uid() IS NOT NULL
);

CREATE POLICY "Todos podem baixar imagens de canais"
ON storage.objects
FOR SELECT 
USING (bucket_id = 'channel_images');

CREATE POLICY "Usuários podem atualizar suas imagens de canais"
ON storage.objects
FOR UPDATE 
USING (
  bucket_id = 'channel_images' 
  AND auth.uid() IS NOT NULL
);

CREATE POLICY "Usuários podem deletar suas imagens de canais"
ON storage.objects
FOR DELETE 
USING (
  bucket_id = 'channel_images' 
  AND auth.uid() IS NOT NULL
);

-- ====================================
-- FUNÇÕES AUXILIARES
-- ====================================

-- Função para buscar canais com informações completas
CREATE OR REPLACE FUNCTION get_channels_with_info(user_id_param UUID DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    owner_id UUID,
    owner_name TEXT,
    image_url TEXT,
    banner_url TEXT,
    subscriber_count INTEGER,
    is_live BOOLEAN,
    live_channel_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    is_subscribed BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.owner_id,
        COALESCE(u.nickname, 'Usuário') as owner_name,
        c.image_url,
        c.banner_url,
        c.subscriber_count,
        c.is_live,
        c.live_channel_name,
        c.created_at,
        CASE 
            WHEN user_id_param IS NOT NULL AND cs.user_id IS NOT NULL THEN true
            ELSE false
        END as is_subscribed
    FROM channels c
    LEFT JOIN users u ON c.owner_id = u.id
    LEFT JOIN channel_subscriptions cs ON c.id = cs.channel_id AND cs.user_id = user_id_param
    ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Função para buscar posts com informações completas
CREATE OR REPLACE FUNCTION get_channel_posts_with_info(channel_id_param UUID, user_id_param UUID DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    channel_id UUID,
    author_id UUID,
    author_name TEXT,
    author_avatar TEXT,
    content TEXT,
    image_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    is_liked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cp.id,
        cp.channel_id,
        cp.author_id,
        COALESCE(u.nickname, 'Usuário') as author_name,
        u.avatar_url as author_avatar,
        cp.content,
        cp.image_url,
        cp.likes_count,
        cp.comments_count,
        cp.created_at,
        CASE 
            WHEN user_id_param IS NOT NULL AND pl.user_id IS NOT NULL THEN true
            ELSE false
        END as is_liked
    FROM channel_posts cp
    LEFT JOIN users u ON cp.author_id = u.id
    LEFT JOIN post_likes pl ON cp.id = pl.post_id AND pl.user_id = user_id_param
    WHERE cp.channel_id = channel_id_param
    ORDER BY cp.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ====================================
-- DADOS DE EXEMPLO (OPCIONAL)
-- ====================================

-- Inserir alguns canais de exemplo (descomente se desejar)
/*
INSERT INTO channels (name, description, owner_id, image_url, banner_url) VALUES 
('Gaming Central', 'Os melhores jogos e reviews!', (SELECT id FROM users LIMIT 1), NULL, NULL),
('Tech News', 'Últimas notícias do mundo da tecnologia', (SELECT id FROM users LIMIT 1), NULL, NULL),
('Música & Arte', 'Explorando a criatividade em todas as formas', (SELECT id FROM users LIMIT 1), NULL, NULL);
*/

-- ====================================
-- VERIFICAÇÃO FINAL
-- ====================================

-- Verificar tabelas criadas
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('channels', 'channel_subscriptions', 'channel_posts', 'post_likes', 'post_comments')
ORDER BY table_name;

-- Verificar bucket criado
SELECT id, name, public FROM storage.buckets WHERE id = 'channel_images';

-- ====================================
-- NOTAS IMPORTANTES
-- ====================================

/*
FUNCIONALIDADES IMPLEMENTADAS:
✅ Sistema completo de canais
✅ Inscrições/desincrições automáticas
✅ Posts com texto e imagens
✅ Sistema de curtidas
✅ Preparado para comentários
✅ Integração com sistema de lives
✅ Upload de imagens (avatares, banners, posts)
✅ Contadores automáticos
✅ Políticas de segurança RLS
✅ Índices para performance
✅ Triggers para consistência de dados

PRÓXIMOS PASSOS:
1. Executar este script no Supabase
2. Testar criação de canais no app
3. Implementar sistema de comentários (opcional)
4. Adicionar notificações push para novos posts
5. Implementar sistema de trending/recomendações

ESTRUTURA DE PERMISSÕES:
- Qualquer usuário pode criar canais
- Apenas donos podem editar/deletar seus canais
- Usuários podem se inscrever/desinscrever livremente
- Qualquer usuário logado pode postar (modifique se necessário)
- Sistema de curtidas livre para usuários logados
*/