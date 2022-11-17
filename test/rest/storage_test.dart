import 'package:faker/faker.dart';
import 'package:nakama/api.dart' as api;
import 'package:nakama/nakama.dart';
import 'package:test/test.dart';

import '../config.dart';

void main() {
  group('[REST] Test Storage Engine', () {
    late final NakamaBaseClient client;
    late final Session session;

    setUpAll(() async {
      client = NakamaRestApiClient.init(
        host: host,
        ssl: false,
        serverKey: serverKey,
      );

      session =
          await client.authenticateDevice(deviceId: testDeviceId, create: true);
    });

    test('write storage object', () async {
      await client.writeStorageObjects(
        session: session,
        object: api.WriteStorageObject(
          collection: 'test',
          key: 'test',
          value: 'test',
          version: '1',
        ),
      );
    });

    test('write storage object with permissions', () async {
      await client.writeStorageObjects(
        session: session,
        object: api.WriteStorageObject(
          collection: 'stats',
          key: 'scores',
          value: '{"skill":25}',
          permissionRead:
              api.Int32Value(value: StorageWritePermission.ownerWrite.index),
          permissionWrite:
              api.Int32Value(value: StorageReadPermission.publicRead.index),
        ),
      );
    });

    test('read storage object', () async {
      await client.writeStorageObjects(
        session: session,
        object: api.WriteStorageObject(
          collection: 'stats',
          key: 'skills',
          value: '{"skill": 100}',
          permissionRead:
              api.Int32Value(value: StorageWritePermission.ownerWrite.index),
          permissionWrite:
              api.Int32Value(value: StorageReadPermission.publicRead.index),
        ),
      );

      final res = await client.readStorageObjects(
        session: session,
        collection: 'stats',
        userId: session.userId,
      );

      expect(res, isA<api.StorageObject>());
      expect(res!.value, equals('{"skill": 100}'));
    });

    test('list storage objects', () async {
      // Write two objects
      await Future.wait([
        client.writeStorageObjects(
            session: session,
            object: api.WriteStorageObject(
              collection: 'stats',
              key: 'skills',
              value: '{"skill": 100}',
              permissionRead: api.Int32Value(
                  value: StorageWritePermission.ownerWrite.index),
              permissionWrite:
                  api.Int32Value(value: StorageReadPermission.publicRead.index),
            )),
        client.writeStorageObjects(
            session: session,
            object: api.WriteStorageObject(
              collection: 'stats',
              key: 'achievements',
              value: '{"hero": 20}',
              permissionRead: api.Int32Value(
                  value: StorageWritePermission.ownerWrite.index),
              permissionWrite:
                  api.Int32Value(value: StorageReadPermission.publicRead.index),
            )),
      ]);

      final res = await client.listStorageObjects(
        session: session,
        collection: 'stats',
        userId: session.userId,
        limit: 10,
      );

      expect(res, isA<api.StorageObjectList>());
      expect(res.objects, hasLength(2));
    });

    test('delete storage object', () async {
      await client.writeStorageObjects(
        session: session,
        object: api.WriteStorageObject(
          collection: 'stats',
          key: 'skills',
          value: '{"skill": 100}',
          permissionRead:
              api.Int32Value(value: StorageWritePermission.ownerWrite.index),
          permissionWrite:
              api.Int32Value(value: StorageReadPermission.publicRead.index),
        ),
      );

      // Be sure we get a result
      final res = await client.readStorageObjects(
        session: session,
        collection: 'stats',
        key: 'skills',
        userId: session.userId,
      );

      expect(res, isA<api.StorageObject>());
      expect(res!.value, equals('{"skill": 100}'));

      // Delete object
      await client.deleteStorageObject(session: session, objectIds: [
        api.DeleteStorageObjectId(
          collection: 'stats',
          key: 'skills',
        ),
      ]);

      final afterRes = await client.readStorageObjects(
        session: session,
        collection: 'stats',
        key: 'skills',
        userId: session.userId,
      );

      expect(afterRes, isNull);
    });
  });
}
