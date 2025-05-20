using DoggyLife.Settings;
using SkiaSharp;

namespace DoggyLife.Rendering.Isometric;

public static class IsometricWallBuilder
{
    /// <summary>
    /// Draws an isometric wall with vertical stripes on the specified side of the floor
    /// </summary>
    /// <param name="canvas">The canvas to draw on</param>
    /// <param name="canvasWidth">Width of the canvas</param>
    /// <param name="canvasHeight">Height of the canvas</param>
    /// <param name="side">Which side of the floor to place the wall</param>
    /// <param name="wallColorLight">Light color for wall sections</param>
    /// <param name="wallColorDark">Dark color for wall sections</param>
    /// <param name="outlineColor">Color for wall outlines</param>
    /// <param name="stripeColor">Color for the vertical stripes</param>
    public static void DrawVerticalWall(
        SKCanvas canvas,
        float canvasWidth,
        float canvasHeight,
        WallSide side,
        SKColor wallColorLight,
        SKColor wallColorDark,
        SKColor outlineColor = default,
        SKColor stripeColor = default)
    {
        // Use default colors if not specified
        outlineColor = outlineColor == default ? SKColors.Gray : outlineColor;
        stripeColor = stripeColor == default ? new SKColor(40, 40, 60) : stripeColor;

        // Get isometric transformation factors
        float isoX = IsometricConfig.IsoX;
        float isoY = IsometricConfig.IsoY;

        // Get offsets for centering
        float offsetX = IsometricConfig.GetOffsetX(canvasWidth);
        float offsetY = IsometricConfig.GetOffsetY(canvasHeight);

        // Create paint objects for wall
        var wallOutlinePaint = new SKPaint
        {
            IsAntialias = true,
            Color = outlineColor,
            StrokeWidth = 1,
            Style = SKPaintStyle.Stroke
        };

        var wallFillPaint = new SKPaint
        {
            IsAntialias = true,
            Style = SKPaintStyle.Fill
        };

        var stripePaint = new SKPaint
        {
            IsAntialias = true,
            Color = stripeColor,
            StrokeWidth = 1.5f,
            Style = SKPaintStyle.Stroke
        };

        // Determine which wall to draw based on side parameter
        if (side == WallSide.Left)
        {
            DrawLeftWall(canvas, offsetX, offsetY, isoX, isoY, wallFillPaint, wallOutlinePaint, stripePaint, wallColorLight, wallColorDark);
        }
        else // Right side
        {
            DrawRightWall(canvas, offsetX, offsetY, isoX, isoY, wallFillPaint, wallOutlinePaint, stripePaint, wallColorLight, wallColorDark);
        }
    }

    private static void DrawLeftWall(
        SKCanvas canvas,
        float offsetX,
        float offsetY,
        float isoX,
        float isoY,
        SKPaint wallFillPaint,
        SKPaint wallOutlinePaint,
        SKPaint stripePaint,
        SKColor wallColorLight,
        SKColor wallColorDark)
    {
        // Draw the left wall (along the y-axis)
        for (int y = 0; y < IsometricConfig.GridLength; y++)
        {
            // Create the wall surface
            var wallPath = new SKPath();

            // Bottom-left corner of the floor tile
            float x1 = (0 - y) * IsometricConfig.GridSize * isoX + offsetX;
            float y1 = (0 + y) * IsometricConfig.GridSize * isoY + offsetY;

            // Bottom-right corner of the floor tile
            float x2 = (0 - (y + 1)) * IsometricConfig.GridSize * isoX + offsetX;
            float y2 = (0 + (y + 1)) * IsometricConfig.GridSize * isoY + offsetY;

            // Top-right corner (vertically up from bottom-right)
            float x3 = x2;
            float y3 = y2 - IsometricConfig.WallHeight * IsometricConfig.GridSize * isoY;

            // Top-left corner (vertically up from bottom-left)
            float x4 = x1;
            float y4 = y1 - IsometricConfig.WallHeight * IsometricConfig.GridSize * isoY;

            // Draw the wall shape
            wallPath.MoveTo(x1, y1);
            wallPath.LineTo(x2, y2);
            wallPath.LineTo(x3, y3);
            wallPath.LineTo(x4, y4);
            wallPath.Close();

            // Set wall color (alternate between dark and light)
            wallFillPaint.Color = y % 2 == 0 ? wallColorLight : wallColorDark;

            // Fill and outline the wall
            canvas.DrawPath(wallPath, wallFillPaint);
            canvas.DrawPath(wallPath, wallOutlinePaint);

            // Draw vertical stripes
            int numStripes = 4; // Number of vertical stripes per section
            for (int i = 1; i < numStripes; i++)
            {
                float ratio = i / (float)numStripes;
                float stripeX1 = x1 + (x2 - x1) * ratio;
                float stripeY1 = y1 + (y2 - y1) * ratio;
                float stripeX2 = x4 + (x3 - x4) * ratio;
                float stripeY2 = y4 + (y3 - y4) * ratio;

                canvas.DrawLine(stripeX1, stripeY1, stripeX2, stripeY2, stripePaint);
            }
        }
    }

    private static void DrawRightWall(
        SKCanvas canvas,
        float offsetX,
        float offsetY,
        float isoX,
        float isoY,
        SKPaint wallFillPaint,
        SKPaint wallOutlinePaint,
        SKPaint stripePaint,
        SKColor wallColorLight,
        SKColor wallColorDark)
    {
        // Draw the right wall (along the x-axis)
        for (int x = 0; x < IsometricConfig.GridWidth; x++)
        {
            // Create the wall surface
            var wallPath = new SKPath();

            // Bottom-left corner of the floor tile
            float x1 = (x - 0) * IsometricConfig.GridSize * isoX + offsetX;
            float y1 = (x + 0) * IsometricConfig.GridSize * isoY + offsetY;

            // Bottom-right corner of the floor tile
            float x2 = ((x + 1) - 0) * IsometricConfig.GridSize * isoX + offsetX;
            float y2 = ((x + 1) + 0) * IsometricConfig.GridSize * isoY + offsetY;

            // Top-right corner (vertically up from bottom-right)
            float x3 = x2;
            float y3 = y2 - IsometricConfig.WallHeight * IsometricConfig.GridSize * isoY;

            // Top-left corner (vertically up from bottom-left)
            float x4 = x1;
            float y4 = y1 - IsometricConfig.WallHeight * IsometricConfig.GridSize * isoY;

            // Draw the wall shape
            wallPath.MoveTo(x1, y1);
            wallPath.LineTo(x2, y2);
            wallPath.LineTo(x3, y3);
            wallPath.LineTo(x4, y4);
            wallPath.Close();

            // Set wall color (alternate between dark and light)
            wallFillPaint.Color = x % 2 == 0 ? wallColorLight : wallColorDark;

            // Fill and outline the wall
            canvas.DrawPath(wallPath, wallFillPaint);
            canvas.DrawPath(wallPath, wallOutlinePaint);

            // Draw vertical stripes
            int numStripes = 4; // Number of vertical stripes per section
            for (int i = 1; i < numStripes; i++)
            {
                float ratio = i / (float)numStripes;
                float stripeX1 = x1 + (x2 - x1) * ratio;
                float stripeY1 = y1 + (y2 - y1) * ratio;
                float stripeX2 = x4 + (x3 - x4) * ratio;
                float stripeY2 = y4 + (y3 - y4) * ratio;

                canvas.DrawLine(stripeX1, stripeY1, stripeX2, stripeY2, stripePaint);
            }
        }
    }
}