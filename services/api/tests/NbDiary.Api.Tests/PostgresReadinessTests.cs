using System.Net;
using Testcontainers.PostgreSql;

namespace NbDiary.Api.Tests;

/// <summary>Integration test against a real PostgreSQL in Docker (Testcontainers).</summary>
[Trait("Category", "Integration")]
public sealed class PostgresReadinessTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder("postgres:17-alpine").Build();

    public Task InitializeAsync() => _postgres.StartAsync();

    public Task DisposeAsync() => _postgres.DisposeAsync().AsTask();

    [Fact]
    public async Task Ready_returns_healthy_when_postgres_is_reachable()
    {
        await using var factory = new ApiFactory(_postgres.GetConnectionString());
        using var client = factory.CreateClient();

        var response = await client.GetAsync(new Uri("/health/ready", UriKind.Relative));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
