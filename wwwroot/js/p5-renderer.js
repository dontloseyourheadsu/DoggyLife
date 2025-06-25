// p5.js rendering script for DoggyLife
let roomSize = 400;
let tileSize = 50;
let floorTiles = 8;
let cameraDistance = 325; // Ultra-close camera for maximum room size in viewport
let cameraAngle = Math.PI / 4; // QUARTER_PI (fixed position)
let cameraHeight = -270; // Further adjusted camera height for the very close camera

// Image for dog sprite
let dogImage = null;

// Room settings that will be populated from C#
let roomSettings = {
  floorLightColor: [220, 220, 220],
  floorDarkColor: [180, 180, 180],
  wallLightColor: [200, 150, 150],
  wallDarkColor: [160, 120, 120],
};

// Dog variables
let dogSpritesheetLoaded = false;
let dogPosition = { x: 100, y: 100, z: 100 }; // Initial position matching your example
let dogScale = 1.0; // Scale of the dog image
let dogSize = 100; // Size of the dog plane
let dogRotationY = Math.PI * 2; // Make dog face the camera

let p5Instance = null;

// Initialize p5 sketch in instance mode
window.createP5RoomRenderer = function (containerId, width, height) {
  // Remove any existing sketch
  if (p5Instance) {
    p5Instance.remove();
  }

  // Create new sketch
  p5Instance = new p5(function (p) {
    // Keyboard state tracking
    let keys = {};
    // Store the last update time for frame-independent animation
    let lastUpdateTime = 0;
    // Dog object reference
    let dog = null;

    // Centralized function to update perspective projection
    function updatePerspective() {
      const fov = p.TWO_PI / 3.8; // Extra wide FOV (approximately 95 degrees) for extreme close-up camera
      const aspect = p.width / p.height;
      const near = 0.1;
      const far = 5000;
      p.perspective(fov, aspect, near, far);
    }

    p.setup = function () {
      p.createCanvas(width, height, p.WEBGL);
      p.angleMode(p.RADIANS);

      // Set initial perspective
      updatePerspective();

      // Load dog animation system
      if (!window.P5DogAnimation) {
        const script = document.createElement("script");
        script.src = "js/p5-dog-animation.js";
        script.onload = function () {
          initializeDog();
        };
        document.head.appendChild(script);
      } else {
        initializeDog();
      }

      // Load dog AI system if not already loaded
      if (!window.DogAI) {
        const aiScript = document.createElement("script");
        aiScript.src = "js/dog-ai.js";
        aiScript.onload = function () {
          console.log("Dog AI module loaded");
          // Initialize AI with starting position
          window.DogAI.init(dogPosition.x, dogPosition.y, dogPosition.z);
        };
        document.head.appendChild(aiScript);
      } else {
        // Initialize AI with starting position if script already loaded
        window.DogAI.init(dogPosition.x, dogPosition.y, dogPosition.z);
      }

      async function initializeDog() {
        // Get the dog sprite path
        const dogImagePath = window.dogSprites
          ? window.dogSprites.getCurrentDogSprite()
          : "images/dogs/dog1.png";

        // Create the dog animation instance at the initial position
        try {
          dog = await window.P5DogAnimation.loadDogSpriteSheet(
            p,
            "main",
            dogImagePath
          );

          // Position the dog at the initial position
          dog.x = dogPosition.x;
          dog.y = dogPosition.y;
          dog.z = dogPosition.z;
          dog.scale = dogScale;

          console.log("Dog animation initialized with sprite:", dogImagePath);
          dogSpritesheetLoaded = true;
        } catch (err) {
          console.error("Error initializing dog animation:", err);
        }
      }

      // Set up keyboard event listeners
      window.addEventListener("keydown", (e) => {
        keys[e.key] = true;

        // One-time key actions
        switch (e.key) {
          case "1":
            // Move dog to position 1 (front)
            dogPosition = { x: 0, y: 0, z: 150 };
            break;
          case "2":
            // Move dog to position 2 (back)
            dogPosition = { x: 0, y: 0, z: -150 };
            break;
          case "3":
            // Move dog to position 3 (left)
            dogPosition = { x: -150, y: 0, z: 0 };
            break;
          case "4":
            // Move dog to position 4 (right)
            dogPosition = { x: 150, y: 0, z: 0 };
            break;
          case "5":
            // Move dog to center
            dogPosition = { x: 0, y: 0, z: 0 };
            break;
          case "t":
          case "T":
            // Toggle dog AI
            if (window.DogAI) {
              const enabled = window.DogAI.toggle();
              console.log("Dog AI " + (enabled ? "enabled" : "disabled"));
            }
            break;
          case "n":
            // Switch to next dog type
            if (window.dogSprites) {
              const newDogPath = window.dogSprites.nextDogType();

              if (window.P5DogAnimation && dog) {
                // Use our animation system if available
                window.P5DogAnimation.loadDogSpriteSheet(p, "main", newDogPath)
                  .then(() => {
                    console.log("Switched to new dog sprite:", newDogPath);
                  })
                  .catch((err) => {
                    console.error("Error loading new dog sprite:", err);
                  });
              } else {
                // Fallback to simple image
                p.loadImage(
                  newDogPath,
                  (img) => {
                    console.log("Switched to new dog image:", newDogPath);
                    dogImage = img;
                  },
                  (err) => {
                    console.error("Error loading new dog image:", err);
                  }
                );
              }
            }
            break;
        }
      });

      window.addEventListener("keyup", (e) => {
        keys[e.key] = false;
      });
    };

    p.draw = function () {
      p.background(50);

      // Calculate delta time for animation
      const now = p.millis() / 1000; // convert to seconds
      const deltaTime = now - lastUpdateTime;
      lastUpdateTime = now;

      // Store previous position for animation state calculation
      const prevDogPosition = { ...dogPosition };

      // Process dog AI if enabled
      if (window.DogAI && window.DogAI.enabled) {
        // Update dog AI and get new position
        const aiUpdate = window.DogAI.update(deltaTime);

        // Store previous position to detect movement direction
        const prevX = dogPosition.x;
        const prevZ = dogPosition.z;

        // Update dog position
        dogPosition.x = aiUpdate.x;
        dogPosition.y = aiUpdate.y;
        dogPosition.z = aiUpdate.z;

        // Detect movement direction
        const moveDx = dogPosition.x - prevX;
        const moveDz = dogPosition.z - prevZ;
        const isMoving = Math.abs(moveDx) > 0.1 || Math.abs(moveDz) > 0.1;

        // Set dog animation based on AI state and movement
        if (dog && window.P5DogAnimation) {
          if (aiUpdate.state === "sitting") {
            // Detect facing direction to choose correct sitting animation
            const dx = Math.cos(cameraAngle);
            const dz = Math.sin(cameraAngle);
            const angle = Math.atan2(dz, dx);

            // Choose sitting animation based on angle
            if (angle > -Math.PI / 4 && angle < Math.PI / 4) {
              dog.setState(
                window.P5DogAnimation.DogAnimationState.RightSitting
              );
            } else if (angle >= Math.PI / 4 && angle < (3 * Math.PI) / 4) {
              dog.setState(
                window.P5DogAnimation.DogAnimationState.FrontSitting
              );
            } else if (
              (angle >= (3 * Math.PI) / 4 && angle <= Math.PI) ||
              (angle >= -Math.PI && angle < (-3 * Math.PI) / 4)
            ) {
              dog.setState(window.P5DogAnimation.DogAnimationState.LeftSitting);
            } else {
              dog.setState(
                window.P5DogAnimation.DogAnimationState.FrontSitting
              );
            }
          } else if (isMoving) {
            // For walking state, calculate direction of movement
            const moveAngle = Math.atan2(moveDz, moveDx);

            // Determine walking animation based on movement direction
            const normalizedAngle = (moveAngle + 2 * Math.PI) % (2 * Math.PI);

            if (
              normalizedAngle >= (7 * Math.PI) / 4 ||
              normalizedAngle < Math.PI / 4
            ) {
              dog.setState(
                window.P5DogAnimation.DogAnimationState.RightWalking
              );
            } else if (
              normalizedAngle >= Math.PI / 4 &&
              normalizedAngle < (3 * Math.PI) / 4
            ) {
              dog.setState(window.P5DogAnimation.DogAnimationState.BackWalking);
            } else if (
              normalizedAngle >= (3 * Math.PI) / 4 &&
              normalizedAngle < (5 * Math.PI) / 4
            ) {
              dog.setState(window.P5DogAnimation.DogAnimationState.LeftWalking);
            } else {
              dog.setState(
                window.P5DogAnimation.DogAnimationState.FrontWalking
              );
            }
          }
        }
      } else {
        // Manual controls when AI is disabled
        // Dog position controls
        if (keys["w"]) dogPosition.z -= 5;
        if (keys["s"]) dogPosition.z += 5;
        if (keys["a"]) dogPosition.x -= 5;
        if (keys["d"]) dogPosition.x += 5;

        // Dog height and scale controls
        if (keys["r"]) dogPosition.y -= 5;
        if (keys["f"]) dogPosition.y += 5;
        if (keys["q"]) dogScale -= 0.1;
        if (keys["e"]) dogScale += 0.1;
      }

      // Keep values in reasonable ranges
      dogScale = Math.max(0.5, Math.min(10, dogScale));

      p.ambientLight(60);
      p.directionalLight(255, 255, 255, -1, 0.5, -1);

      p.updateCamera();
      p.drawRoom();

      // Draw the animated dog using our animation system
      if (dog && window.P5DogAnimation) {
        // Update dog position
        dog.move(dogPosition.x, dogPosition.y, dogPosition.z, deltaTime);
        dog.scale = dogScale;

        // Make sure the dog faces the camera
        p.push();
        // Make dog face the camera based on camera position
        let dx = Math.cos(cameraAngle);
        let dz = Math.sin(cameraAngle);
        let angle = Math.atan2(dz, dx);
        p.translate(dogPosition.x, dogPosition.y, dogPosition.z);
        p.rotateY(angle + dogRotationY);

        // Get current frame as texture and draw it
        const tex = dog.getFrameAsTexture();
        if (tex) {
          p.texture(tex);
          p.noStroke();
          p.plane(dog.spriteWidth * dogScale, dog.spriteHeight * dogScale);
          tex.remove(); // Clean up the texture
        }
        p.pop();
      }
      // Fallback to simple dog image if animation system isn't ready
      else if (dogImage) {
        p.push();
        p.translate(dogPosition.x, dogPosition.y, dogPosition.z);

        // Make it face the camera based on the fixed camera angle
        let dx = Math.cos(cameraAngle);
        let dz = Math.sin(cameraAngle);
        let angle = Math.atan2(dz, dx);
        p.rotateY(angle + dogRotationY);

        // Draw the dog image as a textured plane
        p.texture(dogImage);
        p.noStroke();
        let dogWidth = dogSize * dogScale;
        let dogHeight = dogSize * dogScale * (dogImage.height / dogImage.width);
        p.plane(dogWidth, dogHeight);
        p.pop();
      }

      // Draw helpful axis lines for 3D orientation
      p.push();
      p.strokeWeight(3);
      // X axis - red
      p.stroke(255, 0, 0);
      p.line(-100, 0, 0, 100, 0, 0);
      // Y axis - green
      p.stroke(0, 255, 0);
      p.line(0, -100, 0, 0, 100, 0);
      // Z axis - blue
      p.stroke(0, 0, 255);
      p.line(0, 0, -100, 0, 0, 100);
      p.pop();
    };

    p.drawRoom = function () {
      p.drawFloor();
      p.drawWalls();
    };

    p.drawFloor = function () {
      p.push();
      p.translate(0, roomSize / 2, 0); // Move floor down slightly

      for (let x = 0; x < floorTiles; x++) {
        for (let z = 0; z < floorTiles; z++) {
          p.push();

          let posX = (x - floorTiles / 2 + 0.5) * tileSize;
          let posZ = (z - floorTiles / 2 + 0.5) * tileSize;
          p.translate(posX, 0.5, posZ); // Add slight Y offset to avoid Z-fighting

          if ((x + z) % 2 === 0) {
            p.fill(
              roomSettings.floorLightColor[0],
              roomSettings.floorLightColor[1],
              roomSettings.floorLightColor[2]
            );
          } else {
            p.fill(
              roomSettings.floorDarkColor[0],
              roomSettings.floorDarkColor[1],
              roomSettings.floorDarkColor[2]
            );
          }

          p.noStroke();
          p.rotateX(p.HALF_PI); // Rotate to lie flat
          p.plane(tileSize, tileSize);

          p.pop();
        }
      }

      p.pop();
    };

    p.drawWalls = function () {
      p.drawBackWall();
      p.drawLeftWall();
      // Right wall intentionally removed
    };

    p.drawBackWall = function () {
      p.push();
      p.translate(0, 0, -roomSize / 2);
      p.rotateY(0); // Face forward

      let stripeWidth = 40;
      let numStripes = Math.ceil(roomSize / stripeWidth);

      for (let i = 0; i < numStripes; i++) {
        p.push();

        let x = (i - numStripes / 2 + 0.5) * stripeWidth;
        p.translate(x, 0, 0.5); // Slight offset to avoid overlap

        if (i % 2 === 0) {
          p.fill(
            roomSettings.wallLightColor[0],
            roomSettings.wallLightColor[1],
            roomSettings.wallLightColor[2]
          );
        } else {
          p.fill(
            roomSettings.wallDarkColor[0],
            roomSettings.wallDarkColor[1],
            roomSettings.wallDarkColor[2]
          );
        }

        p.noStroke();
        p.rotateY(p.PI); // Ensure correct orientation
        p.plane(stripeWidth, roomSize);

        p.pop();
      }

      p.pop();
    };

    p.drawLeftWall = function () {
      p.push();
      p.translate(-roomSize / 2, 0, 0);
      p.rotateY(p.HALF_PI); // Face inward like back wall

      let stripeWidth = 40;
      let numStripes = Math.ceil(roomSize / stripeWidth);

      for (let i = 0; i < numStripes; i++) {
        p.push();

        let x = (i - numStripes / 2 + 0.5) * stripeWidth;
        p.translate(x, 0, 0.5); // Slight forward offset

        if (i % 2 === 0) {
          p.fill(
            roomSettings.wallLightColor[0],
            roomSettings.wallLightColor[1],
            roomSettings.wallLightColor[2]
          );
        } else {
          p.fill(
            roomSettings.wallDarkColor[0],
            roomSettings.wallDarkColor[1],
            roomSettings.wallDarkColor[2]
          );
        }

        p.noStroke();
        p.plane(stripeWidth, roomSize);

        p.pop();
      }

      p.pop();
    };

    p.updateCamera = function () {
      // Calculate camera position (fixed position)
      let x = cameraDistance * Math.cos(cameraAngle);
      let z = cameraDistance * Math.sin(cameraAngle);

      // Update perspective projection
      updatePerspective();

      // Use a fixed camera looking at the center (0,0,0)
      p.camera(x, cameraHeight, z, 0, 0, 0, 0, 1, 0);

      // Draw camera position indicator
      p.push();
      p.noLights(); // Disable lighting for UI elements
      p.fill(255);
      p.pop();
    };

    // Add window resize handler to maintain correct perspective
    p.windowResized = function () {
      // Check if we should resize to full window (can be controlled by a flag)
      // This can be activated by a parameter or setting in the future
      if (window.useFullWindowMode) {
        p.resizeCanvas(p.windowWidth, p.windowHeight);
      }

      // Update perspective with new dimensions
      updatePerspective();

      // No need to call redraw() as we're using continuous draw mode
    };
  }, containerId);

  return p5Instance;
};

