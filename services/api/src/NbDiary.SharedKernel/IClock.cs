namespace NbDiary.SharedKernel;

/// <summary>Source of the current time. Always UTC, so modules never call DateTime.Now directly.</summary>
public interface IClock
{
    DateTimeOffset UtcNow { get; }
}

public sealed class SystemClock : IClock
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}
