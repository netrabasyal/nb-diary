using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using NbDiary.Api.Database;
using NbDiary.Api.Health;
using NbDiary.Api.WebApp;
using NbDiary.SharedKernel;

var builder = WebApplication.CreateBuilder(args);

if (!builder.Environment.IsDevelopment())
{
    // Structured JSON logs in Azure; readable console logs locally.
    builder.Logging.ClearProviders();
    builder.Logging.AddJsonConsole();
}

builder.Services.AddSingleton<IClock, SystemClock>();
builder.Services.AddSingleton(services =>
    PostgresDataSourceFactory.Create(services.GetRequiredService<IConfiguration>()));

builder.Services.AddProblemDetails();
builder.Services.AddOpenApi("v1");
builder.Services.AddHealthChecks()
    .AddCheck<PostgresHealthCheck>("postgres", tags: ["ready"]);

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseSecurityHeaders();
app.UseWebAppFiles();
app.UseRouting();

// Liveness: the process is up. No dependencies, no details.
app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false });

// Readiness: the API can reach its database.
app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = check => check.Tags.Contains("ready") });

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapWebAppFallback();

app.Run();

/// <summary>Entry point, exposed for integration tests.</summary>
public partial class Program;
