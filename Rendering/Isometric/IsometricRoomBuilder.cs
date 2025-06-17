using DoggyLife.Services;
using SkiaSharp;

namespace DoggyLife.Rendering.Isometric;

public static class IsometricRoomBuilder
{
    public static void DrawIsometricRoom(SKCanvas canvas, int width, int height, RoomService? roomService = null)
    {
        var floorColors = roomService?.GetFloorColors() ?? new List<SKColor>
        {
            new SKColor(90, 90, 120),
            new SKColor(50, 50, 70)
        };

        // Draw the isometric floor in the middle of the canvas
        IsometricFloorBuilder.DrawIsometricFloor(canvas, width, height,
            floorColors[0],  // light floor color
            floorColors[1]   // dark floor color
        );

        var wallColors = roomService?.GetWallColors() ?? new List<SKColor>
        {
            new SKColor(70, 70, 100),  // light wall color
            new SKColor(70, 70, 100),  // dark wall color
            new SKColor(30, 30, 50),  // optional outline color
            new SKColor(30, 30, 50)    // optional stripe color
        };

        // Draw walls on both sides
        IsometricWallBuilder.DrawVerticalWall(
            canvas,
            width,
            height,
            WallSide.Left,
            wallColors[0],  // light wall color
            wallColors[1],  // dark wall color
            wallColors[2],  // optional outline color
            wallColors[3]   // optional stripe color
            );
        IsometricWallBuilder.DrawVerticalWall(
            canvas,
            width,
            height,
            WallSide.Right,
            wallColors[0],  // light wall color
            wallColors[1],  // dark wall color
            wallColors[2],  // optional outline color
            wallColors[3]   // optional stripe color
            );
    }
}