// Function to update room colors from C#
window.updateRoomColors = function (
  floorLightColor,
  floorDarkColor,
  wallLightColor,
  wallDarkColor
) {
  roomSettings.floorLightColor = convertColor(floorLightColor);
  roomSettings.floorDarkColor = convertColor(floorDarkColor);
  roomSettings.wallLightColor = convertColor(wallLightColor);
  roomSettings.wallDarkColor = convertColor(wallDarkColor);
};

// Helper function to convert C# color values to arrays [r,g,b]
function convertColor(colorString) {
  // Color string expected in format 'R,G,B'
  const parts = colorString.split(",");
  return [
    parseInt(parts[0], 10),
    parseInt(parts[1], 10),
    parseInt(parts[2], 10),
  ];
}

// Handle window resize for responsive canvas
window.resizeP5Canvas = function (width, height) {
  if (p5Instance) {
    p5Instance.resizeCanvas(width, height);

    // Update perspective when canvas is resized
    if (p5Instance._renderer) {
      // Call perspective through p5Instance, accessing private function
      const p = p5Instance;
      const fov = p.TWO_PI / 3.8; // Extra wide FOV (approximately 95 degrees)
      const aspect = width / height;
      const near = 0.1;
      const far = 5000;
      p.perspective(fov, aspect, near, far);
    }
  }
};

