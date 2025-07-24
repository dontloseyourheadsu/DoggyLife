import { DogAnimationState } from "../../../animation/room/dog/dog-animation.js";

// Dog AI Module for random movement in the room
export class DogAI {
  dog;
  enabled = true;
  speed = 30; // Increased speed for more noticeable movement
  roomBounds = null; // Room bounds for constraining movement

  // Movement state
  currentDirection = { x: 0, z: 0 };
  directionTimer = 0;
  directionDuration = 2.0; // Hold direction for 2 seconds
  restTimer = 0;
  restDuration = 1.0; // Rest for 1 second between movements
  isResting = false;

  constructor(dog, enabled = true, roomBounds = null) {
    this.dog = dog;
    this.enabled = enabled;
    this.roomBounds = roomBounds;
    // Start with a random direction
    this.generateNewDirection();
  }

  /**
   * Updates the dog's position and animation based on AI logic.
   * @param {*} deltaTime
   * @returns None
   */
  update(deltaTime) {
    if (!this.enabled) return this.dog.position;

    // Update movement timers
    this.updateMovementState(deltaTime);

    // Update dog position based on AI logic
    const positionUpdate = this.getRandomPositionUpdate(deltaTime);

    // Update dog AI behavior
    this.updateDogPosition(positionUpdate);
    this.updateDogAnimation(
      positionUpdate.isMoving,
      positionUpdate.dx,
      positionUpdate.dz
    );

    return {
      x: this.dog.position.x,
      y: this.dog.position.y,
      z: this.dog.position.z,
    };
  }

  /**
   * Updates the movement state (direction changes and rest periods)
   */
  updateMovementState(deltaTime) {
    if (this.isResting) {
      this.restTimer += deltaTime;
      if (this.restTimer >= this.restDuration) {
        this.isResting = false;
        this.restTimer = 0;
        this.generateNewDirection();
      }
    } else {
      this.directionTimer += deltaTime;
      if (this.directionTimer >= this.directionDuration) {
        this.isResting = true;
        this.directionTimer = 0;
        this.currentDirection = { x: 0, z: 0 }; // Stop moving
      }
    }
  }

  /**
   * Generates a new random direction for the dog to move
   */
  generateNewDirection() {
    const angle = Math.random() * 2 * Math.PI;
    this.currentDirection = {
      x: Math.cos(angle),
      z: Math.sin(angle),
    };
  }

  getRandomPositionUpdate(deltaTime) {
    // Use consistent direction instead of random each frame
    const moveDistance = this.speed * deltaTime;
    const dx = this.currentDirection.x * moveDistance;
    const dz = this.currentDirection.z * moveDistance;

    return {
      x: this.dog.position.x + dx,
      y: this.dog.position.y,
      z: this.dog.position.z + dz,
      dx: dx,
      dz: dz,
      isMoving: !this.isResting && (Math.abs(dx) > 0.01 || Math.abs(dz) > 0.01), // Lower threshold
    };
  }

  /**
   * Updates the dog's position based on the AI logic.
   * @param {*} positionUpdate
   */
  updateDogPosition(positionUpdate) {
    // Constrain position within room bounds if available
    if (this.roomBounds) {
      // Add some padding to keep dog away from walls (dog size consideration)
      const padding = 20;
      positionUpdate.x = Math.max(
        this.roomBounds.minX + padding,
        Math.min(this.roomBounds.maxX - padding, positionUpdate.x)
      );
      positionUpdate.z = Math.max(
        this.roomBounds.minZ + padding,
        Math.min(this.roomBounds.maxZ - padding, positionUpdate.z)
      );

      // If we hit a boundary, generate a new direction
      if (
        positionUpdate.x <= this.roomBounds.minX + padding ||
        positionUpdate.x >= this.roomBounds.maxX - padding ||
        positionUpdate.z <= this.roomBounds.minZ + padding ||
        positionUpdate.z >= this.roomBounds.maxZ - padding
      ) {
        this.generateNewDirection();
      }
    }

    // Update dog position
    this.dog.position.x = positionUpdate.x;
    this.dog.position.y = positionUpdate.y;
    this.dog.position.z = positionUpdate.z;
  }

  /**
   * Updates the dog's animation state based on movement.
   * @param {*} isMoving
   * @param {*} moveDx
   * @param {*} moveDz
   */
  updateDogAnimation(isMoving, moveDx = 0, moveDz = 0) {
    if (isMoving) {
      // For walking state, calculate direction of movement
      const moveAngle = Math.atan2(moveDz, moveDx);

      // Determine walking animation based on movement direction
      const normalizedAngle = (moveAngle + 2 * Math.PI) % (2 * Math.PI);

      if (
        normalizedAngle >= (7 * Math.PI) / 4 ||
        normalizedAngle < Math.PI / 4
      ) {
        this.dog.changeState(DogAnimationState.RightWalking);
      } else if (
        normalizedAngle >= Math.PI / 4 &&
        normalizedAngle < (3 * Math.PI) / 4
      ) {
        this.dog.changeState(DogAnimationState.BackWalking);
      } else if (
        normalizedAngle >= (3 * Math.PI) / 4 &&
        normalizedAngle < (5 * Math.PI) / 4
      ) {
        this.dog.changeState(DogAnimationState.LeftWalking);
      } else {
        this.dog.changeState(DogAnimationState.FrontWalking);
      }
    } else {
      // Default to front sitting when not moving
      this.dog.changeState(DogAnimationState.FrontSitting);
    }
  }

  /**
   * Toggles the AI state on or off.
   * @returns {boolean} The new state of the AI.
   */
  toggle() {
    this.enabled = !this.enabled;
    return this.enabled;
  }
}
