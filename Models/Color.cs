namespace DoggyLife.Models;

/// <summary>
/// Represents a color with red, green, and blue components.
/// </summary>
public struct Color
{
    public byte Red { get; }
    public byte Green { get; }
    public byte Blue { get; }

    public Color(byte red, byte green, byte blue)
    {
        Red = red;
        Green = green;
        Blue = blue;
    }

    public Color(int red, int green, int blue)
    {
        Red = (byte)Math.Clamp(red, 0, 255);
        Green = (byte)Math.Clamp(green, 0, 255);
        Blue = (byte)Math.Clamp(blue, 0, 255);
    }

    /// <summary>
    /// Creates a Color from a hex string (e.g., "#FF0000" or "FF0000")
    /// </summary>
    public static Color FromHex(string hex)
    {
        hex = hex.TrimStart('#');
        if (hex.Length != 6)
            throw new ArgumentException("Hex string must be 6 characters long", nameof(hex));

        byte r = Convert.ToByte(hex.Substring(0, 2), 16);
        byte g = Convert.ToByte(hex.Substring(2, 2), 16);
        byte b = Convert.ToByte(hex.Substring(4, 2), 16);

        return new Color(r, g, b);
    }

    /// <summary>
    /// Converts the color to a hex string (e.g., "#FF0000")
    /// </summary>
    public string ToHex()
    {
        return $"#{Red:X2}{Green:X2}{Blue:X2}";
    }

    /// <summary>
    /// Converts the color to an RGB string (e.g., "rgb(255, 0, 0)")
    /// </summary>
    public string ToRgb()
    {
        return $"rgb({Red}, {Green}, {Blue})";
    }

    public override string ToString()
    {
        return ToHex();
    }

    public override bool Equals(object? obj)
    {
        return obj is Color color && Red == color.Red && Green == color.Green && Blue == color.Blue;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(Red, Green, Blue);
    }

    public static bool operator ==(Color left, Color right)
    {
        return left.Equals(right);
    }

    public static bool operator !=(Color left, Color right)
    {
        return !left.Equals(right);
    }

    // Common colors
    public static Color GetWhite => new(255, 255, 255);
    public static Color GetBlack => new(0, 0, 0);
    public static Color GetRed => new(255, 0, 0);
    public static Color GetGreen => new(0, 255, 0);
    public static Color GetBlue => new(0, 0, 255);
    public static Color GetYellow => new(255, 255, 0);
    public static Color GetCyan => new(0, 255, 255);
    public static Color GetMagenta => new(255, 0, 255);
    public static Color GetGray => new(128, 128, 128);
    public static Color GetDarkGray => new(64, 64, 64);
    public static Color GetLightGray => new(192, 192, 192);
}
