namespace DoggyLife.Models.Objects;

/// <summary>
/// Represents a Hologram object in the DoggyLife game.
/// </summary>
public class Hologram
{
    /// <summary>
    /// Gets or sets the X coordinate of the hologram.
    /// </summary>
    public float X { get; set; }

    /// <summary>
    /// Gets or sets the Y coordinate of the hologram.
    /// </summary>
    public float Y { get; set; }

    /// <summary>
    /// Gets or sets the move speed of the hologram.
    /// </summary>
    public float MoveSpeed { get; set; }

    /// <summary>
    /// Initializes a new instance of the <see cref="Hologram"/> class with default values.
    /// </summary>
    public Hologram()
    {
        X = 0;
        Y = 0;
        MoveSpeed = 0.1f; // Default move speed
    }
}