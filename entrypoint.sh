#!/bin/bash
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Créer le groupe et l'utilisateur avec les UID/GID spécifiés
groupadd -g "$PGID" jackett 2>/dev/null || true
useradd -u "$PUID" -g "$PGID" -s /bin/bash -m jackett 2>/dev/null || true

# S'assurer que /config appartient à l'utilisateur jackett
chown -R "$PUID":"$PGID" /config /app

# Exécuter la commande en tant qu'utilisateur jackett
exec gosu jackett "$@"
