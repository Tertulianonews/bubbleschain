import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pwdCtrl = TextEditingController();
  final _pwdConfirmCtrl = TextEditingController();
  bool _loading = false;
  String? _msg;
  bool _canSubmitPassword = false;

  @override
  void initState() {
    super.initState();
    // Flutter Web: Extrai token e type da URL
    final uri = Uri.base;
    final token = uri.queryParameters['token'] ?? '';
    final type = uri.queryParameters['type'] ?? '';
    if (token.isNotEmpty && type == 'recovery') {
      _restoreSessionWithRecoveryToken(token);
    } else {
      setState(() {
        _msg = 'Link de redefinição inválido ou expirado (token ausente).';
        _canSubmitPassword = false;
      });
    }
  }

  Future<void> _restoreSessionWithRecoveryToken(String token) async {
    setState(() {
      _msg = 'Processando reset de senha...';
      _canSubmitPassword = false;
    });
    try {
      // Troca recovery token pela sessão de autenticação
      final response = await Supabase.instance.client.auth
          .exchangeCodeForSession(token);
      if (response.session != null) {
        setState(() {
          _msg = null;
          _canSubmitPassword = true;
        });
      } else {
        setState(() {
          _msg =
          'Não foi possível ativar sessão de redefinição. Link pode ter expirado, tente pedir novo reset.';
          _canSubmitPassword = false;
        });
      }
    } catch (e) {
      setState(() {
        _msg = 'Erro ao ativar sessão de redefinição: ${e.toString()}';
        _canSubmitPassword = false;
      });
    }
  }

  Future<void> _submitNewPassword() async {
    final pwd = _pwdCtrl.text.trim();
    final pwd2 = _pwdConfirmCtrl.text.trim();
    setState(() => _msg = null);
    if (pwd.length < 6) {
      setState(() => _msg = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (pwd != pwd2) {
      setState(() => _msg = 'As senhas digitadas não coincidem.');
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pwd),
      );
      if (resp.user != null) {
        setState(() {
          _msg = 'Senha redefinida com sucesso! Faça login com a nova senha.';
          _canSubmitPassword = false;
        });
        _pwdCtrl.clear();
        _pwdConfirmCtrl.clear();
      } else {
        setState(() => _msg = 'Erro ao redefinir senha: ${resp.toString()}');
      }
    } catch (e) {
      setState(() => _msg = 'Erro ao redefinir senha: ${e.toString()}');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SizedBox(
            width: 370,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Crie uma nova senha para sua conta.',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w600)),
                const SizedBox(height: 28),
                TextField(
                  controller: _pwdCtrl,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  obscureText: true,
                  enabled: _canSubmitPassword,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pwdConfirmCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Confirme a nova senha'),
                  obscureText: true,
                  enabled: _canSubmitPassword,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _canSubmitPassword && !_loading
                      ? _submitNewPassword
                      : null,
                  child: _loading
                      ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator())
                      : const Text('Atualizar senha'),
                ),
                if (_msg != null) Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(_msg!, style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
