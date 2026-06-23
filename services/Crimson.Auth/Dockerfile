FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
# Build context is the REPO ROOT so shared /packages references (and global.json) resolve.
COPY . .
RUN dotnet restore services/Crimson.Auth/src/Crimson.Auth.csproj
RUN dotnet publish services/Crimson.Auth/src/Crimson.Auth.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Crimson.Auth.dll"]
