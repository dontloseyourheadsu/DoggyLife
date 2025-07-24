namespace DoggyLife.Models.Room;

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

    // Size properties - using generic naming to work for both floor and wall items
    // For floor items: SizeX = width, SizeZ = depth, height calculated in JS
    // For wall items: SizeX = width, SizeY = height, depth calculated in JS
    public int SizeX { get; set; } // Width for both floor and wall items
    public int SizeY { get; set; } // Height for wall items, depth for floor items  
    public int SizeZ { get; set; } // Depth for floor items, width for wall items (alternative dimension)
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
