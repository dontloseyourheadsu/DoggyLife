using DoggyLife.Settings;

namespace DoggyLife.Rendering.Isometric;

public class WallCursor
{
    public WallSide Side { get; private set; }
    public float Position { get; private set; }
    public float Height { get; private set; }

    public WallCursor(WallSide side, float position, float height = 0)
    {
        Side = side;
        Position = position;
        Height = height;
    }

    /// <summary>
    /// Moves the cursor horizontally along the wall
    /// </summary>
    /// <param name="delta">Movement direction: positive for right, negative for left</param>
    /// <param name="moveSpeed">Speed of movement</param>
    public void MoveHorizontal(float delta, float moveSpeed = 0.1f)
    {
        if (Side == WallSide.Left)
        {
            // For left wall, invert the direction to match visual expectations
            // (negate delta because increasing Y visually moves left in isometric view)
            float newPosition = Position + (-delta * moveSpeed);
            Position = Math.Max(0, Math.Min(newPosition, IsometricConfig.GridLength - 1));
        }
        else // Right wall
        {
            // For right wall, normal direction (increasing X moves right)
            float newPosition = Position + (delta * moveSpeed);
            Position = Math.Max(0, Math.Min(newPosition, IsometricConfig.GridWidth - 1));
        }
    }

    public void MoveVertical(float delta, float moveSpeed = 0.1f)
    {
        float newHeight = Height + (delta * moveSpeed);
        // Set maximum height based on configuration
        Height = Math.Max(0, Math.Min(newHeight, IsometricConfig.WallHeight));
    }

    public void ToggleWallSide()
    {
        Side = Side == WallSide.Left ? WallSide.Right : WallSide.Left;
        // Reset position to ensure it's within bounds for the new side
        Position = 0;
    }
}