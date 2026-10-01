using NetArchTest.Rules;
using NbDiary.SharedKernel;

namespace NbDiary.ArchitectureTests;

/// <summary>
/// Guards the modular-monolith boundaries. Each module added later gets a rule here
/// stopping other modules from referencing its internals.
/// </summary>
public sealed class LayeringTests
{
    [Fact]
    public void Shared_kernel_does_not_depend_on_the_api_host()
    {
        var result = Types.InAssembly(typeof(IClock).Assembly)
            .ShouldNot()
            .HaveDependencyOn("NbDiary.Api")
            .GetResult();

        Assert.True(result.IsSuccessful, FailingTypes(result));
    }

    [Fact]
    public void Shared_kernel_does_not_depend_on_infrastructure_libraries()
    {
        var result = Types.InAssembly(typeof(IClock).Assembly)
            .ShouldNot()
            .HaveDependencyOnAny("Npgsql", "Microsoft.EntityFrameworkCore", "Microsoft.AspNetCore")
            .GetResult();

        Assert.True(result.IsSuccessful, FailingTypes(result));
    }

    private static string FailingTypes(TestResult result) =>
        "Violations: " + string.Join(", ", result.FailingTypeNames ?? []);
}
