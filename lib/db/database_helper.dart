import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'user.dart';
import 'combustible_dao.dart';
import 'voucher_dao.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseHelper {
    static final DatabaseHelper _instance = DatabaseHelper._internal();
    factory DatabaseHelper() => _instance;
    DatabaseHelper._internal();

    static Database? _database;

    Future<Database> get database async {
        if (_database != null) return _database!;
        _database = await _initDatabase();
        return _database!;
    }

    Future<Database> _initDatabase() async {
        String path = join(await getDatabasesPath(), 'app_database.db');
        return await openDatabase(
            path,
            version: 1,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
        );
    }

    Future<void> _onCreate(Database db, int version) async {
        await db.execute(''' 
            CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                username TEXT UNIQUE,
                password TEXT,
                letra TEXT,
                nombre TEXT
            )
        ''');

        await db.execute(''' 
            CREATE TABLE combustibles (
                id TEXT PRIMARY KEY,
                fecha TEXT,
                monto REAL,
                patente TEXT,
                nombre TEXT
            )
        ''');

        await db.execute(''' 
            CREATE TABLE vouchers (
                id TEXT PRIMARY KEY,
                empresa TEXT,
                nombre_pasajero TEXT,
                origen TEXT,
                hora_origen TEXT,
                destino TEXT,
                hora_destino TEXT,
                fecha TEXT,
                observaciones TEXT,
                tiempo_espera TEXT,
                signature_path TEXT
            )
        ''');
    }
    
    Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
            await db.execute('''
                CREATE TABLE IF NOT EXISTS vouchers (
                id TEXT PRIMARY KEY,
                empresa TEXT,
                nombre_pasajero TEXT,
                origen TEXT,
                hora_origen TEXT,
                destino TEXT,
                hora_destino TEXT,
                fecha TEXT,
                observaciones TEXT,
                tiempo_espera TEXT, 
                signature_path TEXT
              )
        ''');
        }
    }

    Future<int> insertUser(User user) async {
        final db = await database;
        return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    Future<int> updateUser(User user) async {
        final db = await database;
        return await db.update(
          'users',
          user.toMap(),
          where: 'username = ?',
          whereArgs: [user.username],
        );
    }

    Future<User?> getUser(String username) async {
        final db = await database;
        List<Map<String, dynamic>> result = await db.query(
            'users',
            where: 'username = ?',
            whereArgs: [username],
        );
        if (result.isNotEmpty) {
            return User.fromMap(result.first);
        }
        return null;
    }

    Future<User?> getLoggedInUser() async {
        final db = await database;
        List<Map<String, dynamic>> result = await db.query('users', limit: 1);
        if (result.isNotEmpty) {
            return User.fromMap(result.first);
        }
        return null;
    }

    Future<void> deleteUser() async {
        final db = await database;
        await db.delete('users');
    }

    Future<void> deleteDatabase() async {
        String path = join(await getDatabasesPath(), 'app_database.db');
        await databaseFactory.deleteDatabase(path);
        _database = null; 
    }

    Future<void> insertCombustible(Combustible combustible) async {
        final db = await database;
        await db.insert(
            'combustibles',
            combustible.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
    }

    Future<List<Combustible>> getPendingCombustibles() async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query('combustibles');
        return List.generate(maps.length, (i) {
            return Combustible.fromMap(maps[i]);
        });
    }

    Future<void> deleteCombustible(String id) async {
        final db = await database;
        await db.delete('combustibles', where: 'id = ?', whereArgs: [id]);
    }
    
    Future<String> generarSiguienteRemito(String letraChofer) async {
        String? ultimoID = await obtenerUltimoRemitoServidor(letraChofer);
        if (ultimoID == null) {
            ultimoID = "${letraChofer}000";
        }
        print('Último ID en el servidor: $ultimoID');
        
        String numeroParte = ultimoID.substring(1);
        if (!RegExp(r'^\d+$').hasMatch(numeroParte)) {
            print('Formato de ID inválido, ajustando a formato correcto.');
            ultimoID = "${letraChofer}000";
            numeroParte = ultimoID.substring(1);
        }

        int numero = int.parse(numeroParte) + 1;
        String nuevoID = "$letraChofer${numero.toString().padLeft(3, '0')}";
        print('Nuevo ID generado: $nuevoID');
        return nuevoID;
    }

    Future<String?> obtenerUltimoRemitoServidor(String letraChofer) async {
        try {
            final url = Uri.parse('http://10.0.2.2/newHarvestDes/api/RemitoV.php');
            final bodyData = jsonEncode({'letra_chofer': letraChofer});

            final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: bodyData,
            );

            if (response.statusCode == 200) {
                final responseBody = response.body.replaceAll(RegExp(r'^[^{]*'), '');
                final data = jsonDecode(responseBody);
                print("📊 Datos decodificados: $data");

                if (data != null && data.containsKey('ultimo_remito')) {
                    print("✅ Último remito obtenido: ${data['ultimo_remito']}");
                    return data['ultimo_remito'];
                } else {
                    print("⚠️ Respuesta sin 'ultimo_remito': ${response.body}");
                    return null;
                }
            } else {
                print("⚠️ Error en la respuesta del servidor: ${response.statusCode}");
                return null;
            }
        } catch (e) {
            print("⚠️ Error al obtener el último remito: $e");
            return null;
        }
    }

    Future<List<Voucher>> getPendingVouchers() async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query('vouchers');
        return List.generate(maps.length, (i) {
            return Voucher.fromMap(maps[i]);
        });
    }


    Future<void> insertVoucher(Voucher voucher) async {
        final db = await database;
        print('Insertando voucher: ${voucher.toMap()}');
        await db.insert('vouchers', voucher.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    Future<void> deleteVoucher(String id) async {
        final db = await database;
        await db.delete('vouchers', where: 'id = ?', whereArgs: [id]);
    }
}