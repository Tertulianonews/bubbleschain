-- ====================================
-- CONFIGURAÇÃO: Supabase Storage para Live Frames
-- ====================================
-- Execute este script no Supabase Dashboard > SQL Editor

-- 1. Criar bucket para armazenar frames das lives
INSERT INTO storage.buckets (id, name, public)
VALUES ('live_frames', 'live_frames', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Política de Storage - Usuários podem fazer upload de frames
CREATE POLICY "Usuários podem fazer upload de live frames"
ON storage.objects
FOR INSERT 
WITH CHECK (
  bucket_id = 'live_frames' 
  AND auth.uid()::text = (storage.foldername(name))[1]
  OR bucket_id = 'live_frames'
);

-- 3. Política de Storage - Todos podem baixar frames públicos
CREATE POLICY "Todos podem baixar live frames"
ON storage.objects
FOR SELECT 
USING (bucket_id = 'live_frames');

-- 4. Política de Storage - Usuários podem deletar seus próprios frames
CREATE POLICY "Usuários podem deletar seus próprios live frames"
ON storage.objects
FOR DELETE 
USING (
  bucket_id = 'live_frames' 
  AND auth.uid()::text = (storage.foldername(name))[1]
  OR bucket_id = 'live_frames'
);

-- 5. Política de Storage - Usuários podem atualizar seus próprios frames
CREATE POLICY "Usuários podem atualizar seus próprios live frames"
ON storage.objects
FOR UPDATE 
USING (
  bucket_id = 'live_frames' 
  AND auth.uid()::text = (storage.foldername(name))[1]
  OR bucket_id = 'live_frames'
);

-- ====================================
-- VERIFICAÇÃO: Confirmar criação do bucket
-- ====================================
SELECT id, name, public FROM storage.buckets WHERE id = 'live_frames';

-- ====================================
-- LIMPEZA AUTOMÁTICA (OPCIONAL)
-- ====================================

-- Função para limpar frames antigos (mais de 1 hora)
CREATE OR REPLACE FUNCTION cleanup_old_live_frames()
RETURNS void AS $$
BEGIN
    -- Deletar arquivos de frames mais antigos que 1 hora
    DELETE FROM storage.objects 
    WHERE bucket_id = 'live_frames' 
    AND created_at < NOW() - INTERVAL '1 hour';
    
    RAISE NOTICE 'Limpeza de frames antigos executada';
END;
$$ LANGUAGE plpgsql;

-- ====================================
-- NOTAS IMPORTANTES
-- ====================================

/*
1. **Bucket Público**: Os frames são públicos para permitir visualização
2. **Sobrescrita**: Cada live usa sempre o mesmo nome de arquivo
3. **Limpeza**: Frames são deletados quando a live termina
4. **Performance**: Arquivos pequenos (JPEG comprimido) para velocidade
5. **Cache**: URLs incluem timestamp para evitar cache do navegador

ESTRUTURA DOS ARQUIVOS:
- live_[channel_name].jpg (sempre sobrescreve)
- Exemplo: live_live_12345_67890.jpg

FLUXO:
1. Host captura frame da câmera (500ms)
2. Converte para JPEG comprimido
3. Upload para live_frames/live_[channel].jpg (sobrescreve)
4. Viewers baixam URL com timestamp (800ms)
5. Quando live termina: arquivo é deletado
*/