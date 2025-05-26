using DoggyLife.Settings;

namespace DoggyLife.Rendering.Isometric;

/// <summary>
/// Movement helpers for <see cref="WallCursor"/>.
/// </summary>
public static class WallCursorExtensions
{
  /// <summary>
  /// Move the cursor horizontally; wraps from one wall to the other.
  /// </summary>
  /// <param name="cursor">Cursor to mutate (use with <c>ref</c>)</param>
  /// <param name="delta">-1 for left / +1 for right</param>
  public static void MoveHorizontal(ref this WallCursor cursor, int delta)
  {
    int total = IsometricConfig.GridLength + IsometricConfig.GridWidth;   // full strip length
    int linear = cursor.Side == WallSide.Left
      ? cursor.Cell                                   // 0 … GridLength-1
      : IsometricConfig.GridLength + cursor.Cell;     // GridLength … total-1

    // ring-buffer wrap
    linear = (linear + delta) % total;
    if (linear < 0) linear += total;

    // convert back to (Side, Cell)
    if (linear < IsometricConfig.GridLength)
    {
      cursor = cursor with { Side = WallSide.Left,  Cell = linear };
    }
    else
    {
      cursor = cursor with
      {
        Side = WallSide.Right,
        Cell = linear - IsometricConfig.GridLength
      };
    }
  }
}