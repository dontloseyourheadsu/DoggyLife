

// Main dog class for p5.js
class P5Dog {
  constructor(p5, x = 0, y = 0, z = 0) {
    this.p5 = p5;
    this.x = x;
    this.y = y;
    this.z = z;
    this.scale = 1.0;
    this.spriteSheet = null;
    this.currentState = DogAnimationState.FrontSitting;
    this.currentFrame = 0;
    this.animationTimer = 0;
    this.frameTime = 0.2; // seconds per frame
    this.facingAngle = 0; // Angle the dog is facing

    // Animation definitions - exactly matching C# implementation
    this.animations = {
      [DogAnimationState.RightWalking]: { row: 0, frameCount: 4 },
      [DogAnimationState.LeftWalking]: { row: 1, frameCount: 4 },
      [DogAnimationState.BackWalking]: { row: 2, frameCount: 4 },
      [DogAnimationState.FrontWalking]: { row: 3, frameCount: 4 },
      [DogAnimationState.FrontSitting]: { row: 4, frameCount: 4 }, // Using frameCount 4 as in the C# version
      [DogAnimationState.RightSitting]: { row: 5, frameCount: 4 }, // Using frameCount 4 as in the C# version
      [DogAnimationState.LeftSitting]: { row: 6, frameCount: 4 }, // Using frameCount 4 as in the C# version
    };

    // Exact same dimensions as in the C# code
    this.spriteWidth = 44;
    this.spriteHeight = 46;
    this.spriteHorizontalSpacing = 4;
    this.spriteVerticalSpacing = 1;

    // Direction vectors for determining animation state
    this.lastDirection = { x: 0, z: -1 }; // Initially facing front
  }

  // Load the sprite sheet
  async loadSpriteSheet(url) {
    return new Promise((resolve, reject) => {
      this.p5.loadImage(
        url,
        (img) => {
          this.spriteSheet = img;
          console.log(
            "Spritesheet loaded with dimensions:",
            img.width,
            "x",
            img.height
          );
          resolve(true);
        },
        (err) => reject(err)
      );
    });
  }

  // Set the animation state directly
  setState(state) {
    if (this.currentState !== state) {
      this.currentState = state;
      this.currentFrame = 0;
      this.animationTimer = 0;
    }
  }

  // Move the dog and automatically update animation state based on movement direction
  move(x, y, z, deltaTime) {
    // Store previous position
    const oldX = this.x;
    const oldZ = this.z;

    // Update position
    this.x = x;
    this.y = y;
    this.z = z;

    // Calculate direction vector
    const dx = this.x - oldX;
    const dz = this.z - oldZ;

    // Only update direction if we're actually moving
    if (Math.abs(dx) > 0.1 || Math.abs(dz) > 0.1) {
      this.lastDirection = { x: dx, z: dz };

      // Determine animation state based on direction
      const angle = Math.atan2(dz, dx);
      this.facingAngle = angle;

      // Convert angle to animation state
      // Angle ranges: Right: -π/4 to π/4, Back: π/4 to 3π/4, Left: 3π/4 to 5π/4, Front: 5π/4 to 7π/4
      const normalizedAngle = (angle + 2 * Math.PI) % (2 * Math.PI);

      if (
        normalizedAngle >= (7 * Math.PI) / 4 ||
        normalizedAngle < Math.PI / 4
      ) {
        this.setState(DogAnimationState.RightWalking);
      } else if (
        normalizedAngle >= Math.PI / 4 &&
        normalizedAngle < (3 * Math.PI) / 4
      ) {
        this.setState(DogAnimationState.BackWalking);
      } else if (
        normalizedAngle >= (3 * Math.PI) / 4 &&
        normalizedAngle < (5 * Math.PI) / 4
      ) {
        this.setState(DogAnimationState.LeftWalking);
      } else {
        this.setState(DogAnimationState.FrontWalking);
      }
    } else {
      // Switch to sitting state based on current direction
      if (this.currentState === DogAnimationState.RightWalking) {
        this.setState(DogAnimationState.RightSitting);
      } else if (this.currentState === DogAnimationState.LeftWalking) {
        this.setState(DogAnimationState.LeftSitting);
      } else if (
        this.currentState === DogAnimationState.FrontWalking ||
        this.currentState === DogAnimationState.BackWalking
      ) {
        this.setState(DogAnimationState.FrontSitting);
      }
    }

    // Update animation
    this.update(deltaTime);
  }

  // Update animation frames
  update(deltaTime) {
    if (!this.spriteSheet) return;

    const anim = this.animations[this.currentState];
    if (!anim) return;

    this.animationTimer += deltaTime;

    if (this.animationTimer >= this.frameTime) {
      this.animationTimer -= this.frameTime;
      this.currentFrame = (this.currentFrame + 1) % anim.frameCount;
    }
  }

