import { DogAnimationState } from '../../../animation/room/dog/dog-animation.js';

// Dog AI Module for random movement in the room
export class DogAI {
  dog;
  enabled = true;
  speed = 10;

  constructor(dog, enabled = true) {
    this.dog = dog;
    this.enabled = enabled;
  }

  /**
   * Updates the dog's position and animation based on AI logic.
   * @param {*} deltaTime 
   * @returns None
   */
  update(deltaTime) {
    if (!this.enabled) return;

    // Update dog position based on AI logic
    const positionUpdate = this.getRandomPositionUpdate(deltaTime);

    // Update dog AI behavior
    this.updateDogPosition(positionUpdate);
    this.updateDogAnimation(positionUpdate.isMoving);

    return {x: positionUpdate.x, y: positionUpdate.y, z: positionUpdate.z};
  }

  getRandomPositionUpdate(deltaTime) {
    // Generate a random position update for the dog
    const moveDistance = this.speed * deltaTime; // Adjust speed based on delta time
    const angle = Math.random() * 2 * Math.PI; // Random angle for movement
    const dx = Math.cos(angle) * moveDistance;
    const dz = Math.sin(angle) * moveDistance;

    return { x: dx, y: 0, z: dz, isMoving: moveDistance > 0 };
  }

  /**
   * Updates the dog's position based on the AI logic.
   * @param {*} positionUpdate 
   */
  updateDogPosition(positionUpdate) {
    // Update dog position
    this.dog.position.x = positionUpdate.x;
    this.dog.position.y = positionUpdate.y;
    this.dog.position.z = positionUpdate.z;
  }

  /**
   * Updates the dog's animation state based on movement.
   * @param {*} isMoving 
   */
  updateDogAnimation(isMoving) {
    if (isMoving) {
      // Detect facing direction to choose correct sitting animation
      const dx = Math.cos(cameraAngle);
      const dz = Math.sin(cameraAngle);
      const angle = Math.atan2(dz, dx);

      // Choose sitting animation based on angle
      if (angle > -Math.PI / 4 && angle < Math.PI / 4) {
        this.dog.changeState(DogAnimationState.RightSitting);
      } else if (angle >= Math.PI / 4 && angle < (3 * Math.PI) / 4) {
        this.dog.changeState(DogAnimationState.FrontSitting);
      } else if (
        (angle >= (3 * Math.PI) / 4 && angle <= Math.PI) ||
        (angle >= -Math.PI && angle < (-3 * Math.PI) / 4)
      ) {
        this.dog.changeState(DogAnimationState.LeftSitting);
      } else {
        this.dog.changeState(DogAnimationState.FrontSitting);
      }
    } else {
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
