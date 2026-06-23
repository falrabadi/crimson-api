namespace Crimson.Auth.Models;

public record RegisterRequest(string Email, string Password);

public record LoginRequest(string Email, string Password);

public record UserResponse(Guid Id, string Email, string Roles);
