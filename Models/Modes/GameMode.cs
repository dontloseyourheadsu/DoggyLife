namespace DoggyLife.Models.Modes;

/// <summary>
/// Enum representing different game room modes.
/// </summary>
public enum RoomMode
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
