FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copier les fichiers de solution et de configuration
COPY src/Jackett.sln ./
COPY src/Directory.Build.props ./

# Copier uniquement les fichiers .csproj qui existent
COPY src/Jackett.Common/Jackett.Common.csproj ./Jackett.Common/
COPY src/Jackett.Server/Jackett.Server.csproj ./Jackett.Server/
COPY src/Jackett.Service/Jackett.Service.csproj ./Jackett.Service/
COPY src/Jackett.Updater/Jackett.Updater.csproj ./Jackett.Updater/

# Copier les projets optionnels s'ils existent
COPY src/Jackett.Test/Jackett.Test.csproj ./Jackett.Test/ 2>/dev/null || true
COPY src/Jackett.IntegrationTests/Jackett.IntegrationTests.csproj ./Jackett.IntegrationTests/ 2>/dev/null || true
COPY src/DateTimeRoutines/*.csproj ./DateTimeRoutines/ 2>/dev/null || true

# Restore des dépendances
RUN dotnet restore Jackett.sln

# Copier tout le code source
COPY src/ ./
COPY README.md /README.md
COPY LICENSE /LICENSE

# Build
RUN dotnet build Jackett.Server/Jackett.Server.csproj \
    --configuration Release \
    --framework net9.0 \
    --no-restore

# Publish
RUN dotnet publish Jackett.Server/Jackett.Server.csproj \
    --configuration Release \
    --framework net9.0 \
    --output /app \
    --no-build \
    --no-restore

# Image finale
FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app

# Installer les dépendances système
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copier l'application depuis le stage de build
COPY --from=build /app .

# Créer le répertoire de configuration
RUN mkdir -p /config && \
    chmod 777 /config

# Exposition du port
EXPOSE 9117

# Variables d'environnement
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/config

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:9117/UI/Dashboard || exit 1

# Démarrage
ENTRYPOINT ["dotnet", "Jackett.dll"]
CMD ["--NoRestart", "--NoUpdates", "--DataFolder=/config"]
