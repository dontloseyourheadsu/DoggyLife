using DoggyLife.Models.Storage;
using DoggyLife.Models.Storage.Settings;
using DoggyLife.Models.Storage.Room;
using Microsoft.EntityFrameworkCore;

namespace DoggyLife.Data.Database;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; } = null!;
    public DbSet<MusicSettings> MusicSettings { get; set; } = null!;
    public DbSet<RoomSettings> RoomSettings { get; set; } = null!;
    public DbSet<PlacedItem> PlacedItems { get; set; } = null!;
}