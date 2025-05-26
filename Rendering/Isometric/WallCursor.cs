using DoggyLife.Rendering.Isometric;

namespace DoggyLife.Rendering.Isometric;

/// <summary>
/// Identifies a single grid cell on one of the two vertical walls.
/// </summary>
/// <param name="Side">Wall being edited (Left or Right).</param>
/// <param name="Cell">0-based cell index on that wall.</param>
public readonly record struct WallCursor(WallSide Side, int Cell);