// Dog control functions
window.setDogState = function (stateId) {
  // Update dog state using the dog animation system
  if (window.P5DogAnimation) {
    return window.P5DogAnimation.updateDogState("main", stateId);
  }
  return false;
};

window.moveDog = function (x, y, z) {
  // Update dog position and animation state based on movement
  dogPosition.x = x || 0;
  dogPosition.y = y || 0;
  if (z !== undefined) dogPosition.z = z;

  // If using the dog animation system, update the dog directly
  if (window.P5DogAnimation) {
    window.P5DogAnimation.updateDogState("main", null, x, y, z);
  }
  return true;
};

window.setCameraPosition = function (distance, height, angle) {
  cameraDistance = distance;
  cameraHeight = height;
  cameraAngle = angle;
  return true;
};

window.setCameraTilt = function (tilt) {
  // Function kept for compatibility but does nothing
  return true;
};

// Function to change the dog image from C#
window.setDogImage = function (imageUrl) {
  // Use the dog animation system if available
  if (window.P5DogAnimation) {
    window.P5DogAnimation.loadDogSpriteSheet(p5Instance, "main", imageUrl)
      .then(() => {
        console.log("New dog sprite sheet loaded successfully:", imageUrl);
      })
      .catch((err) => {
        console.error("Error loading new dog sprite sheet:", err);
      });
    return true;
  }
  // Fallback to simple image if animation system isn't available
  else if (p5Instance) {
    p5Instance.loadImage(
      imageUrl,
      (img) => {
        console.log("New dog image loaded successfully");
        dogImage = img;
      },
      (err) => {
        console.error("Error loading new dog image:", err);
      }
    );
    return true;
  }
  return false;
};

