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

    public DogAnimationState _currentState = DogAnimationState.FrontSitting;
    private int _currentFrame = 0;
    private float _animationTimer = 0;
    private readonly float _frameTime = 0.2f; // seconds per frame

    public DogAnimation()
    {
        // Based on the exact states you specified:
        // walking front (row 0)
        // walking right (row 1) 
        // walking left (row 2)
        // walking back (row 3)
        // sitting left (row 4)
        // sitting right (row 5)
        // sitting front (row 6)

        _animations = new Dictionary<DogAnimationState, (int Row, int FrameCount)>
            {
                // Map animations to match your exact states in order
                { DogAnimationState.FrontWalking, (0, 4) },   // walking front
                { DogAnimationState.RightWalking, (1, 4) },   // walking right 
                { DogAnimationState.LeftWalking, (2, 4) },    // walking left
                { DogAnimationState.BackWalking, (3, 4) },    // walking back
                { DogAnimationState.LeftSitting, (4, 4) },   // sitting left
                { DogAnimationState.RightSitting, (5, 4) },  // sitting right
                { DogAnimationState.FrontSitting, (6, 4) },  // sitting front
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