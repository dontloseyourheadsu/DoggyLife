// Wall-aware Hologram Module for DoggyLife
import { BaseHologramSystem } from "./base-hologram.js";

export class WallHologramSystem extends BaseHologramSystem {
  constructor() {
    super();

    // Override base settings
    this.currentWall = "back"; // "back" or "left"
    this.defaultSize = { width: 50, height: 50, depth: 50 };
    this.defaultPosition = { x: -175, y: 0, z: -200 }; // Start on back wall, very close to intersection
    this.hologramColor = [255, 0, 255, 100]; // Purple with transparency for wall mode
    this.wireframeColor = [255, 0, 255, 255]; // Solid purple for wireframe

    // Wall transition settings
    this.transitionThreshold = 25; // How close to intersection before allowing transition (increased for easier transitions)
    this.intersectionLine = { x: -200, z: -200 }; // Where the two walls meet

    // Wall definitions
    this.walls = {
      back: {
        name: "back",
        normal: { x: 0, y: 0, z: 1 }, // Wall faces forward (positive Z)
        position: { x: 0, y: 0, z: -200 }, // Wall is at z = -200
        bounds: {
          // On back wall: can move in X (left-right) and Y (up-down)
          x: { min: -200, max: 200 }, // Left to right along the wall
          y: { min: -200, max: 200 }, // Up to down along the wall
          z: -200, // Fixed Z position (on the wall surface)
        },
        movementAxes: ["x", "y"], // Can move in X and Y directions
        fixedAxis: "z", // Z is fixed to wall position
      },
      left: {
        name: "left",
        normal: { x: 1, y: 0, z: 0 }, // Wall faces right (positive X)
        position: { x: -200, y: 0, z: 0 }, // Wall is at x = -200
        bounds: {
          // On left wall: can move in Z (forward-backward) and Y (up-down)
          x: -200, // Fixed X position (on the wall surface)
          y: { min: -200, max: 200 }, // Up to down along the wall
          z: { min: -200, max: 200 }, // Forward to backward along the wall
        },
        movementAxes: ["z", "y"], // Can move in Z and Y directions
        fixedAxis: "x", // X is fixed to wall position
      },
    };
  }

  // Implement abstract method
  initializeKeyboardState() {
    this.keyboardState = {
      horizontal: false, // Arrow left/right
      vertical: false, // Arrow up/down
      horizontalDirection: 0, // -1 for left, 1 for right
      verticalDirection: 0, // -1 for up, 1 for down
    };
  }

  // Implement abstract method
  getHologramType() {
    return "wall-cube";
  }

  // Override to add wall property
  getAdditionalHologramProperties(wall = "back") {
    return { wall };
  }

  // Override to handle wall constraints
  updateHologramPosition(position, wall) {
    this.currentHologram.position = this.constrainToWall(
      position,
      wall || this.currentWall
    );
  }

  // Override to handle wall logic
  handleAdditionalEnableLogic(wall) {
    if (wall) {
      this.currentWall = wall;
      this.currentHologram.wall = wall;
    }
  }

  // Override to add wall state
  getAdditionalState() {
    return {
      currentWall: this.currentWall,
      walls: this.walls,
    };
  }

  // Override position constraint
  constrainPosition(position) {
    return this.constrainToWall(position, this.currentWall);
  }

  // Create a new wall hologram (override base method to add wall parameter)
  createHologram(position = null, size = null, wall = "back") {
    const pos = position || { ...this.defaultPosition };
    const siz = size || { ...this.defaultSize };

    // Ensure position is valid for the specified wall
    this.currentWall = wall;
    const validPos = this.constrainToWall(pos, wall);

    this.currentHologram = {
      position: validPos,
      size: siz,
      visible: true,
      type: "wall-cube",
      wall: wall,
    };

    return this.currentHologram;
  }

  // Constrain position to a specific wall
  constrainToWall(position, wallName) {
    const wall = this.walls[wallName];
    if (!wall) return position;

    const constrained = { ...position };
    const bounds = wall.bounds;

    // Set the fixed axis to the wall position
    constrained[wall.fixedAxis] = wall.position[wall.fixedAxis];

    // Constrain the moveable axes
    wall.movementAxes.forEach((axis) => {
      const bound = bounds[axis];
      if (typeof bound === "object") {
        // Handle min/max bounds
        const halfSize = this.currentHologram
          ? this.currentHologram.size[
              axis === "x" ? "width" : axis === "y" ? "height" : "depth"
            ] / 2
          : 25;
        constrained[axis] = Math.max(
          bound.min + halfSize,
          Math.min(bound.max - halfSize, constrained[axis])
        );
      } else {
        // Handle fixed value
        constrained[axis] = bound;
      }
    });

    return constrained;
  }

