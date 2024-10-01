using DoggyLife;

public class GardenDog : Dog
{
    public GardenDog(int canvasWidth, int canvasHeight) : base(canvasWidth, canvasHeight) { }

    // Initialize position at the bottom of the canvas
    protected override void InitializePosition(int canvasWidth, int canvasHeight)
    {
        x = 0;  // Start from the left edge
        y = canvasHeight - height;  // Always stay at the bottom
        orientation = Orientation.Right; // Start moving right
    }

    // Override movement logic to only move left and right at the bottom
    public override void Move(int canvasWidth, int canvasHeight, int ticks)
    {
        if (orientation == Orientation.Right)
        {
            x += speed; // Move right
        }
        else if (orientation == Orientation.Left)
        {
            x -= speed; // Move left
        }

        // If the dog hits the left or right boundary, reverse direction
        if (x <= 0)
        {
            orientation = Orientation.Right;
        }
        else if (x >= canvasWidth - width)
        {
            orientation = Orientation.Left;
        }

        // Keep y fixed at the bottom
        y = canvasHeight - height;
    }
}
