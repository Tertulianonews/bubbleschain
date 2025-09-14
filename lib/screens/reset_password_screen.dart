import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialResetToken;

  const ResetPasswordScreen({Key? key, this.initialResetToken})
      : super(key: key);

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

    print('[DEBUG ResetPassword] initState chamado');
    print(
        '[DEBUG ResetPassword] initialResetToken: ${widget.initialResetToken}');

    // Se temos um token inicial (de deep link), usar ele diretamente
    if (widget.initialResetToken != null &&
        widget.initialResetToken!.isNotEmpty) {
      print(
          '[DEBUG ResetPassword] Token do deep link encontrado, processando...');
      _restoreSessionWithRecoveryToken(widget.initialResetToken!);
      return;
    }

    // Caso contrário, verificar URLs tradicionais
    _checkUrlTokens();
  }

  void _checkUrlTokens() {
    print('[DEBUG ResetPassword] Verificando tokens na URL...');

    // Tentar extrair token e type de diferentes fontes
    String token = widget.initialResetToken ?? '';
    String type = '';

    try {
      // Primeiro, tentar da URL atual da página
      final uri = Uri.base;
      if (token.isEmpty) {
        token = uri.queryParameters['token'] ??
            uri.queryParameters['access_token'] ??
            uri.queryParameters['code'] ?? '';
      }
      type = uri.queryParameters['type'] ?? '';

      print('[DEBUG ResetPassword] URL atual: ${uri.toString()}');
      print('[DEBUG ResetPassword] Token extraído: ${token.isNotEmpty
          ? 'PRESENTE (${token.length} chars)'
          : 'VAZIO'}');
      print('[DEBUG ResetPassword] Type extraído: $type');

      // Se não encontrou, tentar do fragment (#)
      if (token.isEmpty && uri.fragment.isNotEmpty) {
        try {
          final fragmentUri = Uri.parse('?${uri.fragment}');
          token = fragmentUri.queryParameters['token'] ??
              fragmentUri.queryParameters['access_token'] ??
              fragmentUri.queryParameters['code'] ?? '';
          type = fragmentUri.queryParameters['type'] ?? '';
          print('[DEBUG ResetPassword] Token do fragment: ${token.isNotEmpty
              ? 'PRESENTE'
              : 'VAZIO'}');
          print('[DEBUG ResetPassword] Type do fragment: $type');
        } catch (e) {
          print('[DEBUG ResetPassword] Erro ao parsear fragment: $e');
        }
      }
    } catch (e) {
      print('[DEBUG ResetPassword] Erro ao extrair parâmetros: $e');
    }

    if (token.isNotEmpty && (type == 'recovery' || type.isEmpty)) {
      print(
          '[DEBUG ResetPassword] Token válido encontrado, iniciando processo de reset');
      _restoreSessionWithRecoveryToken(token);
    } else {
      print('[DEBUG ResetPassword] Token inválido ou ausente');
      setState(() {
        _msg = token.isEmpty
            ? 'Link de redefinição inválido ou expirado (token ausente).\n\nPor favor, solicite um novo link de redefinição de senha.'
            : 'Link de redefinição inválido (tipo incorreto: $type).\n\nPor favor, solicite um novo link de redefinição de senha.';
        _canSubmitPassword = false;
      });
    }
  }

  Future<void> _restoreSessionWithRecoveryToken(String token) async {
    print(
        '[DEBUG ResetPassword] _restoreSessionWithRecoveryToken iniciado com token de ${token
            .length} caracteres');

    setState(() {
      _msg = 'Processando token de redefinição de senha...';
      _canSubmitPassword = false;
    });

    try {
      print(
          '[DEBUG ResetPassword] Verificando token de recovery com verifyOTP...');

      // Para supabase_flutter v2.3.3, usar verifyOTP com os parâmetros corretos
      final response = await Supabase.instance.client.auth.verifyOTP(
        token: token,
        type: OtpType.recovery,
        email: null, // Não precisamos do email para recovery tokens
      );

      print('[DEBUG ResetPassword] Resposta recebida. Session: ${response
          .session != null}');
      print('[DEBUG ResetPassword] User: ${response.user != null}');

      if (response.session != null && response.user != null) {
        print('[DEBUG ResetPassword] Sessão de reset ativada com sucesso!');
        setState(() {
          _msg =
          '✅ Token de reset validado!\n\nAgora você pode definir uma nova senha.';
          _canSubmitPassword = true;
        });
      } else {
        print('[DEBUG ResetPassword] Falha: resposta sem sessão ou usuário');
        setState(() {
          _msg =
          'Token de reset inválido ou expirado.\n\nPor favor, solicite um novo link de reset.';
          _canSubmitPassword = false;
        });
      }
    } catch (e) {
      print('[DEBUG ResetPassword] ERRO ao verificar token: $e');
      print('[DEBUG ResetPassword] Tipo do erro: ${e.runtimeType}');

      String userMessage;
      if (e.toString().contains('expired') ||
          e.toString().contains('invalid_token')) {
        userMessage =
        'Token de reset expirado ou inválido.\n\nPor favor, solicite um novo link de reset.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        userMessage =
        'Erro de conexão.\n\nVerifique sua internet e tente novamente.';
      } else if (e.toString().contains('token_hash_not_found')) {
        userMessage =
        'Token de reset não encontrado.\n\nPor favor, solicite um novo link de reset.';
      } else {
        userMessage = 'Erro ao processar token de reset:\n\n${e
            .toString()}\n\nTente solicitar um novo link.';
      }

      setState(() {
        _msg = userMessage;
        _canSubmitPassword = false;
      });
    }
  }

  Future<void> _submitNewPassword() async {
    final pwd = _pwdCtrl.text.trim();
    final pwd2 = _pwdConfirmCtrl.text.trim();

    print('[DEBUG ResetPassword] _submitNewPassword iniciado');

    setState(() => _msg = null);

    // Validações
    if (pwd.length < 6) {
      print('[DEBUG ResetPassword] Validação falhou: senha muito curta');
      setState(() => _msg = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (pwd != pwd2) {
      print('[DEBUG ResetPassword] Validação falhou: senhas não coincidem');
      setState(() => _msg = 'As senhas digitadas não coincidem.');
      return;
    }

    print(
        '[DEBUG ResetPassword] Validações passaram, iniciando atualização da senha');
    setState(() => _loading = true);

    try {
      print('[DEBUG ResetPassword] Chamando updateUser...');
      final resp = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pwd),
      );

      print('[DEBUG ResetPassword] Resposta recebida.');

      print('[DEBUG ResetPassword] Senha atualizada com sucesso!');
      setState(() {
        _msg =
        '✅ Senha redefinida com sucesso!\n\nVocê pode fechar esta página e fazer login com a nova senha.';
        _canSubmitPassword = false;
      });
      _pwdCtrl.clear();
      _pwdConfirmCtrl.clear();

      // Opcional: fazer logout da sessão de reset após alguns segundos
      Future.delayed(Duration(seconds: 3), () async {
        try {
          await Supabase.instance.client.auth.signOut();
          print('[DEBUG ResetPassword] Sessão de reset encerrada');
        } catch (e) {
          print('[DEBUG ResetPassword] Erro ao encerrar sessão: $e');
        }
      });
    } catch (e) {
      print('[DEBUG ResetPassword] ERRO ao atualizar senha: $e');
      print('[DEBUG ResetPassword] Tipo do erro: ${e.runtimeType}');

      String userMessage;
      if (e.toString().contains('session') || e.toString().contains('auth')) {
        userMessage =
        'Sessão expirada.\n\nPor favor, solicite um novo link de redefinição de senha.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        userMessage =
        'Erro de conexão.\n\nVerifique sua internet e tente novamente.';
      } else {
        userMessage = 'Erro ao redefinir senha:\n\n${e
            .toString()}\n\nTente novamente ou solicite um novo link.';
      }

      setState(() => _msg = userMessage);
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _msg!.startsWith('✅')
                          ? Colors.green.withOpacity(0.1)
                          : _msg!.contains('Link de redefinição validado')
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _msg!.startsWith('✅')
                            ? Colors.green
                            : _msg!.contains('Link de redefinição validado')
                            ? Colors.blue
                            : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _msg!,
                      style: TextStyle(
                        color: _msg!.startsWith('✅')
                            ? Colors.green.shade700
                            : _msg!.contains('Link de redefinição validado')
                            ? Colors.blue.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
