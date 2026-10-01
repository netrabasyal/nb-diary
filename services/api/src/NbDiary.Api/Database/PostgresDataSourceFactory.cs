using Azure.Core;
using Azure.Identity;
using Npgsql;

namespace NbDiary.Api.Database;

/// <summary>
/// Builds the PostgreSQL data source. Locally the connection string carries a password for the
/// Docker database. In Azure there is no password: when <c>Postgres:ManagedIdentityClientId</c> is
/// set, the API signs in with a Microsoft Entra token for its managed identity, refreshed before expiry.
/// </summary>
internal static class PostgresDataSourceFactory
{
    // Token audience for Azure Database for PostgreSQL.
    private static readonly string[] EntraScopes = ["https://ossrdbms-aad.database.windows.net/.default"];

    public static NpgsqlDataSource Create(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Postgres")
            ?? throw new InvalidOperationException("Connection string 'Postgres' is not configured.");
        var builder = new NpgsqlDataSourceBuilder(connectionString);

        var clientId = configuration["Postgres:ManagedIdentityClientId"];
        if (!string.IsNullOrWhiteSpace(clientId))
        {
            var credential = new ManagedIdentityCredential(ManagedIdentityId.FromUserAssignedClientId(clientId));
            builder.UsePeriodicPasswordProvider(
                async (_, cancellationToken) =>
                    (await credential.GetTokenAsync(new TokenRequestContext(EntraScopes), cancellationToken)).Token,
                successRefreshInterval: TimeSpan.FromMinutes(45),
                failureRefreshInterval: TimeSpan.FromSeconds(10));
        }

        return builder.Build();
    }
}
