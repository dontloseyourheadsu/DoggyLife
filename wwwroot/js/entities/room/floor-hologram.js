// Hologram Module for DoggyLife
import { BaseHologramSystem } from "./base-hologram.js";

export class FloorHologramSystem extends BaseHologramSystem {
  constructor() {
    super();

    // Override base settings
    this.defaultSize = { width: 100, height: 100, depth: 100 };
    this.defaultPosition = { x: 0, y: 150, z: 0 };
    this.hologramColor = [0, 255, 0, 150];
    this.wireframeColor = [0, 255, 0, 255];

    this.roomBounds = null;
  }

  // Implement abstract method
  initializeKeyboardState() {
    this.keyboardState = {
      up: false,
      down: false,
      left: false,
      right: false,
      forward: false,
      backward: false,
    };
  }

  // Implement abstract method
  getHologramType() {
    return "cube";
  }

  // Override position constraint
  constrainPosition(position) {
    if (!this.roomBounds || !this.currentHologram) return position;

    const size = this.currentHologram.size;
    const halfWidth = size.width / 2;
    const halfDepth = size.depth / 2;
    const halfHeight = size.height / 2;

    const constrained = { ...position };

    // X bounds (left-right) - allow hologram to reach the walls
    constrained.x = Math.max(
      this.roomBounds.minX + halfWidth,
      Math.min(this.roomBounds.maxX - halfWidth, constrained.x)
    );

    // Z bounds (forward-backward) - allow hologram to reach the walls
    constrained.z = Math.max(
      this.roomBounds.minZ + halfDepth,
      Math.min(this.roomBounds.maxZ - halfDepth, constrained.z)
    );

    // Y bounds (up-down) - keep hologram bottom on floor level
    // For floor placement, position so bottom of hologram is on floor
    constrained.y = this.roomBounds.floorY - halfHeight;

    return constrained;
  }

  // Implement abstract method
  setupKeyboardListeners() {
    // Remove any existing listeners first
    this.removeKeyboardListeners();

    // Add new listeners
    this.onKeyDown = (e) => {
      if (!this.enabled) return;

      switch (e.key) {
        case "ArrowUp":
          this.keyboardState.forward = true;
          e.preventDefault();
          break;
        case "ArrowDown":
          this.keyboardState.backward = true;
          e.preventDefault();
          break;
        case "ArrowLeft":
          this.keyboardState.left = true;
          e.preventDefault();
          break;
        case "ArrowRight":
          this.keyboardState.right = true;
          e.preventDefault();
          break;
        case "PageUp":
          this.keyboardState.up = true;
          e.preventDefault();
          break;
        case "PageDown":
          this.keyboardState.down = true;
          e.preventDefault();
          break;
      }
    };

    this.onKeyUp = (e) => {
      if (!this.enabled) return;

      switch (e.key) {
        case "ArrowUp":
          this.keyboardState.forward = false;
          e.preventDefault();
          break;
        case "ArrowDown":
          this.keyboardState.backward = false;
          e.preventDefault();
          break;
        case "ArrowLeft":
          this.keyboardState.left = false;
          e.preventDefault();
          break;
        case "ArrowRight":
          this.keyboardState.right = false;
          e.preventDefault();
          break;
        case "PageUp":
          this.keyboardState.up = false;
          e.preventDefault();
          break;
        case "PageDown":
          this.keyboardState.down = false;
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

    // Store current position for bounds checking
    const currentPos = { ...this.currentHologram.position };
    const size = this.currentHologram.size;

    // Calculate movement based on keyboard state
    if (this.keyboardState.forward) {
      currentPos.z -= movement; // Move forward (negative Z)
      moved = true;
    }
    if (this.keyboardState.backward) {
      currentPos.z += movement; // Move backward (positive Z)
      moved = true;
    }
    if (this.keyboardState.left) {
      currentPos.x -= movement; // Move left (negative X)
      moved = true;
    }
    if (this.keyboardState.right) {
      currentPos.x += movement; // Move right (positive X)
      moved = true;
    }
    if (this.keyboardState.up) {
      currentPos.y -= movement; // Move up (negative Y)
      moved = true;
    }
    if (this.keyboardState.down) {
      currentPos.y += movement; // Move down (positive Y)
      moved = true;
    }

    // Apply position constraints
    if (moved) {
      this.currentHologram.position = this.constrainPosition(currentPos);
    }

    // Log movement occasionally for debugging
    if (moved && Math.random() < 0.1) {
      console.log("Hologram position:", this.currentHologram.position);
    }

    return this.currentHologram;
  }

  // Implement abstract method
  draw(p5Instance) {
    if (!this.enabled || !this.currentHologram || !p5Instance) return;

    const p = p5Instance;
    const pos = this.currentHologram.position;
    const size = this.currentHologram.size;

    p.push();
    p.translate(pos.x, pos.y, pos.z);

    // Set hologram material properties
    this.setHologramMaterial(p);

    // Draw cube without the top face
    // We'll manually draw the faces to exclude the top

    // Bottom face
    p.push();
    p.translate(0, size.height / 2, 0);
    p.rotateX(p.HALF_PI);
    p.plane(size.width, size.depth);
    p.pop();

    // Front face
    p.push();
    p.translate(0, 0, size.depth / 2);
    p.plane(size.width, size.height);
    p.pop();

    // Back face
    p.push();
    p.translate(0, 0, -size.depth / 2);
    p.plane(size.width, size.height);
    p.pop();

    // Left face
    p.push();
    p.translate(-size.width / 2, 0, 0);
    p.rotateY(p.HALF_PI);
    p.plane(size.depth, size.height);
    p.pop();

    // Right face
    p.push();
    p.translate(size.width / 2, 0, 0);
    p.rotateY(p.HALF_PI);
    p.plane(size.depth, size.height);
    p.pop();

    // Draw wireframe for better visibility using base class method
    this.drawWireframeBox(p, size);

    p.pop();
  }
}
