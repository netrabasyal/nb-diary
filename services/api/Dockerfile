# Build from services/api:  docker build -t nbdiary-api .
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY global.json Directory.Build.props NbDiary.slnx ./
COPY src/ src/
RUN dotnet publish src/NbDiary.Api/NbDiary.Api.csproj -c Release -o /app/publish

# Chiseled image: no shell or package manager, runs as a non-root user.
FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "NbDiary.Api.dll"]
