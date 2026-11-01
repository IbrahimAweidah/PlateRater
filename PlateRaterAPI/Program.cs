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

app.MapGet("/", () => "Biljakt API is running.");

var api = app.MapGroup("/api").RequireAuthorization();

api.MapGet("/plates/{plate}", async (string plate, ClaimsPrincipal principal, AppDb db) =>
{
    plate = Plates.Normalize(plate);
    if (!Plates.IsValid(plate)) return Results.BadRequest(new { error = "Ogiltig registreringsskylt." });

    // Ratings are private: you only ever get your own rating back, never anyone else's.
    var me = await CurrentUser(principal, db);
    var mine = await db.Ratings
        .Where(r => r.Plate == plate && r.UserId == me.Id)
        .Select(r => new { Rating = r, HasPhoto = db.Photos.Any(p => p.RatingId == r.Id) })
        .SingleOrDefaultAsync();

    return Results.Ok(new PlateDto(plate, mine == null ? null : ToDto(mine.Rating, mine.HasPhoto)));
});

// Each account has one rating per plate; posting again updates it.
api.MapPut("/plates/{plate}/rating", async (string plate, RatingInput input, ClaimsPrincipal principal, AppDb db) =>
{
    plate = Plates.Normalize(plate);
    if (!Plates.IsValid(plate)) return Results.BadRequest(new { error = "Ogiltig registreringsskylt." });
    // The driver score is no longer used by the app (Biljakt). Old clients may still send one.
    if (input.Score is < 1 or > 5) return Results.BadRequest(new { error = "Betyget måste vara 1 till 5." });
    var comment = (input.Comment ?? "").Trim();
    if (comment.Length > 500) return Results.BadRequest(new { error = "Kommentaren är för lång." });
    var color = string.IsNullOrWhiteSpace(input.Color) ? null : input.Color.Trim().ToLowerInvariant();
    if (color != null && !CarColors.All.Contains(color)) return Results.BadRequest(new { error = "Okänd bilfärg." });
    var kind = string.IsNullOrWhiteSpace(input.Kind) ? null : input.Kind.Trim().ToLowerInvariant();
    if (kind != null && !CarKinds.All.Contains(kind)) return Results.BadRequest(new { error = "Okänd sorts bil." });
    var brand = string.IsNullOrWhiteSpace(input.Brand) ? null : input.Brand.Trim().ToLowerInvariant();
    if (brand != null && !CarBrands.All.Contains(brand)) return Results.BadRequest(new { error = "Okänt bilmärke." });

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
    rating.Kind = kind;
    rating.Brand = brand;
    rating.UpdatedAt = now;
    await db.SaveChangesAsync();

    return Results.Ok(ToDto(rating, await db.Photos.AnyAsync(p => p.RatingId == rating.Id)));
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
    if (rating == null) return Results.NotFound(new { error = "Spara bilen innan du lägger till en bild." });

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
        x.Rating.Plate, x.Rating.Score, x.Rating.Comment, x.Rating.Color, x.Rating.Kind, x.Rating.Brand, x.HasPhoto, Utc(x.Rating.UpdatedAt))).ToList();
    return Results.Ok(new MyRatingsDto(ratings.Count, ratings));
});

// Friends: add each other by Google e-mail address and compete in the color and car-kind hunt.
// A friend only ever sees your first name and which colors, kinds and brands of car you have found,
// never your plates, ratings, comments or photos.
api.MapGet("/friends", async (ClaimsPrincipal principal, AppDb db) =>
{
    var me = await CurrentUser(principal, db);
    var links = await db.Friendships
        .Include(f => f.FromUser)
        .Include(f => f.ToUser)
        .Where(f => f.FromUserId == me.Id || f.ToUserId == me.Id)
        .ToListAsync();

    var friends = links.Where(f => f.Accepted)
        .Select(f => (Link: f, Friend: f.FromUserId == me.Id ? f.ToUser : f.FromUser))
        .ToList();
    var playerIds = friends.Select(x => x.Friend.Id).Append(me.Id).ToList();
    var found = await db.Ratings
        .Where(r => playerIds.Contains(r.UserId))
        .Select(r => new { r.UserId, r.Color, r.Kind, r.Brand })
        .ToListAsync();

    PlayerDto Player(User user, int? friendshipId)
    {
        var rows = found.Where(r => r.UserId == user.Id).ToList();
        return new PlayerDto(friendshipId, FirstName(user), user.Id == me.Id, rows.Count,
            rows.Select(r => r.Color).OfType<string>().Distinct().ToList(),
            rows.Select(r => r.Kind).OfType<string>().Distinct().ToList(),
            rows.Select(r => r.Brand).OfType<string>().Distinct().ToList());
    }

    var players = friends.Select(x => Player(x.Friend, x.Link.Id)).Append(Player(me, null)).ToList();
    var incoming = links.Where(f => !f.Accepted && f.ToUserId == me.Id)
        .Select(f => new FriendRequestDto(f.Id, FirstName(f.FromUser), f.FromUser.Email)).ToList();
    var outgoing = links.Where(f => !f.Accepted && f.FromUserId == me.Id)
        .Select(f => new FriendRequestDto(f.Id, FirstName(f.ToUser), f.ToUser.Email)).ToList();
    return Results.Ok(new FriendsDto(players, incoming, outgoing));
});

