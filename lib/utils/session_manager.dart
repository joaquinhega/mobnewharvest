class SessionManager {
  static String letra = "";
  static String user = "";
  static String rol = "";
  static String nombre = "";

  static void saveUser(String user) {
    SessionManager.user = user;
  }

  static void saveLetra(String letra) {
    SessionManager.letra = letra;
  }

  static void saveRol(String rol) {
    SessionManager.rol = rol;
  }

  static void saveNombre(String nombre) {
    SessionManager.nombre = nombre;
  }

  static void clearSession() {
    SessionManager.user = "";
    SessionManager.letra = "";
    SessionManager.rol = "";
    SessionManager.nombre = "";
  }
}