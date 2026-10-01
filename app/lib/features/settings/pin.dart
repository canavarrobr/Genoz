// PIN do bloqueio do app: guardado só como hash PBKDF2-HMAC-SHA256 com sal
// aleatório. Tentativas erradas geram espera crescente.
//
// O bloqueio impede que outra pessoa abra o app; não é criptografia dos
// arquivos (isso é o Módulo 11).

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const pinMinLength = 4;
const pinMaxLength = 8;

/// Iterações do PBKDF2: rápido o bastante no navegador (dart2js), lento o
/// bastante para não ser trivial testar todos os PINs a partir do arquivo.
const pinIterations = 20000;

/// Tentativas erradas permitidas antes de começar a espera.
const freeAttempts = 5;

bool isValidPin(String pin) =>
    pin.length >= pinMinLength && pin.length <= pinMaxLength && RegExp(r'^\d+$').hasMatch(pin);

class PinHash {
  const PinHash({required this.hash, required this.salt, required this.iterations});

  final String hash; // base64
  final String salt; // base64
  final int iterations;

  /// Novo hash com sal aleatório (um sal diferente a cada vez que o PIN é definido).
  factory PinHash.create(String pin, {int iterations = pinIterations, Random? random}) {
    final rnd = random ?? Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
    return PinHash(
      hash: base64.encode(pbkdf2(pin, salt, iterations)),
      salt: base64.encode(salt),
      iterations: iterations,
    );
  }

  bool matches(String pin) {
    final computed = pbkdf2(pin, base64.decode(salt), iterations);
    final expected = base64.decode(hash);
    // Comparação em tempo constante.
    if (computed.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < computed.length; i++) {
      diff |= computed[i] ^ expected[i];
    }
    return diff == 0;
  }

  Map<String, Object?> toJson() => {'hash': hash, 'salt': salt, 'iterations': iterations};

  static PinHash? fromJson(Object? json) {
    if (json is! Map) return null;
    final hash = json['hash'], salt = json['salt'], iterations = json['iterations'];
    if (hash is! String || salt is! String || iterations is! int) return null;
    return PinHash(hash: hash, salt: salt, iterations: iterations);
  }
}

/// PBKDF2-HMAC-SHA256 (RFC 8018) com um bloco de saída (32 bytes).
Uint8List pbkdf2(String password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, utf8.encode(password));
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}

/// Espera exigida depois de [failedAttempts] tentativas erradas seguidas:
/// nenhuma até [freeAttempts]; depois 30 s, 1 min, 2 min... até 15 min.
Duration lockoutFor(int failedAttempts) {
  if (failedAttempts < freeAttempts) return Duration.zero;
  final step = failedAttempts - freeAttempts;
  final seconds = 30 * pow(2, min(step, 5)).toInt();
  return Duration(seconds: min(seconds, 15 * 60));
}
