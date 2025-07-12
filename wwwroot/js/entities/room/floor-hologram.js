// Hologram Module for DoggyLife
window.HologramSystem = {
  // Configuration
  enabled: false,
  currentHologram: null,

  // Hologram settings
  defaultSize: { width: 100, height: 100, depth: 100 }, // 2x2x2 floor cells (50 units each)
  defaultPosition: { x: 0, y: 150, z: 0 }, // Start with bottom on floor (floorY - height/2)
  hologramColor: [0, 255, 0, 150], // Green with transparency
  wireframeColor: [0, 255, 0, 255], // Solid green for wireframe

  // Room bounds for hologram movement (expanded to reach walls)
  roomBounds: {
    minX: -200, // Full room bounds
    maxX: 200,
    minZ: -200,
    maxZ: 200,
    floorY: 200, // Floor level
  },

  // Movement settings
  moveSpeed: 50, // Units per second
  keyboardState: {
    up: false,
    down: false,
    left: false,
    right: false,
    forward: false,
    backward: false,
  },

  // Initialize hologram system
  init: function () {
    this.setupKeyboardListeners();
    console.log("Hologram system initialized");
    return this;
  },

  // Create a new hologram cube
  createHologram: function (position = null, size = null) {
    const pos = position || { ...this.defaultPosition };
    const siz = size || { ...this.defaultSize };

    this.currentHologram = {
      position: pos,
      size: siz,
      visible: true,
      type: "cube",
    };

    console.log("Hologram created at position:", pos, "with size:", siz);
    return this.currentHologram;
  },

  // Enable hologram mode
  enable: function (position = null, size = null) {
    this.enabled = true;
    if (!this.currentHologram) {
      this.createHologram(position, size);
    } else {
      // Update existing hologram
      if (position) {
        this.currentHologram.position = { ...position };
      }
      if (size) {
        this.currentHologram.size = { ...size };
      }
    }
    console.log("Hologram mode enabled");
    return this;
  },

  // Disable hologram mode
  disable: function () {
    this.enabled = false;
    this.currentHologram = null;
    console.log("Hologram mode disabled");
    return this;
  },

  // Toggle hologram mode
  toggle: function (position = null, size = null) {
    if (this.enabled) {
      this.disable();
    } else {
      this.enable(position, size);
    }
    return this.enabled;
  },

  // Set hologram position
  setPosition: function (x, y, z) {
    if (this.currentHologram) {
      this.currentHologram.position.x = x;
      this.currentHologram.position.y = y;
      this.currentHologram.position.z = z;
    }
    return this;
  },

  // Set hologram size
  setSize: function (width, height, depth) {
    if (this.currentHologram) {
      this.currentHologram.size.width = width;
      this.currentHologram.size.height = height;
      this.currentHologram.size.depth = depth;
    }
    return this;
  },

  // Setup keyboard event listeners
  setupKeyboardListeners: function () {
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
  },

  // Remove keyboard listeners
  removeKeyboardListeners: function () {
    if (this.onKeyDown) {
      window.removeEventListener("keydown", this.onKeyDown);
    }
    if (this.onKeyUp) {
      window.removeEventListener("keyup", this.onKeyUp);
    }
  },

  // Update hologram position based on keyboard input
  update: function (deltaTime) {
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

    // Apply bounds checking using defined room bounds
    const halfWidth = size.width / 2;
    const halfDepth = size.depth / 2;
    const halfHeight = size.height / 2;

    // X bounds (left-right) - allow hologram to reach the walls
    currentPos.x = Math.max(
      this.roomBounds.minX + halfWidth,
      Math.min(this.roomBounds.maxX - halfWidth, currentPos.x)
    );

    // Z bounds (forward-backward) - allow hologram to reach the walls
    currentPos.z = Math.max(
      this.roomBounds.minZ + halfDepth,
      Math.min(this.roomBounds.maxZ - halfDepth, currentPos.z)
    );

    // Y bounds (up-down) - keep hologram bottom on floor level
    // For floor placement, position so bottom of hologram is on floor
    currentPos.y = this.roomBounds.floorY - halfHeight;

    // Update position only if it changed
    if (moved) {
      this.currentHologram.position = currentPos;
    }

    // Log movement occasionally for debugging
    if (moved && Math.random() < 0.1) {
      console.log("Hologram position:", this.currentHologram.position);
    }

    return this.currentHologram;
  },

  // Draw the hologram (cube without top face)
  draw: function (p5Instance) {
    if (!this.enabled || !this.currentHologram || !p5Instance) return;

    const p = p5Instance;
    const pos = this.currentHologram.position;
    const size = this.currentHologram.size;

    p.push();
    p.translate(pos.x, pos.y, pos.z);

    // Set hologram material properties
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

    // Draw wireframe edges for better visibility
    p.noFill();
    p.stroke(
      this.wireframeColor[0],
      this.wireframeColor[1],
      this.wireframeColor[2],
      255
    );
    p.strokeWeight(1);

    // Draw the wireframe of the open cube
    const hw = size.width / 2;
    const hh = size.height / 2;
    const hd = size.depth / 2;

    // Bottom edges
    p.line(-hw, hh, -hd, hw, hh, -hd);
    p.line(hw, hh, -hd, hw, hh, hd);
    p.line(hw, hh, hd, -hw, hh, hd);
    p.line(-hw, hh, hd, -hw, hh, -hd);

    // Top edges (only the ones we want to show)
    p.line(-hw, -hh, -hd, hw, -hh, -hd);
    p.line(hw, -hh, -hd, hw, -hh, hd);
    p.line(hw, -hh, hd, -hw, -hh, hd);
    p.line(-hw, -hh, hd, -hw, -hh, -hd);

    // Vertical edges
    p.line(-hw, -hh, -hd, -hw, hh, -hd);
    p.line(hw, -hh, -hd, hw, hh, -hd);
    p.line(hw, -hh, hd, hw, hh, hd);
    p.line(-hw, -hh, hd, -hw, hh, hd);

    p.pop();
  },

  // Get current hologram state
  getState: function () {
    return {
      enabled: this.enabled,
      hologram: this.currentHologram,
      keyboardState: { ...this.keyboardState },
    };
  },

  // Clean up resources
  cleanup: function () {
    this.removeKeyboardListeners();
    this.disable();
    console.log("Hologram system cleaned up");
  },
};

// Initialize the hologram system when the script loads
if (typeof window !== "undefined") {
  window.HologramSystem.init();
}
