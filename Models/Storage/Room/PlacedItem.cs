namespace DoggyLife.Models.Storage.Room;

public class PlacedItem
{
    public int Id { get; set; }

    // Item identification
    public string ItemId { get; set; } = string.Empty;
    public string ItemName { get; set; } = string.Empty;
    public string ItemType { get; set; } = string.Empty;

    // Position in 3D space
    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public float PositionZ { get; set; }

    // Rotation in radians
    public float Rotation { get; set; }

    // Size dimensions
    public float SizeX { get; set; }
    public float SizeY { get; set; }
    public float SizeZ { get; set; }

    // Placement type (floor or wall)
    public string PlacementType { get; set; } = string.Empty;

    // For wall items, which wall they're on
    public string? Wall { get; set; }

    // Timestamp when placed
    public DateTime PlacedAt { get; set; } = DateTime.UtcNow;
}
