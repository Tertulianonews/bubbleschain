import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RequestOtpResetScreen extends StatefulWidget {
  const RequestOtpResetScreen({Key? key}) : super(key: key);

  @override
  State<RequestOtpResetScreen> createState() => _RequestOtpResetScreenState();
}

class _RequestOtpResetScreenState extends State<RequestOtpResetScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwdConfirmCtrl = TextEditingController();
  bool _loading = false;
  String? _msg;
  bool _step2 = false; // false = pedir e-mail | true = pedir código+senha

  // Simule que envia um e-mail com OTP
  Future<void> _requestOtp() async {
    setState(() {
      _msg = null;
      _loading = true;
    });
    // Aqui você faria uma chamada ao seu backend para disparar OTP
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _step2 = true;
      _msg = 'Código enviado por e-mail (simulado).';
      _loading = false;
    });
  }

  // Envia código (OTP) + nova senha para o backend custom
  Future<void> _submitNewPassword() async {
    final pwd = _pwdCtrl.text.trim();
    final pwd2 = _pwdConfirmCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    setState(() => _msg = null);
    if (pwd.length < 6) {
      setState(() => _msg = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (pwd != pwd2) {
      setState(() => _msg = 'As senhas digitadas não coincidem.');
      return;
    }
    if (otp.isEmpty) {
      setState(() => _msg = 'Informe o código recebido por e-mail (OTP).');
      return;
    }
    setState(() => _loading = true);
    try {
      // Troque pelo endpoint real após publicar seu backend!
      final url = 'https://SUA_URL_CUSTOM_BACKEND/api/custom-reset';
      final resp = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: '{"email":"$email","otp":"$otp","newPassword":"$pwd"}',
      );
      if (resp.statusCode == 200) {
        setState(() =>
        _msg = 'Senha redefinida com sucesso. Faça login com a nova senha!');
      } else {
        setState(() => _msg = 'Erro ao redefinir senha: ${resp.body}');
      }
    } catch (e) {
      setState(() => _msg = 'Erro ao redefinir senha: ${e.toString()}');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha por código')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!_step2) ...[
                  Text(
                      'Informe seu e-mail cadastrado para receber um código de verificação.',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _loading ? null : _requestOtp,
                    child: _loading
                        ? const SizedBox(width: 18,
                        height: 18,
                        child: CircularProgressIndicator())
                        : const Text('Enviar código'),
                  ),
                ] else
                  ...[
                    Text(
                        'Informe o código (OTP) enviado ao seu e-mail e cadastre uma nova senha.',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _otpCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Código (OTP)'),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _pwdCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nova senha'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _pwdConfirmCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Confirme a nova senha'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitNewPassword,
                      child: _loading
                          ? const SizedBox(width: 18,
                          height: 18,
                          child: CircularProgressIndicator())
                          : const Text('Alterar senha'),
                    ),
                  ],
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