  // Check if position is near the intersection and can transition
  canTransitionWalls(position, fromWall, toWall) {
    const threshold = this.transitionThreshold;
    const intersection = this.intersectionLine;

    // Check if we're close enough to the intersection
    const distanceToIntersection = Math.sqrt(
      Math.pow(position.x - intersection.x, 2) +
        Math.pow(position.z - intersection.z, 2)
    );

    return distanceToIntersection <= threshold;
  }

  // Handle wall transition
  transitionToWall(newWall, currentPosition) {
    if (!this.walls[newWall] || !this.currentHologram) return false;

    const oldWall = this.currentWall;

    // Map position from old wall to new wall
    const mappedPosition = this.mapPositionBetweenWalls(
      currentPosition,
      oldWall,
      newWall
    );

    // Update current wall and constrain position
    this.currentWall = newWall;
    this.currentHologram.wall = newWall;
    this.currentHologram.position = this.constrainToWall(
      mappedPosition,
      newWall
    );
    return true;
  }

  // Map position coordinates between walls
  mapPositionBetweenWalls(position, fromWall, toWall) {
    const mapped = { ...position };

    // When transitioning between back and left walls, preserve the Y coordinate
    // and map the other coordinates appropriately
    if (
      (fromWall === "back" && toWall === "left") ||
      (fromWall === "left" && toWall === "back")
    ) {
      mapped.y = position.y; // Y (vertical) stays the same

      if (fromWall === "back" && toWall === "left") {
        // From back wall (x,y moveable) to left wall (z,y moveable)
        // Map X position to Z position
        mapped.z = position.x;
        mapped.x = this.walls.left.bounds.x; // Set to left wall position (-200)
      } else {
        // From left wall (z,y moveable) to back wall (x,y moveable)
        // Map Z position to X position
        mapped.x = position.z;
        mapped.z = this.walls.back.bounds.z; // Set to back wall position (-200)
      }
    }

    return mapped;
  }

  // Enable wall hologram mode (override base method to add wall parameter)
  enable(position = null, size = null, wall = "back") {
    return super.enable(position, size, wall);
  }

  // Toggle wall hologram mode (override base method to add wall parameter)
  toggle(position = null, size = null, wall = "back") {
    return super.toggle(position, size, wall);
  }

  // Implement abstract method
  setupKeyboardListeners() {
    // Remove any existing listeners first
    this.removeKeyboardListeners();

    // Add new listeners
    this.onKeyDown = (e) => {
      if (!this.enabled) return;

      switch (e.key) {
        case "ArrowLeft":
          this.keyboardState.horizontal = true;
          this.keyboardState.horizontalDirection = -1;
          e.preventDefault();
          break;
        case "ArrowRight":
          this.keyboardState.horizontal = true;
          this.keyboardState.horizontalDirection = 1;
          e.preventDefault();
          break;
        case "ArrowUp":
          this.keyboardState.vertical = true;
          this.keyboardState.verticalDirection = -1;
          e.preventDefault();
          break;
        case "ArrowDown":
          this.keyboardState.vertical = true;
          this.keyboardState.verticalDirection = 1;
          e.preventDefault();
          break;
      }
    };

    this.onKeyUp = (e) => {
      if (!this.enabled) return;

      switch (e.key) {
        case "ArrowLeft":
        case "ArrowRight":
          this.keyboardState.horizontal = false;
          this.keyboardState.horizontalDirection = 0;
          e.preventDefault();
          break;
        case "ArrowUp":
        case "ArrowDown":
          this.keyboardState.vertical = false;
          this.keyboardState.verticalDirection = 0;
          e.preventDefault();
          break;
      }
    };

    window.addEventListener("keydown", this.onKeyDown);
    window.addEventListener("keyup", this.onKeyUp);
  }

