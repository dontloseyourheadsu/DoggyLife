namespace DoggyLife.Models;

/// <summary>
/// Enum representing different game modes.
/// </summary>
public enum GameMode
{
    /// <summary>
    /// Game mode for editing the floor.
    /// </summary>
    FloorEditor,

    /// <summary>
    /// Game mode for editing the wall.
    /// </summary>
    WallEditor,

    /// <summary>
    /// Game mode for editing the roof.
    /// </summary>
    Viewer,

    /// <summary>
    /// Game mode for interacting with the game.
    /// </summary>
    Interaction,
}
