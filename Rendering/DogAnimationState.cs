namespace DoggyLife.Rendering;

/// <summary>
/// Represents the different animation states for a dog.
/// </summary>
public enum DogAnimationState
{
    /// <summary>
    /// The dog is standing still facing the front.
    /// </summary>
    FrontStanding,
    /// <summary>
    /// The dog is walking while facing the left side.
    /// </summary>
    LeftWalking,
    /// <summary>
    /// The dog is walking while facing the right side.
    /// </summary>
    RightWalking,
    /// <summary>
    /// The dog is walking while facing the front.
    /// </summary>
    FrontWalking,
    /// <summary>
    /// The dog is standing still facing the left side.
    /// </summary>
    LeftStanding,
    /// <summary>
    /// The dog is standing still facing the right side.
    /// </summary>
    RightStanding,
    /// <summary>
    /// The dog is walking backwards while facing the left side.
    /// </summary>
    BackWalking
}