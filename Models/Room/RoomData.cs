namespace DoggyLife.Models.Room
{
    /// <summary>
    /// Represents the data for a room, including color settings for floors and walls.
    /// </summary>
    public class RoomData
    {
        /// <summary>
        /// Gets or sets the light color of the floor in RGB format.
        /// </summary>
        public required string FloorLightColor { get; set; }

        /// <summary>
        /// Gets or sets the dark color of the floor in RGB format.
        /// </summary>
        public required string FloorDarkColor { get; set; }

        /// <summary>
        /// Gets or sets the light color of the wall in RGB format.
        /// </summary>
        public required string WallLightColor { get; set; }

        /// <summary>
        /// Gets or sets the dark color of the wall in RGB format.
        /// </summary>
        public required string WallDarkColor { get; set; }
    }
}