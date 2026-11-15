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

app.MapGet("/", () => "Galen API is running.");

var api = app.MapGroup("/api").RequireAuthorization();

api.MapGet("/plates/{plate}", async (string plate, ClaimsPrincipal principal, AppDb db) =>
{
    plate = Plates.Normalize(plate);
    if (!Plates.IsValid(plate)) return Results.BadRequest(new { error = "Ogiltig registreringsskylt." });

    var me = await CurrentUser(principal, db);
    var rows = await db.Ratings
        .Where(r => r.Plate == plate)
        .OrderByDescending(r => r.UpdatedAt)
        .Select(r => new { Rating = r, HasPhoto = db.Photos.Any(p => p.RatingId == r.Id) })
        .ToListAsync();

    // Photos are private: others only see that a rating exists, never its photo.
    var ratings = rows.Select(x => ToDto(x.Rating, me, x.HasPhoto)).ToList();
    var mine = ratings.FirstOrDefault(r => r.IsMine);
    double? average = rows.Count == 0 ? null : Math.Round(rows.Average(x => x.Rating.Score), 2);

    return Results.Ok(new PlateDto(plate, average, rows.Count, mine, ratings.Take(100).ToList()));
});

// Each account has one rating per plate; posting again updates it.
api.MapPut("/plates/{plate}/rating", async (string plate, RatingInput input, ClaimsPrincipal principal, AppDb db) =>
{
    plate = Plates.Normalize(plate);
    if (!Plates.IsValid(plate)) return Results.BadRequest(new { error = "Ogiltig registreringsskylt." });
    if (input.Score is < 1 or > 5) return Results.BadRequest(new { error = "Betyget måste vara 1 till 5." });
    var comment = (input.Comment ?? "").Trim();
    if (comment.Length > 500) return Results.BadRequest(new { error = "Kommentaren är för lång." });
    var color = string.IsNullOrWhiteSpace(input.Color) ? null : input.Color.Trim().ToLowerInvariant();
    if (color != null && !CarColors.All.Contains(color)) return Results.BadRequest(new { error = "Okänd bilfärg." });

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
    rating.Color = color;
    rating.UpdatedAt = now;
    await db.SaveChangesAsync();

    return Results.Ok(ToDto(rating, me, await db.Photos.AnyAsync(p => p.RatingId == rating.Id)));
});

api.MapDelete("/plates/{plate}/rating", async (string plate, ClaimsPrincipal principal, AppDb db) =>
{
    plate = Plates.Normalize(plate);
    var me = await CurrentUser(principal, db);
    // The photo row goes with it (ON DELETE CASCADE in the database).
    await db.Ratings.Where(r => r.Plate == plate && r.UserId == me.Id).ExecuteDeleteAsync();
    return Results.NoContent();
});

// One photo per rating, stored in the database. Only the person who took it can see it.
api.MapPut("/plates/{plate}/rating/photo", async (string plate, HttpRequest request, ClaimsPrincipal principal, AppDb db) =>
{
    if (request.ContentType is not ("image/jpeg" or "image/png"))
        return Results.BadRequest(new { error = "Bilden måste vara JPEG eller PNG." });
    if (request.ContentLength is > Photo.MaxBytes)
        return Results.BadRequest(new { error = "Bilden är för stor." });

    var rating = await MyRating(plate, principal, db);
    if (rating == null) return Results.NotFound(new { error = "Betygsätt bilen innan du lägger till en bild." });

    using var buffer = new MemoryStream();
    await request.Body.CopyToAsync(buffer);
    if (buffer.Length == 0 || buffer.Length > Photo.MaxBytes)
        return Results.BadRequest(new { error = "Bilden är tom eller för stor." });

    var photo = await db.Photos.FindAsync(rating.Id);
    if (photo == null)
    {
        photo = new Photo { RatingId = rating.Id };
        db.Photos.Add(photo);
    }
    photo.Data = buffer.ToArray();
    photo.ContentType = request.ContentType;
    photo.CreatedAt = DateTime.UtcNow;
    await db.SaveChangesAsync();
    return Results.NoContent();
});

api.MapGet("/plates/{plate}/rating/photo", async (string plate, ClaimsPrincipal principal, AppDb db) =>
{
    var rating = await MyRating(plate, principal, db);
    var photo = rating == null ? null : await db.Photos.FindAsync(rating.Id);
    return photo == null ? Results.NotFound() : Results.File(photo.Data, photo.ContentType);
});

api.MapDelete("/plates/{plate}/rating/photo", async (string plate, ClaimsPrincipal principal, AppDb db) =>
{
    var rating = await MyRating(plate, principal, db);
    if (rating != null) await db.Photos.Where(p => p.RatingId == rating.Id).ExecuteDeleteAsync();
    return Results.NoContent();
});

// Everything the signed-in user has rated, newest first, for "Mina betyg" and the color hunt.
api.MapGet("/me/ratings", async (ClaimsPrincipal principal, AppDb db) =>
{
    var me = await CurrentUser(principal, db);
    var rows = await db.Ratings
        .Where(r => r.UserId == me.Id)
        .OrderByDescending(r => r.UpdatedAt)
        .Select(r => new { Rating = r, HasPhoto = db.Photos.Any(p => p.RatingId == r.Id) })
        .ToListAsync();

    var ratings = rows.Select(x => new MyRatingDto(
        x.Rating.Plate, x.Rating.Score, x.Rating.Comment, x.Rating.Color, x.HasPhoto, Utc(x.Rating.UpdatedAt))).ToList();
    return Results.Ok(new MyRatingsDto(ratings.Count, ratings));
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

static async Task<Rating?> MyRating(string plate, ClaimsPrincipal principal, AppDb db)
{
    plate = Plates.Normalize(plate);
    var me = await CurrentUser(principal, db);
    return await db.Ratings.SingleOrDefaultAsync(r => r.Plate == plate && r.UserId == me.Id);
}

// Everyone sees the car color; the photo flag is only set on your own rating.
static RatingDto ToDto(Rating r, User me, bool hasPhoto)
{
    var isMine = r.UserId == me.Id;
    return new RatingDto(r.Id, r.Score, r.Comment, r.Color, isMine && hasPhoto, Utc(r.UpdatedAt), isMine);
}

// Whole seconds in UTC, so the app gets plain ISO 8601 dates like 2026-10-25T21:00:00Z.
static DateTime Utc(DateTime value) => new(value.Ticks - value.Ticks % TimeSpan.TicksPerSecond, DateTimeKind.Utc);

record RatingInput(int Score, string? Comment, string? Color);
record RatingDto(int Id, int Score, string Comment, string? Color, bool HasPhoto, DateTime UpdatedAt, bool IsMine);
record MyRatingDto(string Plate, int Score, string Comment, string? Color, bool HasPhoto, DateTime UpdatedAt);
record MyRatingsDto(int Count, List<MyRatingDto> Ratings);

// The colors the app offers. Keep in sync with CarColor in the iOS app.
static class CarColors
{
    public static readonly HashSet<string> All =
        ["white", "black", "grey", "silver", "red", "blue", "green", "yellow", "orange", "brown", "purple", "pink"];
}
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
