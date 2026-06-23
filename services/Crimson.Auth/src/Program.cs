using Crimson.Auth.Data;
using Crimson.Auth.Models;
using Crimson.Auth.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddHealthChecks();

// OpenAPI/Swagger document generation (the UI is enabled only in Development below).
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<AuthDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Postgres")));

// PasswordHasher is stateless — safe as a singleton.
builder.Services.AddSingleton<IPasswordHasher<User>, PasswordHasher<User>>();
builder.Services.AddScoped<IAuthService, AuthService>();

var app = builder.Build();

// In development, apply EF migrations on startup so `docker compose` / F5 just
// works. In production, migrations run as a separate, controlled deploy step.
if (app.Environment.IsDevelopment() &&
    builder.Configuration.GetConnectionString("Postgres") is not null)
{
    using var scope = app.Services.CreateScope();
    scope.ServiceProvider.GetRequiredService<AuthDbContext>().Database.Migrate();
}

// Swagger UI for interactive API exploration — Development only, since exposing
// an auth service's full API surface in production is a recon aid for attackers.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// TLS is terminated at the ingress in front of the cluster, so the container
// speaks plain HTTP on 8080 — no in-app HTTPS redirect needed.
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();

// Exposed so integration tests can boot the app via WebApplicationFactory<Program>.
public partial class Program;
