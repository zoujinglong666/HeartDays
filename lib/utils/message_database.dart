import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/message.dart';

class MessageDatabase {
  static const String _databaseName = 'heart_days_messages.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'messages';

  // 数据库初始化
  static Future<Database> init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            localId TEXT NOT NULL UNIQUE,
            messageId TEXT,
            sessionId TEXT NOT NULL,
            fromMe INTEGER NOT NULL,
            text TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            sendStatus INTEGER NOT NULL,
            isRead INTEGER NOT NULL DEFAULT 0,
            retryCount INTEGER NOT NULL DEFAULT 0,
            lastRetryAt TEXT
          )
        ''');
        // 创建索引提升查询性能
        await db.execute('CREATE INDEX idx_sessionId ON $_tableName(sessionId)');
        await db.execute('CREATE INDEX idx_sendStatus ON $_tableName(sendStatus)');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // 数据库升级逻辑
        if (oldVersion < newVersion) {
          // 可以添加表结构变更语句
        }
      },
    );
  }

  // 保存消息到数据库
  static Future<int> saveMessage(Database db, Map<String, dynamic> message) async {
    return await db.insert(
      _tableName,
      {
        'localId': message['localId'],
        'messageId': message['messageId'],
        'sessionId': message['sessionId'],
        'fromMe': message['fromMe'] ? 1 : 0,
        'text': message['text'],
        'createdAt': message['createdAt'],
        'sendStatus': message['sendStatus'].index,
        'retryCount': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取未发送的消息
  static Future<List<Map<String, dynamic>>> getUnsentMessages(Database db, String sessionId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sessionId = ? AND sendStatus != ?',
      whereArgs: [sessionId, MessageSendStatus.success.index],
      orderBy: 'createdAt ASC',
    );

    return maps.map((map) => {
      ...map,
      'fromMe': map['fromMe'] == 1,
      'sendStatus': MessageSendStatus.values[map['sendStatus']],
    }).toList();
  }

  // 更新消息状态
  static Future<int> updateMessageStatus(
    Database db,
    String localId,
    MessageSendStatus status,
    {String? messageId, int? retryCount}
  ) async {
    final updates = {
      'sendStatus': status.index,
      if (messageId != null) 'messageId': messageId,
      if (retryCount != null) 'retryCount': retryCount,
      if (retryCount != null) 'lastRetryAt': DateTime.now().toIso8601String(),
    };

    return await db.update(
      _tableName,
      updates,
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  // 标记消息为已发送
  static Future<int> markAsSent(Database db, String messageId) async {
    return await db.update(
      _tableName,
      {
        'sendStatus': MessageSendStatus.success.index,
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // 删除消息
  static Future<int> deleteMessage(Database db, String localId) async {
    return await db.delete(
      _tableName,
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  // 清空会话消息
  static Future<int> clearSessionMessages(Database db, String sessionId) async {
    return await db.delete(
      _tableName,
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
  }
}