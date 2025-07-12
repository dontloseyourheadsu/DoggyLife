// Wall-aware Hologram Module for DoggyLife
window.WallHologramSystem = {
  // Configuration
  enabled: false,
  currentHologram: null,
  currentWall: "back", // "back" or "left"

  // Wall definitions
  walls: {
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
  },

  // Hologram settings
  defaultSize: { width: 50, height: 50, depth: 50 },
  defaultPosition: { x: -175, y: 0, z: -200 }, // Start on back wall, very close to intersection
  hologramColor: [255, 0, 255, 100], // Purple with transparency for wall mode
  wireframeColor: [255, 0, 255, 255], // Solid purple for wireframe

  // Movement settings
  moveSpeed: 50, // Units per second (reduced for easier control)
  keyboardState: {
    horizontal: false, // Arrow left/right
    vertical: false, // Arrow up/down
    horizontalDirection: 0, // -1 for left, 1 for right
    verticalDirection: 0, // -1 for up, 1 for down
  },

  // Wall transition settings
  transitionThreshold: 25, // How close to intersection before allowing transition (increased for easier transitions)
  intersectionLine: { x: -200, z: -200 }, // Where the two walls meet

  // Initialize wall hologram system
  init: function () {
    this.setupKeyboardListeners();
    console.log("Wall hologram system initialized");
    return this;
  },

  // Create a new wall hologram
  createHologram: function (position = null, size = null, wall = "back") {
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

    console.log(
      `🎮 Wall hologram created on ${wall} wall at position:`,
      validPos
    );
    console.log(`🏠 Starting wall: ${this.currentWall}`);
    return this.currentHologram;
  },

  // Constrain position to a specific wall
  constrainToWall: function (position, wallName) {
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
  },

  // Check if position is near the intersection and can transition
  canTransitionWalls: function (position, fromWall, toWall) {
    const threshold = this.transitionThreshold;
    const intersection = this.intersectionLine;

    // Check if we're close enough to the intersection
    const distanceToIntersection = Math.sqrt(
      Math.pow(position.x - intersection.x, 2) +
        Math.pow(position.z - intersection.z, 2)
    );

    return distanceToIntersection <= threshold;
  },

  // Handle wall transition
  transitionToWall: function (newWall, currentPosition) {
    if (!this.walls[newWall] || !this.currentHologram) return false;

    const oldWall = this.currentWall;
    console.log(`🔄 WALL TRANSITION: ${oldWall} → ${newWall}`);
    console.log(`Previous position:`, currentPosition);

    // Map position from old wall to new wall
    const mappedPosition = this.mapPositionBetweenWalls(
      currentPosition,
      oldWall,
      newWall
    );
    console.log(`Mapped position:`, mappedPosition);

    // Update current wall and constrain position
    this.currentWall = newWall;
    this.currentHologram.wall = newWall;
    this.currentHologram.position = this.constrainToWall(
      mappedPosition,
      newWall
    );

    console.log(`✅ Successfully transitioned to ${newWall} wall`);
    console.log(`Final position:`, this.currentHologram.position);
    console.log(`Current wall is now: ${this.currentWall}`);
    return true;
  },

  // Map position coordinates between walls
  mapPositionBetweenWalls: function (position, fromWall, toWall) {
    const mapped = { ...position };

    console.log(`🗺️ Mapping position from ${fromWall} to ${toWall}:`, position);

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

        console.log(
          `🗺️ Back→Left: x=${position.x} mapped to z=${mapped.z}, x set to ${mapped.x}`
        );
      } else {
        // From left wall (z,y moveable) to back wall (x,y moveable)
        // Map Z position to X position
        mapped.x = position.z;
        mapped.z = this.walls.back.bounds.z; // Set to back wall position (-200)

        console.log(
          `🗺️ Left→Back: z=${position.z} mapped to x=${mapped.x}, z set to ${mapped.z}`
        );
      }
    }

    console.log(`🗺️ Final mapped position:`, mapped);
    return mapped;
  },

  // Enable wall hologram mode
  enable: function (position = null, size = null, wall = "back") {
    this.enabled = true;
    if (!this.currentHologram) {
      this.createHologram(position, size, wall);
    } else {
      // Update existing hologram
      if (position) {
        this.currentHologram.position = this.constrainToWall(
          position,
          wall || this.currentWall
        );
      }
      if (size) {
        this.currentHologram.size = { ...size };
      }
      if (wall) {
        this.currentWall = wall;
        this.currentHologram.wall = wall;
      }
    }
    console.log("Wall hologram mode enabled");
    return this;
  },

  // Disable wall hologram mode
  disable: function () {
    this.enabled = false;
    this.currentHologram = null;
    console.log("Wall hologram mode disabled");
    return this;
  },

  // Toggle wall hologram mode
  toggle: function (position = null, size = null, wall = "back") {
    if (this.enabled) {
      this.disable();
    } else {
      this.enable(position, size, wall);
    }
    return this.enabled;
  },

  // Setup keyboard event listeners
  setupKeyboardListeners: function () {
    // Remove any existing listeners first
    this.removeKeyboardListeners();

    // Add new listeners
    this.onKeyDown = (e) => {
      if (!this.enabled) return;

      switch (e.key) {
        case "ArrowLeft":
          this.keyboardState.horizontal = true;
          this.keyboardState.horizontalDirection = -1;
          console.log(
            `⬅️ Arrow Left pressed (current wall: ${this.currentWall})`
          );
          e.preventDefault();
          break;
        case "ArrowRight":
          this.keyboardState.horizontal = true;
          this.keyboardState.horizontalDirection = 1;
          console.log(
            `➡️ Arrow Right pressed (current wall: ${this.currentWall})`
          );
          e.preventDefault();
          break;
        case "ArrowUp":
          this.keyboardState.vertical = true;
          this.keyboardState.verticalDirection = -1;
          console.log(
            `⬆️ Arrow Up pressed (current wall: ${this.currentWall})`
          );
          e.preventDefault();
          break;
        case "ArrowDown":
          this.keyboardState.vertical = true;
          this.keyboardState.verticalDirection = 1;
          console.log(
            `⬇️ Arrow Down pressed (current wall: ${this.currentWall})`
          );
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
        console.log(
          `🎯 Predicted intersection, transitioning to ${targetWall} wall`
        );
        console.log(
          `Current wall: ${this.currentWall} → Target wall: ${targetWall}`
        );

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
          console.log(
            `🚧 Movement was constrained, checking for transition possibility`
          );
          console.log(
            `Intended: (${intendedPos.x.toFixed(1)}, ${intendedPos.y.toFixed(
              1
            )}, ${intendedPos.z.toFixed(
              1
            )}), Constrained: (${constrainedPos.x.toFixed(
              1
            )}, ${constrainedPos.y.toFixed(1)}, ${constrainedPos.z.toFixed(1)})`
          );

          const targetWall = this.currentWall === "back" ? "left" : "back";
          if (
            this.canTransitionWalls(intendedPos, this.currentWall, targetWall)
          ) {
            console.log(
              `🚧 Attempting fallback transition to ${targetWall} wall`
            );
            this.transitionToWall(targetWall, intendedPos);
          } else {
            this.currentHologram.position = constrainedPos;
            console.log(
              `📍 Movement constrained, staying on ${this.currentWall} wall`
            );
          }
        } else {
          this.currentHologram.position = constrainedPos;
          console.log(
            `📍 Normal movement on ${
              this.currentWall
            } wall: (${constrainedPos.x.toFixed(1)}, ${constrainedPos.y.toFixed(
              1
            )}, ${constrainedPos.z.toFixed(1)})`
          );
        }
      }
    }

    return this.currentHologram;
  },

  // Check if the intended movement will reach the intersection
  willReachIntersection: function (currentPos, intendedPos) {
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
        console.log(
          `⬅️ Back wall: Hologram edge will cross to left wall (edge at x=${intendedEdge.toFixed(
            1
          )}, threshold=${crossingThreshold.toFixed(1)})`
        );
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
        console.log(
          `⬆️ Left wall: Hologram edge will cross to back wall (edge at z=${intendedEdge.toFixed(
            1
          )}, threshold=${crossingThreshold.toFixed(1)})`
        );
        return true;
      }
    }

    return false;
  },

  // Check if movement should trigger a wall transition
  shouldTransitionWall: function (intendedPos, constrainedPos) {
    const wall = this.walls[this.currentWall];

    // Check if any axis was constrained significantly
    for (const axis of wall.movementAxes) {
      if (Math.abs(intendedPos[axis] - constrainedPos[axis]) > 1) {
        return true;
      }
    }

    return false;
  },

  // Determine which wall we should transition to
  getTargetWall: function (position) {
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
  },

  // Draw the wall hologram
  draw: function (p5Instance) {
    if (!this.enabled || !this.currentHologram || !p5Instance) return;

    const p = p5Instance;
    const pos = this.currentHologram.position;
    const size = this.currentHologram.size;
    const wall = this.walls[this.currentWall];

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

    // Draw wireframe for better visibility
    p.noFill();
    p.stroke(
      this.wireframeColor[0],
      this.wireframeColor[1],
      this.wireframeColor[2],
      255
    );
    p.strokeWeight(1);

    // Draw additional wireframe lines
    const hw = size.width / 2;
    const hh = size.height / 2;
    const hd = size.depth / 2;

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

    p.pop();
  },

  // Get current wall hologram state
  getState: function () {
    return {
      enabled: this.enabled,
      currentWall: this.currentWall,
      hologram: this.currentHologram,
      keyboardState: { ...this.keyboardState },
      walls: this.walls,
    };
  },

  // Set hologram position (with wall constraint)
  setPosition: function (x, y, z) {
    if (this.currentHologram) {
      const newPos = { x, y, z };
      this.currentHologram.position = this.constrainToWall(
        newPos,
        this.currentWall
      );
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

  // Clean up resources
  cleanup: function () {
    this.removeKeyboardListeners();
    this.disable();
    console.log("Wall hologram system cleaned up");
  },
};

// Initialize the wall hologram system when the script loads
if (typeof window !== "undefined") {
  window.WallHologramSystem.init();
}
