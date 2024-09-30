using Blazor.Extensions.Canvas.Canvas2D;
using DoggyLife;
using Microsoft.AspNetCore.Components;
using Action = DoggyLife.Action;

public abstract class Dog
{
    public Dictionary<string, ElementReference> ImageElements { get; set; } = new();
    private ElementReference ImageElement => GetImage();
    protected float x = 0;
    protected float y = 0;
    protected float width = 50;
    protected float height = 50;
    private int imageTick = 0;
    protected float speed = 1f;
    private Action action = Action.Walk;
    protected Orientation orientation = Orientation.Right;
    private Random random = new Random();

    public Dog(int canvasWidth, int canvasHeight)
    {
        InitializePosition(canvasWidth, canvasHeight);
        InitializeImages();
    }

    // Abstract method for initializing position, to be defined by derived classes
    protected abstract void InitializePosition(int canvasWidth, int canvasHeight);

    // Method for loading image elements
    private void InitializeImages()
    {
        ImageElements = new()
        {
            { "backwalk-1", default },
            { "backwalk-2", default },
            { "backwalk-3", default },
            { "backwalk-4", default },
            { "frontsit-1", default },
            { "frontsit-2", default },
            { "frontsit-3", default },
            { "frontsit-4", default },
            { "frontwalk-1", default },
            { "frontwalk-2", default },
            { "frontwalk-3", default },
            { "frontwalk-4", default },
            { "rightsit-1", default },
            { "rightsit-2", default },
            { "rightsit-3", default },
            { "rightsit-4", default },
            { "rightwalk-1", default },
            { "rightwalk-2", default },
            { "rightwalk-3", default },
            { "rightwalk-4", default },
            { "leftsit-1", default },
            { "leftsit-2", default },
            { "leftsit-3", default },
            { "leftsit-4", default },
            { "leftwalk-1", default },
            { "leftwalk-2", default },
            { "leftwalk-3", default },
            { "leftwalk-4", default }
        };
    }

    public async Task Draw(Canvas2DContext context)
    {
        if (ImageElements.Count > 0)
        {
            await context.DrawImageAsync(ImageElement, x, y, width, height);
        }
    }

    public virtual void Move(int width, int height, int ticks)
    {
        HandlePeriodicDirectionChange(ticks);
        MoveDog();
        HandleBoundaryCollision(width, height);
        ClampPosition(width, height);
    }

    private void HandlePeriodicDirectionChange(int ticks)
    {
        if (ticks % 150 == 0)
        {
            ChangeDirection();
        }
    }

    private void MoveDog()
    {
        switch (orientation)
        {
            case Orientation.Front:
                y += speed;
                break;
            case Orientation.Back:
                y -= speed;
                break;
            case Orientation.Left:
                x -= speed;
                break;
            case Orientation.Right:
                x += speed;
                break;
        }
    }

    private void HandleBoundaryCollision(int width, int height)
    {
        bool hitBoundary = false;

        if (x <= 0 || x >= width - this.width)
        {
            hitBoundary = true;
            ReverseHorizontalDirection();
        }

        if (y <= 0 || y >= height - this.height)
        {
            hitBoundary = true;
            ReverseVerticalDirection();
        }

        if (hitBoundary)
        {
            ChangeDirection();
        }
    }

    private void ReverseHorizontalDirection()
    {
        if (orientation == Orientation.Left)
        {
            orientation = Orientation.Right;
        }
        else if (orientation == Orientation.Right)
        {
            orientation = Orientation.Left;
        }
    }

    private void ReverseVerticalDirection()
    {
        if (orientation == Orientation.Front)
        {
            orientation = Orientation.Back;
        }
        else if (orientation == Orientation.Back)
        {
            orientation = Orientation.Front;
        }
    }

    private void ClampPosition(int width, int height)
    {
        x = Math.Clamp(x, 0, width - this.width);
        y = Math.Clamp(y, 0, height - this.height);
    }

    private void ChangeDirection()
    {
        var values = Enum.GetValues(typeof(Orientation)).Cast<Orientation>().Where(o => o != orientation).ToArray();
        orientation = (Orientation)values.GetValue(random.Next(values.Length))!;
    }

    private void ChangeAction()
    {
        var values = Enum.GetValues(typeof(Action)).Cast<Action>().Where(a => a != action).ToArray();
        action = (Action)values.GetValue(random.Next(values.Length))!;
    }

    private ElementReference GetImage()
    {
        if (ImageElements.Count == 0)
        {
            Console.WriteLine($"No images found for dog with action: {action} and orientation: {orientation}");
            return default;
        }

        var actionValue = action.ToString().ToLower();
        var orientationValue = orientation.ToString().ToLower();

        imageTick = imageTick == 4 ? 1 : imageTick + 1;

        return ImageElements[$"{orientationValue}{actionValue}-{imageTick}"];
    }
}

public class RoomDog : Dog
{
    public RoomDog(int canvasWidth, int canvasHeight) : base(canvasWidth, canvasHeight) { }

    protected override void InitializePosition(int canvasWidth, int canvasHeight)
    {
        x = canvasWidth / 2;
        y = canvasHeight - height;
    }
}

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
