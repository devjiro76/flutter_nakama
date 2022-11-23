import 'dart:convert';
import 'package:chopper/chopper.dart';
import 'package:nakama/api.dart';
import 'package:nakama/nakama.dart';
import 'package:nakama/src/rest/apigrpc.swagger.dart'
    hide $ApiAccountWrappedExtension, $ApiAccountDeviceWrappedExtension;
import 'package:nakama/src/session.dart' as model;

const _kDefaultAppKey = 'default';

/// Base class for communicating with Nakama via gRPC.
/// [NakamaGrpcClient] abstracts the gRPC calls and handles authentication
/// for you.
class NakamaRestApiClient extends NakamaBaseClient {
  static final Map<String, NakamaRestApiClient> _clients = {};

  late final Apigrpc _api;

  /// The key used to authenticate with the server without a session.
  /// Defaults to "defaultkey".
  late final String serverKey;

  /// Temporarily holds the current valid session to use in the Chopper
  /// interceptor for JWT auth.
  model.Session? _session;

  /// Either inits and returns a new instance of [NakamaRestApiClient] or
  /// returns a already initialized one.
  factory NakamaRestApiClient.init({
    String? host,
    String? serverKey,
    String key = _kDefaultAppKey,
    int port = 7350,
    bool ssl = false,
  }) {
    if (_clients.containsKey(key)) {
      return _clients[key]!;
    }

    // Not yet initialized -> check if we've got all parameters to do so
    if (host == null || serverKey == null) {
      throw Exception(
        'Not yet initialized, need parameters [host] and [serverKey] to initialize.',
      );
    }

    // Create a new instance of this with given parameters.
    return _clients[key] = NakamaRestApiClient._(
      host: host,
      port: port,
      serverKey: serverKey,
      ssl: ssl,
    );
  }

  NakamaRestApiClient._({
    required String host,
    required String serverKey,
    required int port,
    required bool ssl,
  }) {
    _api = Apigrpc.create(
      baseUrl: Uri(host: host, scheme: ssl ? 'https' : 'http', port: port)
          .toString(),
      interceptors: [
        // Auth Interceptor
        (Request request) async {
          // Server Key Auth
          if (_session == null) {
            return applyHeader(
              request,
              'Authorization',
              'Basic ${base64Encode('$serverKey:'.codeUnits)}',
            );
          }

          // User's JWT auth
          return applyHeader(
            request,
            'Authorization',
            'Bearer ${_session!.token}',
          );
        },
      ],
    );
  }

  @override
  Future<model.Session> authenticateEmail({
    required String email,
    required String password,
    bool? create,
    String? username,
    Map<String, String>? vars,
  }) async {
    final res = await _api.v2AccountAuthenticateEmailPost(
      body: ApiAccountEmail(
        email: email,
        password: password,
        vars: vars,
      ),
      create: create,
      username: username,
    );

    if (res.body == null) {
      throw Exception('Authentication failed.');
    }

    final data = res.body!;

    return model.Session(
      created: data.created ?? false,
      token: data.token!,
      refreshToken: data.refreshToken,
    );
  }

  @override
  Future<model.Session> authenticateDevice({
    required String deviceId,
    bool create = true,
    String? username,
    Map<String, String>? vars,
  }) async {
    final res = await _api.v2AccountAuthenticateDevicePost(
      body: ApiAccountDevice(id: deviceId, vars: vars),
      create: create,
      username: username,
    );

    if (res.body == null) {
      throw Exception('Authentication failed.');
    }

    final data = res.body!;

    return model.Session(
      created: data.created ?? false,
      token: data.token!,
      refreshToken: data.refreshToken,
    );
  }

  @override
  Future<model.Session> authenticateFacebook({
    required String token,
    bool create = true,
    String? username,
    Map<String, String>? vars,
    bool import = false,
  }) async {
    final res = await _api.v2AccountAuthenticateFacebookPost(
      body: ApiAccountFacebook(
        token: token,
        vars: vars,
      ),
      $sync: import,
      create: create,
      username: username,
    );

    if (res.body == null) {
      throw Exception('Authentication failed.');
    }

    final data = res.body!;

    return model.Session(
      created: data.created ?? false,
      token: data.token!,
      refreshToken: data.refreshToken,
    );
  }

