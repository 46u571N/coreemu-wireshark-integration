#!/bin/bash

echo "========================================================"
echo " Configurando Wireshark y CORE Network Emulator"
echo "========================================================"

# 1. Configurar permisos de captura para Wireshark
echo "[1/6] Asignando permisos de Wireshark al usuario: $USER"
sudo groupadd -f wireshark
sudo usermod -aG wireshark "$USER"
sudo chgrp wireshark /usr/bin/dumpcap
sudo chmod 750 /usr/bin/dumpcap
sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap

# 2. Asegurar acceso al servidor X11
echo "[2/6] Habilitando acceso gráfico para root..."
xhost +local:root

# 3. Inyectar variable DISPLAY en el servicio core-daemon
echo "[3/6] Automatizando la configuración de core-daemon (systemd)..."
sudo mkdir -p /etc/systemd/system/core-daemon.service.d
cat << 'EOF' | sudo tee /etc/systemd/system/core-daemon.service.d/override.conf > /dev/null
[Service]
Environment="DISPLAY=:0"
EOF

# 4. Limpieza de CORE y recarga de systemd
echo "[4/6] Limpiando sesiones previas de CORE..."
sudo core-cleanup
echo "      Recargando demonios de systemd..."
sudo systemctl daemon-reload

# 5. Actualizar config.yaml de la GUI de CORE
echo "[5/6] Inyectando comandos en el menú contextual de CORE..."
CONFIG_FILE="$HOME/.coregui/config.yaml"

# Creamos un bloque de texto temporal con la configuración exacta (respetando espacios)
cat << 'EOF' > /tmp/core_node_cmds_tmp.txt
  - !NodeCommand
    cmd: wireshark 
    name: wireshark
  - !NodeCommand
    cmd: wireshark -k -i eth0
    name: eth0
  - !NodeCommand
    cmd: wireshark -k -i eth1
    name: eth1
  - !NodeCommand
    cmd: wireshark -k -i eth2
    name: eth2
  - !NodeCommand
    cmd: wireshark -k -i eth3
    name: eth3
  
EOF

if [ -f "$CONFIG_FILE" ]; then
    # Hacemos una copia de seguridad por precaución
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    # Comprobamos si la directiva node_commands: ya existe
     if grep -q "^node_commands:" "$CONFIG_FILE"; then
        # LIMPIEZA CLAVE: Quitamos los corchetes o basura que haya en la línea original
        sed -i 's/^node_commands:.*$/node_commands:/' "$CONFIG_FILE"
        # Ahora sí, inyectamos el archivo justo debajo
        sed -i '/^node_commands:/r /tmp/core_node_cmds_tmp.txt' "$CONFIG_FILE"
    else
        # Si no existe, la crea al final del archivo
        echo "node_commands:" >> "$CONFIG_FILE"
        cat /tmp/core_node_cmds_tmp.txt >> "$CONFIG_FILE"
    fi
    echo "      -> Menú actualizado (Respaldo guardado en ${CONFIG_FILE}.bak)"
else
    echo "      -> [ADVERTENCIA] No se encontró $CONFIG_FILE. Ejecuta la GUI de CORE al menos una vez para generarlo."
fi

# Limpieza del archivo temporal
rm -f /tmp/core_node_cmds_tmp.txt

# 6. Reiniciar core-daemon
echo "[6/6] Reiniciando el demonio de CORE..."
sudo systemctl restart core-daemon

echo "========================================================"
echo " ¡Configuración completada con éxito!"
echo "========================================================"
echo ""

# Opción de reinicio interactivo (Estilo Windows)
read -p "Para aplicar los cambios de grupos (wireshark) es necesario reiniciar el equipo. ¿Deseas reiniciar ahora? (S/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "Reiniciando el sistema en 3 segundos..."
    sleep 3
    sudo reboot
else
    echo "Reinicio cancelado. Los cambios en los grupos de usuario se aplicarán en tu próximo inicio de sesión."
fi