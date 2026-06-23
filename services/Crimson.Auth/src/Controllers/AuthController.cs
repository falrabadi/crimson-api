using Crimson.Auth.Models;
using Crimson.Auth.Services;
using Microsoft.AspNetCore.Mvc;

namespace Crimson.Auth.Controllers;

[ApiController]
public class AuthController(IAuthService authService) : ControllerBase
{
    [HttpPost("/register")]
    public async Task<IActionResult> Register(RegisterRequest request, CancellationToken ct)
    {
        var result = await authService.RegisterAsync(request, ct);
        return result.Succeeded
            ? Created($"/users/{result.User!.Id}", result.User)
            : BadRequest(new { error = result.Error });
    }

    [HttpPost("/login")]
    public async Task<IActionResult> Login(LoginRequest request, CancellationToken ct)
    {
        var result = await authService.LoginAsync(request, ct);
        return result.Succeeded
            ? Ok(result.User)
            : Unauthorized(new { error = result.Error });
    }
}