  @override
  Future<model.Session> authenticateGoogle({
    required String token,
    bool create = true,
    String? username,
    Map<String, String>? vars,
  }) async {
    final res = await _api.v2AccountAuthenticateGooglePost(
      body: ApiAccountGoogle(
        token: token,
        vars: vars,
      ),
      create: create,
      username: username,
    );

    if (res.body == null) {
      throw Exception('Authentication failed.');
    }

    final data = res.body!;

    return model.Session(
      created: data.created ?? false,
      token: data.token!,
      refreshToken: data.refreshToken,
    );
  }

  @override
  Future<model.Session> authenticateGameCenter({
    required String playerId,
    required String bundleId,
    required int timestampSeconds,
    required String salt,
    required String signature,
    required String publicKeyUrl,
    bool create = true,
    String? username,
    Map<String, String>? vars,
  }) async {
    final res = await _api.v2AccountAuthenticateGamecenterPost(
      body: ApiAccountGameCenter(
        playerId: playerId,
        bundleId: bundleId,
        timestampSeconds: timestampSeconds.toString(),
        salt: salt,
        signature: signature,
        publicKeyUrl: publicKeyUrl,
        vars: vars,
      ),
      create: create,
      username: username,
    );

    if (res.body == null) {
      throw Exception('Authentication failed.');
    }

    final data = res.body!;

    return model.Session(
      created: data.created ?? false,
      token: data.token!,
      refreshToken: data.refreshToken,
    );
  }

  @override
  Future<model.Session> authenticateSteam({
    required String token,
    bool create = true,
    String? username,
    Map<String, String>? vars,
  }) async {
    final res = await _api.v2AccountAuthenticateSteamPost(
      body: ApiAccountSteam(token: token, vars: vars),
      create: create,
      username: username,
    );

    if (res.body == null) {
      throw Exception('Authentication failed.');
    }

    final data = res.body!;

    return model.Session(
      created: data.created ?? false,
      token: data.token!,
      refreshToken: data.refreshToken,
    );
  }

  @override
  Future<model.Session> authenticateCustom({
    required String id,
    bool create = true,
    String? username,
    Map<String, String>? vars,
  }) async {
    final res = await _api.v2AccountAuthenticateCustomPost(
      body: ApiAccountCustom(id: id, vars: vars),
      create: create,
      username: username,
    );

    if (res.body == null) {
      throw Exception('Authentication failed.');
    }

    final data = res.body!;

    return model.Session(
      created: data.created ?? false,
      token: data.token!,
      refreshToken: data.refreshToken,
    );
  }

  @override
  Future<Account> getAccount(model.Session session) async {
    _session = session;
    final res = await _api.v2AccountGet();

    final acc = Account();
    // Some workaround here while protobuf expects the vars map to not be null
    acc.mergeFromProto3Json((res.body!.copyWith(
      devices: res.body!.devices!
          .map((e) => e.copyWith(
                vars: e.vars ?? {},
              ))
          .toList(),
    )).toJson());

    return acc;
  }

  @override
  Future<Response> sessionLogout(model.Session session) async {
    return await _api.v2SessionLogoutPost(
      body: ApiSessionLogoutRequest(
        token: session.token,
        refreshToken: session.refreshToken,
      ),
    );
  }

  @override
  Future<Response> updateAccount({
    required model.Session session,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? langTag,
    String? location,
    String? timezone,
  }) async {
    _session = session;

    return await _api.v2AccountPut(
        body: ApiUpdateAccountRequest(
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
            langTag: langTag,
            location: location,
            timezone: timezone));
  }

