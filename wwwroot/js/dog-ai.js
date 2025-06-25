// Dog AI Module for random movement in the room
window.DogAI = {
  // Configuration
  enabled: false,
  roomBounds: {
    minX: -150,
    maxX: 150,
    minZ: -150,
    maxZ: 150,
    y: 0, // Height where dog stands
  },

  // Movement parameters
  moveSpeed: 20, // Units per second (increased for more visible movement)
  sittingProbability: 0.2, // Probability of sitting when reaching target
  minSitTime: 3, // Minimum time to sit (seconds)
  maxSitTime: 8, // Maximum time to sit (seconds)
  minWalkTime: 4, // Minimum time to walk (seconds)
  maxWalkTime: 10, // Maximum time to walk (seconds)

  // Internal state
  currentState: "idle", // idle, walking, sitting
  currentTarget: { x: 0, z: 0 },
  sitTimer: 0,
  stateTimer: 0,
  dogPosition: { x: 0, y: 0, z: 0 },

  // Initialize the AI
  init: function (startX, startY, startZ) {
    this.dogPosition.x = startX || 0;
    this.dogPosition.y = startY || 0;
    this.dogPosition.z = startZ || 0;
    this.pickNewTarget();
    this.currentState = "idle";

    console.log("Dog AI initialized at position:", this.dogPosition);
    return this;
  },

  // Start the AI
  start: function () {
    this.enabled = true;
    this.currentState = "walking";
    this.pickNewTarget();
    console.log("Dog AI started");
    return this;
  },

  // Stop the AI
  stop: function () {
    this.enabled = false;
    console.log("Dog AI stopped");
    return this;
  },

  // Toggle the AI on/off
  toggle: function () {
    if (this.enabled) {
      this.stop();
    } else {
      this.start();
    }
    return this.enabled;
  },

  // Pick a new random target position within room bounds
  pickNewTarget: function () {
    this.currentTarget = {
      x:
        Math.random() * (this.roomBounds.maxX - this.roomBounds.minX) +
        this.roomBounds.minX,
      z:
        Math.random() * (this.roomBounds.maxZ - this.roomBounds.minZ) +
        this.roomBounds.minZ,
    };
    console.log("New dog target:", this.currentTarget, "Current position:", this.dogPosition);
    return this.currentTarget;
  },

  // Check if dog has reached current target (with some tolerance)
  hasReachedTarget: function () {
    const dx = this.currentTarget.x - this.dogPosition.x;
    const dz = this.currentTarget.z - this.dogPosition.z;
    const distance = Math.sqrt(dx * dx + dz * dz);
    return distance < 10; // 10 units tolerance
  },

  // Move toward the current target
  moveTowardTarget: function (deltaTime) {
    // Calculate direction vector
    const dx = this.currentTarget.x - this.dogPosition.x;
    const dz = this.currentTarget.z - this.dogPosition.z;

    // Normalize direction
    const distance = Math.sqrt(dx * dx + dz * dz);
    if (distance > 0) {
      const normalizedDx = dx / distance;
      const normalizedDz = dz / distance;

      // Move dog position
      const oldX = this.dogPosition.x;
      const oldZ = this.dogPosition.z;
      
      // Apply movement with speed
      this.dogPosition.x += normalizedDx * this.moveSpeed * deltaTime;
      this.dogPosition.z += normalizedDz * this.moveSpeed * deltaTime;
      
      // Log movement for debugging (only occasionally to avoid console spam)
      if (Math.random() < 0.05) {
        console.log(`Dog moved from (${oldX.toFixed(1)}, ${oldZ.toFixed(1)}) to (${this.dogPosition.x.toFixed(1)}, ${this.dogPosition.z.toFixed(1)})`);
        console.log(`Target: (${this.currentTarget.x.toFixed(1)}, ${this.currentTarget.z.toFixed(1)}), Distance: ${distance.toFixed(1)}`);
      }
    }

    // Return if reached target
    const reached = this.hasReachedTarget();
    if (reached) {
      console.log("Dog reached target!");
    }
    return reached;
  },

  // Update dog AI state machine
  update: function (deltaTime) {
    if (!this.enabled) return this.dogPosition;

    // Update the state timer
    this.stateTimer -= deltaTime;

    // State machine
    switch (this.currentState) {
      case "idle":
        // Idle state is just a transition state
        this.currentState = "walking";
        this.stateTimer =
          Math.random() * (this.maxWalkTime - this.minWalkTime) +
          this.minWalkTime;
        this.pickNewTarget();
        break;

      case "walking":
        // Move toward current target
        const reachedTarget = this.moveTowardTarget(deltaTime);

        // Check if state timer expired or reached target
        if (reachedTarget || this.stateTimer <= 0) {
          // Decide whether to sit or pick a new target
          if (Math.random() < this.sittingProbability) {
            this.currentState = "sitting";
            this.stateTimer =
              Math.random() * (this.maxSitTime - this.minSitTime) +
              this.minSitTime;
            console.log(
              "Dog sitting for",
              this.stateTimer.toFixed(1),
              "seconds"
            );
          } else {
            // Continue walking to a new target
            this.pickNewTarget();
            this.stateTimer =
              Math.random() * (this.maxWalkTime - this.minWalkTime) +
              this.minWalkTime;
          }
        }
        break;

      case "sitting":
        // Just wait until timer expires
        if (this.stateTimer <= 0) {
          this.currentState = "walking";
          this.pickNewTarget();
          this.stateTimer =
            Math.random() * (this.maxWalkTime - this.minWalkTime) +
            this.minWalkTime;
          console.log(
            "Dog walking again for",
            this.stateTimer.toFixed(1),
            "seconds"
          );
        }
        break;
    }

    // Return the current position
    return {
      x: this.dogPosition.x,
      y: this.dogPosition.y,
      z: this.dogPosition.z,
      state: this.currentState,
    };
  },

  // Set room boundaries
  setRoomBounds: function (minX, maxX, minZ, maxZ, y) {
    this.roomBounds = {
      minX: minX || -150,
      maxX: maxX || 150,
      minZ: minZ || -150,
      maxZ: maxZ || 150,
      y: y || 0,
    };
    return this;
  },

  // Get current target
  getCurrentTarget: function () {
    return this.currentTarget;
  },

  // Get current state
  getState: function () {
    return {
      state: this.currentState,
      position: this.dogPosition,
      target: this.currentTarget,
      timeRemaining: this.stateTimer,
    };
  },
};
