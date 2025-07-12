import { DogRenderer } from "../../systems/drawing/room/dog-renderer.js";
import {
  DogAnimationState,
  sprites,
} from "../../animation/room/dog/dog-animation.js";

export class Dog {
  // Rendering data
  dogRenderer = null;
  spritesheetLoaded = false;

  // Position data
  position = { x: 0, y: 150, z: 0 };
  scale = 1.0;
  size = 100;
  rotationY = Math.PI * 2; // Control the facing direction of the dog

  // Identifier
  name = "Dog";

  constructor(dogName = "Dog") {
    this.name = dogName;
  }

  /**
   * Starts the dog data
   */
  async initialize(p5Instance, dogType = 1) {
    // Get the dog sprite path
    const dogImagePath = sprites.getDogSpritePath(dogType);

    // Create the dog animation instance at the initial position
    try {
      this.loadDogSpriteSheet(p5Instance, dogImagePath);

      // Position the dog at the initial position
      this.dogRenderer.x = this.position.x;
      this.dogRenderer.y = this.position.y;
      this.dogRenderer.z = this.position.z;
      this.dogRenderer.scale = this.scale;

      this.spritesheetLoaded = true;
    } catch (err) {
      console.error("Error initializing dog animation:", err);
    }
  }

  /**
   * Loads the dog sprite sheet into p5.js.
   * @param {*} p5Instance
   * @param {*} spriteUrl
   */
  async loadDogSpriteSheet(p5Instance, spriteUrl) {
    if (!this.dogRenderer) {
      this.dogRenderer = this.createDog(p5Instance);
    }
    await this.dogRenderer.loadSpriteSheet(spriteUrl);
  }

  /**
   * Creates a new dog instance.
   * @param {*} p5Instance
   * @returns {DogRenderer} A new DogRender instance.
   */
  createDog(p5Instance) {
    const dog = new DogRenderer(
      p5Instance,
      this.position.x,
      this.position.y,
      this.position.z
    );
    return dog;
  }

  /**
   * Updates the dog's state.
   * @param {*} stateId
   */
  changeState(stateId) {
    // If the dog has a new state, set it
    if (stateId !== undefined && stateId !== null) {
      this.dogRenderer.setState(stateId);
    }
  }

  /**
   * Updates the dog's position.
   * @param {*} newPosition
   * @param {*} deltaTime
   */
  move(newPosition, deltaTime = 0.016) {
    // If position is provided, move to that position
    if (newPosition !== undefined && newPosition !== null) {
      // Update the position
      this.position = newPosition;

      // Move the dog in the renderer
      this.dogRenderer.move(
        newPosition.x,
        newPosition.y,
        newPosition.z || this.dogRenderer.z,
        deltaTime
      );

    }
  }
  
  /**
   * Renders the dog on the canvas with dog renderer.
   * @param {*} p5Instance 
   * @param {*} cameraAngle 
   */
  render(p5Instance, cameraAngle) {
    // Keep scale values in reasonable ranges
    this.dog.scale = Math.max(0.5, Math.min(10, this.dog.scale));
    
    // Make sure the dog faces the camera
    p5Instance.push();
    
    // Make dog face the camera based on camera position
    let dx = Math.cos(cameraAngle);
    let dz = Math.sin(cameraAngle);
    let angle = Math.atan2(dz, dx);
    p5Instance.translate(this.position.x, this.position.y, this.position.z);
    p5Instance.rotateY(angle + this.rotationY);

    // Get current frame as texture and draw it
    const tex = this.dogRenderer.getFrameAsTexture();
    if (tex) {
      p5Instance.texture(tex);
      p5Instance.noStroke();
      p5Instance.plane(this.dogRenderer.spriteWidth * this.scale, this.dogRenderer.spriteHeight * this.scale);
      tex.remove(); // Clean up the texture
    }

    p5Instance.pop();
  }
    
  /**
   * Updates the dog's animation frame.
   * @param {*} deltaTime
   */
  updateFrame(deltaTime = 0.016) {
    // Just update the animation
    this.dogRenderer.update(deltaTime);
  }

  /**
   * Draws the dog on the p5.js canvas.
   */
  draw() {
    if (this.dogRenderer) {
      this.dogRenderer.draw();
    }
  }
}
