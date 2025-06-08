using DoggyLife.Models.Storage;
using Microsoft.EntityFrameworkCore;

namespace DoggyLife.Data.Database;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; } = null!;
}