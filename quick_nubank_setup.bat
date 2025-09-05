@echo off
REM ====================================
REM SCRIPT RÁPIDO: Adicionar Bolha Social do Nubank
REM ====================================
REM Execute: quick_nubank_setup.bat

echo 🟣 Configurando bolha social do Nubank...

REM Verificar se o Supabase CLI está instalado
where supabase >nul 2>&1
if errorlevel 1 (
    echo ❌ Supabase CLI não encontrado. Instale com:
    echo npm install -g supabase
    pause
    exit /b 1
)

REM Criar script SQL temporário seguindo o padrão das outras bolhas
echo -- Inserir Nubank seguindo o padrão das outras bolhas sociais > temp_nubank.sql
echo INSERT INTO socialBubbles (id, avatar_url, link_url, color) >> temp_nubank.sql
echo VALUES ( >> temp_nubank.sql
echo     'nubank', >> temp_nubank.sql
echo     'https://i.ibb.co/pBbXftcV/nubank.png', >> temp_nubank.sql
echo     'https://nubank.com.br/', >> temp_nubank.sql
echo     '#820AD1' >> temp_nubank.sql
echo ) ON CONFLICT (id) DO UPDATE SET >> temp_nubank.sql
echo     avatar_url = EXCLUDED.avatar_url, >> temp_nubank.sql
echo     link_url = EXCLUDED.link_url, >> temp_nubank.sql
echo     color = EXCLUDED.color; >> temp_nubank.sql
echo. >> temp_nubank.sql
echo -- Verificar inserção >> temp_nubank.sql
echo SELECT 'Nubank adicionado com sucesso!' as status, id, avatar_url, color  >> temp_nubank.sql
echo FROM socialBubbles WHERE id = 'nubank'; >> temp_nubank.sql

echo 📡 Execute no Supabase Dashboard > SQL Editor:
echo.
echo ====================================
type temp_nubank.sql
echo ====================================
echo.

echo ✅ Script SQL criado como temp_nubank.sql
echo 🟣 Copie e cole o conteúdo acima no Supabase
echo 🔗 A bolha abrirá: https://nubank.com.br/
echo 🎨 Cor: #820AD1 (roxo oficial)
echo 🏦 Logo: https://i.ibb.co/pBbXftcV/nubank.png
echo ✨ Efeitos especiais automáticos já implementados!
echo 🫧 BubblesChain - Nubank Social Bubble

pause