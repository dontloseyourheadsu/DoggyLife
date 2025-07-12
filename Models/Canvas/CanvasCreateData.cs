namespace DoggyLife.Models.Canvas;

/// <summary>
/// Represents the data required to create a canvas in the application.
/// </summary>
class CanvasCreateData
{
    /// <summary>
    /// The type of canvas to create (e.g., "room").
    /// </summary>
    public required string CanvasType { get; set; }

    /// <summary>
    /// The ID of the container where the canvas will be created.
    /// </summary>
    public required string CanvasContainerId { get; set; }

    /// <summary>
    /// Additional data required for creating the canvas, such as room data.
    /// </summary>
    public required object AdditionalData { get; set; }
}