  // Draw the dog with proper sprite rectangle
  draw() {
    if (!this.spriteSheet) return;

    this.p5.push();
    this.p5.translate(this.x, this.y, this.z);
    this.p5.scale(this.scale);

    // Calculate source rectangle from the spritesheet
    const anim = this.animations[this.currentState];
    if (!anim) {
      this.p5.pop();
      return;
    }

    // Use exact same formula as in C# version to calculate sprite position
    const srcX =
      this.currentFrame * (this.spriteWidth + this.spriteHorizontalSpacing);
    const srcY = anim.row * (this.spriteHeight + this.spriteVerticalSpacing);

    // Create a graphics buffer that's exactly the size of our sprite
    // This is equivalent to the SKRectI in the C# version
    const buffer = this.p5.createGraphics(this.spriteWidth, this.spriteHeight);
    buffer.imageMode(this.p5.CORNER);
    buffer.image(
      this.spriteSheet,
      0,
      0, // dest position
      this.spriteWidth,
      this.spriteHeight, // dest size
      srcX,
      srcY, // source position
      this.spriteWidth,
      this.spriteHeight // source size
    );

    // Make the dog face the camera based on the current view
    // Align the plane to face the camera
    this.p5.texture(buffer);
    this.p5.noStroke();
    this.p5.plane(this.spriteWidth, this.spriteHeight);

    this.p5.pop();
    buffer.remove(); // Clean up the buffer
  }

  // Get the current animation frame as a texture
  getFrameAsTexture() {
    if (!this.spriteSheet) return null;

    // Calculate source rectangle from the spritesheet
    const anim = this.animations[this.currentState];
    if (!anim) return null;

    // Calculate source rectangle using same formula as in C# version
    const srcX =
      this.currentFrame * (this.spriteWidth + this.spriteHorizontalSpacing);
    const srcY = anim.row * (this.spriteHeight + this.spriteVerticalSpacing);

    // Create a graphics buffer that's exactly the size of our sprite
    const buffer = this.p5.createGraphics(this.spriteWidth, this.spriteHeight);
    buffer.imageMode(this.p5.CORNER);
    buffer.image(
      this.spriteSheet,
      0,
      0, // dest position
      this.spriteWidth,
      this.spriteHeight, // dest size
      srcX,
      srcY, // source position
      this.spriteWidth,
      this.spriteHeight // source size
    );

    return buffer;
  }
}

// Export functions for use in our main p5.js rendering script
window.P5DogAnimation = {
  DogAnimationState: DogAnimationState,
  P5Dog: P5Dog,

  // Store active dog instances
  activeDogs: {},

  // Create a new dog
  createDog: function (p5Instance, dogId = "main", x = 0, y = 0, z = 0) {
    const dog = new P5Dog(p5Instance, x, y, z);
    this.activeDogs[dogId] = dog;
    return dog;
  },

  // Get a dog instance by ID
  getDog: function (dogId = "main") {
    return this.activeDogs[dogId] || null;
  },

  // Load spritesheet for a dog
  loadDogSpriteSheet: async function (p5Instance, dogId = "main", spriteUrl) {
    let dog = this.getDog(dogId);
    if (!dog) {
      dog = this.createDog(p5Instance, dogId);
    }
    await dog.loadSpriteSheet(spriteUrl);
    return dog;
  },

  // Update dog state and position from C#
  updateDogState: function (
    dogId = "main",
    stateId,
    x,
    y,
    z,
    deltaTime = 0.016
  ) {
    const dog = this.getDog(dogId);
    if (!dog) return false;

    // If state is provided, set it directly
    if (stateId !== undefined && stateId !== null) {
      dog.setState(stateId);
    }

    // If position is provided, move to that position
    if (x !== undefined && y !== undefined) {
      dog.move(x, y, z || dog.z, deltaTime);
    } else {
      // Just update the animation
      dog.update(deltaTime);
    }

    return true;
  },

  // Draw a dog
  drawDog: function (dogId = "main") {
    const dog = this.getDog(dogId);
    if (!dog) return false;
    dog.draw();
    return true;
  },

  // Set dog scale
  setDogScale: function (dogId = "main", scale) {
    const dog = this.getDog(dogId);
    if (!dog) return false;
    dog.scale = scale;
    return true;
  },

  // Get dog position
  getDogPosition: function (dogId = "main") {
    const dog = this.getDog(dogId);
    if (!dog) return null;
    return { x: dog.x, y: dog.y, z: dog.z };
  },

  // Get current animation frame as texture
  getDogFrameTexture: function (dogId = "main") {
    const dog = this.getDog(dogId);
    if (!dog) return null;
    return dog.getFrameAsTexture();
  },
};
