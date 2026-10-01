using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace NbDiary.Api.Tests;

/// <summary>Hosts the API in memory with a chosen PostgreSQL connection string and, optionally, a web root.</summary>
public sealed class ApiFactory(string connectionString, string? webRoot = null) : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:Postgres", connectionString);
        if (webRoot is not null)
        {
            builder.UseWebRoot(webRoot);
        }
    }
}
