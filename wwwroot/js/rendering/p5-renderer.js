// p5.js rendering script for DoggyLife
let roomSize = 400;
let tileSize = 50;
let floorTiles = 8;
let cameraDistance = 325; // Ultra-close camera for maximum room size in viewport
let cameraAngle = Math.PI / 4; // QUARTER_PI (fixed position)
let cameraHeight = -270; // Further adjusted camera height for the very close camera

// Debug mode flag
let debugMode = true; // Set to true for debugging

// Debug camera control variables
let debugCameraDistance = 500;
let debugCameraAngleX = 0; // Vertical rotation
let debugCameraAngleY = 0; // Horizontal rotation
let isDragging = false;
let lastMouseX = 0;
let lastMouseY = 0;

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
let dogPosition = { x: 0, y: 150, z: 0 }; // Position dog so bottom is on floor (floorY - dogSize/2)
let dogScale = 1.0; // Scale of the dog image
let dogSize = 100; // Size of the dog plane
let dogRotationY = Math.PI * 2; // Make dog face the camera

// Room bounds for collision detection
let roomBounds = {
  minX: -200, // Room edge (full room size/2)
  maxX: 200,
  minZ: -200,
  maxZ: 200,
  floorY: 200, // Floor level (roomSize/2)
};

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
          case "d":
          case "D":
            // Toggle debug mode
            debugMode = !debugMode;
            console.log("Debug mode " + (debugMode ? "enabled" : "disabled"));
            break;
        }
      });

      window.addEventListener("keyup", (e) => {
        keys[e.key] = false;
      });

      // Debug mode mouse controls
      if (debugMode) {
        // Mouse press
        p.canvas.addEventListener("mousedown", (e) => {
          isDragging = true;
          lastMouseX = e.clientX;
          lastMouseY = e.clientY;
          e.preventDefault();
        });

        // Mouse release
        window.addEventListener("mouseup", (e) => {
          isDragging = false;
        });

        // Mouse move
        window.addEventListener("mousemove", (e) => {
          if (isDragging) {
            const deltaX = e.clientX - lastMouseX;
            const deltaY = e.clientY - lastMouseY;

            // Update camera angles based on mouse movement
            debugCameraAngleY += deltaX * 0.01; // Horizontal rotation
            debugCameraAngleX += deltaY * 0.01; // Vertical rotation

            // Clamp vertical rotation to prevent flipping
            debugCameraAngleX = Math.max(
              -Math.PI / 2 + 0.1,
              Math.min(Math.PI / 2 - 0.1, debugCameraAngleX)
            );

            lastMouseX = e.clientX;
            lastMouseY = e.clientY;
          }
        });

        // Mouse wheel for zoom
        p.canvas.addEventListener("wheel", (e) => {
          e.preventDefault();
          const zoomFactor = e.deltaY > 0 ? 1.1 : 0.9;
          debugCameraDistance *= zoomFactor;

          // Clamp zoom distance
          debugCameraDistance = Math.max(
            50,
            Math.min(2000, debugCameraDistance)
          );
        });
      }
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
        // Manual controls when AI is disabled - only allow WASD if not in debug mode
        if (!debugMode) {
          // Dog position controls with bounds checking
          let newX = dogPosition.x;
          let newZ = dogPosition.z;
          let newY = dogPosition.y;

          if (keys["w"]) newZ -= 5;
          if (keys["s"]) newZ += 5;
          if (keys["a"]) newX -= 5;
          if (keys["d"]) newX += 5;

          // Check bounds and apply movement (with margin for dog size)
          const dogMargin = dogSize / 2; // Half dog size as margin
          if (
            newX >= roomBounds.minX + dogMargin &&
            newX <= roomBounds.maxX - dogMargin
          ) {
            dogPosition.x = newX;
          }
          if (
            newZ >= roomBounds.minZ + dogMargin &&
            newZ <= roomBounds.maxZ - dogMargin
          ) {
            dogPosition.z = newZ;
          }

          // Dog height controls (for testing/debugging)
          if (keys["r"]) newY -= 5;
          if (keys["f"]) newY += 5;
          dogPosition.y = Math.max(
            roomBounds.floorY - dogSize,
            Math.min(roomBounds.floorY + 50, newY)
          );

          // Dog scale controls
          if (keys["q"]) dogScale -= 0.1;
          if (keys["e"]) dogScale += 0.1;
        }
      }

      // Keep values in reasonable ranges
      dogScale = Math.max(0.5, Math.min(10, dogScale));

      // Update hologram system if available
      if (window.HologramSystem) {
        window.HologramSystem.update(deltaTime);
      }

      // Update wall hologram system if available
      if (window.WallHologramSystem) {
        window.WallHologramSystem.update(deltaTime);
      }

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

      // Draw helpful axis lines for 3D orientation (debug mode only)
      if (debugMode) {
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
      }

      // Draw hologram if enabled
      if (window.HologramSystem) {
        window.HologramSystem.draw(p);
      }

      // Draw wall hologram if enabled
      if (window.WallHologramSystem) {
        window.WallHologramSystem.draw(p);
      }

      // Draw debug info if in debug mode
      if (debugMode) {
        p.push();
        p.fill(255, 255, 0); // Yellow text
        p.textAlign(p.LEFT, p.TOP);
        p.textSize(12);

        // Move to 2D space for UI
        p.camera();
        p.ortho();
        p.translate(-p.width / 2, -p.height / 2);

        let debugText = "DEBUG MODE (Press D to toggle)\n";
        debugText += "Mouse: Click+Drag to rotate, Scroll to zoom\n";
        debugText += `Camera Distance: ${debugCameraDistance.toFixed(1)}\n`;
        debugText += `Camera Angles: X=${debugCameraAngleX.toFixed(
          2
        )}, Y=${debugCameraAngleY.toFixed(2)}\n`;
        if (window.HologramSystem && window.HologramSystem.enabled) {
          const state = window.HologramSystem.getState();
          if (state.hologram) {
            debugText += `Floor Hologram: (${state.hologram.position.x.toFixed(
              1
            )}, ${state.hologram.position.y.toFixed(
              1
            )}, ${state.hologram.position.z.toFixed(1)})\n`;
          }
        }
        if (window.WallHologramSystem && window.WallHologramSystem.enabled) {
          const state = window.WallHologramSystem.getState();
          if (state.hologram) {
            debugText += `Wall Hologram [${
              state.currentWall
            }]: (${state.hologram.position.x.toFixed(
              1
            )}, ${state.hologram.position.y.toFixed(
              1
            )}, ${state.hologram.position.z.toFixed(1)})\n`;
          }
        }

        p.text(debugText, 10, 10);
        p.pop();
      }
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
      // Update perspective projection
      updatePerspective();

      if (debugMode) {
        // Debug camera with free movement
        const x =
          debugCameraDistance *
          Math.cos(debugCameraAngleX) *
          Math.cos(debugCameraAngleY);
        const y = debugCameraDistance * Math.sin(debugCameraAngleX);
        const z =
          debugCameraDistance *
          Math.cos(debugCameraAngleX) *
          Math.sin(debugCameraAngleY);

        // Use debug camera looking at the center (0,0,0)
        p.camera(x, y, z, 0, 0, 0, 0, 1, 0);
      } else {
        // Original fixed camera
        let x = cameraDistance * Math.cos(cameraAngle);
        let z = cameraDistance * Math.sin(cameraAngle);
        p.camera(x, cameraHeight, z, 0, 0, 0, 0, 1, 0);
      }
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