  // Implement abstract method
  update(deltaTime) {
    if (!this.enabled || !this.currentHologram) return;

    const movement = this.moveSpeed * deltaTime;
    let moved = false;

    // Store current position for transition checking
    const currentPos = { ...this.currentHologram.position };
    const wall = this.walls[this.currentWall];

    // Calculate intended movement based on keyboard state and current wall
    const intendedPos = { ...currentPos };
    if (this.keyboardState.horizontal) {
      // Map horizontal movement to the appropriate axis for current wall
      const axis = wall.movementAxes[0]; // First axis is horizontal for both walls
      let direction = this.keyboardState.horizontalDirection;

      // On the left wall, we need to reverse the direction for intuitive controls
      // because left/right arrows should move forward/backward (Z-axis), not left/right (X-axis)
      if (this.currentWall === "left") {
        direction = -direction; // Reverse direction for left wall
      }

      intendedPos[axis] += direction * movement;
      moved = true;
    }

    if (this.keyboardState.vertical) {
      // Map vertical movement to Y axis (same for both walls)
      intendedPos.y += this.keyboardState.verticalDirection * movement;
      moved = true;
    }

    if (moved) {
      // Check if the intended movement will reach the intersection BEFORE moving
      if (this.willReachIntersection(currentPos, intendedPos)) {
        const targetWall = this.currentWall === "back" ? "left" : "back";
        // Transition to the other wall with the intended position
        this.transitionToWall(targetWall, intendedPos);
      } else {
        // Normal movement within wall bounds
        const constrainedPos = this.constrainToWall(
          intendedPos,
          this.currentWall
        );

        // Check if the position was significantly constrained (alternative transition trigger)
        const wasConstrained = this.shouldTransitionWall(
          intendedPos,
          constrainedPos
        );

        if (wasConstrained) {
          const targetWall = this.currentWall === "back" ? "left" : "back";
          if (
            this.canTransitionWalls(intendedPos, this.currentWall, targetWall)
          ) {
            this.transitionToWall(targetWall, intendedPos);
          } else {
            this.currentHologram.position = constrainedPos;
          }
        } else {
          this.currentHologram.position = constrainedPos;
        }
      }
    }

    return this.currentHologram;
  }

  // Check if the intended movement will reach the intersection
  willReachIntersection(currentPos, intendedPos) {
    const threshold = this.transitionThreshold;
    const hologramSize = this.currentHologram.size;

    if (this.currentWall === "back") {
      // On back wall: if moving left and hologram's edge crosses x = -200 threshold
      // Account for hologram's half-width to check the edge, not center
      const halfWidth = hologramSize.width / 2;
      const crossingThreshold = -200 + threshold;
      const currentEdge = currentPos.x - halfWidth;
      const intendedEdge = intendedPos.x - halfWidth;

      const willCross =
        intendedEdge <= crossingThreshold && currentEdge > crossingThreshold;

      if (willCross) {
        return true;
      }
    } else if (this.currentWall === "left") {
      // On left wall: if moving back and hologram's edge crosses z = -200 threshold
      // Account for hologram's half-depth to check the edge, not center
      const halfDepth = hologramSize.depth / 2;
      const crossingThreshold = -200 + threshold;
      const currentEdge = currentPos.z - halfDepth;
      const intendedEdge = intendedPos.z - halfDepth;

      const willCross =
        intendedEdge <= crossingThreshold && currentEdge > crossingThreshold;

      if (willCross) {
        return true;
      }
    }

    return false;
  }

  // Check if movement should trigger a wall transition
  shouldTransitionWall(intendedPos, constrainedPos) {
    const wall = this.walls[this.currentWall];

    // Check if any axis was constrained significantly
    for (const axis of wall.movementAxes) {
      if (Math.abs(intendedPos[axis] - constrainedPos[axis]) > 1) {
        return true;
      }
    }

    return false;
  }

  // Determine which wall we should transition to
  getTargetWall(position) {
    const intersection = this.intersectionLine;
    const threshold = this.transitionThreshold;

    // Check if we're near the intersection
    const distanceToIntersection = Math.sqrt(
      Math.pow(position.x - intersection.x, 2) +
        Math.pow(position.z - intersection.z, 2)
    );

    if (distanceToIntersection <= threshold) {
      // We're at the intersection, determine target wall based on current wall
      return this.currentWall === "back" ? "left" : "back";
    }

    return null;
  }

  // Implement abstract method
  draw(p5Instance) {
    if (!this.enabled || !this.currentHologram || !p5Instance) return;

    const p = p5Instance;
    const pos = this.currentHologram.position;
    const size = this.currentHologram.size;
    const wall = this.walls[this.currentWall];

    p.push();
    p.translate(pos.x, pos.y, pos.z);

    // Set hologram material properties
    this.setHologramMaterial(p);

    // Draw cube that's flush with the wall
    // Adjust the cube so it appears to be "on" the wall surface
    const offset = size.depth / 2;

    if (this.currentWall === "back") {
      // For back wall, move cube forward so it's flush with the wall
      p.translate(0, 0, offset);
    } else if (this.currentWall === "left") {
      // For left wall, move cube right so it's flush with the wall
      p.translate(offset, 0, 0);
    }

    // Draw the cube
    p.box(size.width, size.height, size.depth);

    // Draw wireframe for better visibility using base class method
    this.drawWireframeBox(p, size);

    p.pop();
  }
}
