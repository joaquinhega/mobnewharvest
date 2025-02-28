class Combustible {
  String id;
  String fecha;
  double monto;
  String patente;
  String nombre;

  Combustible({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.patente,
    required this.nombre,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'monto': monto,
      'patente': patente,
      'nombre': nombre,
    };
  }

  factory Combustible.fromMap(Map<String, dynamic> map) {
    return Combustible(
      id: map['id'].toString(), // Asegúrate de que el id sea un String
      fecha: map['fecha'],
      monto: map['monto'],
      patente: map['patente'],
      nombre: map['nombre'],
    );
  }
}