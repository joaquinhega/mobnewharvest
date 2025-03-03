class Voucher {
  String id;
  String empresa;
  String nombrePasajero;
  String origen;
  String horaOrigen;
  String destino;
  String horaDestino;
  String fecha;
  String? observaciones;
  String? tiempoEspera;
  String? signaturePath;

  Voucher({
    required this.id,
    required this.empresa,
    required this.nombrePasajero,
    required this.origen,
    required this.horaOrigen,
    required this.destino,
    required this.horaDestino,
    required this.fecha,
    this.observaciones,
    this.tiempoEspera,
    this.signaturePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa': empresa,
      'nombre_pasajero': nombrePasajero,
      'origen': origen,
      'hora_origen': horaOrigen,
      'destino': destino,
      'hora_destino': horaDestino,
      'fecha': fecha,
      'observaciones': observaciones,
      'tiempo_espera': tiempoEspera,
      'signature_path': signaturePath,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    print('Convirtiendo map a Voucher: $map');
    if (!RegExp(r'^[A-Z]\d{3}$').hasMatch(map['id'])) {
      print('Formato de ID inválido: ${map['id']}');
    }
    return Voucher(
      id: map['id'],
      empresa: map['empresa'],
      nombrePasajero: map['nombre_pasajero'],
      origen: map['origen'],
      horaOrigen: map['hora_origen'],
      destino: map['destino'],
      horaDestino: map['hora_destino'],
      fecha: map['fecha'],
      observaciones: map['observaciones'],
      tiempoEspera: map['tiempo_espera'],
      signaturePath: map['signature_path'],
    );
  }
}