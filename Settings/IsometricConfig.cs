using SkiaSharp;

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
    public const int GridSize = 15;

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
    /// Dark floor color
    /// </summary>
    public static readonly SKColor FloorColorDark = new SKColor(60, 60, 90);

    /// <summary>
    /// Light floor color
    /// </summary>
    public static readonly SKColor FloorColorLight = new SKColor(90, 90, 120);

    /// <summary>
    /// Dark wall color
    /// </summary>
    public static readonly SKColor WallColorDark = new SKColor(40, 40, 70);

    /// <summary>
    /// Light wall color
    /// </summary>
    public static readonly SKColor WallColorLight = new SKColor(70, 70, 100);

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