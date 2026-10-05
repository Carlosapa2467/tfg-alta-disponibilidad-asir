#!/bin/bash
# Backup semanal de Grafana con notificación por Telegram.
# crontab:  0 2 * * 0 /opt/scripts/backup_grafana.sh >> /var/log/backup_grafana.log 2>&1
#
# El token y el chat ID se leen de un fichero aparte (permisos 600), nunca se escriben en el script:
#   /etc/grafana-backup.env
#     TELEGRAM_BOT_TOKEN="..."
#     CHAT_ID="..."

set -u
source /etc/grafana-backup.env

# === CONFIGURACIÓN ===
BACKUP_DIR="/opt/backups/grafana"
DATE=$(date +%Y-%m-%d_%H-%M)
FILE_NAME="grafana_backup_$DATE.tar.gz"
LOG_FILE="/var/log/grafana_backup.log"
GRAFANA_DB="/var/lib/grafana/grafana.db"
GRAFANA_CONFIG_DIR="/etc/grafana"

# === FUNCIONES ===
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" \
         -d text="$message" > /dev/null
}

# === INICIO ===
log "Iniciando proceso de backup de Grafana"
mkdir -p "$BACKUP_DIR"

# Eliminar backups anteriores para no llenar el disco
log "Eliminando backups anteriores..."
find "$BACKUP_DIR" -type f -name "grafana_backup_*.tar.gz" -exec rm -f {} \;

# Comprobar que existe lo que se va a copiar
if [ ! -f "$GRAFANA_DB" ]; then
    log "Error: no se encontró la base de datos: $GRAFANA_DB"
    send_telegram_message "❌ Error: no se encontró la base de datos de Grafana"
    exit 1
fi
if [ ! -d "$GRAFANA_CONFIG_DIR" ]; then
    log "Error: no se encontró el directorio de configuración: $GRAFANA_CONFIG_DIR"
    send_telegram_message "❌ Error: no se encontró la configuración de Grafana"
    exit 1
fi

# Crear backup
log "Creando archivo de backup..."
if tar -czf "$BACKUP_DIR/$FILE_NAME" "$GRAFANA_DB" "$GRAFANA_CONFIG_DIR"; then
    log "Backup creado correctamente: $FILE_NAME"
    send_telegram_message "✅ Backup de Grafana realizado: $FILE_NAME"
else
    log "Error al crear el backup"
    send_telegram_message "❌ Error al crear el backup de Grafana"
    exit 1
fi
