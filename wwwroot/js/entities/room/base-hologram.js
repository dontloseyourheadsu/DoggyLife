// Base Hologram System for DoggyLife
export class BaseHologramSystem {
  constructor() {
    // Configuration
    this.enabled = false;
    this.currentHologram = null;

    // Hologram settings (to be overridden by subclasses)
    this.defaultSize = { width: 100, height: 100, depth: 100 };
    this.defaultPosition = { x: 0, y: 0, z: 0 };
    this.hologramColor = [0, 255, 0, 150];
    this.wireframeColor = [0, 255, 0, 255];

    // Movement settings
    this.moveSpeed = 50; // Units per second
    this.keyboardState = {};

    // Initialize after properties are set
    this.initializeKeyboardState();
    this.setupKeyboardListeners();
    console.log("Base hologram system initialized");
  }

  // Abstract method - to be implemented by subclasses
  initializeKeyboardState() {
    throw new Error("initializeKeyboardState must be implemented by subclass");
  }

  // Abstract method - to be implemented by subclasses
  setupKeyboardListeners() {
    throw new Error("setupKeyboardListeners must be implemented by subclass");
  }

  // Create a new hologram
  createHologram(position = null, size = null, ...args) {
    const pos = position || { ...this.defaultPosition };
    const siz = size || { ...this.defaultSize };

    this.currentHologram = {
      position: pos,
      size: siz,
      visible: true,
      type: this.getHologramType(),
      ...this.getAdditionalHologramProperties(...args),
    };

    console.log(`Hologram created at position:`, pos, `with size:`, siz);
    return this.currentHologram;
  }

  // Abstract method - to be implemented by subclasses
  getHologramType() {
    throw new Error("getHologramType must be implemented by subclass");
  }

  // Hook for subclasses to add additional properties
  getAdditionalHologramProperties(...args) {
    return {};
  }

  // Enable hologram mode
  enable(position = null, size = null, ...args) {
    this.enabled = true;
    if (!this.currentHologram) {
      this.createHologram(position, size, ...args);
    } else {
      // Update existing hologram
      if (position) {
        this.updateHologramPosition(position, ...args);
      }
      if (size) {
        this.currentHologram.size = { ...size };
      }
      this.handleAdditionalEnableLogic(...args);
    }
    console.log("Hologram mode enabled");
    return this;
  }

  // Hook for subclasses to handle additional enable logic
  handleAdditionalEnableLogic(...args) {
    // Default implementation does nothing
  }

  // Hook for subclasses to handle position updates
  updateHologramPosition(position, ...args) {
    this.currentHologram.position = { ...position };
  }

  // Disable hologram mode
  disable() {
    this.enabled = false;
    this.currentHologram = null;
    console.log("Hologram mode disabled");
    return this;
  }

  // Toggle hologram mode
  toggle(position = null, size = null, ...args) {
    if (this.enabled) {
      this.disable();
    } else {
      this.enable(position, size, ...args);
    }
    return this.enabled;
  }

  // Set hologram position
  setPosition(x, y, z) {
    if (this.currentHologram) {
      const newPos = { x, y, z };
      this.currentHologram.position = this.constrainPosition(newPos);
    }
    return this;
  }

  // Hook for subclasses to constrain position
  constrainPosition(position) {
    return position; // Default implementation returns position unchanged
  }

  // Set hologram size
  setSize(width, height, depth) {
    if (this.currentHologram) {
      this.currentHologram.size.width = width;
      this.currentHologram.size.height = height;
      this.currentHologram.size.depth = depth;
    }
    return this;
  }

  // Remove keyboard listeners
  removeKeyboardListeners() {
    if (this.onKeyDown) {
      window.removeEventListener("keydown", this.onKeyDown);
    }
    if (this.onKeyUp) {
      window.removeEventListener("keyup", this.onKeyUp);
    }
  }

  // Abstract method - to be implemented by subclasses
  update(deltaTime) {
    throw new Error("update must be implemented by subclass");
  }

  // Abstract method - to be implemented by subclasses
  draw(p5Instance) {
    throw new Error("draw must be implemented by subclass");
  }

  // Get current hologram state
  getState() {
    return {
      enabled: this.enabled,
      hologram: this.currentHologram,
      keyboardState: { ...this.keyboardState },
      ...this.getAdditionalState(),
    };
  }

  // Hook for subclasses to add additional state
  getAdditionalState() {
    return {};
  }

  // Clean up resources
  cleanup() {
    this.removeKeyboardListeners();
    this.disable();
    console.log("Hologram system cleaned up");
  }

  // Helper method for drawing wireframe edges
  drawWireframeBox(p5Instance, size) {
    const p = p5Instance;
    const hw = size.width / 2;
    const hh = size.height / 2;
    const hd = size.depth / 2;

    p.noFill();
    p.stroke(
      this.wireframeColor[0],
      this.wireframeColor[1],
      this.wireframeColor[2],
      255
    );
    p.strokeWeight(1);

    // Draw wireframe edges
    p.beginShape(p.LINES);

    // Bottom face
    p.vertex(-hw, hh, -hd);
    p.vertex(hw, hh, -hd);
    p.vertex(hw, hh, -hd);
    p.vertex(hw, hh, hd);
    p.vertex(hw, hh, hd);
    p.vertex(-hw, hh, hd);
    p.vertex(-hw, hh, hd);
    p.vertex(-hw, hh, -hd);

    // Top face
    p.vertex(-hw, -hh, -hd);
    p.vertex(hw, -hh, -hd);
    p.vertex(hw, -hh, -hd);
    p.vertex(hw, -hh, hd);
    p.vertex(hw, -hh, hd);
    p.vertex(-hw, -hh, hd);
    p.vertex(-hw, -hh, hd);
    p.vertex(-hw, -hh, -hd);

    // Vertical edges
    p.vertex(-hw, -hh, -hd);
    p.vertex(-hw, hh, -hd);
    p.vertex(hw, -hh, -hd);
    p.vertex(hw, hh, -hd);
    p.vertex(hw, -hh, hd);
    p.vertex(hw, hh, hd);
    p.vertex(-hw, -hh, hd);
    p.vertex(-hw, hh, hd);

    p.endShape();
  }

  // Helper method for setting hologram material properties
  setHologramMaterial(p5Instance) {
    const p = p5Instance;
    p.fill(
      this.hologramColor[0],
      this.hologramColor[1],
      this.hologramColor[2],
      this.hologramColor[3]
    );
    p.stroke(
      this.wireframeColor[0],
      this.wireframeColor[1],
      this.wireframeColor[2],
      this.wireframeColor[3]
    );
    p.strokeWeight(2);
  }
}
