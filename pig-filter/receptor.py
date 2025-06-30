import socket

# Configuración del receptor
HOST = "0.0.0.0"  # Escucha en todas las interfaces
PORT = 5000       # Puerto donde espera el mensaje

def esperar_mensaje():
    print("escuchando mensaje en el puerto {}...".format(PORT))
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen(1)
        print(f"Esperando mensaje en {HOST}:{PORT} para iniciar procesamiento...")
        conn, addr = s.accept()
        with conn:
            print(f"Mensaje recibido de {addr}. Iniciando procesamiento de datos.")
            # Aquí puedes llamar a tu función de procesamiento de datos
            # procesar_datos()
            # Por ahora solo espera el mensaje y termina
            conn.recv(1024)  # Lee el mensaje (puedes ignorar el contenido)

if __name__ == "__main__":
    esperar_mensaje()