using DoggyLife.Models.Objects;
using DoggyLife.Rendering;
using DoggyLife.Rendering.Isometric;
using DoggyLife.Settings;
using SkiaSharp;

namespace DoggyLife.Helpers;

/// <summary>
/// Provides helper methods for drawing objects in the DoggyLife game.
/// </summary>
public static class DrawingHelper
{
    /// <summary>
    /// Draws the dog on the canvas in an isometric view based on its position in the room.
    /// </summary>
    /// <param name="canvas">Graphics canvas to draw on.</param>
    /// <param name="room">The room the dog is in.</param>
    /// <param name="dog">The dog to draw.</param>
    /// <param name="deltaTime">Time since the last frame.</param>
    public static void DrawDog(SKCanvas canvas, Room room, Dog dog, float deltaTime)
    {
        // Calculate the isometric position for the dog
        float isoX = IsometricConfig.IsoX;
        float isoY = IsometricConfig.IsoY;
        float offsetX = IsometricConfig.GetOffsetX(room.Width);
        float offsetY = IsometricConfig.GetOffsetY(room.Height);

        // Convert screen coordinates to isometric grid coordinates
        float gridX = dog.X / room.Width * IsometricConfig.GridWidth;
        float gridY = dog.Y / room.Height * IsometricConfig.GridLength;

        // Convert grid coordinates to screen coordinates using isometric projection
        float dogScreenX = (gridX - gridY) * IsometricConfig.GridSize * isoX + offsetX;
        float dogScreenY = (gridX + gridY) * IsometricConfig.GridSize * isoY + offsetY;

        // Update and draw dog animations at the isometric position
        dog.Animation.Update(deltaTime);
        dog.Animation.Draw(canvas, dogScreenX, dogScreenY, dog.Scale);
    }

    /// <summary>
    /// Draws a hologram on the canvas in an isometric view based on its position in the room.
    /// </summary>
    /// <param name="canvas">Graphics canvas to draw on.</param>
    /// <param name="room">The room the hologram is in.</param>
    /// <param name="hologram">The hologram to draw.</param>
    public static void DrawFloorHologram(SKCanvas canvas, Room room, Hologram hologram)
    {
        float isoX = IsometricConfig.IsoX;
        float isoY = IsometricConfig.IsoY;
        float offsetX = IsometricConfig.GetOffsetX(room.Width);
        float offsetY = IsometricConfig.GetOffsetY(room.Height);
        var x = hologram.X;
        var y = hologram.Y;

        float x1 = (x - y) * IsometricConfig.GridSize * isoX + offsetX;
        float y1 = (x + y) * IsometricConfig.GridSize * isoY + offsetY;
        float x2 = ((x + 1) - y) * IsometricConfig.GridSize * isoX + offsetX;
        float y2 = ((x + 1) + y) * IsometricConfig.GridSize * isoY + offsetY;
        float x3 = ((x + 1) - (y + 1)) * IsometricConfig.GridSize * isoX + offsetX;
        float y3 = ((x + 1) + (y + 1)) * IsometricConfig.GridSize * isoY + offsetY;
        float x4 = (x - (y + 1)) * IsometricConfig.GridSize * isoX + offsetX;
        float y4 = (x + (y + 1)) * IsometricConfig.GridSize * isoY + offsetY;

        var path = new SKPath();
        path.MoveTo(x1, y1);
        path.LineTo(x2, y2);
        path.LineTo(x3, y3);
        path.LineTo(x4, y4);
        path.Close();

        var fill = new SKPaint
        {
            IsAntialias = true,
            Color = new SKColor(0, 255, 0, 128),
            Style = SKPaintStyle.Fill
        };
        var stroke = new SKPaint
        {
            IsAntialias = true,
            Color = new SKColor(0, 255, 0, 255),
            Style = SKPaintStyle.Stroke,
            StrokeWidth = 2
        };

        canvas.DrawPath(path, fill);
        canvas.DrawPath(path, stroke);
    }

