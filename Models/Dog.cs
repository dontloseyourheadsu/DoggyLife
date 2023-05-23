namespace DoggyLife.Models;

public class Dog
{
    public float X { get; set; }
    public float Y { get; set; }

	public List<List<float>> Boundaries = new() 
	{
		
	}

	public async void WalkAsync()
    {
        while (true)
        {
            await Task.Delay(1000);
            X += 1;
            Y += 1;
        }
    }
}