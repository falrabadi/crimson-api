using Crimson.Auth.Data;
using Crimson.Auth.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Crimson.Auth.Services;

public record AuthResult(bool Succeeded, string? Error = null, UserResponse? User = null);

public interface IAuthService
{
    Task<AuthResult> RegisterAsync(RegisterRequest request, CancellationToken ct = default);
    Task<AuthResult> LoginAsync(LoginRequest request, CancellationToken ct = default);
}

public class AuthService(AuthDbContext db, IPasswordHasher<User> passwordHasher) : IAuthService
{
    public async Task<AuthResult> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        var email = Normalize(request.Email);
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(request.Password))
            return new AuthResult(false, "Email and password are required.");

        if (await db.Users.AnyAsync(u => u.Email == email, ct))
            return new AuthResult(false, "An account with that email already exists.");

        var user = new User { Email = email, PasswordHash = string.Empty };
        user.PasswordHash = passwordHasher.HashPassword(user, request.Password);

        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        return new AuthResult(true, User: ToResponse(user));
    }

    public async Task<AuthResult> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var email = Normalize(request.Email);
        var user = await db.Users.SingleOrDefaultAsync(u => u.Email == email, ct);

        // Same generic error whether the account is unknown or the password is
        // wrong, so we never reveal which emails are registered.
        if (user is null)
            return new AuthResult(false, "Invalid email or password.");

        var verification = passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);
        if (verification == PasswordVerificationResult.Failed)
            return new AuthResult(false, "Invalid email or password.");

        return new AuthResult(true, User: ToResponse(user));
    }

    private static string Normalize(string email) => email.Trim().ToLowerInvariant();

    private static UserResponse ToResponse(User user) => new(user.Id, user.Email, user.Roles);
}
