public class RoomDog : Dog
{
    public RoomDog(int canvasWidth, int canvasHeight) : base(canvasWidth, canvasHeight) { }

    protected override void InitializePosition(int canvasWidth, int canvasHeight)
    {
        x = canvasWidth / 2;
        y = canvasHeight - height;
    }
}
