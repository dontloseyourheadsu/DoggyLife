using Blazor.Extensions.Canvas.Canvas2D;
using Microsoft.AspNetCore.Components;

namespace DoggyLife.Models;

public class Ball
{
    public ElementReference ImageElement { get; set; }

    public float X { get; set; } = 100;
    public float Y { get; set; } = 0;
    private float previousX;
    private float previousY;
    private float radius = 12.5f; // Half of 25 to match your original size

    private const float Gravity = 0.5f;
    private const float Friction = 0.99f;
    private const float Bounce = 0.8f;

    public Ball()
    {
        // Initialize previous position to current position
        previousX = X;
        previousY = Y;
    }

    public void Move(int canvasWidth, int canvasHeight, int ticks)
    {
        // Save current position
        float tempX = X;
        float tempY = Y;

        // Verlet integration
        float velocityX = (X - previousX) * Friction;
        float velocityY = (Y - previousY) * Friction;

        // Update position
        X += velocityX;
        Y += velocityY;
        Y += Gravity; // Apply gravity

        // Update previous position
        previousX = tempX;
        previousY = tempY;

        // Handle collisions with canvas borders
        if (X + radius > canvasWidth)
        {
            X = canvasWidth - radius;
            previousX = X + velocityX * Bounce;
        }
        else if (X - radius < 0)
        {
            X = radius;
            previousX = X + velocityX * Bounce;
        }

        if (Y + radius > canvasHeight)
        {
            Y = canvasHeight - radius;
            previousY = Y + velocityY * Bounce;
        }
        else if (Y - radius < 0)
        {
            Y = radius;
            previousY = Y + velocityY * Bounce;
        }
    }

    public void ApplyForce(float forceX, float forceY)
    {
        previousX -= forceX;
        previousY -= forceY;
    }

    public async Task Draw(Canvas2DContext context)
    {
        // Adjust x and y to account for the image being drawn from top-left corner
        await context.DrawImageAsync(ImageElement, X - radius, Y - radius, radius * 2, radius * 2);
    }

    // Method to set the ball's position directly (useful for initialization or testing)
    public void SetPosition(float newX, float newY)
    {
        X = newX;
        Y = newY;
        previousX = newX;
        previousY = newY;
    }
}