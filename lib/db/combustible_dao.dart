class Combustible {
  int? id;
  String fecha;
  double monto;
  double patente;

  Combustible({
    this.id,
    required this.fecha,
    required this.monto,
    required this.patente,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'monto': monto,
      'patente': patente,
    };
  }

  factory Combustible.fromMap(Map<String, dynamic> map) {
    return Combustible(
      id: map['id'],
      fecha: map['fecha'],
      monto: map['monto'],
      patente: map['patente'],
    );
  }
}
