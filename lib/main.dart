import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/bubbles_home_screen.dart';
import 'screens/chat_screen.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'screens/reset_password_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/account_verified_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vuihslbjlohumjtgejzd.supabase.co',
    anonKey: 'sb_publishable_4UmDtWDPUSZ8YtgFYaH97w_XXKyMG40',
  );
  runApp(const PepeChatApp());
}

class PepeChatApp extends StatelessWidget {
  const PepeChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _PepeChatAppRoot();
  }
}

class _PepeChatAppRoot extends StatefulWidget {
  @override
  State<_PepeChatAppRoot> createState() => _PepeChatAppRootState();
}

class _PepeChatAppRootState extends State<_PepeChatAppRoot> {
  StreamSubscription? _linkSub;
  AppLinks? _appLinks;

  // Process reset password deep link and route to reset screen, passing token if possible
  void _processResetPasswordUri(Uri uri) {
    print('[DEBUG DeepLink] Processando URI: ${uri.toString()}');

    if (mounted) {
      final token = uri.queryParameters['token'] ??
          uri.queryParameters['access_token'] ??
          uri.queryParameters['code'];
      final type = uri.queryParameters['type'];

      print(
          '[DEBUG DeepLink] Token extraído: ${token != null ? 'PRESENTE (${token
              .length} chars)' : 'AUSENTE'}');
      print('[DEBUG DeepLink] Type extraído: $type');

      if (token != null && token.isNotEmpty) {
        print('[DEBUG DeepLink] Navegando para ResetPasswordScreen com token');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ResetPasswordScreen(
                  initialResetToken: token,
                ),
          ),
        );
      } else {
        print('[DEBUG DeepLink] Token ausente ou vazio');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
            const ResetPasswordScreen(
              initialResetToken: null,
            ),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _appLinks = AppLinks();
      _linkSub = _appLinks!.uriLinkStream.listen((Uri? uri) {
        if (uri != null && uri.path.contains('reset-password')) {
          _processResetPasswordUri(uri);
        }
      }, onError: (_) {});
      // TODO: Handle cold start deep link - check app_links documentation for correct method
      // For now, only handling links while app is running
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _appLinks = null;
    super.dispose();
  }

  Route<dynamic>? _handleWebRoute(RouteSettings settings) {
    // Priorizar /reset-password acima de tudo
    if (settings.name != null &&
        (settings.name!.contains('reset-password') ||
            settings.name!.contains('auth_confirm=success'))) {
      print('[DEBUG] Reset password route detected: ${settings.name}');

      // Tentar extrair parâmetros da URL
      try {
        final uri = Uri.parse(settings.name!);
        final token = uri.queryParameters['token'] ??
            uri.queryParameters['access_token'] ??
            uri.queryParameters['code'] ?? '';
        final type = uri.queryParameters['type'] ?? '';
        final authConfirm = uri.queryParameters['auth_confirm'] ?? '';

        print('[DEBUG] Extracted from URL - Token: ${token.isNotEmpty
            ? 'PRESENT'
            : 'EMPTY'}, Type: $type, AuthConfirm: $authConfirm');

        // Se não encontrou parâmetros na URL da rota, tentar pegar da URL atual da página
        if (token.isEmpty && authConfirm.isEmpty) {
          final currentUri = Uri.base;
          final currentToken = currentUri.queryParameters['token'] ??
              currentUri.queryParameters['access_token'] ??
              currentUri.queryParameters['code'] ?? '';
          final currentType = currentUri.queryParameters['type'] ?? '';
          final currentAuthConfirm = currentUri
              .queryParameters['auth_confirm'] ?? '';
          print('[DEBUG] Extracted from current URL - Token: ${currentToken
              .isNotEmpty
              ? 'PRESENT'
              : 'EMPTY'}, Type: $currentType, AuthConfirm: $currentAuthConfirm');
        }
      } catch (e) {
        print('[DEBUG] Error parsing reset URL: $e');
      }

      // Sempre abrir a tela de reset, ela vai lidar com a validação dos tokens internamente
      // Extraia parâmetros do URI para poder repassar à tela
      String? resetToken;
      try {
        final uri = Uri.parse(settings.name!);
        resetToken = uri.queryParameters['token'] ??
            uri.queryParameters['access_token'] ??
            uri.queryParameters['code'];
        // Se não encontrou, tentar pegar da URL base da página
        if (resetToken == null || resetToken.isEmpty) {
          final currentUri = Uri.base;
          resetToken = currentUri.queryParameters['token'] ??
              currentUri.queryParameters['access_token'] ??
              currentUri.queryParameters['code'];
        }
      } catch (_) {}
      return MaterialPageRoute(
        builder: (_) =>
            ResetPasswordScreen(
              initialResetToken: resetToken,
            ),
        settings: settings,
      );
    }
    // Depois cair para as rotas normais
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bubbles',
      theme: quantumTheme,
      // Configurações para melhor comportamento com redimensionamento
      builder: (context, child) {
        return MediaQuery(
          // Previne que fontes sejam escalonadas automaticamente pelo sistema
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      routes: {
        '/': (_) => const BubblesHomeScreen(),
        '/bubbles': (_) => const BubblesHomeScreen(),
        '/splash': (_) => const SplashScreen(),
        // For direct navigation, allow passing token (web and app)
        '/reset-password': (context) {
          final uri = Uri.base;
          final token =
              uri.queryParameters['token'] ??
                  uri.queryParameters['access_token'] ??
                  uri.queryParameters['code'];
          return ResetPasswordScreen(
            initialResetToken: token,
          );
        },
      },
      onGenerateRoute: (kIsWeb ? _handleWebRoute : null),
    );
  }
}
