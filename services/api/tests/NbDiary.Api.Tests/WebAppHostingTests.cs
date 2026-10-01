using System.Net;

namespace NbDiary.Api.Tests;

/// <summary>The API serves the Flutter web build with the headers the browser app needs.</summary>
public sealed class WebAppHostingTests : IDisposable
{
    private const string NoDatabase = "Host=127.0.0.1;Port=1;Database=none;Username=none;Password=none;Timeout=2";
    private readonly string _webRoot = Directory.CreateTempSubdirectory("nbdiary-web").FullName;

    public WebAppHostingTests()
    {
        File.WriteAllText(Path.Combine(_webRoot, "index.html"), "<!DOCTYPE html><title>NB Diary</title>");
        File.WriteAllText(Path.Combine(_webRoot, "main.dart.js"), "console.log('app');");
        File.WriteAllBytes(Path.Combine(_webRoot, "sqlite3.wasm"), [0x00, 0x61, 0x73, 0x6d]);
    }

    public void Dispose() => Directory.Delete(_webRoot, recursive: true);

    private HttpClient CreateClient(out ApiFactory factory)
    {
        factory = new ApiFactory(NoDatabase, _webRoot);
        return factory.CreateClient();
    }

    [Fact]
    public async Task Root_serves_the_app_with_isolation_and_csp_headers()
    {
        using var client = CreateClient(out var factory);
        await using var _ = factory;

        var response = await client.GetAsync(new Uri("/", UriKind.Relative));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Contains("NB Diary", await response.Content.ReadAsStringAsync());
        Assert.Equal("same-origin", response.Headers.GetValues("Cross-Origin-Opener-Policy").Single());
        Assert.Equal("require-corp", response.Headers.GetValues("Cross-Origin-Embedder-Policy").Single());
        Assert.Contains("frame-ancestors 'none'", response.Headers.GetValues("Content-Security-Policy").Single());
        Assert.Equal("no-cache", response.Headers.CacheControl?.ToString());
    }

    [Fact]
    public async Task Deep_links_fall_back_to_the_app()
    {
        using var client = CreateClient(out var factory);
        await using var _ = factory;

        var response = await client.GetAsync(new Uri("/gym", UriKind.Relative));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Contains("NB Diary", await response.Content.ReadAsStringAsync());
    }

    [Theory]
    [InlineData("/v1/does-not-exist")]
    [InlineData("/health/unknown")]
    [InlineData("/auth/unknown")]
    public async Task Api_routes_never_fall_back_to_the_app(string path)
    {
        using var client = CreateClient(out var factory);
        await using var _ = factory;

        var response = await client.GetAsync(new Uri(path, UriKind.Relative));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task WebAssembly_is_served_with_its_mime_type()
    {
        using var client = CreateClient(out var factory);
        await using var _ = factory;

        var response = await client.GetAsync(new Uri("/sqlite3.wasm", UriKind.Relative));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("application/wasm", response.Content.Headers.ContentType?.MediaType);
    }

    [Fact]
    public async Task Without_a_web_build_the_root_is_not_found()
    {
        await using var factory = new ApiFactory(NoDatabase);
        using var client = factory.CreateClient();

        var response = await client.GetAsync(new Uri("/", UriKind.Relative));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