// Dog AI control functions for C# integration
window.enableDogAI = function () {
  if (window.DogAI) {
    window.DogAI.start();
    return true;
  }
  return false;
};

window.disableDogAI = function () {
  if (window.DogAI) {
    window.DogAI.stop();
    return true;
  }
  return false;
};

window.toggleDogAI = function () {
  if (window.DogAI) {
    return window.DogAI.toggle();
  }
  return false;
};

window.configureDogAI = function (config) {
  if (!window.DogAI) return false;

  if (config.roomBounds) {
    window.DogAI.setRoomBounds(
      config.roomBounds.minX,
      config.roomBounds.maxX,
      config.roomBounds.minZ,
      config.roomBounds.maxZ,
      config.roomBounds.y
    );
  }

  if (config.moveSpeed !== undefined) window.DogAI.moveSpeed = config.moveSpeed;
  if (config.sittingProbability !== undefined)
    window.DogAI.sittingProbability = config.sittingProbability;
  if (config.minSitTime !== undefined)
    window.DogAI.minSitTime = config.minSitTime;
  if (config.maxSitTime !== undefined)
    window.DogAI.maxSitTime = config.maxSitTime;
  if (config.minWalkTime !== undefined)
    window.DogAI.minWalkTime = config.minWalkTime;
  if (config.maxWalkTime !== undefined)
    window.DogAI.maxWalkTime = config.maxWalkTime;

  return true;
};

