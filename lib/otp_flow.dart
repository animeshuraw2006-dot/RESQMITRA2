import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'theme.dart';

/// One-tap phone verification (Renflair SMS OTP via the backend).
///
/// Call this from a single "Verify" button. It opens the dialog immediately, sends the SMS,
/// and verifies automatically as soon as the 6th digit is typed / pasted / auto-filled.
/// Returns true only when the server answered `verified: true`.
Future<bool> verifyPhoneWithOtp(BuildContext context, String rawPhone) async {
  final phone = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (phone.length != 10) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit Indian mobile number')));
    return false;
  }
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _OtpDialog(phone: phone),
  );
  return ok == true;
}

class _OtpDialog extends StatefulWidget {
  final String phone;
  const _OtpDialog({required this.phone});
  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  bool _sending = true; // SMS request in flight
  bool _verifying = false; // verify request in flight
  bool _sentOnce = false; // a code exists on the server for this phone
  int _cooldown = 0;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _send(); // one click: sending starts as soon as the dialog opens
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown(int s) {
    _timer?.cancel();
    setState(() => _cooldown = s);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
      if (_cooldown == 0) t.cancel();
    });
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
      _info = null;
      _code.clear();
    });
    final r = await Api.I.sendPhoneOtp(widget.phone);
    if (!mounted) return;
    if (r.ok) {
      _sentOnce = true;
      setState(() {
        _sending = false;
        _info = 'Code sent by SMS. It is valid for 5 minutes.';
      });
      _startCooldown(60);
      _focus.requestFocus();
    } else if (r.status == 429 && r.data['retry_after'] is num) {
      // A code was sent a moment ago and is still valid – let the user type it.
      _sentOnce = true;
      setState(() {
        _sending = false;
        _info = 'A code was already sent. Enter it below, or resend when the timer ends.';
      });
      _startCooldown((r.data['retry_after'] as num).toInt());
      _focus.requestFocus();
    } else {
      setState(() {
        _sending = false;
        _error = r.data['error']?.toString() ??
            (r.status == 0
                ? 'Could not reach the server. Check your internet connection and API_BASE.'
                : 'Could not send the OTP. Please try again.');
      });
    }
  }

  Future<void> _verify() async {
    if (_verifying || _sending) return;
    final otp = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _error = 'Enter the complete 6-digit code.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final r = await Api.I.verifyPhoneOtp(widget.phone, otp);
    if (!mounted) return;
    if (r.ok && r.data['verified'] == true) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, true);
      return;
    }
    final msg = r.data['error']?.toString() ??
        (r.status == 0
            ? 'Could not reach the server. Check your internet connection.'
            : 'Verification failed. Check the code and try again.');
    // After "expired / too many attempts" the old code is gone: a resend is needed.
    final dead = r.status == 429 || msg.toLowerCase().contains('expired') || msg.toLowerCase().contains('request a new');
    setState(() {
      _verifying = false;
      _error = msg;
      if (dead) _sentOnce = false;
    });
    if (!dead) {
      _code.clear();
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _sending || _verifying;
    return PopScope(
      canPop: !_verifying,
      child: AlertDialog(
        title: Text('Verify +91 ${widget.phone}'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_sending)
            const Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Expanded(child: Text('Sending verification code…')),
            ])
          else ...[
            if (_info != null && _error == null)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_info!, style: const TextStyle(fontSize: 13))),
            if (_sentOnce)
              TextField(
                controller: _code,
                focusNode: _focus,
                enabled: !_verifying,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(counterText: '', hintText: '••••••'),
                onChanged: (v) {
                  if (_error != null) setState(() => _error = null);
                  if (v.length == 6) _verify(); // auto-verify on the 6th digit
                },
                onSubmitted: (_) => _verify(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
              ),
            if (_verifying)
              const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: _verifying ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (!_sending)
            TextButton(
              onPressed: (busy || _cooldown > 0) ? null : _send,
              child: Text(_cooldown > 0 ? 'Resend in ${_cooldown}s' : (_sentOnce ? 'Resend OTP' : 'Try again')),
            ),
          if (!_sending && _sentOnce)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.royal),
              onPressed: busy ? null : _verify,
              child: const Text('Verify'),
            ),
        ],
      ),
    );
  }
}
