namespace DoggyLife.Models;

/// <summary>
/// Represents different environments in the application.
/// </summary>
public enum GameEnvironment
{
    /// <summary>
    /// Represents the settings environment.
    /// </summary>
    Settings = -1,
    /// <summary>
    /// Represents no specific environment.
    /// </summary>
    None = 0,
    /// <summary>
    /// Represents the home environment.
    /// </summary>
    Home = 1,
    /// <summary>
    /// Represents the room appearance customization environment.
    /// </summary>
    RoomAppearance = 2,
}