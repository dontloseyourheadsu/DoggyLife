/**
 * Dog Animation State Constants
 */
export const DogAnimationState = {
  RightWalking: 0,
  LeftWalking: 1,
  BackWalking: 2,
  FrontWalking: 3,
  FrontSitting: 4,
  RightSitting: 5,
  LeftSitting: 6,
};

/**
 * Holds the sprite information for the dog.
 */
export const sprites = {
  // Paths to different dog sprites
  dogTypes: [
    "images/dogs/dog1.png", // White dog
    "images/dogs/dog2.png", // Beagle
    "images/dogs/dog3.png", // Brown dog
    "images/dogs/dog4.png", // Orange dog
  ],

  // Get current dog sprite path
  getDogSpritePath(dogType = 1) {
    return this.dogTypes[dogType - 1] || this.dogTypes[0];
  },
};
