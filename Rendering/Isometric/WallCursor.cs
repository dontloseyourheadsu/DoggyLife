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

    public void MoveHorizontal(float delta, float moveSpeed = 0.1f)
    {
        if (Side == WallSide.Left)
        {
            // For left wall, we move along the Y axis of the grid
            // Invert delta because visual left/right is opposite to grid Y direction
            float newPosition = Position + (-delta * moveSpeed);
            Position = Math.Max(0, Math.Min(newPosition, IsometricConfig.GridLength - 1));
        }
        // Right wall logic will be added later
    }

    public void MoveVertical(float delta, float moveSpeed = 0.1f)
    {
        float newHeight = Height + (delta * moveSpeed);
        // Subtract hologram height from max limit so hologram doesn't go above wall
        float hologramHeightInGrid = 0.3f; // Same as in DrawWallHologram
        float maxHeight = IsometricConfig.WallHeight - hologramHeightInGrid;
        Height = Math.Max(0, Math.Min(newHeight, maxHeight));
    }
}