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

      // Update furniture position if we have selected furniture
      if (this.selectedFurniture) {
        this.updateFurniturePosition();
      }
    }

    // Log movement occasionally for debugging
    if (moved && Math.random() < 0.1) {
      console.log("Hologram position:", this.currentHologram.position);
    }

    return this.currentHologram;
  }

  // Set selected furniture item
  setSelectedItem(itemId, itemName, itemType, sizeX, sizeY, sizeZ) {
    console.log(
      `Floor hologram: Setting selected item ${itemName} (${itemType}) with size ${sizeX}x${sizeY}x${sizeZ}`
    );

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

    // Update hologram size to match furniture
    if (this.currentHologram) {
      this.currentHologram.size = {
        width: sizeX,
        height: sizeY,
        depth: sizeZ,
      };
      this.updateFurniturePosition();
    }

    console.log(
      `Floor hologram: Selected ${itemName} with size ${sizeX}x${sizeY}x${sizeZ}`,
      this.selectedFurniture
    );
  }

  // Clear selected furniture item
  clearSelectedItem() {
    // Properly clean up existing furniture
    if (this.selectedFurniture) {
      // If furniture has a cleanup method, call it
      if (typeof this.selectedFurniture.cleanup === "function") {
        this.selectedFurniture.cleanup();
      }
    }

    this.selectedItemData = null;
    this.selectedFurniture = null;
    console.log("Floor hologram: Selected item cleared");
  }

  // Create furniture object based on selected item
  createFurnitureObject() {
    if (!this.selectedItemData) {
      this.selectedFurniture = null;
      return;
    }

    const { type, itemType, sizeX, sizeY, sizeZ } = this.selectedItemData;
    const furnitureType = type || itemType; // Use either property
    console.log(
      `Creating furniture object for type: "${furnitureType}" with size ${sizeX}x${sizeY}x${sizeZ}`
    );
    console.log("Full selectedItemData:", this.selectedItemData);

    switch (furnitureType) {
      case "couch":
        this.selectedFurniture = new CouchFurniture(sizeX, sizeY, sizeZ);
        console.log("Created couch furniture:", this.selectedFurniture);
        break;
      case "bed":
        this.selectedFurniture = new BedFurniture(sizeX, sizeY, sizeZ);
        console.log("Created bed furniture:", this.selectedFurniture);
        break;
      case "shelf":
        this.selectedFurniture = new ShelfFurniture(sizeX, sizeY, sizeZ);
        console.log("Created shelf furniture:", this.selectedFurniture);
        break;
      default:
        console.warn(`Unknown furniture type: "${furnitureType}"`);
        console.warn(
          "Available properties:",
          Object.keys(this.selectedItemData)
        );
        this.selectedFurniture = null;
        break;
    }

    if (this.selectedFurniture) {
      this.updateFurniturePosition();
    }
  }

  // Update furniture position to match hologram position
  updateFurniturePosition() {
    if (!this.selectedFurniture || !this.currentHologram) return;

    const pos = this.currentHologram.position;
    this.selectedFurniture.setPosition(pos.x, pos.y, pos.z);
  }

  // Override updateHologramSize to also update furniture
  updateHologramSize(width, height, depth) {
    super.updateHologramSize(width, height, depth);

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

    // Always draw a floor tile to show the furniture placement area
    this.drawFloorTile(p, pos, size);

    // If we have selected furniture, render it
    if (this.selectedFurniture) {
      console.log(
        "Drawing furniture:",
        this.selectedItemData.name,
        "at position:",
        pos
      );

      // Draw the furniture object
      this.selectedFurniture.draw(p5Instance);
    } else {
      // Draw the default hologram cube (without top face)
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

  // Helper method to draw a floor tile beneath the furniture/hologram
  drawFloorTile(p, position, size) {
    p.push();

    // Position the tile on the floor, slightly below the furniture
    p.translate(position.x, position.y + size.height / 2 + 5, position.z);

    // Rotate to be flat on the floor
    p.rotateX(p.HALF_PI);

    // Set tile appearance - bright green with some transparency
    p.fill(0, 255, 0, 120);
    p.stroke(0, 255, 0, 200);
    p.strokeWeight(2);

    // Draw a rectangular tile matching the furniture footprint
    p.plane(size.width, size.depth);

    // Add grid lines for better visibility
    p.stroke(0, 255, 0, 150);
    p.strokeWeight(1);

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
}
