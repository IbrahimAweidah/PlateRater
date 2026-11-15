using Microsoft.EntityFrameworkCore;

namespace BiljaktAPI;

public class User
{
    public int Id { get; set; }
    public string GoogleSubject { get; set; } = "";
    public string? Email { get; set; }
    public string? Name { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class Rating
{
    public int Id { get; set; }
    public string Plate { get; set; } = "";
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public int? Score { get; set; }
    public string Comment { get; set; } = "";
    public string? Color { get; set; }
    public string? Kind { get; set; }
    public string? Brand { get; set; }
    // Set when the photo didn't match what was picked: "pending" until a friend answers,
    // then "confirmed" or "rejected". Null means no check is needed. Only null and "confirmed" give points.
    public string? CheckStatus { get; set; }
    public int? CheckedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class Photo
{
    public const int MaxBytes = 3 * 1024 * 1024;

    public int RatingId { get; set; }
    public byte[] Data { get; set; } = [];
    public string ContentType { get; set; } = "image/jpeg";
    // A copy with the plate pixelated on the phone, shown only to accepted friends while the check is pending.
    public byte[]? CheckData { get; set; }
    public DateTime CreatedAt { get; set; }
}

// A friend request from one player to another. Once accepted, both can see each other's
// hunt progress (which colors, kinds and brands of car they have found), never their plates or ratings.
public class Friendship
{
    public int Id { get; set; }
    public int FromUserId { get; set; }
    public User FromUser { get; set; } = null!;
    public int ToUserId { get; set; }
    public User ToUser { get; set; } = null!;
    public bool Accepted { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Tables are created by schema.sql. They are prefixed so they can live next to the
// other tables in the shared SmarterASP.NET database.
public class AppDb(DbContextOptions<AppDb> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Rating> Ratings => Set<Rating>();
    public DbSet<Photo> Photos => Set<Photo>();
    public DbSet<Friendship> Friendships => Set<Friendship>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<User>().ToTable("BiljaktUsers");
        model.Entity<User>().HasIndex(u => u.GoogleSubject).IsUnique();

        model.Entity<Rating>().ToTable("BiljaktRatings");
        model.Entity<Rating>().HasIndex(r => new { r.Plate, r.UserId }).IsUnique();

        model.Entity<Photo>().ToTable("BiljaktPhotos");
        model.Entity<Photo>().HasKey(p => p.RatingId);
        model.Entity<Photo>().Property(p => p.RatingId).ValueGeneratedNever();

        model.Entity<Friendship>().ToTable("BiljaktFriendships");
        model.Entity<Friendship>().HasIndex(f => new { f.FromUserId, f.ToUserId }).IsUnique();
        model.Entity<Friendship>().HasOne(f => f.FromUser).WithMany().HasForeignKey(f => f.FromUserId).OnDelete(DeleteBehavior.NoAction);
        model.Entity<Friendship>().HasOne(f => f.ToUser).WithMany().HasForeignKey(f => f.ToUserId).OnDelete(DeleteBehavior.NoAction);
    }
}
