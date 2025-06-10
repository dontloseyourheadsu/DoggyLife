using SkiaSharp;

namespace DoggyLife.Rendering;

/// <summary>
/// Represents the different states of dog animations.
/// </summary>
public class DogAnimation
{
    private SKBitmap _spritesheet;
    private readonly int _spriteWidth = 44;
    private readonly int _spriteHeight = 46;
    private readonly int _spriteHorizontalSpacing = 4;
    private readonly int _spriteVerticalSpacing = 1;
    private readonly Dictionary<DogAnimationState, (int Row, int FrameCount)> _animations;

    public DogAnimationState _currentState = DogAnimationState.FrontSitting;
    private int _currentFrame = 0;
    private float _animationTimer = 0;
    private readonly float _frameTime = 0.2f; // seconds per frame

    public DogAnimation()
    {
        // Updated animation order:
        // right walking (row 0)
        // left walking (row 1)
        // back walking (row 2)
        // front walking (row 3)
        // front sitting (row 4)
        // right sitting (row 5)
        // left sitting (row 6)

        _animations = new Dictionary<DogAnimationState, (int Row, int FrameCount)>
            {
                // Map animations to match your updated order
                { DogAnimationState.RightWalking, (0, 4) },   // right walking
                { DogAnimationState.LeftWalking, (1, 4) },    // left walking
                { DogAnimationState.BackWalking, (2, 4) },    // back walking
                { DogAnimationState.FrontWalking, (3, 4) },   // front walking
                { DogAnimationState.FrontSitting, (4, 4) },   // front sitting
                { DogAnimationState.RightSitting, (5, 4) },   // right sitting
                { DogAnimationState.LeftSitting, (6, 4) },    // left sitting
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
            _currentFrame * (_spriteWidth + _spriteHorizontalSpacing),
            row * (_spriteHeight + _spriteVerticalSpacing),
            _currentFrame * (_spriteWidth + _spriteHorizontalSpacing) + _spriteWidth,
            row * (_spriteHeight + _spriteVerticalSpacing) + _spriteHeight
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