# Bubbles Chat

Este é um aplicativo de chat social desenvolvido em Flutter com Supabase como backend.

## 🔐 Sistema de Reset de Senha - SOLUÇÃO DEFINITIVA ✅

### 🔍 Problema Original (401 Missing authorization header)

**Por que o reset falhava:**

- **Apps Web**: Funcionavam bem com cookies no navegador
- **Apps Flutter Nativos**: Não compartilham cookies do navegador
- **Resultado**: Supabase client não recebia a sessão → erro 401

### 🛠️ Solução Implementada: Deep Links + Client-Side Token Exchange

#### Como Funciona Agora

1. **Solicitação de Reset**: Usuário clica "Esqueceu a senha?"
2. **Email com Deep Link**: Email contém `bubbleschain://reset-password?token_hash=...`
3. **App Abre via Deep Link**: Sistema operacional abre o app automaticamente
4. **Troca de Token Client-Side**: App usa `verifyOTP()` para trocar token por sessão
5. **Reset de Senha**: Usuário define nova senha com sessão ativa

#### Arquitetura Técnica

```
[Email] → [Deep Link] → [App Nativo] → [verifyOTP] → [Nova Sessão] → [Reset Senha]
```

### 📱 Configuração de Deep Links

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="bubbleschain" android:host="reset-password"/>
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>bubbleschain.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>bubbleschain</string>
        </array>
    </dict>
</array>
```

### 💻 Implementação Flutter

#### URLs de Redirecionamento
```dart
// Antes (Edge Function - apenas web)
const String kResetRedirectUrl = 'https://vuihslbjlohumjtgejzd.supabase.co/functions/v1/auth-confirm?type=recovery&next=...';

// Agora (Deep Link - apps nativos)  
const String kResetRedirectUrl = 'bubbleschain://reset-password';
```

#### Captura de Deep Links (`main.dart`)

```dart
// Usando app_links para capturar URLs
void _processResetPasswordUri(Uri uri) {
  final token = uri.queryParameters['token'] ?? 
                uri.queryParameters['access_token'] ?? 
                uri.queryParameters['code'];
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => ResetPasswordScreen(initialResetToken: token),
  ));
}
```

#### Troca de Token (`reset_password_screen.dart`)

```dart
// Usando verifyOTP para estabelecer sessão
final response = await Supabase.instance.client.auth.verifyOTP(
  token: token,
  type: OtpType.recovery,
);

if (response.session != null) {
  // Sessão ativa! Usuário pode redefinir senha
  setState(() {
    _canSubmitPassword = true;
  });
}
```

### 🧪 Como Testar

#### No Dispositivo Real:

1. **Instalar App**: `flutter install` no dispositivo
2. **Solicitar Reset**: Clique "Esqueceu a senha?" no app
3. **Verificar Email**: Abra o email recebido
4. **Clicar Link**: Link deve abrir o app automaticamente
5. **Definir Nova Senha**: Tela de reset deve estar ativa

#### Logs de Debug:

```
[DEBUG ResetPassword] initialResetToken: ABC123...
[DEBUG ResetPassword] Token do deep link encontrado, processando...
[DEBUG ResetPassword] Verificando token de recovery...
[DEBUG ResetPassword] Sessão de reset ativada com sucesso!
```

### 📧 Template de Email (Supabase)

Configure no painel do Supabase → Authentication → Email Templates → Reset Password:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <h2 style="color: #333;">Reset your password</h2>
    <p>Follow this link to reset the password for your user:</p>
    
    <!-- Mobile App Button -->
    <div style="margin: 30px 0;">
        <a href="bubbleschain://reset-password?token={{ .Token }}&type=recovery" 
           style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; margin-right: 10px;">
           Open in App
        </a>
        <!-- Web Fallback Button -->
        <a href="https://tertulianonews.github.io/bubbleschain/#/reset-password?token={{ .Token }}&type=recovery" 
           style="background-color: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
           Open in Browser
        </a>
    </div>
    
    <p style="color: #666; font-size: 14px;">
        • <strong>Open in App</strong>: Use if you have the mobile app installed<br>
        • <strong>Open in Browser</strong>: Use on computer or if app link doesn't work
    </p>
    
    <p style="margin-top: 30px; font-size: 12px; color: #666;">
        This link will expire in 1 hour for security reasons.
    </p>
</body>
</html>
```

**⚠️ IMPORTANTE:** Use `{{ .Token }}` (não `{{ .TokenHash }}`)!

### 🔄 Compatibilidade

| Plataforma      | Suporte | Método                  |
|-----------------|---------|-------------------------|
| **iOS App**     | ✅       | Deep Links + verifyOTP  |
| **Android App** | ✅       | Deep Links + verifyOTP  |
| **Flutter Web** | ✅       | URL routing + verifyOTP |
| **PWA**         | ✅       | URL routing + verifyOTP |

### 🛠️ Troubleshooting

#### App não abre com o link:

```bash
# Verificar configuração Android
adb shell am start -W -a android.intent.action.VIEW -d "bubbleschain://reset-password?token=test" com.example.cripto_chat

# Verificar logs
flutter logs
```

#### Erro na troca de token:

- Verificar se `supabase_flutter: ^2.3.3` está atualizado
- Confirmar se `verifyOTP` está disponível na versão
- Verificar logs: `[DEBUG ResetPassword] ERRO ao verificar token`

#### Token não chegando:

- Verificar template de email no Supabase
- Confirmar URL scheme: `bubbleschain://reset-password`
- Testar com token mock: `bubbleschain://reset-password?token=test123`

### 🎯 Vantagens da Solução

✅ **Sem erro 401**: Token trocado client-side  
✅ **Multiplataforma**: Funciona em iOS, Android e Web  
✅ **UX Nativa**: Abre app automaticamente  
✅ **Seguro**: Token usado apenas uma vez  
✅ **Debug Completo**: Logs detalhados para troubleshooting  
✅ **Fallback Robusto**: Web continua funcionando

### 📚 Recursos Técnicos

- **Deep Links**: `app_links: ^3.4.1`
- **Supabase**: `supabase_flutter: ^2.3.3`
- **Token Exchange**: `verifyOTP()` com `OtpType.recovery`
- **Session Management**: Automático após verificação

## 🚀 Outros Recursos

- Chat em tempo real
- Sistema de autenticação completo
- Live streaming integrado
- Sistema de notificações
- Interface responsiva
- Suporte multiplataforma