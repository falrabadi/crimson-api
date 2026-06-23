using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Crimson.Auth.Data;

// Used ONLY by EF Core tooling (`dotnet ef migrations`). At runtime the
// connection string comes from configuration (see Program.cs); this hardcoded
// one just lets the tooling build the model without a running database.
public class AuthDbContextFactory : IDesignTimeDbContextFactory<AuthDbContext>
{
    public AuthDbContext CreateDbContext(string[] args)
    {
        var options = new DbContextOptionsBuilder<AuthDbContext>()
            .UseNpgsql("Host=localhost;Database=crimson_auth;Username=postgres;Password=postgres")
            .Options;

        return new AuthDbContext(options);
    }
}
