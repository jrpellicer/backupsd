#!/bin/bash

# Directorios de montaje
mount_dir_disco="/mnt/disco"
mount_dir_tarjeta="/mnt/tarjeta"

# Desmontamos posibles unidades
sudo umount "$mount_dir_disco" 2> /dev/null
sudo umount "$mount_dir_tarjeta" 2> /dev/null
sudo umount /dev/sdb1
sudo umount /dev/sda1

# Tamaño mínimo de la partición de disco en GB
min_size_gb=900

# Verificar si los directorios de montaje existen, si no, se crean
if [ ! -d "$mount_dir_disco" ]; then
    sudo mkdir -p "$mount_dir_disco"
fi

if [ ! -d "$mount_dir_tarjeta" ]; then
    sudo mkdir -p "$mount_dir_tarjeta"
fi

echo "Obteniendo lista de dispositivos"
# Obtener una lista de dispositivos
devices=$(lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT -lnpb -I 8,9,179,253)

# Iterar sobre la lista de dispositivos
while IFS= read -r line; do
    # Obtener el nombre del dispositivo, el tipo de sistema de archivos, tamaño de la partición y punto montaje
    device=$(echo "$line" | awk '{print $1}')
    fstype=$(echo "$line" | awk '{print $2}')
    size_gb=$(echo "$line" | awk '{print int($3/1000000)}')  # Convertir tamaño de Bytes a GB
    mountpoint=$(echo "$line" | awk '{print $4}')

    # Verificar si el dispositivo tiene un sistema de archivos NTFS y el tamaño es mayor que 900 GB
    if [ "$fstype" == "vfat" ] && [ "$size_gb" -gt "$min_size_gb" ]; then
        # Montar el dispositivo en el directorio especificado
        sudo umount "$device"
        sleep 2
        sudo mount -t vfat -w "$device" "$mount_dir_disco"
        echo "Disco NTFS de más de $min_size_gb GB montado en $mount_dir_disco"
    fi

    # Verificar si el dispositivo tiene un sistema de archivos vfat
    if [ "$fstype" == "vfat" ] && [ "$mountpoint" == "" ]; then
        echo "Intentado montar tarjeta"
        # Montar el dispositivo en el directorio especificado
        sudo mount -t vfat "$device" "$mount_dir_tarjeta"
        echo "Dispositivo $device montado en $mount_dir_tarjeta"
    fi

done <<< "$devices"

echo "Comprobar que existe directorio /mnt/disco/backupsd"
# Comprobamos que en el disco existe el directorio backup
if [ ! -d "/mnt/disco/backupsd" ]; then
    echo "No existe el directorio backupsd en disco. Imposible continuar"
    exit 1
fi

# Obtenemos fecha y hora para nombre fichero
fecha_hora=$(date +%Y%m%d-%H%M)
dir_destino="$mount_dir_disco/backupsd/$fecha_hora"

# Creamos directorio para copia de seguridad actual
mkdir "$dir_destino"

# Copiamos contenido tarjeta SD a directorio Backup
echo "Copiando a $dir_destino ..."
cp /mnt/tarjeta/DCIM/* "$dir_destino" -r
echo "Terminado"
sleep 5
