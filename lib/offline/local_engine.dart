import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

typedef Row = Map<String, dynamic>;

class LocalFailure implements Exception {
  LocalFailure(this.status, this.message);
  final int status;
  final String message;
}

/// Single local authority shared by the UI and the in-process API adapter.
/// No network fallback: unimplemented operations fail explicitly.
class LocalEngine {
  LocalEngine._(this.file, this.state);
  final File file;
  Row state;
  final changes = StreamController<Row>.broadcast();
  Future<void> _pending = Future.value();

  static Future<LocalEngine> open(String directory) async {
    final file = File('$directory/ficon-local-v1.json');
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      final temp = File('${file.path}.new');
      final backup = File('${file.path}.bak');
      if (await temp.exists()) {
        // Recover a completed flush interrupted before replacing the old file.
        final recovered = jsonDecode(await temp.readAsString());
        if (recovered is! Map || recovered['schema'] != 1) {
          throw StateError('Archivo de recuperación local inválido');
        }
        await temp.rename(file.path);
      } else if (await backup.exists()) {
        await backup.copy(file.path);
      }
    }
    // A failed write must never cause an automatic destructive reset.
    final Row data;
    if (await file.exists()) {
      data = (jsonDecode(await file.readAsString()) as Map)
          .cast<String, dynamic>();
      if (data['schema'] != 1) throw StateError('Formato local no compatible');
    } else {
      data = _seed();
    }
    final engine = LocalEngine._(file, data);
    if (!await file.exists()) await engine._save();
    return engine;
  }

  List<Row> rows(String table) => (state[table] as List).cast<Row>();
  String get now => DateTime.now().toIso8601String();
  String id() => '${DateTime.now().microsecondsSinceEpoch}-${_randomToken(8)}';

  static String _randomToken(int length) {
    final random = Random.secure();
    return base64UrlEncode(List.generate(length, (_) => random.nextInt(256)));
  }

  static String _hash(String password, String salt) {
    List<int> value = utf8.encode('$salt:$password');
    for (var i = 0; i < 10000; i++) {
      value = sha256.convert(value).bytes;
    }
    return base64Encode(value);
  }

  static void _password(Row user, String password) {
    final salt = _randomToken(24);
    user['salt'] = salt;
    user['passwordHash'] = _hash(password, salt);
  }

  Future<void> _save() async {
    final temp = File('${file.path}.new');
    await temp.writeAsString(jsonEncode(state), flush: true);
    // Backup is retained for manual recovery; never silently discard damaged data.
    if (await file.exists()) await file.copy('${file.path}.bak');
    if (Platform.isWindows && await file.exists()) await file.delete();
    await temp.rename(file.path);
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<dynamic> request(String method, Uri uri, Row body, String token) =>
      _serialized(() async {
        final before = jsonEncode(state);
        try {
          final result = _route(method, uri, body, token);
          if (jsonEncode(state) != before) {
            await _save();
            for (final entity in [
              'device',
              'incident',
              'event',
              'user',
              'notification',
              'site',
              'whatsapp_recipient',
              'tuya_plan',
            ]) {
              changes.add({
                'id': id(),
                'eventType': '$entity.updated',
                'entityType': entity,
                'payload': <String, dynamic>{},
                'createdAt': now,
              });
            }
          }
          return result;
        } catch (error) {
          state = (jsonDecode(before) as Map).cast<String, dynamic>();
          if (uri.path == '/api/auth/login' &&
              error is LocalFailure &&
              error.status == 401) {
            rows('logins').insert(0, {
              'id': id(),
              'username': body['username'],
              'success': false,
              'reason': 'invalid_credentials',
              'createdAt': now,
              'ipAddress': 'local',
            });
            await _save();
          }
          rethrow;
        }
      });

  Row authenticate(String token) {
    final sessions = rows('sessions').where(
      (s) =>
          s['id'] == token &&
          s['revokedAt'] == null &&
          DateTime.parse(s['expiresAt']).isAfter(DateTime.now()),
    );
    if (sessions.isEmpty) throw LocalFailure(401, 'Inicia sesión nuevamente.');
    final user = rows(
      'users',
    ).where((u) => u['id'] == sessions.first['userId'] && u['active'] == true);
    if (user.isEmpty) throw LocalFailure(401, 'Usuario inactivo.');
    return user.first;
  }

  void _admin(Row actor, {bool superadmin = false}) {
    if (actor['role'] != 'SUPERADMIN' &&
        (superadmin || actor['role'] != 'ADMIN')) {
      throw LocalFailure(403, 'No tienes permiso para esta operación.');
    }
  }

  Row _find(String table, String key) => rows(table).firstWhere(
    (r) => '${r['id']}' == key,
    orElse: () => throw LocalFailure(404, 'Registro no encontrado.'),
  );

  Row _publicUser(Row user) => {...user}
    ..remove('salt')
    ..remove('passwordHash');

  void _audit(Row actor, String action, String entity, String entityId) {
    rows('audit').insert(0, {
      'id': id(),
      'actorUsername': actor['username'],
      'actorRole': actor['role'],
      'action': action,
      'entityType': entity,
      'entityId': entityId,
      'createdAt': now,
      'ipAddress': 'local',
    });
  }

  dynamic _route(String method, Uri uri, Row body, String token) {
    final path = uri.path;
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    final get = method == 'GET';
    if (path == '/api/auth/login' && method == 'POST') {
      final matches = rows(
        'users',
      ).where((u) => u['username'] == body['username'] && u['active'] == true);
      final valid =
          matches.isNotEmpty &&
          _hash('${body['password']}', matches.first['salt']) ==
              matches.first['passwordHash'];
      if (!valid) throw LocalFailure(401, 'Usuario o contraseña incorrectos.');
      final user = matches.first;
      final session = {
        'id': _randomToken(32),
        'userId': user['id'],
        'username': user['username'],
        'role': user['role'],
        'createdAt': now,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 12))
            .toIso8601String(),
        'ipAddress': 'local',
      };
      rows('sessions').insert(0, session);
      rows('logins').insert(0, {
        'id': id(),
        'username': user['username'],
        'success': true,
        'createdAt': now,
        'ipAddress': 'local',
      });
      return {
        'token': session['id'],
        'refreshToken': '',
        'expiresAt': session['expiresAt'],
        'user': _publicUser(user),
      };
    }
    final actor = authenticate(token);
    if (path == '/api/auth/logout' && method == 'POST') {
      _find('sessions', token)['revokedAt'] = now;
      return <String, dynamic>{};
    }
    if (path.startsWith('/api/local/')) {
      _admin(actor);
      return _local(method, parts, body, actor);
    }
    if (path == '/api/devices' && get) {
      return rows(
        'devices',
      ).where((d) => d['active'] == true).map(_device).toList();
    }
    if (parts.length >= 3 && parts[1] == 'devices') {
      final device = _find('devices', parts[2]);
      if (parts.length == 4 && parts[3] == 'detail' && get) {
        return _detail(device);
      }
      if (parts.length == 3 && method == 'PUT') {
        _admin(actor);
        final name = '${body['name'] ?? ''}'.trim();
        if (name.isEmpty) throw LocalFailure(400, 'El nombre es obligatorio.');
        final site = _find('sites', '${body['siteId']}');
        device.addAll({'name': name, 'siteId': site['id']});
        _audit(actor, 'UPDATE_DEVICE', 'device', parts[2]);
        return _device(device);
      }
    }
    if (path == '/api/sites') {
      if (get) {
        return rows('sites')
            .map(
              (s) => {
                ...s,
                'deviceCount': rows(
                  'devices',
                ).where((d) => d['active'] && d['siteId'] == s['id']).length,
              },
            )
            .toList();
      }
      _admin(actor);
      if (method == 'POST') {
        final name = '${body['name'] ?? ''}'.trim();
        if (name.isEmpty) {
          throw LocalFailure(400, 'El distrito es obligatorio.');
        }
        final site = {
          'id': id(),
          'name': name,
          'district': body['district'] ?? name,
          'province': body['province'] ?? name,
          'department': 'Puno',
          'active': true,
          'timeZone': 'America/Lima',
        };
        rows('sites').add(site);
        return site;
      }
    }
    if ((path == '/api/incidents' || path == '/api/events') && get) {
      final table = path.endsWith('incidents') ? 'incidents' : 'events';
      return _query(rows(table).map(_decorate).toList(), uri.queryParameters);
    }
    if (parts.length == 4 &&
        parts[1] == 'incidents' &&
        parts[3] == 'acknowledge' &&
        method == 'PATCH') {
      final incident = _find('incidents', parts[2]);
      if (incident['status'] == 'resolved') {
        throw LocalFailure(409, 'El incidente ya está resuelto.');
      }
      incident['status'] = 'acknowledged';
      _audit(actor, 'ACKNOWLEDGE', 'incident', parts[2]);
      return <String, dynamic>{};
    }
    if (path == '/api/users' || (parts.length >= 3 && parts[1] == 'users')) {
      _admin(actor, superadmin: true);
      if (get && parts.length == 2) {
        return rows('users').map(_publicUser).toList();
      }
      if (parts.length == 4 && parts[3] == 'whatsapp-deliveries' && get) {
        return rows(
          'deliveries',
        ).where((d) => d['userId'] == parts[2]).toList();
      }
      if (parts.length == 4 &&
          parts[3] == 'whatsapp-test' &&
          method == 'POST') {
        final user = _find('users', parts[2]);
        if (user['whatsappEnabled'] != true || user['whatsappPhone'] == null) {
          throw LocalFailure(400, 'Habilita WhatsApp y registra un número.');
        }
        return _testDelivery(user['id']);
      }
      if (method == 'POST' && parts.length == 2 ||
          method == 'PUT' && parts.length == 3) {
        final creating = method == 'POST';
        final user = creating
            ? <String, dynamic>{
                'id': id(),
                'active': true,
                'username': '${body['username'] ?? ''}'.trim(),
              }
            : _find('users', parts[2]);
        if (creating &&
            (user['username'] == '' ||
                rows('users').any((u) => u['username'] == user['username']))) {
          throw LocalFailure(409, 'El usuario ya existe o está vacío.');
        }
        if (!['SUPERADMIN', 'ADMIN', 'USER'].contains(body['role'])) {
          throw LocalFailure(400, 'Rol inválido.');
        }
        final otherSuper = rows('users').any(
          (u) =>
              u['id'] != user['id'] &&
              u['role'] == 'SUPERADMIN' &&
              u['active'] == true,
        );
        if (!creating &&
            user['role'] == 'SUPERADMIN' &&
            !otherSuper &&
            (body['role'] != 'SUPERADMIN' || body['active'] == false)) {
          throw LocalFailure(
            409,
            'Debe permanecer un superadministrador activo.',
          );
        }
        user.addAll(
          {...body}
            ..remove('password')
            ..remove('username'),
        );
        user['whatsappPhone'] = _phone(body['whatsappPhone']);
        if (user['whatsappEnabled'] == true && user['whatsappPhone'] == null) {
          throw LocalFailure(400, 'Registra un número válido.');
        }
        if (creating || body.containsKey('password')) {
          final password = '${body['password'] ?? ''}';
          if (password.length < 8) {
            throw LocalFailure(
              400,
              'Usa una contraseña de al menos 8 caracteres.',
            );
          }
          _password(user, password);
        }
        if (creating) rows('users').add(user);
        // Recipient views are projections, never divergent copies of user settings.
        _audit(
          actor,
          creating ? 'CREATE_USER' : 'UPDATE_USER',
          'user',
          user['id'],
        );
        return _publicUser(user);
      }
    }
    if (parts.length >= 2 && parts[1] == 'whatsapp-recipients') {
      _admin(actor);
      if (get) {
        return [
          ...rows('users')
              .where((u) => u['whatsappPhone'] != null)
              .map(
                (u) => {
                  'id': 'user:${u['id']}',
                  'userId': u['id'],
                  'label': u['displayName'],
                  'phone': u['whatsappPhone'],
                  'active': u['active'] == true && u['whatsappEnabled'] == true,
                  'notifyOutage': true,
                  'notifyRestored': true,
                },
              ),
          ...rows('recipients'),
        ];
      }
      if (parts.length == 4 && parts[3] == 'test' && method == 'POST') {
        return _testDelivery(parts[2].replaceFirst('user:', ''));
      }
      if (parts.length == 3 && parts[2].startsWith('user:')) {
        throw LocalFailure(
          409,
          'Edita este destinatario desde su ficha de usuario.',
        );
      }
      if (method == 'DELETE' && parts.length == 3) {
        rows('recipients').remove(_find('recipients', parts[2]));
        return <String, dynamic>{};
      }
      if (method == 'POST' && parts.length == 2 ||
          method == 'PUT' && parts.length == 3) {
        final row = method == 'POST'
            ? <String, dynamic>{'id': id()}
            : _find('recipients', parts[2]);
        final phone = _phone(body['phone']);
        if (phone == null) {
          throw LocalFailure(400, 'Número de WhatsApp inválido.');
        }
        row.addAll({...body, 'phone': phone});
        if (body['siteId'] != null) {
          row['siteName'] = _find('sites', body['siteId'])['name'];
        }
        if (method == 'POST') rows('recipients').add(row);
        return row;
      }
    }
    if (path.startsWith('/api/admin/')) {
      _admin(actor, superadmin: true);
      if (get) {
        final table = {
          'audit-logs': 'audit',
          'sessions': 'sessions',
          'login-attempts': 'logins',
          'blocked-users': 'blocked',
        }[parts[2]];
        if (table != null) {
          return rows(table)
              .take(int.tryParse(uri.queryParameters['limit'] ?? '') ?? 100)
              .toList();
        }
      }
      if (parts.length == 5 && parts[2] == 'sessions' && parts[4] == 'revoke') {
        _find('sessions', parts[3])['revokedAt'] = now;
        return <String, dynamic>{};
      }
    }
    if (path == '/api/notification-templates' && get) {
      return [
        for (final type in ['power_outage', 'power_restored'])
          {
            'eventType': type,
            'metaTemplateName': 'local_$type',
            'metaTemplateLanguage': 'es',
          },
      ];
    }
    if (path.startsWith('/api/mobile/notifications')) {
      final notifications = rows(
        'notifications',
      ).where((n) => n['userId'] == actor['id']).toList();
      if (path.endsWith('/unread-count') && get) {
        return {
          'unreadCount': notifications.where((n) => n['unread'] == true).length,
        };
      }
      if (get) {
        return notifications
            .take(int.tryParse(uri.queryParameters['limit'] ?? '') ?? 100)
            .toList();
      }
      if (method == 'PATCH') {
        for (final n in notifications.where(
          (n) =>
              path.endsWith('/read-all') ||
              parts.length > 3 && n['id'] == parts[3],
        )) {
          n.addAll({'unread': false, 'readAt': now});
        }
        return <String, dynamic>{};
      }
    }
    if (path == '/api/calendar/tuya-plans' && get) return rows('plans');
    if (path == '/api/calendar' && get) {
      return [
        ...rows('incidents').map(
          (i) => {
            ..._decorate(i),
            'id': 'incident:${i['id']}',
            'type': 'INCIDENT',
            'title': 'Corte · ${_decorate(i)['deviceName']}',
            'date': i['startTime'],
            'startAt': i['startTime'],
            'endAt': i['endTime'],
          },
        ),
        ...rows('plans').map(
          (p) => {
            'id': 'plan:${p['id']}',
            'type': 'TUYA_RENEWAL',
            'title': 'Renovación Tuya Developer',
            'date': p['nextRenewalOn'],
            'tuyaPlanId': p['id'],
          },
        ),
      ];
    }
    throw LocalFailure(404, 'Operación local no disponible: $method $path');
  }

  String? _phone(dynamic input) {
    var digits = '${input ?? ''}'.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0051')) digits = digits.substring(2);
    if (digits.length == 9) digits = '51$digits';
    return RegExp(r'^519\d{8}$').hasMatch(digits) ? '+$digits' : null;
  }

  dynamic _query(List<Row> data, Map<String, String> q) {
    var filtered =
        data.where((r) {
          for (final field in [
            'status',
            'eventType',
            'deviceName',
            'siteName',
          ]) {
            if (q[field]?.isNotEmpty == true && r[field] != q[field]) {
              return false;
            }
          }
          if (q['incidentId']?.isNotEmpty == true &&
              r['id'] != q['incidentId']) {
            return false;
          }
          if (q['search']?.isNotEmpty == true &&
              !'${r['deviceName']} ${r['siteName']}'.toLowerCase().contains(
                q['search']!.toLowerCase(),
              )) {
            return false;
          }
          final date = DateTime.parse(r['startTime'] ?? r['occurredAt']);
          if (q['startDate'] != null &&
              date.isBefore(DateTime.parse(q['startDate']!))) {
            return false;
          }
          if (q['endDate'] != null &&
              !date.isBefore(
                DateTime.parse(q['endDate']!).add(const Duration(days: 1)),
              )) {
            return false;
          }
          if (q['occurredDate'] != null &&
              date.toIso8601String().substring(0, 10) != q['occurredDate']) {
            return false;
          }
          return true;
        }).toList()..sort(
          (a, b) => '${b['startTime'] ?? b['occurredAt']}'.compareTo(
            '${a['startTime'] ?? a['occurredAt']}',
          ),
        );
    if (!q.containsKey('page')) {
      return filtered
          .take((int.tryParse(q['limit'] ?? '') ?? 100).clamp(1, 10000))
          .toList();
    }
    final size = (int.tryParse(q['size'] ?? '') ?? 10).clamp(1, 100);
    final page = (int.tryParse(q['page'] ?? '') ?? 0).clamp(0, 100000);
    return {
      'items': filtered.skip(page * size).take(size).toList(),
      'page': page,
      'size': size,
      'totalItems': filtered.length,
      'totalPages': (filtered.length / size).ceil(),
      'hasPrevious': page > 0,
      'hasNext': (page + 1) * size < filtered.length,
    };
  }

  Row _decorate(Row record) {
    final device = _find('devices', record['deviceId']);
    final site = _find('sites', record['siteId'] ?? device['siteId']);
    return {
      ...record,
      'deviceName': record['deviceName'] ?? device['name'],
      'siteName': site['name'],
    };
  }

  int _duration(Row incident, {DateTime? from}) {
    var start = DateTime.parse(incident['startTime']);
    final end = DateTime.parse(incident['endTime'] ?? now);
    if (from != null && start.isBefore(from)) start = from;
    return max(0, end.difference(start).inSeconds);
  }

  Row _device(Row device) {
    final site = _find('sites', device['siteId']);
    final incidents = rows(
      'incidents',
    ).where((i) => i['deviceId'] == device['id']);
    final open = incidents.where((i) => i['endTime'] == null);
    return {
      ...site,
      ...device,
      'siteName': site['name'],
      'eventCount': rows(
        'events',
      ).where((e) => e['deviceId'] == device['id']).length,
      'incidentCount': incidents.length,
      'totalDowntimeSeconds': incidents.fold<int>(
        0,
        (sum, i) => sum + _duration(i),
      ),
      'currentIncidentStartedAt': open.isEmpty ? null : open.first['startTime'],
    };
  }

  Row _detail(Row device) {
    final incidents = rows(
      'incidents',
    ).where((i) => i['deviceId'] == device['id']).toList();
    final events = rows(
      'events',
    ).where((e) => e['deviceId'] == device['id']).toList();
    final current = DateTime.now();
    int count(int days) => incidents
        .where(
          (i) => DateTime.parse(
            i['startTime'],
          ).isAfter(current.subtract(Duration(days: days))),
        )
        .length;
    final durations = incidents.map(_duration).toList();
    final downtime = incidents.fold<int>(
      0,
      (sum, i) =>
          sum + _duration(i, from: current.subtract(const Duration(days: 30))),
    );
    List<Row> buckets(int n, int days) => List.generate(n, (i) {
      final start = DateTime(
        current.year,
        current.month,
        current.day,
      ).subtract(Duration(days: (n - 1 - i) * days));
      final end = start.add(Duration(days: days));
      return {
        'label': '${start.day}/${start.month}',
        'count': incidents.where((r) {
          final date = DateTime.parse(r['startTime']);
          return !date.isBefore(start) && date.isBefore(end);
        }).length,
      };
    });
    return {
      'device': _device(device),
      'metrics': {
        'incidentsLast7Days': count(7),
        'incidentsLast30Days': count(30),
        'incidentsLast90Days': count(90),
        'averageDowntimeSeconds': durations.isEmpty
            ? 0
            : durations.reduce((a, b) => a + b) ~/ durations.length,
        'longestDowntimeSeconds': durations.isEmpty ? 0 : durations.reduce(max),
        'availabilityLast30Days':
            (100 * (1 - downtime / const Duration(days: 30).inSeconds))
                .clamp(0, 100)
                .toDouble(),
      },
      'dailyIncidents': buckets(30, 1),
      'weeklyIncidents': buckets(12, 7),
      'monthlyIncidents': List.generate(6, (i) {
        final start = DateTime(current.year, current.month - 5 + i);
        final end = DateTime(start.year, start.month + 1);
        return {
          'label': '${start.month}/${start.year}',
          'count': incidents.where((r) {
            final t = DateTime.parse(r['startTime']);
            return !t.isBefore(start) && t.isBefore(end);
          }).length,
        };
      }),
      'weekdayIncidents': List.generate(
        7,
        (i) => {
          'label': ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][i],
          'count': incidents
              .where((r) => DateTime.parse(r['startTime']).weekday == i + 1)
              .length,
        },
      ),
      'timeOfDayIncidents': List.generate(
        4,
        (i) => {
          'label': '${i * 6}–${i * 6 + 5} h',
          'count': incidents
              .where((r) => DateTime.parse(r['startTime']).hour ~/ 6 == i)
              .length,
        },
      ),
      'recentIncidents': incidents.reversed.map(_decorate).toList(),
      'recentEvents': events.reversed.map(_decorate).toList(),
    };
  }

  Row _testDelivery(String userId) {
    rows('deliveries').insert(0, {
      'id': (state['sequence'] as int) + 1,
      'userId': userId,
      'eventType': 'test',
      'status': 'SIMULATED',
      'errorMessage': 'Mensaje simulado; no enviado a WhatsApp.',
      'createdAt': now,
    });
    state['sequence']++;
    return {
      'configured': true,
      'accepted': true,
      'message': 'Prueba registrada localmente. No se envió un WhatsApp real.',
    };
  }

  dynamic _local(String method, List<String> parts, Row body, Row actor) {
    if (parts.last == 'reset' && method == 'POST') {
      _admin(actor, superadmin: true);
      state = _seed();
      return <String, dynamic>{};
    }
    if (parts.last == 'devices' && method == 'POST') {
      final site = _find('sites', '${body['siteId']}');
      final name = '${body['name'] ?? ''}'.trim();
      if (name.isEmpty) throw LocalFailure(400, 'Nombre obligatorio.');
      final device = {
        'id': id(),
        'externalId': 'local-${id()}',
        'name': name,
        'siteId': site['id'],
        'status': 'online',
        'active': true,
        'provider': 'local',
        'lastStatusChange': now,
        'createdAt': now,
      };
      rows('devices').add(device);
      _audit(actor, 'CREATE_DEVICE', 'device', device['id']);
      return _device(device);
    }
    if (parts.length == 5 && parts[2] == 'devices') {
      final device = _find('devices', parts[3]);
      if (parts.last == 'archive' && method == 'POST') {
        if (rows(
          'incidents',
        ).any((i) => i['deviceId'] == device['id'] && i['endTime'] == null)) {
          throw LocalFailure(
            409,
            'Restaura la energía antes de retirar el dispositivo.',
          );
        }
        device['active'] = false;
        _audit(actor, 'ARCHIVE_DEVICE', 'device', device['id']);
        return <String, dynamic>{};
      }
      if (parts.last == 'power' && method == 'POST') {
        if (device['active'] != true) {
          throw LocalFailure(409, 'Dispositivo inactivo.');
        }
        final online = body['online'];
        if (online is! bool) throw LocalFailure(400, 'Estado inválido.');
        if ((device['status'] == 'online') == online) return _device(device);
        final open = rows(
          'incidents',
        ).where((i) => i['deviceId'] == device['id'] && i['endTime'] == null);
        late Row incident;
        if (!online) {
          incident = {
            'id': id(),
            'deviceId': device['id'],
            'deviceName': device['name'],
            'siteId': device['siteId'],
            'status': 'active',
            'startTime': now,
          };
          rows('incidents').add(incident);
        } else if (open.isNotEmpty) {
          incident = open.first;
          incident.addAll({'status': 'resolved', 'endTime': now});
          incident['durationSeconds'] = _duration(incident);
        } else {
          throw LocalFailure(409, 'No hay un corte abierto para restaurar.');
        }
        final type = online ? 'power_restored' : 'power_outage';
        rows('events').add({
          'id': id(),
          'deviceId': device['id'],
          'deviceName': device['name'],
          'siteId': device['siteId'],
          'eventType': type,
          'occurredAt': now,
          'receivedAt': now,
          'deliveryLatencyMillis': 0,
        });
        device.addAll({
          'status': online ? 'online' : 'offline',
          'lastStatusChange': now,
        });
        for (final user in rows('users').where((u) => u['active'] == true)) {
          rows('notifications').insert(0, {
            'id': id(),
            'userId': user['id'],
            'title': online ? 'Energía restaurada' : 'Corte de energía',
            'body': device['name'],
            'eventType': type,
            'createdAt': now,
            'unread': true,
            'status': 'LOCAL',
            'data': {
              'deviceId': device['id'],
              'incidentId': incident['id'],
              'eventType': type,
            },
          });
          if (user['whatsappEnabled'] == true &&
              user['whatsappPhone'] != null) {
            _testDelivery(user['id']);
            rows('deliveries').first['eventType'] = type;
          }
        }
        _audit(actor, type.toUpperCase(), 'device', device['id']);
        return _device(device);
      }
    }
    throw LocalFailure(404, 'Operación no disponible.');
  }

  static Row _seed() {
    final current = DateTime.now();
    final users = <Row>[];
    for (final role in ['SUPERADMIN', 'ADMIN', 'USER']) {
      final username = role == 'USER' ? 'tecnico' : role.toLowerCase();
      final user = <String, dynamic>{
        'id': 'u-$username',
        'username': username,
        'displayName': {
          'SUPERADMIN': 'Administrador general',
          'ADMIN': 'Administrador',
          'USER': 'Técnico',
        }[role],
        'role': role,
        'email': '$username@example.invalid',
        'active': true,
        'whatsappEnabled': false,
      };
      _password(user, 'FiconLocal2026!');
      users.add(user);
    }
    final towns = ['Alto Puno', 'Juliaca', 'Lampa', 'Putina'];
    final coords = [
      [-15.7901, -70.0416],
      [-15.4997, -70.1333],
      [-15.3647, -70.3678],
      [-14.9131, -69.8689],
    ];
    final sites = <Row>[
      for (var i = 0; i < 4; i++)
        {
          'id': 's-$i',
          'name': towns[i],
          'district': towns[i],
          'province': towns[i] == 'Juliaca' ? 'San Román' : towns[i],
          'department': 'Puno',
          'active': true,
          'latitude': coords[i][0],
          'longitude': coords[i][1],
          'timeZone': 'America/Lima',
        },
    ];
    final devices = <Row>[
      for (var i = 0; i < 4; i++)
        {
          'id': 'd-$i',
          'externalId': 'local-$i',
          'name': 'Timax - ${towns[i]}',
          'siteId': 's-$i',
          'status': 'online',
          'active': true,
          'provider': 'local',
          'category': 'Medidor',
          'model': 'Medidor de energía',
          'lastStatusChange': current.toIso8601String(),
          'createdAt': current
              .subtract(const Duration(days: 90))
              .toIso8601String(),
        },
    ];
    final incidents = <Row>[];
    final events = <Row>[];
    for (var i = 1; i <= 24; i++) {
      final device = devices[i % 4];
      final start = current.subtract(Duration(days: i, hours: i % 6));
      final end = start.add(Duration(minutes: 5 + i * 2));
      final common = {
        'deviceId': device['id'],
        'deviceName': device['name'],
        'siteId': device['siteId'],
      };
      incidents.add({
        ...common,
        'id': 'i-$i',
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'durationSeconds': end.difference(start).inSeconds,
        'status': 'resolved',
      });
      for (final online in [false, true]) {
        final time = (online ? end : start).toIso8601String();
        events.add({
          ...common,
          'id': 'e-$i-$online',
          'eventType': online ? 'power_restored' : 'power_outage',
          'occurredAt': time,
          'receivedAt': time,
          'deliveryLatencyMillis': 0,
        });
      }
    }
    return {
      'schema': 1,
      'sequence': 0,
      'users': users,
      'sites': sites,
      'devices': devices,
      'incidents': incidents,
      'events': events,
      'notifications': <Row>[],
      'deliveries': <Row>[],
      'recipients': <Row>[],
      'sessions': <Row>[],
      'audit': <Row>[],
      'logins': <Row>[],
      'blocked': <Row>[],
      'plans': <Row>[
        {
          'id': 1,
          'projectName': 'FICON Power',
          'planName': 'Plan gratuito Tuya IoT',
          'lastRenewedOn': '2026-08-28',
          'nextRenewalOn': '2027-02-28',
          'renewalIntervalMonths': 6,
          'reminderDays': 7,
          'active': true,
          'notes': 'Calendario local de renovación.',
        },
      ],
    };
  }
}

class LocalClient extends http.BaseClient {
  LocalClient(this.engine);
  final LocalEngine engine;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host != 'local.ficon') {
      throw StateError('Conexión externa deshabilitada.');
    }
    final token =
        (request.headers['Authorization'] ??
                request.headers['authorization'] ??
                '')
            .replaceFirst('Bearer ', '');
    try {
      if (request.url.path == '/api/realtime/stream' &&
          request.method == 'GET') {
        engine.authenticate(token);
        return http.StreamedResponse(
          _stream(token),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }
      final bytes = await request.finalize().toBytes();
      final body = bytes.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
      final result = await engine.request(
        request.method,
        request.url,
        body,
        token,
      );
      return _response(result, 200);
    } on LocalFailure catch (error) {
      return _response({'message': error.message}, error.status);
    }
  }

  Stream<List<int>> _stream(String token) async* {
    yield utf8.encode('event: ready\ndata: {}\n\n');
    await for (final change in engine.changes.stream) {
      engine.authenticate(token);
      yield utf8.encode('event: change\ndata: ${jsonEncode(change)}\n\n');
    }
  }

  http.StreamedResponse _response(dynamic data, int status) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(data))),
        status,
        headers: {'content-type': 'application/json'},
      );
}
