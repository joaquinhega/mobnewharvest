class User {
  int? id;
  String username;
  String password;
  String letra;
  String nombre;

  User({this.id, required this.username, required this.password, required this.letra, required this.nombre});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'letra': letra,
      'nombre': nombre,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      letra: map['letra'],
      nombre: map['nombre'],
    );
  }
}