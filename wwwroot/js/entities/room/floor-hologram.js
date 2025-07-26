// Hologram Module for DoggyLife
import { BaseHologramSystem } from "./base-hologram.js";
import { CouchFurniture } from "./furniture/couch-furniture.js";
import { BedFurniture } from "./furniture/bed-furniture.js";
import { ShelfFurniture } from "./furniture/shelf-furniture.js";

export class FloorHologramSystem extends BaseHologramSystem {
  constructor() {
    super();

    // Override base settings
    this.defaultSize = { width: 100, height: 100, depth: 100 };
    this.defaultPosition = { x: 0, y: 150, z: 0 };
    this.hologramColor = [0, 255, 0, 150];
    this.wireframeColor = [0, 255, 0, 255];

    this.roomBounds = null;
    this.selectedFurniture = null;
    this.selectedItemData = null;

    // Rotation button properties
    this.showRotationButtons = true;
    this.rotationButtons = [];
    this.buttonSize = 30; // Size of rotation buttons
    this.buttonDistance = 120; // Distance from furniture center (increased to place outside furniture)

    // Mouse interaction state
    this.mouseState = {
      isPressed: false,
      lastX: 0,
      lastY: 0,
    };

    this.setupMouseListeners();
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

  // Create a new hologram with rotation support
  createHologram(position = null, size = null, ...args) {
    const hologram = super.createHologram(position, size, ...args);
    
    // Add rotation property for furniture synchronization
    if (hologram) {
      hologram.rotation = 0; // Initialize rotation
    }
    
    return hologram;
  }
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

  // Setup mouse listeners for rotation control
  setupMouseListeners() {
    this.onMousePressed = (e) => {
      if (!this.enabled || !this.selectedFurniture) return;

      // Find the canvas element - look for the first canvas in the document
      const canvas = document.querySelector("canvas");
      if (!canvas) {
        return;
      }

      // Get canvas dimensions and click position
      const rect = canvas.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const clickY = e.clientY - rect.top;

      // Use the actual displayed canvas dimensions
      const canvasWidth = rect.width;
      const canvasHeight = rect.height;

      const buttonSize = 60;
      const margin = 10;

      // Simple 2D rectangular bounds checking
      // Bottom-left corner button (counter-clockwise)
      if (
        clickX >= margin &&
        clickX <= margin + buttonSize &&
        clickY >= canvasHeight - margin - buttonSize &&
        clickY <= canvasHeight - margin
      ) {
        this.selectedFurniture.rotate(-Math.PI / 12); // -15 degrees
        // Update hologram rotation to match furniture
        if (this.currentHologram) {
          this.currentHologram.rotation = this.selectedFurniture.rotation;
        }
        e.preventDefault();
        e.stopPropagation();
        return;
      }

      // Bottom-right corner button (clockwise)
      if (
        clickX >= canvasWidth - margin - buttonSize &&
        clickX <= canvasWidth - margin &&
        clickY >= canvasHeight - margin - buttonSize &&
        clickY <= canvasHeight - margin
      ) {
        this.selectedFurniture.rotate(Math.PI / 12); // +15 degrees
        // Update hologram rotation to match furniture
        if (this.currentHologram) {
          this.currentHologram.rotation = this.selectedFurniture.rotation;
        }
        e.preventDefault();
        e.stopPropagation();
        return;
      }

    };

    this.onMouseReleased = (e) => {
      // Nothing needed for simple button clicks
    };

    this.onMouseMoved = (e) => {
      // Nothing needed for simple button clicks
    };
  }

  // Add mouse listeners dynamically
  addMouseListeners() {
    // Try to attach to canvas first, fallback to window
    const canvas = document.querySelector("canvas");
    const target = canvas || window;
    target.addEventListener("mousedown", this.onMousePressed, {
      passive: false,
    });
    target.addEventListener("mouseup", this.onMouseReleased, {
      passive: false,
    });
    target.addEventListener("mousemove", this.onMouseMoved, { passive: false });

    // Store the target for cleanup
    this.mouseListenerTarget = target;
  }

  // Remove mouse listeners
  removeMouseListeners() {
    if (this.mouseListenerTarget) {
      this.mouseListenerTarget.removeEventListener(
        "mousedown",
        this.onMousePressed
      );
      this.mouseListenerTarget.removeEventListener(
        "mouseup",
        this.onMouseReleased
      );
      this.mouseListenerTarget.removeEventListener(
        "mousemove",
        this.onMouseMoved
      );
      this.mouseListenerTarget = null;
    }
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

      // Update furniture position if we have selected furniture
      if (this.selectedFurniture) {
        this.updateFurniturePosition();
      }
    }

    return this.currentHologram;
  }

