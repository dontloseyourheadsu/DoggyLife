using DoggyLife.Models;
using Microsoft.JSInterop;

namespace DoggyLife.Services;

public class MusicService
{
    private readonly IJSRuntime _jsRuntime;
    private MusicTrack _currentTrack = MusicTrack.None;

    public MusicService(IJSRuntime jsRuntime)
    {
        _jsRuntime = jsRuntime;
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
        }
    }

    public MusicTrack CurrentTrack => _currentTrack;
}