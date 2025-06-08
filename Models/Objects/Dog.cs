using DoggyLife.Rendering;

namespace DoggyLife.Models.Objects;

/// <summary>
/// Represents a Dog object in the DoggyLife game.
/// </summary>
public class Dog
{
    /// <summary>
    /// Gets or sets the X coordinate of the dog.
    /// </summary>
    public float X { get; set; }

    /// <summary>
    /// Gets or sets the Y coordinate of the dog.
    /// </summary>
    public float Y { get; set; }

    /// <summary>
    /// Gets or sets the scale of the dog.
    /// </summary>
    public float Scale { get; set; }

    /// <summary>
    /// Gets or sets the size of the dog, which is used for rendering and collision detection.
    /// </summary>
    public float Size { get; set; }

    /// <summary>
    /// Gets or sets the animation state of the dog.
    /// </summary>
    public DogAnimation Animation { get; set; }

    /// <summary>
    /// Initializes a new instance of the <see cref="Dog"/> class.
    /// </summary>
    public Dog()
    {
        X = 0;
        Y = 0;
        Scale = 1.0f;
        Animation = new DogAnimation();
    }
}