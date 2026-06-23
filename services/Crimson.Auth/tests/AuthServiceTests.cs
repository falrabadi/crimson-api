using Crimson.Auth.Data;
using Crimson.Auth.Models;
using Crimson.Auth.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace Crimson.Auth.Tests;

public class AuthServiceTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AuthDbContext _db;
    private readonly AuthService _sut;

    public AuthServiceTests()
    {
        // SQLite in-memory keeps a real schema (incl. the unique email index),
        // so it exercises relational behavior the EF in-memory provider can't.
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AuthDbContext>()
            .UseSqlite(_connection)
            .Options;

        _db = new AuthDbContext(options);
        _db.Database.EnsureCreated();

        _sut = new AuthService(_db, new PasswordHasher<User>());
    }

    [Fact]
    public async Task Register_persists_user_with_normalized_email_and_hashed_password()
    {
        var result = await _sut.RegisterAsync(new RegisterRequest("Alice@Example.com", "s3cret-pw"));

        Assert.True(result.Succeeded);
        var user = await _db.Users.SingleAsync();
        Assert.Equal("alice@example.com", user.Email);   // normalized to lowercase
        Assert.NotEmpty(user.PasswordHash);
        Assert.NotEqual("s3cret-pw", user.PasswordHash);  // never stored in plaintext
    }

    [Fact]
    public async Task Register_rejects_duplicate_email_case_insensitively()
    {
        await _sut.RegisterAsync(new RegisterRequest("bob@example.com", "pw-123456"));

        var second = await _sut.RegisterAsync(new RegisterRequest("BOB@example.com", "different"));

        Assert.False(second.Succeeded);
        Assert.Equal(1, await _db.Users.CountAsync());
    }

    [Fact]
    public async Task Login_succeeds_with_correct_password()
    {
        await _sut.RegisterAsync(new RegisterRequest("carol@example.com", "correct-horse"));

        var result = await _sut.LoginAsync(new LoginRequest("carol@example.com", "correct-horse"));

        Assert.True(result.Succeeded);
        Assert.Equal("carol@example.com", result.User!.Email);
    }

    [Fact]
    public async Task Login_fails_with_wrong_password()
    {
        await _sut.RegisterAsync(new RegisterRequest("dave@example.com", "right-password"));

        var result = await _sut.LoginAsync(new LoginRequest("dave@example.com", "wrong-password"));

        Assert.False(result.Succeeded);
    }

    [Fact]
    public async Task Login_fails_for_unknown_user()
    {
        var result = await _sut.LoginAsync(new LoginRequest("nobody@example.com", "whatever"));

        Assert.False(result.Succeeded);
    }

    public void Dispose()
    {
        _db.Dispose();
        _connection.Dispose();
    }
}
