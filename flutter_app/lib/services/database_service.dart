import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'raffle_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create tickets table
    await db.execute('''
      CREATE TABLE tickets (
        id INTEGER PRIMARY KEY,
        barcode TEXT UNIQUE,
        category TEXT,
        price REAL,
        status TEXT,
        buyer_id INTEGER,
        seller_id INTEGER,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        phone TEXT UNIQUE,
        name TEXT,
        email TEXT,
        role TEXT,
        department TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY,
        ticket_id INTEGER,
        amount REAL,
        method TEXT,
        status TEXT,
        transaction_id TEXT,
        created_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create raffles table
    await db.execute('''
      CREATE TABLE raffles (
        id INTEGER PRIMARY KEY,
        name TEXT,
        draw_date TEXT,
        status TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create sync_queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        entity_type TEXT,
        entity_id INTEGER,
        data TEXT,
        created_at TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Create notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY,
        title TEXT,
        body TEXT,
        type TEXT,
        data TEXT,
        read INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Create cache_metadata table
    await db.execute('''
      CREATE TABLE cache_metadata (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_tickets_status ON tickets(status)');
    await db.execute('CREATE INDEX idx_tickets_buyer_id ON tickets(buyer_id)');
    await db.execute('CREATE INDEX idx_tickets_synced ON tickets(synced)');
    await db.execute('CREATE INDEX idx_payments_ticket_id ON payments(ticket_id)');
    await db.execute('CREATE INDEX idx_notifications_read ON notifications(read)');
    await db.execute('CREATE INDEX idx_sync_queue_created_at ON sync_queue(created_at)');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add any new columns or tables for version 2
    }
  }

  // Ticket operations
  Future<int> insertTicket(Map<String, dynamic> ticket) async {
    final db = await database;
    return await db.insert('tickets', ticket,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTickets({
    int? buyerId,
    String? status,
    bool? unsynced,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (buyerId != null) {
      where += 'buyer_id = ?';
      whereArgs.add(buyerId);
    }

    if (status != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'status = ?';
      whereArgs.add(status);
    }

    if (unsynced == true) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'synced = 0';
    }

    return await db.query(
      'tickets',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateTicket(int id, Map<String, dynamic> ticket) async {
    final db = await database;
    return await db.update(
      'tickets',
      ticket,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTicket(int id) async {
    final db = await database;
    return await db.delete(
      'tickets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Payment operations
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    return await db.insert('payments', payment,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPayments({int? ticketId}) async {
    final db = await database;
    return await db.query(
      'payments',
      where: ticketId != null ? 'ticket_id = ?' : null,
      whereArgs: ticketId != null ? [ticketId] : null,
      orderBy: 'created_at DESC',
    );
  }

  // Raffle operations
  Future<int> insertRaffle(Map<String, dynamic> raffle) async {
    final db = await database;
    return await db.insert('raffles', raffle,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getRaffles() async {
    final db = await database;
    return await db.query('raffles', orderBy: 'draw_date DESC');
  }

  // Sync queue operations
  Future<int> addToSyncQueue(Map<String, dynamic> syncTask) async {
    final db = await database;
    return await db.insert('sync_queue', syncTask);
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<int> deleteSyncQueueItem(int id) async {
    final db = await database;
    return await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSyncQueueRetryCount(int id, int retryCount) async {
    final db = await database;
    return await db.update(
      'sync_queue',
      {'retry_count': retryCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Notification operations
  Future<int> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.insert('notifications', notification,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getNotifications({bool? unreadOnly}) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: unreadOnly == true ? 'read = 0' : null,
      orderBy: 'created_at DESC',
    );
  }

  Future<int> markNotificationAsRead(int id) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAllNotificationsAsRead() async {
    final db = await database;
    return await db.update('notifications', {'read': 1});
  }

  // Cache metadata operations
  Future<int> setCacheMetadata(String key, String value) async {
    final db = await database;
    return await db.insert(
      'cache_metadata',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCacheMetadata(String key) async {
    final db = await database;
    final results = await db.query(
      'cache_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return results.isNotEmpty ? results.first['value'] as String? : null;
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tickets');
    await db.delete('users');
    await db.delete('payments');
    await db.delete('raffles');
    await db.delete('sync_queue');
    await db.delete('notifications');
    await db.delete('cache_metadata');
  }

  // Clear cache only (keep sync queue)
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('tickets');
    await db.delete('users');
    await db.delete('payments');
    await db.delete('raffles');
    await db.delete('notifications');
    await db.delete('cache_metadata');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
