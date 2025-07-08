using DoggyLife.Data.Database;
using DoggyLife.Models;
using DoggyLife.Models.Storage.Settings;
using Microsoft.EntityFrameworkCore;
using SqliteWasmHelper;

namespace DoggyLife.Services;

public class RoomService
{
    private readonly ISqliteWasmDbContextFactory<AppDbContext> _dbFactory;
    private RoomSettings? _currentSettings;

    // Default colors stored as static variables so they can be changed later if needed
    public static readonly Color DefaultFloorLightColor = new(90, 90, 120);
    public static readonly Color DefaultFloorDarkColor = new(50, 50, 70);

    public static readonly Color DefaultWallLightColor = new(70, 70, 100);
    public static readonly Color DefaultWallDarkColor = new(70, 70, 100);
    public static readonly Color DefaultWallOutlineColor = new(30, 30, 50);
    public static readonly Color DefaultWallStripeColor = new(30, 30, 50);

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
    public List<Color> GetFloorColors()
    {
        if (_currentSettings == null)
        {
            return new List<Color> { DefaultFloorLightColor, DefaultFloorDarkColor };
        }

        return new List<Color>
        {
            _currentSettings.GetFloorLightColor(),
            _currentSettings.GetFloorDarkColor()
        };
    }

    // Get the current colors for walls
    public List<Color> GetWallColors()
    {
        if (_currentSettings == null)
        {
            return new List<Color>
            {
                DefaultWallLightColor,
                DefaultWallDarkColor,
                DefaultWallOutlineColor,
                DefaultWallStripeColor
            };
        }

        return new List<Color>
        {
            _currentSettings.GetWallLightColor(),
            _currentSettings.GetWallDarkColor(),
            _currentSettings.GetWallOutlineColor(),
            _currentSettings.GetWallStripeColor()
        };
    }

    // Get all room colors (combined floor and wall colors)
    public List<Color> GetRoomColors()
    {
        var colors = new List<Color>();
        colors.AddRange(GetFloorColors());
        colors.AddRange(GetWallColors());
        return colors;
    }
}
