using DoggyLife.Settings;
using SkiaSharp;

namespace DoggyLife.Rendering.Isometric;

public static class IsometricFloorBuilder
{
    public static void DrawIsometricFloor(
        SKCanvas canvas,
        float width,
        float height,
        SKColor floorColorLight,
        SKColor floorColorDark,
        SKColor outlineColor = default)
    {
        // Use default gray outline if not specified
        outlineColor = outlineColor == default ? SKColors.Gray : outlineColor;

        // Calculate the center of the canvas
        float centerX = width / 2f;
        float centerY = height / 2f;

        // Get isometric transformation factors
        float isoX = IsometricConfig.IsoX;
        float isoY = IsometricConfig.IsoY;

        // Create paint objects for the grid
        var gridPaint = new SKPaint
        {
            IsAntialias = true,
            Color = outlineColor,
            StrokeWidth = 1,
            Style = SKPaintStyle.Stroke
        };

        var tilePaint = new SKPaint
        {
            IsAntialias = true,
            Style = SKPaintStyle.Fill
        };

        // Calculate offset to center the grid
        float offsetX = IsometricConfig.GetOffsetX(width);
        float offsetY = IsometricConfig.GetOffsetY(height);

        // Draw the grid cells
        for (int x = 0; x < IsometricConfig.GridWidth; x++)
        {
            for (int y = 0; y < IsometricConfig.GridLength; y++)
            {
                // Create points for a grid cell in isometric projection
                var cellPath = new SKPath();

                // Calculate the four corners of the grid cell in isometric space
                float x1 = (x - y) * IsometricConfig.GridSize * isoX + offsetX;
                float y1 = (x + y) * IsometricConfig.GridSize * isoY + offsetY;

                float x2 = ((x + 1) - y) * IsometricConfig.GridSize * isoX + offsetX;
                float y2 = ((x + 1) + y) * IsometricConfig.GridSize * isoY + offsetY;

                float x3 = ((x + 1) - (y + 1)) * IsometricConfig.GridSize * isoX + offsetX;
                float y3 = ((x + 1) + (y + 1)) * IsometricConfig.GridSize * isoY + offsetY;

                float x4 = (x - (y + 1)) * IsometricConfig.GridSize * isoX + offsetX;
                float y4 = (x + (y + 1)) * IsometricConfig.GridSize * isoY + offsetY;

                // Draw the tile shape
                cellPath.MoveTo(x1, y1);
                cellPath.LineTo(x2, y2);
                cellPath.LineTo(x3, y3);
                cellPath.LineTo(x4, y4);
                cellPath.Close();

                // Use a checkerboard pattern for tiles
                tilePaint.Color = (x + y) % 2 == 0 ? floorColorLight : floorColorDark;

                // Fill the tile
                canvas.DrawPath(cellPath, tilePaint);

                // Draw the outline
                canvas.DrawPath(cellPath, gridPaint);
            }
        }
    }
}