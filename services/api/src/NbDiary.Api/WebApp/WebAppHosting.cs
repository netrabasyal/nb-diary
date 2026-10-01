using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Net.Http.Headers;

namespace NbDiary.Api.WebApp;

/// <summary>
/// Serves the Flutter web app from wwwroot on the same address as the API, with the
/// browser security headers the app needs. See docs/decisions.md ADR-003.
/// </summary>
internal static class WebAppHosting
{
    // Flutter's CanvasKit and Drift's SQLite run as WebAssembly ('wasm-unsafe-eval').
    // Flutter injects its own styles ('unsafe-inline' for styles only). Everything else is same-origin.
    internal const string ContentSecurityPolicy =
        "default-src 'self'; " +
        "script-src 'self' 'wasm-unsafe-eval'; " +
        "style-src 'self' 'unsafe-inline'; " +
        "img-src 'self' data: blob:; " +
        "font-src 'self' data:; " +
        "connect-src 'self'; " +
        "worker-src 'self' blob:; " +
        "manifest-src 'self'; " +
        "base-uri 'self'; " +
        "form-action 'self'; " +
        "frame-ancestors 'none'; " +
        "object-src 'none'";

    // Files that must always be revalidated so a new release is picked up.
    private static readonly HashSet<string> AlwaysRevalidate = new(StringComparer.OrdinalIgnoreCase)
    {
        "/index.html", "/nb_service_worker.js", "/flutter_bootstrap.js", "/manifest.json", "/version.json",
    };

    // Routes that belong to the API and must never fall back to the web app.
    private const string FallbackRoute = "{*path:regex(^(?!v1/|v1$|auth/|health/).*$)}";

    public static WebApplication UseSecurityHeaders(this WebApplication app)
    {
        app.Use(async (context, next) =>
        {
            var headers = context.Response.Headers;
            headers.XContentTypeOptions = "nosniff";
            headers["Referrer-Policy"] = "no-referrer";
            // Cross-origin isolation lets Drift use the browser's fastest storage (OPFS).
            headers["Cross-Origin-Opener-Policy"] = "same-origin";
            headers["Cross-Origin-Embedder-Policy"] = "require-corp";
            headers["Cross-Origin-Resource-Policy"] = "same-origin";
            headers.ContentSecurityPolicy = ContentSecurityPolicy;
            await next(context);
        });
        return app;
    }

    private static bool HasWebBuild(WebApplication app) =>
        app.Environment.WebRootFileProvider.GetFileInfo("index.html").Exists;

    /// <summary>
    /// Serves files from wwwroot when a web build is present (it isn't in local API-only runs).
    /// Must run before routing: static files are skipped once an endpoint has been selected.
    /// </summary>
    public static WebApplication UseWebAppFiles(this WebApplication app)
    {
        if (!HasWebBuild(app))
        {
            return app;
        }

        var contentTypes = new FileExtensionContentTypeProvider();
        contentTypes.Mappings[".wasm"] = "application/wasm";
        contentTypes.Mappings[".mjs"] = "text/javascript";
        contentTypes.Mappings[".frag"] = "application/octet-stream";
        contentTypes.Mappings[".bin"] = "application/octet-stream";
        contentTypes.Mappings[".otf"] = "font/otf";
        contentTypes.Mappings[".ttf"] = "font/ttf";

        app.UseDefaultFiles();
        app.UseStaticFiles(new StaticFileOptions
        {
            ContentTypeProvider = contentTypes,
            OnPrepareResponse = context =>
            {
                var path = context.Context.Request.Path.Value ?? string.Empty;
                context.Context.Response.Headers.CacheControl =
                    AlwaysRevalidate.Contains(path) || path == "/" ? "no-cache" : "public, max-age=3600";
            },
        });

        return app;
    }

    /// <summary>Deep links such as /gym load the app, which then routes on the client.</summary>
    public static WebApplication MapWebAppFallback(this WebApplication app)
    {
        if (!HasWebBuild(app))
        {
            return app;
        }

        app.MapFallbackToFile(FallbackRoute, "index.html", new StaticFileOptions
        {
            OnPrepareResponse = context => context.Context.Response.Headers.CacheControl = "no-cache",
        });

        return app;
    }
}
