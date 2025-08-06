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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vuihslbjlohumjtgejzd.supabase.co',
    anonKey: 'sb_publishable_4UmDtWDPUSZ8YtgFYaH97w_XXKyMG40',
  );
  runApp(const PepeChatApp());
}

class AuthRedirector extends StatelessWidget {
  const AuthRedirector({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && session.user != null) {
      return const BubblesHomeScreen();
    } else {
      return const LoginScreen();
    }
  }
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

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _appLinks = AppLinks();
      _linkSub = _appLinks!.uriLinkStream.listen((Uri? uri) {
        if (uri != null && uri.path.contains('reset-password')) {
          final accessToken =
              uri.queryParameters['access_token'] ??
              uri.queryParameters['code'];
          if (accessToken != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ResetPasswordScreen(),
              ),
            );
          }
        }
      }, onError: (_) {});
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
    if (settings.name != null && settings.name!.startsWith('/reset-password')) {
      final uri = Uri.parse(settings.name!);
      // Suporte tanto para code= quanto access_token=
      final token =
          uri.queryParameters['code'] ??
          uri.queryParameters['access_token'] ??
          '';
      // Sempre abrir a tela, mesmo que token esteja vazio (para debugging)
      return MaterialPageRoute(
        builder: (_) => const ResetPasswordScreen(),
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
      routes: {
        '/': (_) => const AuthRedirector(),
        '/bubbles': (_) => const BubblesHomeScreen(),
      },
      onGenerateRoute: (kIsWeb ? _handleWebRoute : null),
    );
  }
}
