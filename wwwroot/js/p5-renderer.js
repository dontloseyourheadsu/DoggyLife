// p5.js rendering script for DoggyLife
let roomSize = 400;
let tileSize = 50;
let floorTiles = 8;
let cameraDistance = 800;
let cameraAngle = Math.PI / 4; // QUARTER_PI (fixed position as in your example)
let cameraHeight = -550;

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
let dogRotationY = Math.PI * 2.2; // Make dog face the camera

// Camera variables
let cameraAutoRotate = false; // Camera doesn't rotate
let cameraTilt = 0; // No tilt, looking at center (0,0,0) as in your example

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

    p.setup = function () {
      p.createCanvas(width, height, p.WEBGL);
      p.angleMode(p.RADIANS);

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
          // Create a fallback image if animation fails to load
          dogImage = p.createGraphics(100, 100);
          dogImage.background(255, 150, 150);
          dogImage.fill(100, 100, 255);
          dogImage.textSize(20);
          dogImage.textAlign(p.CENTER, p.CENTER);
          dogImage.text("DOG", 50, 50);
        }
      }

      // Set up keyboard event listeners
      window.addEventListener("keydown", (e) => {
        keys[e.key] = true;

        // One-time key actions
        switch (e.key) {
          case "t":
            // Toggle camera rotation
            cameraAutoRotate = !cameraAutoRotate;
            break;
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

      // Process continuous key controls
      // Camera controls
      if (keys["ArrowLeft"]) cameraAngle += 0.03;
      if (keys["ArrowRight"]) cameraAngle -= 0.03;
      if (keys["ArrowUp"]) cameraTilt -= 0.01;
      if (keys["ArrowDown"]) cameraTilt += 0.01;

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

      // Keep values in reasonable ranges
      cameraTilt = Math.max(-1, Math.min(0, cameraTilt));
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
      // Calculate camera position (fixed position as in your example)
      let x = cameraDistance * Math.cos(cameraAngle);
      let z = cameraDistance * Math.sin(cameraAngle);

      // Use a fixed camera looking at the center (0,0,0)
      p.camera(x, cameraHeight, z, 0, 0, 0, 0, 1, 0);

      // Draw camera position indicator
      p.push();
      p.noLights(); // Disable lighting for UI elements
      p.fill(255);
      p.textSize(16);
      p.textAlign(p.LEFT, p.TOP);
      p.text(
        `Camera: ${Math.round(x)}, ${Math.round(cameraHeight)}, ${Math.round(
          z
        )}`,
        10,
        10
      );
      p.text(
        `Dog position: (${Math.round(dogPosition.x)}, ${Math.round(
          dogPosition.y
        )}, ${Math.round(dogPosition.z)})`,
        10,
        30
      );
      p.pop();
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

// Camera control functions
window.toggleCameraRotation = function () {
  cameraAutoRotate = !cameraAutoRotate;
  return cameraAutoRotate;
};

window.setCameraPosition = function (distance, height, angle) {
  cameraDistance = distance;
  cameraHeight = height;
  cameraAngle = angle;
  return true;
};

window.setCameraTilt = function (tilt) {
  cameraTilt = tilt;
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
