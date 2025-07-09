namespace DoggyLife.Models.Storage.Settings;

public class RoomSettings
{
    public int Id { get; set; }

    // Floor colors
    public byte FloorLightRed { get; set; } = 90;
    public byte FloorLightGreen { get; set; } = 90;
    public byte FloorLightBlue { get; set; } = 120;

    public byte FloorDarkRed { get; set; } = 50;
    public byte FloorDarkGreen { get; set; } = 50;
    public byte FloorDarkBlue { get; set; } = 70;

    // Wall colors
    public byte WallLightRed { get; set; } = 70;
    public byte WallLightGreen { get; set; } = 70;
    public byte WallLightBlue { get; set; } = 100;

    public byte WallDarkRed { get; set; } = 70;
    public byte WallDarkGreen { get; set; } = 70;
    public byte WallDarkBlue { get; set; } = 100;

    public byte WallOutlineRed { get; set; } = 30;
    public byte WallOutlineGreen { get; set; } = 30;
    public byte WallOutlineBlue { get; set; } = 50;

    public byte WallStripeRed { get; set; } = 30;
    public byte WallStripeGreen { get; set; } = 30;
    public byte WallStripeBlue { get; set; } = 50;

    // Color helper methods
    public DoggyLife.Models.Color GetFloorLightColor() => new(FloorLightRed, FloorLightGreen, FloorLightBlue);
    public DoggyLife.Models.Color GetFloorDarkColor() => new(FloorDarkRed, FloorDarkGreen, FloorDarkBlue);

    public DoggyLife.Models.Color GetWallLightColor() => new(WallLightRed, WallLightGreen, WallLightBlue);
    public DoggyLife.Models.Color GetWallDarkColor() => new(WallDarkRed, WallDarkGreen, WallDarkBlue);
    public DoggyLife.Models.Color GetWallOutlineColor() => new(WallOutlineRed, WallOutlineGreen, WallOutlineBlue);
    public DoggyLife.Models.Color GetWallStripeColor() => new(WallStripeRed, WallStripeGreen, WallStripeBlue);

    public void SetFloorLightColor(DoggyLife.Models.Color color)
    {
        FloorLightRed = color.Red;
        FloorLightGreen = color.Green;
        FloorLightBlue = color.Blue;
    }

    public void SetFloorDarkColor(DoggyLife.Models.Color color)
    {
        FloorDarkRed = color.Red;
        FloorDarkGreen = color.Green;
        FloorDarkBlue = color.Blue;
    }

    public void SetWallLightColor(DoggyLife.Models.Color color)
    {
        WallLightRed = color.Red;
        WallLightGreen = color.Green;
        WallLightBlue = color.Blue;
    }

    public void SetWallDarkColor(DoggyLife.Models.Color color)
    {
        WallDarkRed = color.Red;
        WallDarkGreen = color.Green;
        WallDarkBlue = color.Blue;
    }

    public void SetWallOutlineColor(DoggyLife.Models.Color color)
    {
        WallOutlineRed = color.Red;
        WallOutlineGreen = color.Green;
        WallOutlineBlue = color.Blue;
    }

    public void SetWallStripeColor(DoggyLife.Models.Color color)
    {
        WallStripeRed = color.Red;
        WallStripeGreen = color.Green;
        WallStripeBlue = color.Blue;
    }
}
