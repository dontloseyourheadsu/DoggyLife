using DoggyLife.Models.Modes;
using DoggyLife.Models.Room;

namespace DoggyLife.Services;

/// <summary>
/// Service for managing hologram items and their availability based on game mode.
/// </summary>
public class HologramItemService
{
    private readonly Dictionary<HologramItemType, HologramItem> _items;

    public HologramItemService()
    {
        // Room size is 400x400, so bounds are -200 to 200 in each direction
        // Setting reasonable default sizes relative to room size
        _items = new Dictionary<HologramItemType, HologramItem>
        {
            // Floor items (SizeX = width, SizeY = depth, SizeZ will be calculated as height in JS)
            {
                HologramItemType.Bed,
                new HologramItem
                {
                    Id = "bed",
                    Name = "bed",
                    DisplayName = "Bed",
                    Description = "A comfortable sleeping place",
                    Type = HologramItemType.Bed,
                    SizeX = 120, // Width - reasonable bed width for 400 room
                    SizeY = 80,  // Depth - bed depth
                    SizeZ = 40   // Height will be calculated in JS, this is placeholder
                }
            },
            {
                HologramItemType.Shelf,
                new HologramItem
                {
                    Id = "shelf",
                    Name = "shelf",
                    DisplayName = "Shelf",
                    Description = "Storage furniture for items",
                    Type = HologramItemType.Shelf,
                    SizeX = 100, // Width
                    SizeY = 30,  // Depth - shelves are typically shallow
                    SizeZ = 80   // Height will be calculated in JS, this is placeholder
                }
            },
            {
                HologramItemType.Couch,
                new HologramItem
                {
                    Id = "couch",
                    Name = "couch",
                    DisplayName = "Couch",
                    Description = "A comfortable seating furniture",
                    Type = HologramItemType.Couch,
                    SizeX = 150, // Width - longer than bed
                    SizeY = 70,  // Depth
                    SizeZ = 35   // Height will be calculated in JS, this is placeholder
                }
            },
            
            // Wall items (SizeX = width, SizeY = height, SizeZ will be calculated as depth in JS)
            {
                HologramItemType.Window,
                new HologramItem
                {
                    Id = "window",
                    Name = "window",
                    DisplayName = "Window",
                    Description = "A window for natural light",
                    Type = HologramItemType.Window,
                    SizeX = 80,  // Width
                    SizeY = 100, // Height
                    SizeZ = 10   // Depth will be calculated in JS, this is placeholder
                }
            },
            {
                HologramItemType.Painting,
                new HologramItem
                {
                    Id = "painting",
                    Name = "painting",
                    DisplayName = "Painting",
                    Description = "Decorative wall art",
                    Type = HologramItemType.Painting,
                    SizeX = 60,  // Width
                    SizeY = 80,  // Height
                    SizeZ = 5    // Depth will be calculated in JS, this is placeholder
                }
            }
        };
    }

    /// <summary>
    /// Gets available hologram items based on the current room mode.
    /// </summary>
    /// <param name="roomMode">The current room mode</param>
    /// <returns>List of available hologram items</returns>
    public List<HologramItem> GetAvailableItems(RoomMode roomMode)
    {
        return roomMode switch
        {
            RoomMode.FloorEditor => GetFloorItems(),
            RoomMode.WallEditor => GetWallItems(),
            _ => new List<HologramItem>()
        };
    }

    /// <summary>
    /// Gets all floor-related hologram items.
    /// </summary>
    /// <returns>List of floor items</returns>
    public List<HologramItem> GetFloorItems()
    {
        return _items.Values
            .Where(item => item.Type == HologramItemType.Bed ||
                          item.Type == HologramItemType.Shelf ||
                          item.Type == HologramItemType.Couch)
            .ToList();
    }

    /// <summary>
    /// Gets all wall-related hologram items.
    /// </summary>
    /// <returns>List of wall items</returns>
    public List<HologramItem> GetWallItems()
    {
        return [.. _items.Values
            .Where(item => item.Type == HologramItemType.Window ||
                          item.Type == HologramItemType.Painting)];
    }

    /// <summary>
    /// Gets a specific hologram item by its ID.
    /// </summary>
    /// <param name="itemId">The item ID</param>
    /// <returns>The hologram item if found, null otherwise</returns>
    public HologramItem? GetItemById(string itemId)
    {
        return _items.Values.FirstOrDefault(item => item.Id == itemId);
    }
}
