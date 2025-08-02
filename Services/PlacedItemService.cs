using DoggyLife.Data.Database;
using DoggyLife.Models.Storage.Room;
using Microsoft.EntityFrameworkCore;

namespace DoggyLife.Services;

public class PlacedItemService
{
    private readonly SqliteWasmHelper.ISqliteWasmDbContextFactory<AppDbContext> _dbContextFactory;
    private static bool _isInitialized = false;

    public PlacedItemService(SqliteWasmHelper.ISqliteWasmDbContextFactory<AppDbContext> dbContextFactory)
    {
        _dbContextFactory = dbContextFactory;
    }

    public Task InitializeAsync()
    {
        if (_isInitialized) return Task.CompletedTask;

        _isInitialized = true;
        return Task.CompletedTask;
    }

    /// <summary>
    /// Save a placed item to the database
    /// </summary>
    public async Task<PlacedItem> SavePlacedItemAsync(PlacedItem item)
    {
        await InitializeAsync();

        try
        {
            Console.WriteLine($"Attempting to save placed item: {item.ItemName} at ({item.PositionX}, {item.PositionY}, {item.PositionZ})");

            using var context = await _dbContextFactory.CreateDbContextAsync();
            context.PlacedItems.Add(item);
            var result = await context.SaveChangesAsync();

            Console.WriteLine($"Database save completed. Changes saved: {result}");
            Console.WriteLine($"Placed item ID after save: {item.Id}");

            return item;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error saving placed item: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            throw; // Re-throw to let the calling code handle it
        }
    }

    /// <summary>
    /// Get all placed items from the database
    /// </summary>
    public async Task<List<PlacedItem>> GetAllPlacedItemsAsync()
    {
        await InitializeAsync();

        try
        {
            using var context = await _dbContextFactory.CreateDbContextAsync();
            return await context.PlacedItems
                .OrderBy(item => item.PlacedAt)
                .ToListAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading placed items: {ex.Message}");
            return new List<PlacedItem>();
        }
    }

    /// <summary>
    /// Get placed items by placement type (floor or wall)
    /// </summary>
    public async Task<List<PlacedItem>> GetPlacedItemsByTypeAsync(string placementType)
    {
        await InitializeAsync();

        using var context = await _dbContextFactory.CreateDbContextAsync();
        return await context.PlacedItems
            .Where(item => item.PlacementType == placementType)
            .OrderBy(item => item.PlacedAt)
            .ToListAsync();
    }

    /// <summary>
    /// Delete a placed item by ID
    /// </summary>
    public async Task<bool> DeletePlacedItemAsync(int itemId)
    {
        await InitializeAsync();

        using var context = await _dbContextFactory.CreateDbContextAsync();
        var item = await context.PlacedItems.FindAsync(itemId);
        if (item == null)
            return false;

        context.PlacedItems.Remove(item);
        await context.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Clear all placed items
    /// </summary>
    public async Task ClearAllPlacedItemsAsync()
    {
        await InitializeAsync();

        using var context = await _dbContextFactory.CreateDbContextAsync();
        context.PlacedItems.RemoveRange(context.PlacedItems);
        await context.SaveChangesAsync();
    }
}
