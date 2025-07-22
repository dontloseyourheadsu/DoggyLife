namespace DoggyLife.Models.Canvas;

/// <summary>
/// Represents a hologram item that can be selected and placed.
/// </summary>
public class HologramItem
{
    public required string Id { get; set; }
    public required string Name { get; set; }
    public required string DisplayName { get; set; }
    public string Description { get; set; } = string.Empty;
    public required HologramItemType Type { get; set; }
}

/// <summary>
/// Types of hologram items available for placement.
/// </summary>
public enum HologramItemType
{
    // Floor items
    Bed,
    Shelf,
    Couch,

    // Wall items
    Window,
    Painting
}
