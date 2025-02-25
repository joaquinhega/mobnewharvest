class Voucher {
  int? id;
  String empresa;
  String fecha;
  String origen;
  String horaOrigen;
  String destino;
  String horaDestino;
  String tiempoEspera;
  String observaciones;
  String nombrePasajero;
  String firma;

  Voucher({
    this.id,
    required this.empresa,
    required this.fecha,
    required this.origen,
    required this.horaOrigen,
    required this.destino,
    required this.horaDestino,
    required this.tiempoEspera,
    required this.observaciones,
    required this.nombrePasajero,
    required this.firma,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa': empresa,
      'fecha': fecha,
      'origen': origen,
      'horaOrigen': horaOrigen,
      'destino': destino,
      'horaDestino': horaDestino,
      'tiempo_espera': tiempoEspera,
      'observaciones': observaciones,
      'nombrePasajero': nombrePasajero,
      'firma': firma,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'],
      empresa: map['empresa'],
      fecha: map['fecha'],
      origen: map['origen'],
      horaOrigen: map['horaOrigen'],
      destino: map['destino'],
      horaDestino: map['horaDestino'],
      tiempoEspera: map['tiempo_espera'],
      observaciones: map['observaciones'],
      nombrePasajero: map['nombrePasajero'],
      firma: map['firma'],
    );
  }
}
