using Microsoft.EntityFrameworkCore;

namespace PlateRaterAPI;

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
    public int Score { get; set; }
    public string Comment { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

// Tables are created by schema.sql. They are prefixed so they can live next to the
// other tables in the shared SmarterASP.NET database.
public class AppDb(DbContextOptions<AppDb> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Rating> Ratings => Set<Rating>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<User>().ToTable("PlateRaterUsers");
        model.Entity<User>().HasIndex(u => u.GoogleSubject).IsUnique();

        model.Entity<Rating>().ToTable("PlateRaterRatings");
        model.Entity<Rating>().HasIndex(r => new { r.Plate, r.UserId }).IsUnique();
    }
}
