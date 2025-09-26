import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/message.dart';

class MessageDatabase {
  static const String _databaseName = 'heart_days_messages.db';
  static const int _databaseVersion = 2; // 增加版本号以支持新表
  static const String _tableName = 'messages';
  static const String _readMessagesTableName = 'read_messages'; // 新增已读消息表

  // 数据库初始化
  static Future<Database> init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        // 创建消息表
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
        
        // 创建已读消息表
        await db.execute('''
          CREATE TABLE $_readMessagesTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionId TEXT NOT NULL,
            messageId TEXT NOT NULL,
            readAt TEXT NOT NULL,
            UNIQUE(sessionId, messageId)
          )
        ''');
        
        // 创建索引提升查询性能
        await db.execute('CREATE INDEX idx_sessionId ON $_tableName(sessionId)');
        await db.execute('CREATE INDEX idx_sendStatus ON $_tableName(sendStatus)');
        await db.execute('CREATE INDEX idx_read_sessionId ON $_readMessagesTableName(sessionId)');
        await db.execute('CREATE INDEX idx_read_messageId ON $_readMessagesTableName(messageId)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 数据库升级逻辑
        if (oldVersion < 2 && newVersion >= 2) {
          // 添加已读消息表
          await db.execute('''
            CREATE TABLE $_readMessagesTableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sessionId TEXT NOT NULL,
              messageId TEXT NOT NULL,
              readAt TEXT NOT NULL,
              UNIQUE(sessionId, messageId)
            )
          ''');
          
          // 创建索引
          await db.execute('CREATE INDEX idx_read_sessionId ON $_readMessagesTableName(sessionId)');
          await db.execute('CREATE INDEX idx_read_messageId ON $_readMessagesTableName(messageId)');
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

  // 保存已读消息ID
  static Future<int> saveReadMessageId(Database db, String sessionId, String messageId) async {
    return await db.insert(
      _readMessagesTableName,
      {
        'sessionId': sessionId,
        'messageId': messageId,
        'readAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // 如果已存在则忽略
    );
  }

  // 获取会话的所有已读消息ID
  static Future<Set<String>> getReadMessageIds(Database db, String sessionId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      _readMessagesTableName,
      columns: ['messageId'],
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );

    return maps.map((map) => map['messageId'] as String).toSet();
  }

  // 检查消息是否已读
  static Future<bool> isMessageRead(Database db, String sessionId, String messageId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      _readMessagesTableName,
      where: 'sessionId = ? AND messageId = ?',
      whereArgs: [sessionId, messageId],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // 批量保存已读消息ID
  static Future<void> batchSaveReadMessageIds(Database db, String sessionId, List<String> messageIds) async {
    final batch = db.batch();
    final readAt = DateTime.now().toIso8601String();
    
    for (final messageId in messageIds) {
      batch.insert(
        _readMessagesTableName,
        {
          'sessionId': sessionId,
          'messageId': messageId,
          'readAt': readAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // 清空会话的已读消息记录
  static Future<int> clearSessionReadMessages(Database db, String sessionId) async {
    return await db.delete(
      _readMessagesTableName,
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
  }
}