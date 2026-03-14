# coreemu-wireshark-integration 🦈⚡

This repository provides automated bash scripts to seamlessly integrate Wireshark into the CORE Network Emulator GUI. It automatically handles `dumpcap` group permissions, X11 forwarding for root namespaces, and YAML configuration injection, allowing you to right-click any node and start capturing traffic instantly.
*(Instrucciones detalladas en español a continuación).*
Este proyecto contiene scripts de automatización para habilitar la ejecución de Wireshark directamente desde el menú contextual de los nodos dentro de la interfaz gráfica de CORE Network Emulator, resolviendo de forma transparente los problemas de permisos de captura y de visualización gráfica (X11).

Archivos Incluidos
setup_wireshark.sh: Script de instalación. Se encarga de crear el grupo de captura, asignar los permisos necesarios a tu usuario, configurar el servidor gráfico para permitir conexiones de root e inyectar las opciones de Wireshark en el menú de la interfaz gráfica de CORE (config.yaml).

revert_wireshark.sh: Script de reversión (desinstalación). Deshace de forma segura todos los cambios realizados por el script de instalación. Revoca permisos, elimina al usuario del grupo de captura y restaura el archivo de configuración original.

Instrucciones de Uso (Quick Start)
1. Clonar el repositorio
Abre una terminal y descarga los archivos a tu máquina local:
git clone 
cd coreemu-wireshark-integration

2. Dar permisos de ejecución
chmod +x setup_wireshark.sh revert_wireshark.sh

4. Ejecute el script de configuración (NO UTILICE SUDO).
./setup_wireshark.sh

5. Ejecutar la instalación (¡IMPORTANTE: NO USAR SUDO!)
Para aplicar la configuración, ejecuta el script directamente como tu usuario normal:
./setup_wireshark.sh
(Para revertir los cambios en el futuro, usa ./revert_wireshark.sh).

⚠️ ADVERTENCIA CRÍTICA: NO ejecutes los scripts anteponiendo sudo (ej. sudo ./setup_wireshark.sh). El script está diseñado para leer la variable $USER y la ruta $HOME de tu usuario estándar para agregarlo al grupo de Wireshark y modificar tu configuración personal de CORE. Si lo ejecutas con sudo, la configuración fallará. El script pedirá la contraseña de administrador automáticamente cuando sea necesario.

4. Reiniciar el sistema
Al finalizar, el script te dará la opción de reiniciar el equipo. Este paso es obligatorio para que el sistema operativo reconozca tu entrada al grupo wireshark.

Anatomía Técnica de los Comandos
A continuación se detalla la función de los comandos clave utilizados por debajo en los scripts, en caso de requerir auditoría o adaptaciones manuales.

1. Gestión de Permisos de Captura de Red
Por defecto, solo el usuario root puede capturar tráfico de red. Para permitir que Wireshark capture paquetes sin ejecutar la aplicación gráfica completa como superusuario:

groupadd -f wireshark y usermod -aG wireshark $USER: Crea un grupo específico y añade al usuario actual.

chgrp wireshark /usr/bin/dumpcap y chmod 750 /usr/bin/dumpcap: Transfiere la propiedad de grupo del motor de captura (dumpcap) al grupo wireshark y restringe los permisos para que solo root y los miembros del grupo puedan utilizarlo.

setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap: Utiliza Linux Capabilities para otorgar privilegios granulares al binario para interceptar paquetes sin dar permisos totales de sudo.

2. Configuración del Servidor Gráfico (X11)
Los nodos en CORE operan bajo el usuario root en network namespaces aislados. Para que puedan abrir ventanas gráficas en tu escritorio estándar:

xhost +local:root: Modifica la lista de control de acceso del servidor X11 para permitir que root envíe interfaces gráficas al display actual, evitando el error cannot open display.

Inyección de override.conf en systemd: Crea un archivo drop-in para core-daemon que inyecta la variable Environment="DISPLAY=:0", indicando al demonio a qué pantalla enviar la salida gráfica.

3. Modificación del Menú Contextual de CORE
sed -i 's/^node_commands:.*$/node_commands:/' ~/.coregui/config.yaml: Limpia listas vacías (como []) generadas por el emulador, garantizando un YAML válido antes de la inyección.

sed -i '/^node_commands:/r ...' ~/.coregui/config.yaml: Busca la directiva de comandos y anexa debajo un bloque estructurado con las etiquetas !NodeCommand, asociando comandos de bash (wireshark -k -i ethX) a la GUI.Se genera un comando general y se adicionan 4 más para cuatro interfaces que se pueden modificar desde la GUI en el menu Widgets>>Node Commands.

4. Mantenimiento y Limpieza del Emulador
core-cleanup: Herramienta nativa que destruye puentes de red remanentes, interfaces virtuales y finaliza procesos huérfanos de simulaciones previas.

systemctl daemon-reload y systemctl restart core-daemon: Obliga a systemd a releer sus configuraciones para aplicar el nuevo display y reinicia el motor del emulador.
