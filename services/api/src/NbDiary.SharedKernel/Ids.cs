namespace NbDiary.SharedKernel;

/// <summary>
/// Identifier helpers. Entity IDs are UUIDv7 so they sort by creation time.
/// User-owned rows normally get their ID on the client; the server uses this for its own rows.
/// </summary>
public static class Ids
{
    public static Guid NewId() => Guid.CreateVersion7();

    public static bool IsVersion7(Guid id) => id.Version == 7;
}
