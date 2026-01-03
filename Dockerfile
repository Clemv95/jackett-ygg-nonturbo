FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY src/*.sln ./
COPY src/Directory.Build.props ./
COPY src/Jackett.Common/*.csproj ./Jackett.Common/
COPY src/Jackett.Server/*.csproj ./Jackett.Server/
COPY src/Jackett.Service/*.csproj ./Jackett.Service/
COPY src/Jackett.Updater/*.csproj ./Jackett.Updater/
COPY src/Jackett.Test/*.csproj ./Jackett.Test/
COPY src/Jackett.Tray/*.csproj ./Jackett.Tray/
COPY src/Jackett.IntegrationTests/*.csproj ./Jackett.IntegrationTests/
COPY src/DateTimeRoutines/*.csproj ./DateTimeRoutines/

RUN dotnet restore Jackett.sln

COPY src/ ./

COPY README.md /README.md
COPY LICENSE /LICENSE

RUN dotnet build Jackett.Server/Jackett.Server.csproj \
    --configuration Release \
    --framework net9.0 \
    --no-restore

RUN dotnet publish Jackett.Server/Jackett.Server.csproj \
    --configuration Release \
    --framework net9.0 \
    --output /app \
    --no-build \
    --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /app .
# Créer le répertoire config avec permissions larges
RUN mkdir -p /config && \
    chmod -R 777 /config

# Script d'entrypoint pour gérer PUID/PGID
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9117

ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/config
ENV PUID=1000
ENV PGID=1000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:9117/UI/Dashboard || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["dotnet", "/app/jackett.dll", "--NoRestart", "--NoUpdates", "--DataFolder=/config"]