// Hologram control functions for C# integration
window.enableHologramMode = function (
  x = 0,
  y = 0,
  z = 0,
  width = 50,
  height = 50,
  depth = 50,
  mode = "floor"
) {
  // Disable both systems first
  if (window.HologramSystem) {
    window.HologramSystem.disable();
  }
  if (window.WallHologramSystem) {
    window.WallHologramSystem.disable();
  }

  if (mode === "wall") {
    if (window.WallHologramSystem) {
      const position = { x: x, y: y, z: z };
      const size = { width: width, height: height, depth: depth };
      window.WallHologramSystem.enable(position, size, "back");
      console.log("Wall hologram mode enabled via C# interop");
      return true;
    }
  } else {
    if (window.HologramSystem) {
      const position = { x: x, y: y, z: z };
      const size = { width: width, height: height, depth: depth };
      window.HologramSystem.enable(position, size);
      console.log("Floor hologram mode enabled via C# interop");
      return true;
    }
  }
  return false;
};

window.disableHologramMode = function () {
  let success = false;
  if (window.HologramSystem) {
    window.HologramSystem.disable();
    success = true;
  }
  if (window.WallHologramSystem) {
    window.WallHologramSystem.disable();
    success = true;
  }
  if (success) {
    console.log("Hologram mode disabled via C# interop");
  }
  return success;
};

window.toggleHologramMode = function (
  x = 0,
  y = 0,
  z = 0,
  width = 50,
  height = 50,
  depth = 50,
  mode = "floor"
) {
  // Check if any hologram is currently enabled
  const floorEnabled = window.HologramSystem && window.HologramSystem.enabled;
  const wallEnabled =
    window.WallHologramSystem && window.WallHologramSystem.enabled;

  if (floorEnabled || wallEnabled) {
    // Disable all holograms
    window.disableHologramMode();
    return false;
  } else {
    // Enable the requested hologram mode
    return window.enableHologramMode(x, y, z, width, height, depth, mode);
  }
};

window.setHologramPosition = function (x, y, z) {
  let success = false;
  if (window.HologramSystem && window.HologramSystem.enabled) {
    window.HologramSystem.setPosition(x, y, z);
    success = true;
  }
  if (window.WallHologramSystem && window.WallHologramSystem.enabled) {
    window.WallHologramSystem.setPosition(x, y, z);
    success = true;
  }
  return success;
};

window.setHologramSize = function (width, height, depth) {
  let success = false;
  if (window.HologramSystem && window.HologramSystem.enabled) {
    window.HologramSystem.setSize(width, height, depth);
    success = true;
  }
  if (window.WallHologramSystem && window.WallHologramSystem.enabled) {
    window.WallHologramSystem.setSize(width, height, depth);
    success = true;
  }
  return success;
};

window.getHologramState = function () {
  if (window.WallHologramSystem && window.WallHologramSystem.enabled) {
    return {
      type: "wall",
      ...window.WallHologramSystem.getState(),
    };
  }
  if (window.HologramSystem && window.HologramSystem.enabled) {
    return {
      type: "floor",
      ...window.HologramSystem.getState(),
    };
  }
  return null;
};

// Debug mode control functions
window.setDebugMode = function (enabled) {
  debugMode = enabled;
  console.log("Debug mode " + (debugMode ? "enabled" : "disabled"));
  return debugMode;
};

window.toggleDebugMode = function () {
  debugMode = !debugMode;
  console.log("Debug mode " + (debugMode ? "enabled" : "disabled"));
  return debugMode;
};

window.getDebugMode = function () {
  return debugMode;
};
