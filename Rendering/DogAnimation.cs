using SkiaSharp;

namespace DoggyLife.Rendering;

/// <summary>
/// Represents the different states of dog animations.
/// </summary>
public class DogAnimation
{
    private SKBitmap _spritesheet;
    private readonly int _spriteWidth = 50;
    private readonly int _spriteHeight = 50;
    private readonly int _spriteSpacing = 10;
    private readonly Dictionary<DogAnimationState, (int Row, int FrameCount)> _animations;

    public DogAnimationState _currentState = DogAnimationState.FrontStanding;
    private int _currentFrame = 0;
    private float _animationTimer = 0;
    private readonly float _frameTime = 0.2f; // seconds per frame

    public DogAnimation()
    {
        // Initialize the animations dictionary
        _animations = new Dictionary<DogAnimationState, (int Row, int FrameCount)>
            {
                { DogAnimationState.FrontStanding, (0, 4) },   // First row, 4 frames
                { DogAnimationState.LeftWalking, (1, 4) },     // Second row, 4 frames
                { DogAnimationState.BackStanding, (2, 4) },    // Third row, 4 frames
                { DogAnimationState.Laying, (3, 4) },          // Fourth row, 4 frames
                { DogAnimationState.FrontWalking, (4, 4) },    // Fifth row, 4 frames
                { DogAnimationState.LeftStanding, (5, 4) },    // Sixth row, 4 frames
                { DogAnimationState.BackWalking, (6, 4) }      // Seventh row, 4 frames
            };
    }

    public async Task LoadSpritesheetAsync(HttpClient httpClient, string path)
    {
        try
        {
            using var stream = await httpClient.GetStreamAsync(path);
            using var skiaStream = new SKManagedStream(stream);
            _spritesheet = SKBitmap.Decode(skiaStream);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading spritesheet: {ex.Message}");
        }
    }

    public void SetState(DogAnimationState state)
    {
        if (_currentState != state)
        {
            _currentState = state;
            _currentFrame = 0;
            _animationTimer = 0;
        }
    }

    public void Update(float deltaTime)
    {
        if (_spritesheet == null) return;

        _animationTimer += deltaTime;

        if (_animationTimer >= _frameTime)
        {
            _animationTimer -= _frameTime;
            var frameCount = _animations[_currentState].FrameCount;
            _currentFrame = (_currentFrame + 1) % frameCount;
        }
    }

    public void Draw(SKCanvas canvas, float x, float y, float scale = 1.0f)
    {
        if (_spritesheet == null) return;

        var (row, _) = _animations[_currentState];

        // Calculate source rectangle (from the spritesheet)
        var sourceRect = new SKRectI(
            _currentFrame * (_spriteWidth + _spriteSpacing),
            row * (_spriteHeight + _spriteSpacing),
            _currentFrame * (_spriteWidth + _spriteSpacing) + _spriteWidth,
            row * (_spriteHeight + _spriteSpacing) + _spriteHeight
        );

        // Calculate destination rectangle (where to draw on canvas)
        var destRect = new SKRect(
            x,
            y,
            x + _spriteWidth * scale,
            y + _spriteHeight * scale
        );

        // Draw the sprite
        canvas.DrawBitmap(_spritesheet, sourceRect, destRect);
    }
}