  // Set selected furniture item
  setSelectedItem(itemId, itemName, itemType, sizeX, sizeY, sizeZ) {
    // Clear any existing furniture first to prevent errors
    this.clearSelectedItem();

    this.selectedItemData = {
      id: itemId,
      name: itemName,
      type: itemType, // Store as 'type'
      itemType: itemType, // Also store as 'itemType' for compatibility
      sizeX: sizeX,
      sizeY: sizeY,
      sizeZ: sizeZ,
    };

    // Create the appropriate furniture object
    this.createFurnitureObject();

    // Update hologram size to match furniture dimensions
    if (this.currentHologram) {
      // For floor items: sizeX = width, sizeY = depth, sizeZ = height
      this.currentHologram.size = {
        width: sizeX,
        height: sizeZ, // sizeZ is the height for floor items
        depth: sizeY,  // sizeY is the depth for floor items
      };
      this.updateFurniturePosition();
    }

    // Add mouse listeners for rotation when furniture is selected
    this.addMouseListeners();
  }

  // Clear selected furniture item
  clearSelectedItem() {
    // Remove mouse listeners first
    this.removeMouseListeners();

    // Properly clean up existing furniture
    if (this.selectedFurniture) {
      // If furniture has a cleanup method, call it
      if (typeof this.selectedFurniture.cleanup === "function") {
        this.selectedFurniture.cleanup();
      }
    }

    this.selectedItemData = null;
    this.selectedFurniture = null;
    this.rotationButtons = [];
  }

  // Create furniture object based on selected item
  createFurnitureObject() {
    if (!this.selectedItemData) {
      this.selectedFurniture = null;
      return;
    }

    const { type, itemType, sizeX, sizeY, sizeZ } = this.selectedItemData;
    const furnitureType = type || itemType; // Use either property
    switch (furnitureType) {
      case "couch":
        this.selectedFurniture = new CouchFurniture(sizeX, sizeY, sizeZ);
        break;
      case "bed":
        this.selectedFurniture = new BedFurniture(sizeX, sizeY, sizeZ);
        break;
      case "shelf":
        this.selectedFurniture = new ShelfFurniture(sizeX, sizeY, sizeZ);
        break;
      default:
        this.selectedFurniture = null;
        break;
    }

    if (this.selectedFurniture) {
      // Initialize hologram rotation to match furniture
      if (this.currentHologram) {
        this.currentHologram.rotation = this.selectedFurniture.rotation || 0;
      }
      this.updateFurniturePosition();
    }
  }

  // Update furniture position to match hologram position
  updateFurniturePosition() {
    if (!this.selectedFurniture || !this.currentHologram) return;

    const pos = this.currentHologram.position;
    this.selectedFurniture.setPosition(pos.x, pos.y, pos.z);
    
    // Sync hologram rotation with furniture rotation
    if (this.currentHologram.rotation !== undefined) {
      this.selectedFurniture.setRotation(this.currentHologram.rotation);
    } else {
      // If hologram doesn't have rotation, sync from furniture
      this.currentHologram.rotation = this.selectedFurniture.rotation || 0;
    }
  }

  // Check if a screen position clicks on a rotation button
  checkRotationButtonClick(screenX, screenY) {
    for (let button of this.rotationButtons) {
      const distance = Math.sqrt(
        Math.pow(screenX - button.screenX, 2) +
          Math.pow(screenY - button.screenY, 2)
      );

      if (distance <= this.buttonSize) {
        return button;
      }
    }

    return null;
  }