// Sends a friend request. If that person already asked you, this accepts their request instead.
api.MapPost("/friends", async (FriendInput input, ClaimsPrincipal principal, AppDb db) =>
{
    var email = (input.Email ?? "").Trim().ToLowerInvariant();
    if (email.Length is < 3 or > 320 || !email.Contains('@'))
        return Results.BadRequest(new { error = "Skriv kompisens e-postadress." });

    var me = await CurrentUser(principal, db);
    if (me.Email != null && me.Email.ToLower() == email)
        return Results.BadRequest(new { error = "Du kan inte tävla mot dig själv. 😄" });

    var other = await db.Users.FirstOrDefaultAsync(u => u.Email != null && u.Email.ToLower() == email);
    if (other == null)
        return Results.BadRequest(new { error = "Hittade ingen Biljakt-spelare med den adressen. Be kompisen logga in i Biljakt först." });

    var existing = await db.Friendships.FirstOrDefaultAsync(f =>
        (f.FromUserId == me.Id && f.ToUserId == other.Id) || (f.FromUserId == other.Id && f.ToUserId == me.Id));
    if (existing == null)
    {
        var waiting = await db.Friendships.CountAsync(f => f.FromUserId == me.Id && !f.Accepted);
        if (waiting >= 20) return Results.BadRequest(new { error = "Du har för många obesvarade förfrågningar." });
        db.Friendships.Add(new Friendship { FromUserId = me.Id, ToUserId = other.Id, CreatedAt = DateTime.UtcNow });
    }
    else if (!existing.Accepted && existing.ToUserId == me.Id)
    {
        existing.Accepted = true;
    }
    await db.SaveChangesAsync();
    return Results.NoContent();
});

api.MapPost("/friends/{id:int}/accept", async (int id, ClaimsPrincipal principal, AppDb db) =>
{
    var me = await CurrentUser(principal, db);
    var request = await db.Friendships.SingleOrDefaultAsync(f => f.Id == id && f.ToUserId == me.Id);
    if (request == null) return Results.NotFound();
    request.Accepted = true;
    await db.SaveChangesAsync();
    return Results.NoContent();
});

// Declines a request, takes back your own request, or removes a friend.
api.MapDelete("/friends/{id:int}", async (int id, ClaimsPrincipal principal, AppDb db) =>
{
    var me = await CurrentUser(principal, db);
    await db.Friendships.Where(f => f.Id == id && (f.FromUserId == me.Id || f.ToUserId == me.Id)).ExecuteDeleteAsync();
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

// Friends see only the first name from the Google account.
static string FirstName(User user) =>
    user.Name?.Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? "Biljakt-spelare";

static async Task<Rating?> MyRating(string plate, ClaimsPrincipal principal, AppDb db)
{
    plate = Plates.Normalize(plate);
    var me = await CurrentUser(principal, db);
    return await db.Ratings.SingleOrDefaultAsync(r => r.Plate == plate && r.UserId == me.Id);
}

static RatingDto ToDto(Rating r, bool hasPhoto) =>
    new(r.Id, r.Score, r.Comment, r.Color, r.Kind, r.Brand, hasPhoto, Utc(r.UpdatedAt));

// Whole seconds in UTC, so the app gets plain ISO 8601 dates like 2026-10-25T21:00:00Z.
static DateTime Utc(DateTime value) => new(value.Ticks - value.Ticks % TimeSpan.TicksPerSecond, DateTimeKind.Utc);

record RatingInput(int? Score, string? Comment, string? Color, string? Kind, string? Brand);
record FriendInput(string? Email);
record PlayerDto(int? FriendshipId, string Name, bool IsMe, int Cars, List<string> Colors, List<string> Kinds, List<string> Brands);
record FriendRequestDto(int Id, string Name, string? Email);
record FriendsDto(List<PlayerDto> Players, List<FriendRequestDto> Incoming, List<FriendRequestDto> Outgoing);
record RatingDto(int Id, int? Score, string Comment, string? Color, string? Kind, string? Brand, bool HasPhoto, DateTime UpdatedAt);
record MyRatingDto(string Plate, int? Score, string Comment, string? Color, string? Kind, string? Brand, bool HasPhoto, DateTime UpdatedAt);
record MyRatingsDto(int Count, List<MyRatingDto> Ratings);

// The colors the app offers. Keep in sync with CarColor in the iOS app.
static class CarColors
{
    public static readonly HashSet<string> All =
        ["white", "black", "grey", "silver", "red", "blue", "green", "yellow", "orange", "brown", "purple", "pink"];
}
// The kinds of car for the car-kind hunt. Keep in sync with CarKind in the iOS app.
static class CarKinds
{
    public static readonly HashSet<string> All =
        ["car", "suv", "van", "truck", "bus", "motorcycle", "taxi", "camper", "tractor", "sports", "vintage", "emergency"];
}
// The car brands for the brand hunt. Keep in sync with CarBrand in the iOS app.
static class CarBrands
{
    public static readonly HashSet<string> All =
        ["volvo", "volkswagen", "toyota", "audi", "bmw", "mercedes", "kia", "ford", "skoda", "tesla", "renault",
         "peugeot", "hyundai", "nissan", "polestar", "saab", "porsche", "ferrari", "lamborghini"];
}
record PlateDto(string Plate, RatingDto? MyRating);

static partial class Plates
{
    public static string Normalize(string raw) =>
        string.Concat(raw.Where(c => !char.IsWhiteSpace(c))).ToUpperInvariant();

    // Swedish plates: ABC123 (old format) or ABC12D (since 2019).
    public static bool IsValid(string plate) => PlatePattern().IsMatch(plate);

    [GeneratedRegex("^[A-ZÅÄÖ]{3}[0-9]{2}[0-9A-ZÅÄÖ]$")]
    private static partial Regex PlatePattern();
}