window.getDogAIState = function () {
  if (window.DogAI) {
    return window.DogAI.getState();
  }
  return null;
};

// Function to toggle full-window mode
window.toggleFullWindowMode = function (enabled) {
  window.useFullWindowMode = enabled;

  // If enabling full window mode, resize canvas immediately
  if (enabled && p5Instance) {
    p5Instance.resizeCanvas(p5Instance.windowWidth, p5Instance.windowHeight); // Update perspective
    if (p5Instance._renderer) {
      const p = p5Instance;
      const fov = p.TWO_PI / 3.8; // Extra wide FOV (approximately 95 degrees)
      const aspect = p.width / p.height;
      const near = 0.1;
      const far = 5000;
      p.perspective(fov, aspect, near, far);
    }
  }

  return true;
};

// Function to switch between perspective and orthographic projections
window.setCameraProjection = function (useOrthographic) {
  if (!p5Instance) return false;

  if (useOrthographic) {
    // Set orthographic projection with reasonable parameters
    const scale = 1.2;
    const width = p5Instance.width * scale;
    const height = p5Instance.height * scale;
    p5Instance.ortho(-width / 2, width / 2, -height / 2, height / 2, 0.1, 5000);
  } else {
    // Revert to perspective projection
    const p = p5Instance;
    const fov = p.TWO_PI / 3.8; // Extra wide FOV (approximately 95 degrees)
    const aspect = p.width / p.height;
    const near = 0.1;
    const far = 5000;
    p.perspective(fov, aspect, near, far);
  }

  return true;
};
