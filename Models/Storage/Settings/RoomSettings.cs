using SkiaSharp;

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

    // Helper methods to get the actual SKColor objects
    public SKColor GetFloorLightColor() => new SKColor(FloorLightRed, FloorLightGreen, FloorLightBlue);
    public SKColor GetFloorDarkColor() => new SKColor(FloorDarkRed, FloorDarkGreen, FloorDarkBlue);

    public SKColor GetWallLightColor() => new SKColor(WallLightRed, WallLightGreen, WallLightBlue);
    public SKColor GetWallDarkColor() => new SKColor(WallDarkRed, WallDarkGreen, WallDarkBlue);
    public SKColor GetWallOutlineColor() => new SKColor(WallOutlineRed, WallOutlineGreen, WallOutlineBlue);
    public SKColor GetWallStripeColor() => new SKColor(WallStripeRed, WallStripeGreen, WallStripeBlue);
}
