namespace Crimson.Auth.Models;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Email { get; set; }
    public required string PasswordHash { get; set; }

    // Coarse roles only (e.g. "user", "admin"), comma-separated and baked into
    // token claims. Fine-grained authorization lives in the resource services.
    public string Roles { get; set; } = "user";

    public bool EmailVerified { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
