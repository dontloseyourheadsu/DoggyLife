namespace DoggyLife.Settings;

/// <summary>
/// Shared configuration parameters for isometric rendering.
/// </summary>
public static class IsometricConfig
{
    /// <summary>
    /// The angle of the isometric projection in degrees.
    /// </summary>
    public const float IsometricAngle = 30f;

    /// <summary>
    /// Grid size in pixels. Size of each cell.
    /// </summary>
    public static int GridSize = 15;

    /// <summary>
    /// Number of cells horizontally.
    /// </summary>
    public const int GridWidth = 10;

    /// <summary>
    /// Number of cells vertically.
    /// </summary>
    public const int GridLength = 10;

    /// <summary>
    /// Height of walls in grid units
    /// </summary>
    public const int WallHeight = 10;

    /// <summary>
    /// Get isometric X transformation factor based on angle.
    /// </summary>
    public static float IsoX => (float)Math.Cos(IsometricAngle * Math.PI / 180f);

    /// <summary>
    /// Get isometric Y transformation factor based on angle.
    /// </summary>
    public static float IsoY => (float)Math.Sin(IsometricAngle * Math.PI / 180f);

    /// <summary>
    /// Get the offset X position to center the grid on canvas.
    /// </summary>
    public static float GetOffsetX(float canvasWidth) => canvasWidth / 2f;

    /// <summary>
    /// Get the offset Y position to center the grid on canvas.
    /// </summary>
    public static float GetOffsetY(float canvasHeight) =>
        canvasHeight / 2f - (GridWidth + GridLength) * GridSize * IsoY / 4;
}