  // Update rotation button positions
  updateRotationButtons(p5Instance) {
    if (!this.enabled || !this.currentHologram || !this.selectedFurniture) {
      this.rotationButtons = [];
      return;
    }

    const pos = this.currentHologram.position;
    const size = this.currentHologram.size;

    // Position buttons below the furniture, on the floor
    const buttonY = pos.y + size.height / 2 + 30;

    // Create two rotation buttons: clockwise and counterclockwise
    this.rotationButtons = [
      {
        direction: "counterclockwise",
        worldX: pos.x - this.buttonDistance,
        worldY: buttonY,
        worldZ: pos.z,
        screenX: 0, // Will be calculated later
        screenY: 0, // Will be calculated later
      },
      {
        direction: "clockwise",
        worldX: pos.x + this.buttonDistance,
        worldY: buttonY,
        worldZ: pos.z,
        screenX: 0, // Will be calculated later
        screenY: 0, // Will be calculated later
      },
    ];

    // Calculate screen positions (simplified approximation)
    for (let button of this.rotationButtons) {
      // Simple screen position approximation based on 3D to 2D projection
      const screenX = p5Instance.width / 2 + (button.worldX - pos.x) * 2;
      const screenY = p5Instance.height / 2 + (button.worldZ - pos.z) * 2;

      button.screenX = screenX;
      button.screenY = screenY;
    }
  }

  // Override updateHologramSize to also update furniture
  updateHologramSize(width, height, depth) {
    super.updateHologramSize(width, height, depth);

    // For floor items, ensure proper dimension mapping
    if (this.currentHologram) {
      // Store dimensions correctly for floor furniture
      this.currentHologram.size = {
        width: width,   // X dimension
        height: depth,  // Z dimension becomes height
        depth: height   // Y dimension becomes depth
      };
    }

    if (this.selectedFurniture) {
      this.selectedFurniture.updateSize(width, height, depth);
    }

    return this;
  }

  // Implement abstract method
  draw(p5Instance) {
    if (!this.enabled || !this.currentHologram || !p5Instance) return;

    const p = p5Instance;
    const pos = this.currentHologram.position;
    const size = this.currentHologram.size;
    const rotation = this.currentHologram.rotation || 0;

    // Draw the 3D hologram outline
    this.draw3DHologram(p, pos, size, rotation);

    // If we have selected furniture, render it
    if (this.selectedFurniture) {
      // Draw the furniture object
      this.selectedFurniture.draw(p5Instance);

      // Draw simple corner rotation buttons
      this.drawRotationButtons(p5Instance);
    }
  }

  // Draw a 3D hologram outline
  draw3DHologram(p, position, size, rotation = 0) {
    p.push();
    p.translate(position.x, position.y, position.z);
    
    // Apply rotation to match furniture
    p.rotateY(rotation);

    // Set hologram material properties
    this.setHologramMaterial(p);

    // Draw the full 3D wireframe box
    this.drawWireframeBox(p, size);

    // Draw semi-transparent faces for better visibility
    p.fill(
      this.hologramColor[0],
      this.hologramColor[1],
      this.hologramColor[2],
      80 // Lower alpha for subtle face visibility
    );

    // Bottom face (floor contact)
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

    // Top face (optional, for complete outline)
    p.push();
    p.translate(0, -size.height / 2, 0);
    p.rotateX(p.HALF_PI);
    p.plane(size.width, size.depth);
    p.pop();

    // Draw floor tile beneath for placement reference
    this.drawFloorTile(p, { x: 0, y: 0, z: 0 }, size);

    p.pop();
  }

  // Helper method to draw a floor tile beneath the furniture/hologram
  drawFloorTile(p, relativePosition, size) {
    p.push();

    // Position the tile slightly above the floor level for visibility
    // relativePosition is relative to the current transform
    p.translate(relativePosition.x, relativePosition.y + size.height / 2 - 2, relativePosition.z);

    // Rotate to be flat on the floor
    p.rotateX(p.HALF_PI);

    // Set tile appearance - bright green with some transparency
    p.fill(0, 255, 0, 60); // Lower alpha to not interfere with 3D hologram
    p.stroke(0, 255, 0, 150);
    p.strokeWeight(1);

    // Draw a rectangular tile matching the furniture footprint
    p.plane(size.width, size.depth);

    // Add grid lines for better visibility
    p.stroke(0, 255, 0, 100);
    p.strokeWeight(0.5);

    // Draw grid lines
    const gridSpacing = 20;
    const halfWidth = size.width / 2;
    const halfDepth = size.depth / 2;

    // Vertical lines
    for (let x = -halfWidth + gridSpacing; x < halfWidth; x += gridSpacing) {
      p.line(x, -halfDepth, x, halfDepth);
    }

    // Horizontal lines
    for (let z = -halfDepth + gridSpacing; z < halfDepth; z += gridSpacing) {
      p.line(-halfWidth, z, halfWidth, z);
    }

    p.pop();
  }

