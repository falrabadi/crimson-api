using Crimson.Auth.Data;
using Crimson.Auth.Models;
using Crimson.Auth.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddHealthChecks();

builder.Services.AddDbContext<AuthDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Postgres")));

// PasswordHasher is stateless — safe as a singleton.
builder.Services.AddSingleton<IPasswordHasher<User>, PasswordHasher<User>>();
builder.Services.AddScoped<IAuthService, AuthService>();

var app = builder.Build();

// TLS is terminated at the ingress in front of the cluster, so the container
// speaks plain HTTP on 8080 — no in-app HTTPS redirect needed.
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();

// Exposed so integration tests can boot the app via WebApplicationFactory<Program>.
public partial class Program;
