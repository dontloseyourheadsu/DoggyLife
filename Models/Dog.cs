using Blazor.Extensions.Canvas.Canvas2D;
using DoggyLife;
using Microsoft.AspNetCore.Components;
using Action = DoggyLife.Action;

public class Dog
{
    public Dictionary<string, ElementReference> ImageElements { get; set; } = new();
    private ElementReference ImageElement => GetImage();
    private float x = 0;
    private float y = 0;
    private float width = 50;
    private float height = 50;
    private int imageTick = 0;
    private float speed = 1f;
    private Action action = Action.Walk;
    private Orientation orientation = Orientation.Front;
    private Random random = new Random();

    public Dog(int canvasWidth, int canvasHeight)
    {
        x = random.Next(0, canvasWidth - (int)width);
        y = random.Next(0, canvasHeight - (int)height);
    
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

    public void Move(int width, int height, int ticks)
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
        Console.WriteLine($"Action: {action}, Orientation: {orientation}");

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