  // Draw simple rotation buttons in screen corners
  drawRotationButtons(p5Instance) {
    if (!this.selectedFurniture) return;

    const p = p5Instance;

    // Save the current camera state
    p.push();

    // Reset to 2D orthographic projection for UI elements
    p.camera(0, 0, p.height / 2 / Math.tan(Math.PI / 6), 0, 0, 0, 0, 1, 0);
    p.ortho(-p.width / 2, p.width / 2, -p.height / 2, p.height / 2, 0, 1000);

    const buttonSize = 60;
    const margin = 10;
    const scaleFactor = 1.5; // Scale factor for the arrow

    // Your perfect triangle pattern
    const trianglePixels = [
      [5, 0],
      [4, 1],
      [5, 1],
      [6, 1],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [7, 2],
      [2, 3],
      [3, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [7, 3],
      [8, 3],
      [1, 4],
      [2, 4],
      [3, 4],
      [4, 4],
      [5, 4],
      [6, 4],
      [7, 4],
      [8, 4],
      [9, 4],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [4, 5],
      [5, 5],
      [6, 5],
      [7, 5],
      [8, 5],
      [9, 5],
      [10, 5],
      [3, 6],
      [4, 6],
      [5, 6],
      [6, 6],
      [7, 6],
      [4, 7],
      [5, 7],
      [6, 7],
    ];

    // Bottom-left corner button (counter-clockwise)
    p.push();
    p.translate(
      -p.width / 2 + margin + buttonSize / 2,
      p.height / 2 - margin - buttonSize / 2,
      0
    );

    // Button background
    p.fill(255, 165, 0, 200);
    p.stroke(255, 140, 0);
    p.strokeWeight(3);
    p.circle(0, 0, buttonSize);

    // Draw curved arc (counter-clockwise semicircle)
    p.noFill();
    p.stroke(255, 255, 255);
    p.strokeWeight(3);
    p.arc(0, 0, 32, 32, p.HALF_PI, 3 * p.HALF_PI);

    // Draw rotated arrowhead at the end of arc
    p.push();
    p.translate(0, -16); // Position at top of arc
    p.rotate(3 * p.HALF_PI + p.PI);
    p.translate(-5 * scaleFactor, -4 * scaleFactor); // Center arrow shape

    // Disable blending to prevent transparency issues
    p.blendMode(p.REPLACE);
    p.fill(255, 255, 255, 255); // Solid white
    p.noStroke();
    for (let [x, y] of trianglePixels) {
      p.rect(x * scaleFactor, y * scaleFactor, scaleFactor, scaleFactor);
    }
    // Reset blend mode back to normal
    p.blendMode(p.BLEND);
    p.pop();

    p.pop();

    // Bottom-right corner button (clockwise)
    p.push();
    p.translate(
      p.width / 2 - margin - buttonSize / 2,
      p.height / 2 - margin - buttonSize / 2,
      0
    );

    // Button background
    p.fill(255, 165, 0, 200);
    p.stroke(255, 140, 0);
    p.strokeWeight(3);
    p.circle(0, 0, buttonSize);

    // Draw curved arc (clockwise semicircle)
    p.noFill();
    p.stroke(255, 255, 255);
    p.strokeWeight(3);
    p.arc(0, 0, 32, 32, -p.HALF_PI, p.HALF_PI);

    // Draw rotated arrowhead at the end of arc
    p.push();
    p.translate(0, 16); // Position at bottom of arc
    p.rotate(-(3 * p.HALF_PI + p.PI)); // Same rotation but opposite direction
    p.translate(-5 * scaleFactor, -4 * scaleFactor); // Center arrow shape

    // Disable blending to prevent transparency issues
    p.blendMode(p.REPLACE);
    p.fill(255, 255, 255, 255); // Solid white
    p.noStroke();
    for (let [x, y] of trianglePixels) {
      p.rect(x * scaleFactor, y * scaleFactor, scaleFactor, scaleFactor);
    }
    // Reset blend mode back to normal
    p.blendMode(p.BLEND);
    p.pop();

    p.pop();

    // Restore the previous camera state
    p.pop();
  }

  // Override cleanup to include mouse listeners
  cleanup() {
    super.cleanup();

    // Remove mouse listeners
    this.removeMouseListeners();
  }
}
