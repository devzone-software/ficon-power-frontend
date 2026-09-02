import 'dart:convert';

import 'package:http/http.dart' as http;

class ExceptionHandler {
  const ExceptionHandler._();

  static String fromResponse(http.Response response, String path) {
    final body = utf8.decode(response.bodyBytes);
    final decoded = _decodeJson(body);
    if (decoded is Map<String, dynamic>) {
      final validation = _validationMessage(decoded);
      if (validation != null) return validation;

      final direct = _firstText(decoded, const [
        'error',
        'message',
        'detail',
        'title',
      ]);
      if (direct != null) return _friendly(direct, path, response.statusCode);
    }

    final bodyMessage = _friendly(body, path, response.statusCode);
    if (bodyMessage.isNotEmpty) return bodyMessage;
    return _statusFallback(response.statusCode, path);
  }

  static String fromException(Object error) {
    final message = error.toString();
    return _friendly(message, '', null);
  }

  static Object? _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String? _validationMessage(Map<String, dynamic> decoded) {
    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      final messages = errors
          .map(_validationEntryMessage)
          .whereType<String>()
          .where((message) => message.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }

    final detail = decoded['detail'];
    if (detail is String) {
      final friendly = _validationText(detail);
      if (friendly != null) return friendly;
    }
    return null;
  }

  static String? _validationEntryMessage(Object? entry) {
    if (entry is Map<String, dynamic>) {
      final field = entry['field']?.toString() ?? '';
      final message =
          _firstText(entry, const ['defaultMessage', 'message', 'reason']) ??
          '';
      return _fieldMessage(field, message);
    }
    if (entry is String) return _validationText(entry) ?? entry;
    return null;
  }

  static String? _validationText(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('field error') &&
        normalized.contains('password') &&
        normalized.contains('size must be between 8 and 120')) {
      return 'La contraseña debe tener entre 8 y 120 caracteres.';
    }
    if (normalized.contains('password') &&
        normalized.contains('size must be between 8 and 120')) {
      return 'La contraseña debe tener entre 8 y 120 caracteres.';
    }
    return null;
  }

  static String _fieldMessage(String field, String message) {
    final normalizedField = field.toLowerCase();
    final normalizedMessage = message.toLowerCase();
    if (normalizedField == 'password' &&
        normalizedMessage.contains('size must be between 8 and 120')) {
      return 'La contraseña debe tener entre 8 y 120 caracteres.';
    }
    if (normalizedField == 'username' && normalizedMessage.contains('blank')) {
      return 'El usuario es obligatorio.';
    }
    if (normalizedField == 'displayname' &&
        normalizedMessage.contains('blank')) {
      return 'El nombre visible es obligatorio.';
    }
    if (normalizedField == 'role' && normalizedMessage.contains('blank')) {
      return 'El rol es obligatorio.';
    }
    if (message.isNotEmpty && field.isNotEmpty) return '$field: $message';
    return message;
  }

  static String? _firstText(Map<String, dynamic> decoded, List<String> keys) {
    for (final key in keys) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String _friendly(String message, String path, int? statusCode) {
    final clean = message.trim();
    if (clean.isEmpty) return '';
    final validation = _validationText(clean);
    if (validation != null) return validation;

    if (clean.startsWith('ApiException(')) {
      final index = clean.indexOf(': ');
      if (index != -1 && index + 2 < clean.length) {
        return clean.substring(index + 2).trim();
      }
    }
    if (statusCode != null && statusCode >= 500) {
      return 'El servidor no pudo completar la operación. Inténtalo nuevamente.';
    }
    if (clean.startsWith('El backend respondió')) {
      return _statusFallback(statusCode ?? 0, path);
    }
    return clean;
  }

  static String _statusFallback(int statusCode, String path) =>
      switch (statusCode) {
        400 => 'Hay datos inválidos en el formulario.',
        401 => 'La sesión no es válida. Vuelve a iniciar sesión.',
        403 => 'No tienes permisos para realizar esta acción.',
        404 => 'No se encontró el recurso solicitado.',
        409 => 'No se pudo guardar porque ya existe un registro relacionado.',
        429 => 'Demasiados intentos. Espera unos minutos e inténtalo otra vez.',
        >= 500 =>
          'El servidor no pudo completar la operación. Inténtalo nuevamente.',
        _ => 'El backend respondió con un error en $path',
      };
}
