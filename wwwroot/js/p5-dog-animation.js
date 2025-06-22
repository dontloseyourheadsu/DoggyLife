// P5.js Dog Animation Module for DoggyLife

// Dog animation states that match C# DogAnimationState enum
const DogAnimationState = {
  RightWalking: 0,
  LeftWalking: 1,
  BackWalking: 2,
  FrontWalking: 3,
  FrontSitting: 4,
  RightSitting: 5,
  LeftSitting: 6,
};

// Main dog class for p5.js
class P5Dog {
  constructor(p5, x = 0, y = 0) {
    this.p5 = p5;
    this.x = x;
    this.y = y;
    this.scale = 1.0;
    this.size = 44; // Default size from the C# code
    this.spriteSheet = null;
    this.currentState = DogAnimationState.FrontSitting;
    this.currentFrame = 0;
    this.animationTimer = 0;
    this.frameTime = 0.2; // seconds per frame

    // Animation definitions - matches C# dog animation structure
    this.animations = {
      [DogAnimationState.RightWalking]: { row: 0, frameCount: 4 },
      [DogAnimationState.LeftWalking]: { row: 1, frameCount: 4 },
      [DogAnimationState.BackWalking]: { row: 2, frameCount: 4 },
      [DogAnimationState.FrontWalking]: { row: 3, frameCount: 4 },
      [DogAnimationState.FrontSitting]: { row: 4, frameCount: 1 },
      [DogAnimationState.RightSitting]: { row: 5, frameCount: 1 },
      [DogAnimationState.LeftSitting]: { row: 6, frameCount: 1 },
    };

    this.spriteWidth = 44;
    this.spriteHeight = 46;
    this.spriteHorizontalSpacing = 4;
    this.spriteVerticalSpacing = 1;
  }

  // Load the sprite sheet
  async loadSpriteSheet(url) {
    return new Promise((resolve, reject) => {
      this.p5.loadImage(
        url,
        (img) => {
          this.spriteSheet = img;
          resolve(true);
        },
        (err) => reject(err)
      );
    });
  }

  // Set the animation state
  setState(state) {
    if (this.currentState !== state) {
      this.currentState = state;
      this.currentFrame = 0;
      this.animationTimer = 0;
    }
  }

  // Update animation frames
  update(deltaTime) {
    if (!this.spriteSheet) return;

    const anim = this.animations[this.currentState];
    if (!anim) return;

    // Only update if we have more than one frame
    if (anim.frameCount > 1) {
      this.animationTimer += deltaTime;

      if (this.animationTimer >= this.frameTime) {
        this.currentFrame = (this.currentFrame + 1) % anim.frameCount;
        this.animationTimer = 0;
      }
    }
  }

  // Draw the dog
  draw() {
    this.p5.push();
    this.p5.translate(this.x, this.y, 0);
    this.p5.scale(this.scale);

    if (this.spriteSheet) {
      // Calculate source rectangle
      const anim = this.animations[this.currentState];
      if (!anim) return;

      const srcX =
        this.currentFrame * (this.spriteWidth + this.spriteHorizontalSpacing);
      const srcY = anim.row * (this.spriteHeight + this.spriteVerticalSpacing);

      // Use image() to draw the correct portion of the spritesheet
      this.p5.imageMode(this.p5.CENTER);
      this.p5.image(
        this.spriteSheet,
        0,
        0, // destination x,y
        this.spriteWidth,
        this.spriteHeight, // destination width, height
        srcX,
        srcY, // source x,y
        this.spriteWidth,
        this.spriteHeight // source width, height
      );
    } else {
      // Fallback rendering when sprite sheet isn't available - 3D style dog
      // Body
      this.p5.fill(255, 200, 100);
      this.p5.stroke(150, 100, 50);
      this.p5.strokeWeight(2);
      this.p5.ellipse(0, 0, this.size, this.size * 0.8); // Dog body

      // Head
      this.p5.push();
      this.p5.translate(this.size * 0.4, 0, this.size * 0.1);
      this.p5.fill(255, 200, 100);
      this.p5.ellipse(0, 0, this.size * 0.5, this.size * 0.4);

      // Eyes
      this.p5.fill(0);
      this.p5.noStroke();
      this.p5.ellipse(
        -this.size * 0.1,
        -this.size * 0.1,
        this.size * 0.08,
        this.size * 0.1
      );
      this.p5.ellipse(
        this.size * 0.1,
        -this.size * 0.1,
        this.size * 0.08,
        this.size * 0.1
      );

      // Add shine to eyes
      this.p5.fill(255);
      this.p5.ellipse(
        -this.size * 0.1,
        -this.size * 0.12,
        this.size * 0.03,
        this.size * 0.03
      );
      this.p5.ellipse(
        this.size * 0.1,
        -this.size * 0.12,
        this.size * 0.03,
        this.size * 0.03
      );

      // Nose
      this.p5.fill(50, 30, 20);
      this.p5.ellipse(0, 0, this.size * 0.12, this.size * 0.08);

      // Mouth
      this.p5.noFill();
      this.p5.stroke(100, 70, 50);
      this.p5.strokeWeight(2);
      this.p5.arc(
        0,
        this.size * 0.05,
        this.size * 0.2,
        this.size * 0.1,
        0,
        this.p5.PI
      );
      this.p5.pop();

      // Ears
      this.p5.stroke(150, 100, 50);
      this.p5.strokeWeight(2);
      this.p5.fill(200, 150, 50);
      this.p5.ellipse(
        this.size * 0.3,
        -this.size * 0.3,
        this.size * 0.2,
        this.size * 0.3
      );
      this.p5.ellipse(
        this.size * 0.5,
        -this.size * 0.3,
        this.size * 0.2,
        this.size * 0.3
      );

      // Tail
      this.p5.push();
      this.p5.translate(-this.size * 0.3, 0);
      this.p5.stroke(200, 150, 50);
      this.p5.strokeWeight(5);
      this.p5.noFill();
      // Create wagging motion based on time
      let wagAngle = Math.sin(Date.now() / 200) * 0.5;
      this.p5.rotate(wagAngle);
      this.p5.arc(
        0,
        0,
        this.size * 0.4,
        this.size * 0.5,
        -this.p5.PI / 2,
        this.p5.PI / 2
      );
      this.p5.pop();
    }

    this.p5.pop();
  }
}

// Export functions for use in our main p5.js rendering script
window.P5DogAnimation = {
  DogAnimationState: DogAnimationState,
  P5Dog: P5Dog,

  // Create a new dog
  createDog: function (p5Instance, x = 0, y = 0) {
    return new P5Dog(p5Instance, x, y);
  },

  // Update dog state from C#
  updateDogState: function (dogId, state, x, y, scale) {
    // This function would be called from C# through interop to update a dog's state
    // Implementation depends on how dogs are stored and managed in the p5 sketch
  },
};
