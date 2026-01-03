
# jackett-ygg-nonturbo

Une image Docker Jackett reconstruite automatiquement chaque jour à 10h avec l’indexer **YggTorrent pour les turbos et non turbos** intégré directement dans le code source de Jackett (fichier `YggTorrent.cs` ajouté dans `src/Jackett.Common/Indexers/Definitions/` avant la compilation).  
L’image est construite à partir des sources officielles de Jackett et publiée sur Docker Hub et GitHub Container Registry.

## Fonctionnement du projet

- Tous les jours à 10h (heure de Paris), un workflow CI :
  - clone le dépôt officiel [`Jackett/Jackett`](https://github.com/Jackett/Jackett)  
  - ajoute le fichier `YggTorrent.cs` dans `src/Jackett.Common/Indexers/Definitions/`  
  - construit Jackett via le Dockerfile fourni dans ce dépôt  
  - pousse une nouvelle image Docker sur Docker Hub et GHCR avec plusieurs tags (par exemple `latest` et la date du build).  

L’objectif est de toujours disposer d’une image Jackett **à jour** avec l’indexer YggTorrent intégré, sans avoir à patcher manuellement le binaire ou les définitions.

## Images Docker disponibles

Les images sont automatiquement publiées sur :

- Docker Hub  
  - `docker.io/frisy/jackett-ygg-nonturbo:latest`  
  - `docker.io/frisy/jackett-ygg-nonturbo:<date>` (ex: `20260103`)
- GitHub Container Registry (GHCR)  
  - `ghcr.io/clemv95/jackett-ygg-nonturbo:latest`  
  - `ghcr.io/clemv95/jackett-ygg-nonturbo:<date>`


## Usage

### CLI

```bash
docker run --rm \
    --name jackett \
    -p 9117:9117 \
    -e PUID=1000 \
    -e PGID=1000 \
    -e UMASK=002 \
    -e TZ="Europe/Paris" \
    -v /<host_folder_config>:/config \
    ghcr.io/clemv95/jackett-ygg-nonturbo:latest
```

Paramètres principaux :

- `PUID` / `PGID` : UID/GID de l’utilisateur sur l’hôte pour les permissions de fichiers.
- `UMASK` : masque de permissions pour les fichiers créés (par défaut `002`).
- `TZ` : fuseau horaire (ex. `Europe/Paris`).
- `/<host_folder_config>` : dossier de configuration persistant sur l’hôte (par exemple `/docker/jackett`).

Ensuite, ouvre un navigateur sur :

- `http://localhost:9117`

### docker-compose

`docker-compose.yml` minimal :

```yaml
services:
  jackett:
    container_name: jackett
    image: ghcr.io/clemv95/jackett-ygg-nonturbo:latest
    ports:
      - "9117:9117"
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Europe/Paris
    volumes:
      - /<host_folder_config>:/config
    restart: unless-stopped
```

Démarrage :

```bash
docker-compose up -d
```

## Configuration

Une fois le conteneur démarré :

- Accède à l’interface web sur `http://localhost:9117`.
- Le répertoire de configuration de Jackett est monté sur `/config` dans le conteneur, correspondant à `/<host_folder_config>` sur l’hôte.
- Les indexers, y compris **YggTorrent turbo et non turbo**, sont configurables via l’interface Jackett :
  - Ajout / modification de trackers
  - Gestion des clés API
  - Paramètres avancés (cache, logs, etc.)
- Ajouter Indexer YGGTorrent
Pour sauvegarder ou migrer la configuration, il suffit de sauvegarder le dossier `/<host_folder_config>` utilisé dans les volumes.
