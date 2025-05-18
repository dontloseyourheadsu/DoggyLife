﻿using DoggyLife.Helpers;
using SkiaSharp;
using System.Drawing;
using System.Numerics;

namespace DoggyLife.Physics;

/// <summary>
/// Distance constraint (spring) between two Verlet points.
/// </summary>
public class VerletSpring
{
    /// <summary>
    /// The first Verlet point.
    /// </summary>
    public readonly VerletPoint P1;

    /// <summary>
    /// The second Verlet point.
    /// </summary>
    public readonly VerletPoint P2;

    /// <summary>
    /// The length the spring tries to maintain.
    /// </summary>
    public float RestLength;

    /// <summary>
    /// Stiffness of the correction (0 – 1). 1 = full correction in a single sub-step.
    /// </summary>
    public float Stiffness;

    private SKPaint SKPaint { get; set; } = new SKPaint
    {
        Style = SKPaintStyle.Stroke,
        StrokeWidth = 2f,
        IsAntialias = true
    };

    /// <summary>
    /// Creates a new spring between two points.
    /// </summary>
    /// <param name="p1">First point.</param>
    /// <param name="p2">Second point.</param>
    /// <param name="stiffness">Stiffness of the spring (0 – 1).</param>
    /// <param name="thickness">Thickness of the spring when drawn.</param>
    public VerletSpring(VerletPoint p1, VerletPoint p2, SKColor skColor, float stiffness = 1f, float thickness = 2f)
    {
        P1 = p1;
        P2 = p2;
        RestLength = Vector2.Distance(p1.Position, p2.Position);
        Stiffness = MathHelper.Clamp(stiffness, 0f, 1f);
        SKPaint.StrokeWidth = thickness;
        SKPaint.Color = skColor;
    }

    /// <summary>
    /// Applies distance correction using positional integration.
    /// </summary>
    public void SatisfyConstraint()
    {
        // No correction needed if both points are fixed.
        if (P1.IsFixed && P2.IsFixed) return;

        Vector2 delta = P2.Position - P1.Position;
        float dist = delta.Length();
        if (dist <= 1e-5f) return; // Prevent division by zero

        float diff = (dist - RestLength) / dist; // Deviation factor
        Vector2 correction = delta * diff * Stiffness;

        float totalMass = P1.Mass + P2.Mass;

        if (!P1.IsFixed)
            P1.Position += correction * (P2.Mass / totalMass); // Move proportional to mass

        if (!P2.IsFixed)
            P2.Position -= correction * (P1.Mass / totalMass);
    }

    /// <summary>
    /// Draws the spring as a line.
    /// </summary>
    /// <param name="sb">SpriteBatch used for drawing.</param>
    public void Draw(SKCanvas sb)
    {
        sb.DrawLine(P1.Position, P2.Position, SKPaint);
    }
}