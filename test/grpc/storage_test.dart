import 'dart:convert';
import 'package:nakama/api.dart' as api;
import 'package:nakama/nakama.dart';
import 'package:nakama/rtapi.dart';
import 'package:test/test.dart';

import '../config.dart';

void main() {
  const testDeviceId = '86321d89-003d-500e-6408-61d97dbed0ce';

  group('[gRPC] Test Storage', () {
    late final NakamaBaseClient client;
    late final Session session;

    setUpAll(() async {
      client = getNakamaClient(
        host: host,
        ssl: false,
        serverKey: serverKey,
        httpPort: httpPort,
      );

      session = await client.authenticateDevice(
        deviceId: testDeviceId,
        create: true,
      );
    });

    test('write storage test', () async {
      final result = await client.writeStorageObjects(
        session: session,
        object: api.WriteStorageObject(
          collection: 'test',
          key: 'test',
          value: jsonEncode({
            'testKey': ['testValue1', 'testValue2']
          }),
          permissionRead: Int32Value(value: 1),
          permissionWrite: Int32Value(value: 1),
        ),
      );

      expect(result, isA<api.StorageObjectAcks>());
    });

    test('get list storage test', () async {
      final result = await client.readStorageObjects(
        session: session,
        userId: session.userId,
        collection: 'test',
        key: 'test',
      );

      expect(result, isA<api.StorageObject>());
    });
  });
}
