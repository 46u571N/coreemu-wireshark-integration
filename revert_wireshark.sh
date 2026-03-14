#!/bin/bash

echo "========================================================"
echo " Revirtiendo configuración de Wireshark y CORE Emulator"
echo "========================================================"

# 1. Revertir permisos de dumpcap y remover del grupo wireshark
echo "[1/6] Revirtiendo permisos de Wireshark para el usuario: $USER..."
sudo gpasswd -d "$USER" wireshark 2>/dev/null
sudo setcap -r /usr/bin/dumpcap 2>/dev/null
sudo chgrp root /usr/bin/dumpcap 2>/dev/null
sudo chmod 755 /usr/bin/dumpcap 2>/dev/null

# 2. Revocar acceso al servidor X11 para root
echo "[2/6] Revocando acceso gráfico explícito para root..."
xhost -local:root 2>/dev/null

# 3. Eliminar la variable DISPLAY del servicio core-daemon
echo "[3/6] Eliminando la configuración personalizada de systemd..."
sudo rm -f /etc/systemd/system/core-daemon.service.d/override.conf
# Intentamos borrar el directorio si quedó vacío
sudo rmdir /etc/systemd/system/core-daemon.service.d 2>/dev/null

# 4. Limpieza de CORE y recarga de systemd
echo "[4/6] Ejecutando core-cleanup y recargando systemd..."
sudo core-cleanup
sudo systemctl daemon-reload

# 5. Restaurar config.yaml de la GUI de CORE
echo "[5/6] Restaurando el archivo de configuración de la GUI..."
CONFIG_FILE="$HOME/.coregui/config.yaml"
BAK_FILE="${CONFIG_FILE}.bak"

if [ -f "$BAK_FILE" ]; then
    cp "$BAK_FILE" "$CONFIG_FILE"
    echo "      -> Archivo config.yaml restaurado desde la copia de seguridad."
else
    echo "      -> [ATENCIÓN] No se encontró la copia de seguridad ($BAK_FILE)."
    echo "         Como configuraste esto manualmente, por favor abre:"
    echo "         $CONFIG_FILE"
    echo "         y borra manualmente el bloque de comandos de Wireshark."
fi

# 6. Reiniciar core-daemon
echo "[6/6] Reiniciando el demonio de CORE..."
sudo systemctl restart core-daemon

echo "========================================================"
echo " ¡Reversión completada!"
echo "========================================================"
echo ""

# Opción de reinicio interactivo
read -p "¿Deseas reiniciar el equipo ahora para aplicar la remoción del grupo wireshark? (S/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "Reiniciando el sistema en 3 segundos..."
    sleep 3
    sudo reboot
else
    echo "Reinicio cancelado. Recuerda cerrar y abrir sesión para que la salida del grupo surta efecto."
fi
