using System.Security.Claims;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using PlateRaterAPI;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDb>(o => o.UseSqlServer(builder.Configuration.GetConnectionString("PlateRater")));

// The iOS app signs in with Google and sends the Google ID token as a bearer token.
// It is checked against Google's signing keys and must be issued for one of our client IDs.
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.Authority = "https://accounts.google.com";
        o.MapInboundClaims = false;
        o.TokenValidationParameters.ValidIssuers = ["https://accounts.google.com", "accounts.google.com"];
        o.TokenValidationParameters.ValidAudiences = builder.Configuration.GetSection("Google:ClientIds").Get<string[]>();
    });
builder.Services.AddAuthorization();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => "PlateRater API is running.");

var api = app.MapGroup("/api").RequireAuthorization();

api.MapGet("/plates/{plate}", async (string plate, ClaimsPrincipal principal, AppDb db) =>
{
    plate = Plates.Normalize(plate);
    if (!Plates.IsValid(plate)) return Results.BadRequest(new { error = "Invalid plate." });

    var me = await CurrentUser(principal, db);
    var rows = await db.Ratings
        .Where(r => r.Plate == plate)
        .OrderByDescending(r => r.UpdatedAt)
        .ToListAsync();

    var ratings = rows.Select(r => new RatingDto(r.Id, r.Score, r.Comment, Utc(r.UpdatedAt), r.UserId == me.Id)).ToList();
    var mine = ratings.FirstOrDefault(r => r.IsMine);
    double? average = rows.Count == 0 ? null : Math.Round(rows.Average(r => r.Score), 2);

    return Results.Ok(new PlateDto(plate, average, rows.Count, mine, ratings.Take(100).ToList()));
});

// Each account has one rating per plate; posting again updates it.
api.MapPut("/plates/{plate}/rating", async (string plate, RatingInput input, ClaimsPrincipal principal, AppDb db) =>
{
    plate = Plates.Normalize(plate);
    if (!Plates.IsValid(plate)) return Results.BadRequest(new { error = "Invalid plate." });
    if (input.Score is < 1 or > 5) return Results.BadRequest(new { error = "Score must be 1 to 5." });
    var comment = (input.Comment ?? "").Trim();
    if (comment.Length > 500) return Results.BadRequest(new { error = "Comment is too long." });

    var me = await CurrentUser(principal, db);
    var now = DateTime.UtcNow;
    var rating = await db.Ratings.SingleOrDefaultAsync(r => r.Plate == plate && r.UserId == me.Id);
    if (rating == null)
    {
        rating = new Rating { Plate = plate, UserId = me.Id, CreatedAt = now };
        db.Ratings.Add(rating);
    }
    rating.Score = input.Score;
    rating.Comment = comment;
    rating.UpdatedAt = now;
    await db.SaveChangesAsync();

    return Results.Ok(new RatingDto(rating.Id, rating.Score, rating.Comment, Utc(rating.UpdatedAt), true));
});

api.MapDelete("/plates/{plate}/rating", async (string plate, ClaimsPrincipal principal, AppDb db) =>
{
    plate = Plates.Normalize(plate);
    var me = await CurrentUser(principal, db);
    await db.Ratings.Where(r => r.Plate == plate && r.UserId == me.Id).ExecuteDeleteAsync();
    return Results.NoContent();
});

app.Run();

// Finds the signed-in Google account in the database, adding it on first use.
static async Task<User> CurrentUser(ClaimsPrincipal principal, AppDb db)
{
    var subject = principal.FindFirstValue("sub")!;
    var user = await db.Users.SingleOrDefaultAsync(u => u.GoogleSubject == subject);
    if (user == null)
    {
        user = new User { GoogleSubject = subject, CreatedAt = DateTime.UtcNow };
        db.Users.Add(user);
    }
    user.Email = principal.FindFirstValue("email");
    user.Name = principal.FindFirstValue("name");
    await db.SaveChangesAsync();
    return user;
}

// Whole seconds in UTC, so the app gets plain ISO 8601 dates like 2026-10-25T21:00:00Z.
static DateTime Utc(DateTime value) => new(value.Ticks - value.Ticks % TimeSpan.TicksPerSecond, DateTimeKind.Utc);

record RatingInput(int Score, string? Comment);
record RatingDto(int Id, int Score, string Comment, DateTime UpdatedAt, bool IsMine);
record PlateDto(string Plate, double? Average, int Count, RatingDto? MyRating, List<RatingDto> Ratings);

static partial class Plates
{
    public static string Normalize(string raw) =>
        string.Concat(raw.Where(c => !char.IsWhiteSpace(c))).ToUpperInvariant();

    // Swedish plates: ABC123 (old format) or ABC12D (since 2019).
    public static bool IsValid(string plate) => PlatePattern().IsMatch(plate);

    [GeneratedRegex("^[A-ZÅÄÖ]{3}[0-9]{2}[0-9A-ZÅÄÖ]$")]
    private static partial Regex PlatePattern();
}
