namespace DoggyLife.Helpers;

/// <summary>
/// Helper class for mathematical operations.
/// </summary>
public static class MathHelper
{
    /// <summary>
    /// Clamps a value between a minimum and maximum range.
    /// </summary>
    /// <param name="value">Value to clamp.</param>
    /// <param name="min">Minimum value.</param>
    /// <param name="max">Maximum value.</param>
    /// <returns>The clamped value.</returns>
    public static float Clamp(float value, float min, float max)
    {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }
}
