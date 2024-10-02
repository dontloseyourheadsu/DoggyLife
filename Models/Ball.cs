using Blazor.Extensions.Canvas.Canvas2D;
using Microsoft.AspNetCore.Components;

public class Ball
{
    public ElementReference ImageElement { get; set; }
    public float X { get; set; } = 100;
    public float Y { get; set; } = 0;
    private float previousX;
    private float previousY;
    private float radius = 12.5f;

    // Adjusted constants for smoother movement
    private const float Gravity = 0.2f;
    private const float Friction = 0.99f;
    private const float Bounce = 0.7f;

    public Ball()
    {
        previousX = X;
        previousY = Y;
    }

    public void Move(int canvasWidth, int canvasHeight, int ticks)
    {
        float tempX = X;
        float tempY = Y;

        // Calculate velocity
        float velocityX = (X - previousX) * Friction;
        float velocityY = (Y - previousY) * Friction;

        // Update position
        X += velocityX;
        Y += velocityY + Gravity;

        // Update previous position
        previousX = tempX;
        previousY = tempY;

        // Handle collisions
        HandleCollisions(canvasWidth, canvasHeight, velocityX, velocityY);
    }

    private void HandleCollisions(int canvasWidth, int canvasHeight, float velocityX, float velocityY)
    {
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
        await context.DrawImageAsync(ImageElement, X - radius, Y - radius, radius * 2, radius * 2);
    }

    public void SetPosition(float newX, float newY)
    {
        X = newX;
        Y = newY;
        previousX = newX;
        previousY = newY;
    }
}