using DoggyLife.Data.Database;
using DoggyLife.Models;
using DoggyLife.Models.Storage.Settings;
using Microsoft.EntityFrameworkCore;
using Microsoft.JSInterop;
using SqliteWasmHelper;

namespace DoggyLife.Services;

public sealed class MusicService(ILogger<MusicService> logger, IJSRuntime jsRuntime, ISqliteWasmDbContextFactory<AppDbContext> dbFactory)
{
    public MusicTrack CurrentTrack { get; private set; } = MusicTrack.None;
    public bool IsMuted { get; private set; } = false;
    private static bool _isInitialized = false;

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
            using var ctx = await dbFactory.CreateDbContextAsync();

            var settingsList = await ctx.MusicSettings.ToListAsync();
            var settings = settingsList.FirstOrDefault();

            if (settings is null)
            {
                // Create default settings if none exist
                settings = new MusicSettings { IsMuted = false };
                ctx.MusicSettings.Add(settings);
                await ctx.SaveChangesAsync();
            }

            // Apply the mute setting
            IsMuted = settings.IsMuted;
            await ApplyMuteSettingAsync();
        }
        catch (Exception ex)
        {
            logger.LogError("Error loading music settings: {Message}", ex.Message);
        }
    }

    public async Task PlayTrack(MusicTrack track)
    {
        if (CurrentTrack == track) return;

        string trackName = track switch
        {
            MusicTrack.MatchaGreenTea => "Matcha Green Tea",
            _ => string.Empty
        };

        if (!string.IsNullOrWhiteSpace(trackName))
        {
            await jsRuntime.InvokeVoidAsync("changeTrack", trackName);
            CurrentTrack = track;

            await ApplyMuteSettingAsync();
        }
    }

    public async Task ToggleMuteAsync()
    {
        IsMuted = !IsMuted;
        await ApplyMuteSettingAsync();
        await SaveMuteSettingAsync();
    }

    private async Task ApplyMuteSettingAsync()
    {
        try
        {
            if (IsMuted)
            {
                await jsRuntime.InvokeVoidAsync("muteAudio");
            }
            else
            {
                await jsRuntime.InvokeVoidAsync("unmuteAudio");
            }
        }
        catch (Exception ex)
        {
            logger.LogError("Error applying mute setting: {Message}", ex.Message);
        }
    }

    private async Task SaveMuteSettingAsync()
    {
        try
        {
            using var ctx = await dbFactory.CreateDbContextAsync();
            var settings = await ctx.MusicSettings.FirstOrDefaultAsync();

            if (settings == null)
            {
                settings = new MusicSettings { IsMuted = IsMuted };
                ctx.MusicSettings.Add(settings);
            }
            else
            {
                settings.IsMuted = IsMuted;
                ctx.MusicSettings.Update(settings);
            }

            await ctx.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            logger.LogError("Error saving music settings: {Message}", ex.Message);
        }
    }
}