export class Dog {
  // Dog data
  dog = null;
  image = null;
  spritesheetLoaded = false;
  position = { x: 0, y: 150, z: 0 };
  scale = 1.0;
  size = 100;
  rotationY = Math.PI * 2;

  DogAnimationState = {
    RightWalking: 0,
    LeftWalking: 1,
    BackWalking: 2,
    FrontWalking: 3,
    FrontSitting: 4,
    RightSitting: 5,
    LeftSitting: 6,
  };

  /**
   * Starts the dog data
   */
  async initializeDog() {
    // Get the dog sprite path
    const dogImagePath = this.sprites
      ? this.sprites.getCurrentDogSprite()
      : "images/dogs/dog1.png";

    // Create the dog animation instance at the initial position
    try {
      dog = await window.P5DogAnimation.loadDogSpriteSheet(
        p,
        "main",
        dogImagePath
      );

      // Position the dog at the initial position
      dog.x = dogPosition.x;
      dog.y = dogPosition.y;
      dog.z = dogPosition.z;
      dog.scale = dogScale;

      dogSpritesheetLoaded = true;
    } catch (err) {
      console.error("Error initializing dog animation:", err);
    }
  }

  sprites = {
    // Paths to different dog sprites
    dogTypes: [
      "images/dogs/dog1.png", // White dog
      "images/dogs/dog2.png", // Beagle
      "images/dogs/dog3.png", // Brown dog
      "images/dogs/dog4.png", // Orange dog
    ],

    // Default dog type index
    currentDogType: 0,

    // Get current dog sprite path
    getCurrentDogSprite: function () {
      return this.dogTypes[this.currentDogType];
    },

    // Change to next dog type
    nextDogType: function () {
      this.currentDogType = (this.currentDogType + 1) % this.dogTypes.length;
      return this.getCurrentDogSprite();
    },
  };
}
