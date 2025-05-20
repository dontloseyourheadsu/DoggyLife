using SkiaSharp;

namespace DoggyLife.Rendering.Isometric;

public static class IsometricFloorBuilder
{
    /// <summary>
    /// The angle of the isometric projection in degrees.
    /// </summary>
    private const float _isometricAngle = 20f;

    /// <summary>
    /// Grid size in pixels. Size of each cell.
    /// </summary>
    private const int _gridSize = 20;

    /// <summary>
    /// Number of cells horizontally.
    /// </summary>
    private const int _gridWidth = 10;

    /// <summary>
    /// Number of cells vertically.
    /// </summary>
    private const int _gridLength = 10;

    public static void DrawIsometricFloor(SKCanvas canvas, float width, float height)
    {
        // Calculate the center of the canvas
        float centerX = width / 2f;
        float centerY = height / 2f;

        // Define isometric projection angles
        // Standard isometric angle is approximately 30 degrees
        float isoAngle = _isometricAngle * (float)Math.PI / 180f;

        // Calculate isometric transformation factors
        float isoX = (float)Math.Cos(isoAngle);
        float isoY = (float)Math.Sin(isoAngle);

        // Define floor colors
        var floorColorDark = new SKColor(60, 60, 90);
        var floorColorLight = new SKColor(90, 90, 120);

        // Create paint objects for the grid
        var gridPaint = new SKPaint
        {
            IsAntialias = true,
            Color = SKColors.Gray,
            StrokeWidth = 1,
            Style = SKPaintStyle.Stroke
        };

        var tilePaint = new SKPaint
        {
            IsAntialias = true,
            Style = SKPaintStyle.Fill
        };

        // Calculate offset to center the grid
        float offsetX = centerX;
        float offsetY = centerY - (_gridWidth + _gridLength) * _gridSize * isoY / 4;

        // Draw the grid cells
        for (int x = 0; x < _gridWidth; x++)
        {
            for (int y = 0; y < _gridLength; y++)
            {
                // Create points for a grid cell in isometric projection
                var cellPath = new SKPath();

                // Calculate the four corners of the grid cell in isometric space
                float x1 = (x - y) * _gridSize * isoX + offsetX;
                float y1 = (x + y) * _gridSize * isoY + offsetY;

                float x2 = ((x + 1) - y) * _gridSize * isoX + offsetX;
                float y2 = ((x + 1) + y) * _gridSize * isoY + offsetY;

                float x3 = ((x + 1) - (y + 1)) * _gridSize * isoX + offsetX;
                float y3 = ((x + 1) + (y + 1)) * _gridSize * isoY + offsetY;

                float x4 = (x - (y + 1)) * _gridSize * isoX + offsetX;
                float y4 = (x + (y + 1)) * _gridSize * isoY + offsetY;

                // Draw the tile shape
                cellPath.MoveTo(x1, y1);
                cellPath.LineTo(x2, y2);
                cellPath.LineTo(x3, y3);
                cellPath.LineTo(x4, y4);
                cellPath.Close();

                // Use a checkerboard pattern for tiles
                if ((x + y) % 2 == 0)
                {
                    tilePaint.Color = floorColorLight;
                }
                else
                {
                    tilePaint.Color = floorColorDark;
                }

                // Fill the tile
                canvas.DrawPath(cellPath, tilePaint);

                // Draw the outline
                canvas.DrawPath(cellPath, gridPaint);
            }
        }
    }
}