  @override
  Future<Users> getUsers({
    required model.Session session,
    List<String>? facebookIds,
    List<String>? ids,
    List<String>? usernames,
  }) async {
    _session = session;
    final res = await _api.v2UserGet(
      facebookIds: facebookIds,
      ids: ids,
      usernames: usernames,
    );

    return Users()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<StorageObjectAcks> writeStorageObjects({
    required model.Session session,
    List<WriteStorageObject>? objects,
    WriteStorageObject? object,
  }) async {
    _session = session;

    if (objects == null && object == null) {
      throw Exception('No objects provided.');
    }

    objects ??= [object!];

    final result = await _api.v2StoragePost(
      body: ApiWriteStorageObjectsRequest(
        objects: objects
            .map(
              (el) => ApiWriteStorageObject(
                collection: el.collection,
                key: el.key,
                value: el.value,
                version: el.version,
                permissionWrite: el.permissionWrite.value,
                permissionRead: el.permissionRead.value,
              ),
            )
            .toList(),
      ),
    );

    return StorageObjectAcks()..mergeFromProto3Json(result.body!.toJson());
  }

  @override
  Future<StorageObject?> readStorageObjects({
    required model.Session session,
    String? collection,
    String? key,
    String? userId,
  }) async {
    _session = session;

    final res = await _api.v2StorageGet(
      body: ApiReadStorageObjectsRequest(
        objectIds: [
          ApiReadStorageObjectId(
            collection: collection,
            key: key,
            userId: userId,
          ),
        ],
      ),
    );

    final result = StorageObjects()..mergeFromProto3Json(res.body!.toJson());
    return result.objects.isEmpty ? null : result.objects.first;
  }

  @override
  Future<StorageObjectList> listStorageObjects({
    required model.Session session,
    String? collection,
    String? cursor,
    String? userId,
    int? limit,
  }) async {
    _session = session;

    final res = await _api.v2StorageCollectionGet(
      collection: collection,
      cursor: cursor,
      userId: userId,
      limit: limit,
    );

    return StorageObjectList()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<Response> deleteStorageObject({
    required model.Session session,
    required Iterable<DeleteStorageObjectId> objectIds,
  }) async {
    _session = session;

    return await _api.v2StorageDelete(
      body: ApiDeleteStorageObjectsRequest(
        objectIds: objectIds
            .map((e) => ApiDeleteStorageObjectId(
                  collection: e.collection,
                  key: e.key,
                  version: e.version,
                ))
            .toList(),
      ),
    );
  }

  @override
  Future<ChannelMessageList?> listChannelMessages({
    required model.Session session,
    required String channelId,
    int limit = 20,
    bool? forward,
    String? cursor,
  }) async {
    assert(limit > 0 && limit <= 100);

    _session = session;
    final res = await _api.v2ChannelChannelIdGet(
      channelId: channelId,
      limit: limit,
      forward: forward,
      cursor: cursor,
    );

    return ChannelMessageList()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<LeaderboardRecordList> listLeaderboardRecords({
    required model.Session session,
    required String leaderboardName,
    List<String>? ownerIds,
    int limit = 20,
    String? cursor,
    DateTime? expiry,
  }) async {
    assert(limit > 0 && limit <= 100);

    _session = session;

    final res = await _api.v2LeaderboardLeaderboardIdGet(
      leaderboardId: leaderboardName,
      ownerIds: ownerIds,
      limit: limit,
      cursor: cursor,
      expiry: expiry == null
          ? null
          : (expiry.millisecondsSinceEpoch ~/ 1000).toString(),
    );

    return LeaderboardRecordList()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<LeaderboardRecord> writeLeaderboardRecord({
    required model.Session session,
    required String leaderboardId,
    int? score,
    int? subscore,
    String? metadata,
  }) async {
    _session = session;

    final res = await _api.v2LeaderboardLeaderboardIdPost(
        leaderboardId: leaderboardId,
        body: WriteLeaderboardRecordRequestLeaderboardRecordWrite(
          score: score?.toString(),
          subscore: subscore?.toString(),
          metadata: metadata,
        ));

    return LeaderboardRecord()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<Response> linkDevice({
    required model.Session session,
    String? id,
    Map<String, String>? vars,
  }) async {
    _session = session;

    return await _api.v2AccountLinkDevicePost(
      body: ApiAccountDevice(
        id: id,
        vars: vars,
      ),
    );
  }

  @override
  Future<Response> unlinkDevice({
    required model.Session session,
    String? id,
    Map<String, String>? vars,
  }) async {
    _session = session;

    return await _api.v2AccountUnlinkDevicePost(
      body: ApiAccountDevice(
        id: id,
        vars: vars,
      ),
    );
  }

  @override
  Future<void> linkCustom({
    required model.Session session,
    required String id,
    Map<String, String>? vars,
  }) async {
    _session = session;

    await _api.v2AccountLinkCustomPost(
      body: ApiAccountCustom(
        id: id,
        vars: vars,
      ),
    );
  }

  @override
  Future<void> unlinkCustom({
    required model.Session session,
    String? id,
    Map<String, String>? vars,
  }) async {
    _session = session;

    await _api.v2AccountUnlinkCustomPost(
      body: ApiAccountCustom(
        id: id,
      ),
    );
  }

  @override
  Future<FriendList> listFriends({
    required model.Session session,
    int? state,
    int? limit = 20,
    String? cursor,
  }) async {
    _session = session;

    final res = await _api.v2FriendGet(
      state: state,
      limit: limit,
      cursor: cursor,
    );

    return FriendList()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<void> addFriends({
    required model.Session session,
    List<String>? ids,
    List<String>? usernames,
  }) async {
    _session = session;

    _api.v2FriendPost(
      ids: ids,
      usernames: usernames,
    );
  }

  @override
  Future<Response> deleteFriends({
    required model.Session session,
    List<String>? ids,
    List<String>? usernames,
  }) async {
    _session = session;

    return await _api.v2FriendDelete(
      ids: ids,
      usernames: usernames,
    );
  }

  @override
  Future<Response> blockFriends({
    required model.Session session,
    List<String>? ids,
    List<String>? usernames,
  }) async {
    _session = session;

    return await _api.v2FriendBlockPost(
      ids: ids,
      usernames: usernames,
    );
  }

  @override
  Future<GroupList> listGroups({
    required model.Session session,
    String? name,
    String? cursor,
    int? limit = 20,
    String? langTag,
    int? members,
    bool? open,
  }) async {
    _session = session;

    final param = <Symbol, dynamic>{};
    if (name != null) {
      param.addEntries([MapEntry(const Symbol('name'), name)]);
    }
    if (cursor != null) {
      param.addEntries([MapEntry(const Symbol('cursor'), cursor)]);
    }
    if (limit != null) {
      param.addEntries([MapEntry(const Symbol('limit'), limit)]);
    }
    if (langTag != null) {
      param.addEntries([MapEntry(const Symbol('langTag'), langTag)]);
    }
    if (members != null) {
      param.addEntries([MapEntry(const Symbol('members'), members)]);
    }
    if (open != null) {
      param.addEntries([MapEntry(const Symbol('open'), open)]);
    }

    final res = await Function.apply(
      _api.v2GroupGet,
      [],
      param,
    );

    return GroupList()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<Group> createGroup({
    required model.Session session,
    required String name,
    String? description,
    String? avatarUrl,
    String? langTag,
    bool? open,
    int? maxCount,
  }) async {
    _session = session;

    final res = await _api.v2GroupPost(
      body: ApiCreateGroupRequest(
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        langTag: langTag,
        open: open,
        maxCount: maxCount,
      ),
    );

    return Group()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<Empty> joinGroup({
    required model.Session session,
    required String groupId,
  }) async {
    _session = session;

    final res = await _api.v2GroupGroupIdJoinPost(
      groupId: groupId,
    );

    return Empty()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<UserGroupList> listUserGroups({
    required model.Session session,
    String? userId,
    int? state,
    int? limit,
    String? cursor,
  }) async {
    _session = session;

    final res = await _api.v2UserUserIdGroupGet(
      userId: userId,
      limit: limit,
      state: state,
      cursor: cursor,
    );

    return UserGroupList()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<GroupUserList> listGroupUsers({
    required model.Session session,
    required String groupId,
    int? state,
    int? limit = 20,
    String? cursor,
  }) async {
    final res = await _api.v2GroupGroupIdUserGet(
      groupId: groupId,
      state: state,
      limit: limit,
      cursor: cursor,
    );

    return GroupUserList()..mergeFromProto3Json(res.body!.toJson());
  }

  @override
  Future<void> rpc({
    required model.Session session,
    required String id,
    String? payload,
  }) async {
    _session = session;

    await _api.v2RpcIdGet(
      id: id,
      payload: payload,
    );
  }
}
