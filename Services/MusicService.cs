using DoggyLife.Data.Database;
using DoggyLife.Models;
using DoggyLife.Models.Storage.Settings;
using Microsoft.EntityFrameworkCore;
using Microsoft.JSInterop;
using SqliteWasmHelper;

namespace DoggyLife.Services;

public class MusicService
{
    private readonly IJSRuntime _jsRuntime;
    private readonly ISqliteWasmDbContextFactory<AppDbContext> _dbFactory;
    private MusicTrack _currentTrack = MusicTrack.None;
    private bool _isMuted = false;
    private static bool _isInitialized = false;

    public MusicService(IJSRuntime jsRuntime, ISqliteWasmDbContextFactory<AppDbContext> dbFactory)
    {
        _jsRuntime = jsRuntime;
        _dbFactory = dbFactory;
    }

    public async Task InitializeAsync()
    {
        if (_isInitialized) return;

        await LoadSettingsAsync();
        _isInitialized = true;
    }

    public async Task LoadSettingsAsync()
    {
        try
        {
            // Load mute settings from database
            using var ctx = await _dbFactory.CreateDbContextAsync();

            Console.WriteLine("Loading existing music settings from database...");
            var settingsList = await ctx.MusicSettings.ToListAsync();
            Console.WriteLine($"Found {settingsList.Count} music settings entries in the database.");
            var settings = settingsList.FirstOrDefault();

            Console.WriteLine($"Found {settingsList.Count} music settings entries in the database.");
            if (settings == null)
            {
                Console.WriteLine("No existing music settings found, creating default settings...");
                // Create default settings if none exist
                settings = new MusicSettings { IsMuted = false };
                ctx.MusicSettings.Add(settings);
                await ctx.SaveChangesAsync();
                Console.WriteLine("Default music settings created.");
            }

            // Apply the mute setting
            _isMuted = settings.IsMuted;
            Console.WriteLine($"Music settings loaded: IsMuted = {_isMuted}");
            await ApplyMuteSettingAsync();
            Console.WriteLine($"Music settings loaded: IsMuted = {_isMuted}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading music settings: {ex.Message}");
        }
    }

    public async Task PlayTrack(MusicTrack track)
    {
        if (_currentTrack == track) return;

        string trackName = track switch
        {
            MusicTrack.MatchaGreenTea => "Matcha Green Tea",
            _ => string.Empty
        };

        if (!string.IsNullOrEmpty(trackName))
        {
            await _jsRuntime.InvokeVoidAsync("changeTrack", trackName);
            _currentTrack = track;

            // Apply mute setting after changing track
            await ApplyMuteSettingAsync();
        }
    }

    public async Task ToggleMuteAsync()
    {
        _isMuted = !_isMuted;
        await ApplyMuteSettingAsync();
        await SaveMuteSettingAsync();
    }

    public async Task MuteAsync()
    {
        if (_isMuted) return;
        _isMuted = true;
        await ApplyMuteSettingAsync();
        await SaveMuteSettingAsync();
    }

    public async Task UnmuteAsync()
    {
        if (!_isMuted) return;
        _isMuted = false;
        await ApplyMuteSettingAsync();
        await SaveMuteSettingAsync();
    }

    private async Task ApplyMuteSettingAsync()
    {
        try
        {
            if (_isMuted)
            {
                await _jsRuntime.InvokeVoidAsync("muteAudio");
            }
            else
            {
                await _jsRuntime.InvokeVoidAsync("unmuteAudio");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error applying mute setting: {ex.Message}");
        }
    }

    private async Task SaveMuteSettingAsync()
    {
        try
        {
            using var ctx = await _dbFactory.CreateDbContextAsync();
            var settings = await ctx.MusicSettings.FirstOrDefaultAsync();

            if (settings == null)
            {
                settings = new MusicSettings { IsMuted = _isMuted };
                ctx.MusicSettings.Add(settings);
            }
            else
            {
                settings.IsMuted = _isMuted;
                ctx.MusicSettings.Update(settings);
            }

            await ctx.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error saving music settings: {ex.Message}");
        }
    }

    public MusicTrack CurrentTrack => _currentTrack;
    public bool IsMuted => _isMuted;
}