    /// <summary>
    /// Draws a wall hologram on the canvas in an isometric view based on its position in the room.
    /// </summary>
    /// <param name="canvas">Graphics canvas to draw on.</param>
    /// <param name="room">The room the hologram is in.</param>
    /// <param name="hologram">The hologram to draw.</param>
    public static void DrawWallHologram(SKCanvas canvas, Room room, Hologram hologram)
    {
        float isoX = IsometricConfig.IsoX;
        float isoY = IsometricConfig.IsoY;
        float offsetX = IsometricConfig.GetOffsetX(room.Width);
        float offsetY = IsometricConfig.GetOffsetY(room.Height);

        float x1, y1, x2, y2;

        // Calculate base points for wall segment based on side
        if (hologram.WallCursor.Side == WallSide.Left)
        {
            // Left wall logic
            float y = hologram.WallCursor.Position;
            x1 = (0 - y) * IsometricConfig.GridSize * isoX + offsetX;
            y1 = (0 + y) * IsometricConfig.GridSize * isoY + offsetY;
            x2 = (0 - (y + 1)) * IsometricConfig.GridSize * isoX + offsetX;
            y2 = (0 + (y + 1)) * IsometricConfig.GridSize * isoY + offsetY;
        }
        else // Right wall
        {
            float x = hologram.WallCursor.Position;
            x1 = (x - 0) * IsometricConfig.GridSize * isoX + offsetX;
            y1 = (x + 0) * IsometricConfig.GridSize * isoY + offsetY;
            x2 = ((x + 1) - 0) * IsometricConfig.GridSize * isoX + offsetX;
            y2 = ((x + 1) + 0) * IsometricConfig.GridSize * isoY + offsetY;
        }

        // Calculate the height offset in pixels
        float baseWallHeight = hologram.WallCursor.Height * IsometricConfig.GridSize * isoY;
        float hologramHeight = IsometricConfig.GridSize * isoY * 0.3f;

        // Draw visual guides to show where the wall will connect to the floor
        var guidePaint = new SKPaint
        {
            IsAntialias = true,
            Color = new SKColor(255, 255, 0, 150),
            Style = SKPaintStyle.Stroke,
            StrokeWidth = 1,
            PathEffect = SKPathEffect.CreateDash(new float[] { 4, 4 }, 0)
        };

        // Draw guides from floor to wall base
        canvas.DrawLine(x1, y1, x1, y1 - baseWallHeight, guidePaint);
        canvas.DrawLine(x2, y2, x2, y2 - baseWallHeight, guidePaint);

        // Calculate points for the wall hologram
        var path = new SKPath();

        // Bottom edge at current height
        path.MoveTo(x1, y1 - baseWallHeight);
        path.LineTo(x2, y2 - baseWallHeight);

        // Top edge at hologram height above current height
        float x3 = x2;
        float y3 = y2 - baseWallHeight - hologramHeight;
        float x4 = x1;
        float y4 = y1 - baseWallHeight - hologramHeight;

        path.LineTo(x3, y3);
        path.LineTo(x4, y4);
        path.Close();

        // Draw the hologram
        var fill = new SKPaint
        {
            IsAntialias = true,
            Color = new SKColor(0, 255, 0, 128),
            Style = SKPaintStyle.Fill
        };
        var stroke = new SKPaint
        {
            IsAntialias = true,
            Color = new SKColor(0, 255, 0, 255),
            Style = SKPaintStyle.Stroke,
            StrokeWidth = 2
        };

        canvas.DrawPath(path, fill);
        canvas.DrawPath(path, stroke);

        // Draw connection points
        var pointPaint = new SKPaint
        {
            IsAntialias = true,
            Color = SKColors.Yellow,
            Style = SKPaintStyle.Fill
        };

        // Draw indicators at the connection points
        canvas.DrawCircle(x1, y1 - baseWallHeight, 3, pointPaint);
        canvas.DrawCircle(x2, y2 - baseWallHeight, 3, pointPaint);

        // Add grid indicator
        var gridPaint = new SKPaint
        {
            IsAntialias = true,
            Color = SKColors.Red,
            Style = SKPaintStyle.Fill
        };

        // Draw position indicator on the floor
        if (hologram.WallCursor.Side == WallSide.Right)
        {
            float x = hologram.WallCursor.Position;
            float floorX = (x - 0) * IsometricConfig.GridSize * isoX + offsetX;
            float floorY = (x + 0) * IsometricConfig.GridSize * isoY + offsetY;
            canvas.DrawCircle(floorX, floorY, 4, gridPaint);
        }
        else // Left wall
        {
            float y = hologram.WallCursor.Position;
            float floorX = (0 - y) * IsometricConfig.GridSize * isoX + offsetX;
            float floorY = (0 + y) * IsometricConfig.GridSize * isoY + offsetY;
            canvas.DrawCircle(floorX, floorY, 4, gridPaint);
        }
    }
}