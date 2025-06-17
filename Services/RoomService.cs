using DoggyLife.Data.Database;
using DoggyLife.Models.Storage.Settings;
using Microsoft.EntityFrameworkCore;
using SkiaSharp;
using SqliteWasmHelper;

namespace DoggyLife.Services;

public class RoomService
{
    private readonly ISqliteWasmDbContextFactory<AppDbContext> _dbFactory;
    private RoomSettings? _currentSettings;

    // Default colors stored as static variables so they can be changed later if needed
    public static readonly SKColor DefaultFloorLightColor = new SKColor(90, 90, 120);
    public static readonly SKColor DefaultFloorDarkColor = new SKColor(50, 50, 70);

    public static readonly SKColor DefaultWallLightColor = new SKColor(70, 70, 100);
    public static readonly SKColor DefaultWallDarkColor = new SKColor(70, 70, 100);
    public static readonly SKColor DefaultWallOutlineColor = new SKColor(30, 30, 50);
    public static readonly SKColor DefaultWallStripeColor = new SKColor(30, 30, 50);

    public RoomService(ISqliteWasmDbContextFactory<AppDbContext> dbFactory)
    {
        _dbFactory = dbFactory;
    }

    public async Task InitializeAsync()
    {
        await using var db = await _dbFactory.CreateDbContextAsync();
        var roomSettings = await db.RoomSettings.ToListAsync();
        _currentSettings = roomSettings.FirstOrDefault();

        if (_currentSettings == null)
        {
            // Create default settings if none exist
            _currentSettings = new RoomSettings();
            db.RoomSettings.Add(_currentSettings);
            await db.SaveChangesAsync();
        }
    }

    public async Task<RoomSettings> GetSettingsAsync()
    {
        if (_currentSettings == null)
        {
            await InitializeAsync();
        }

        return _currentSettings ?? new RoomSettings();
    }

    public async Task UpdateSettingsAsync(RoomSettings settings)
    {
        await using var db = await _dbFactory.CreateDbContextAsync();

        if (settings.Id == 0)
        {
            // New settings
            db.RoomSettings.Add(settings);
        }
        else
        {
            // Update existing settings
            db.RoomSettings.Update(settings);
        }

        await db.SaveChangesAsync();
        _currentSettings = settings;
    }

    // Get the current colors for floor
    public List<SKColor> GetFloorColors()
    {
        if (_currentSettings == null)
        {
            return new List<SKColor> { DefaultFloorLightColor, DefaultFloorDarkColor };
        }

        return new List<SKColor>
        {
            _currentSettings.GetFloorLightColor(),
            _currentSettings.GetFloorDarkColor()
        };
    }

    // Get the current colors for walls
    public List<SKColor> GetWallColors()
    {
        if (_currentSettings == null)
        {
            return new List<SKColor>
            {
                DefaultWallLightColor,
                DefaultWallDarkColor,
                DefaultWallOutlineColor,
                DefaultWallStripeColor
            };
        }

        return new List<SKColor>
        {
            _currentSettings.GetWallLightColor(),
            _currentSettings.GetWallDarkColor(),
            _currentSettings.GetWallOutlineColor(),
            _currentSettings.GetWallStripeColor()
        };
    }
}
