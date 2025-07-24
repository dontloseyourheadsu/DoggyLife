import { Dog } from "../entities/room/dog.js";
import { DogAI } from "../systems/ai/room/dog-ai.js";
import { DebugKeyListener } from "../systems/input/room/debug-listener.js";
import { KeyListener } from "../systems/input/room/key-listener.js";
import { RoomRenderer } from "../systems/drawing/room/room-renderer.js";
import { FloorHologramSystem } from "../entities/room/floor-hologram.js";
import { WallHologramSystem } from "../entities/room/wall-hologram.js";

export function createRoomCanvas(
  canvasWidth,
  canvasHeight,
  canvasContainerId,
  roomData
) {
  const sketch = (p5Instance) => {
    // Camera settings
    let cameraDistance = 325;
    let cameraAngle = Math.PI / 4;
    let cameraHeight = -270;

    // Room renderer instance
    let roomRenderer = new RoomRenderer(p5Instance, roomData, 400);

    // Dog rendering data
    let dog = new Dog();
    let dogAI = new DogAI(dog, true, roomRenderer.roomBounds);

    // Physics data
    let lastUpdateTime = 0;

    // Debug mode settings
    let debugKeyListener = new DebugKeyListener(false);

    // Hologram systems
    let floorHologramSystem = new FloorHologramSystem();
    let wallHologramSystem = new WallHologramSystem();

    // Initialize room bounds for floor hologram system
    floorHologramSystem.roomBounds = roomRenderer.roomBounds;

    // Key listener
    let keyListener = new KeyListener();

    p5Instance.setup = () => {
      // Start the p5.js canvas with the specified dimensions and container
      p5Instance
        .createCanvas(canvasWidth, canvasHeight, p5Instance.WEBGL)
        .parent(canvasContainerId);
      p5Instance.angleMode(p5Instance.RADIANS);

      // Initial perspective
      updatePerspective();

      // Creates a dog instance
      dog.initialize(p5Instance);

      keyListener.listenKeysDown(p5Instance, dogAI);
      keyListener.listenKeysUp(p5Instance);

      // Initialize debug key listener
      if (debugKeyListener.active) {
        debugKeyListener.listenMouseDown(p5Instance);
        debugKeyListener.listenMouseUp(p5Instance);
        debugKeyListener.listenMouseMove(p5Instance);
        debugKeyListener.listenWheel(p5Instance);
      }
    };

    p5Instance.draw = () => {
      p5Instance.background(50);

      // Calculate delta time for animation
      const timeNowInSeconds = p5Instance.millis() / 1000;
      const deltaTime = timeNowInSeconds - lastUpdateTime;
      lastUpdateTime = timeNowInSeconds;

      // Update dog AI or keep position if AI is disabled
      let dogUpdatedPosition =
        dogAI && dogAI.enabled ? dogAI.update(deltaTime) : dog.position;

      // Update hologram systems
      floorHologramSystem.update(deltaTime);
      wallHologramSystem.update(deltaTime);

      p5Instance.ambientLight(60);
      p5Instance.directionalLight(255, 255, 255, -1, 0.5, -1);
      updateCamera();
      roomRenderer.draw();

      // Render hologram systems
      floorHologramSystem.draw(p5Instance);
      wallHologramSystem.draw(p5Instance);

      // Update dog position
      dog.move(dogUpdatedPosition, deltaTime);
      dog.render(p5Instance, cameraAngle);
    };

    function updateCamera() {
      // Update perspective projection
      updatePerspective();

      if (debugKeyListener.active) {
        // Debug camera with free movement
        const x =
          debugKeyListener.debugCameraDistance *
          Math.cos(debugKeyListener.debugCameraAngleX) *
          Math.cos(debugKeyListener.debugCameraAngleY);
        const y =
          debugKeyListener.debugCameraDistance *
          Math.sin(debugKeyListener.debugCameraAngleX);
        const z =
          debugKeyListener.debugCameraDistance *
          Math.cos(debugKeyListener.debugCameraAngleX) *
          Math.sin(debugKeyListener.debugCameraAngleY);

        // Use debug camera looking at the center (0,0,0)
        p5Instance.camera(x, y, z, 0, 0, 0, 0, 1, 0);
      } else {
        // Original fixed camera
        let x = cameraDistance * Math.cos(cameraAngle);
        let z = cameraDistance * Math.sin(cameraAngle);
        p5Instance.camera(x, cameraHeight, z, 0, 0, 0, 0, 1, 0);
      }
    }

    /**
     * Updates the perspective of the canvas based on the current dimensions.
     */
    function updatePerspective() {
      const fov = p5Instance.TWO_PI / 3.8;
      const aspect = p5Instance.width / p5Instance.height;
      const near = 0.1;
      const far = 5000;
      p5Instance.perspective(fov, aspect, near, far);
    }

    // Expose hologram systems for external access
    p5Instance.getFloorHologramSystem = () => floorHologramSystem;
    p5Instance.getWallHologramSystem = () => wallHologramSystem;

    // Helper functions for hologram control
    p5Instance.toggleFloorHologram = (position, size) => {
      return floorHologramSystem.toggle(position, size);
    };

    p5Instance.toggleWallHologram = (position, size, wall) => {
      return wallHologramSystem.toggle(position, size, wall);
    };

    p5Instance.enableFloorHologram = (position, size) => {
      return floorHologramSystem.enable(position, size);
    };

    p5Instance.enableWallHologram = (position, size, wall) => {
      return wallHologramSystem.enable(position, size, wall);
    };

    p5Instance.disableAllHolograms = () => {
      floorHologramSystem.disable();
      wallHologramSystem.disable();
    };

    // Selected hologram item functionality
    let selectedHologramItem = null;

    p5Instance.setSelectedHologramItem = (
      itemId,
      itemName,
      itemType,
      sizeX,
      sizeY,
      sizeZ
    ) => {
      selectedHologramItem = {
        id: itemId,
        name: itemName,
        type: itemType,
        sizeX: sizeX,
        sizeY: sizeY,
        sizeZ: sizeZ,
      };
      console.log(`Selected hologram item set:`, selectedHologramItem);

      // Update hologram systems with the new item size
      // TODO: Implement height/depth calculation based on item type
      // For floor items: use sizeX (width), sizeY (depth), calculate height
      // For wall items: use sizeX (width), sizeY (height), calculate depth
      const hologramSize = calculateHologramSize(itemType, sizeX, sizeY, sizeZ);

      // Update active hologram system with new size
      if (floorHologramSystem.enabled) {
        floorHologramSystem.setSize(
          hologramSize.width,
          hologramSize.height,
          hologramSize.depth
        );
      }
      if (wallHologramSystem.enabled) {
        wallHologramSystem.setSize(
          hologramSize.width,
          hologramSize.height,
          hologramSize.depth
        );
      }
    };

    // Helper function to calculate hologram dimensions based on item type
    function calculateHologramSize(itemType, sizeX, sizeY, sizeZ) {
      // Floor items: sizeX = width, sizeY = height, sizeZ = depth
      if (itemType === "bed" || itemType === "shelf" || itemType === "couch") {
        return {
          width: sizeX,
          height: sizeY, // Use the actual sizeY parameter
          depth: sizeZ,
        };
      }
      // Wall items: sizeX = width, sizeY = height, sizeZ = depth
      else if (itemType === "window" || itemType === "painting") {
        return {
          width: sizeX,
          height: sizeY,
          depth: sizeZ, // Use the actual sizeZ parameter
        };
      }

      // Default fallback
      return {
        width: sizeX,
        height: sizeY,
        depth: sizeZ,
      };
    }

    p5Instance.clearSelectedHologramItem = () => {
      selectedHologramItem = null;
      console.log("Selected hologram item cleared");
    };

    p5Instance.getSelectedHologramItem = () => {
      return selectedHologramItem;
    };

    // Cleanup function
    p5Instance.cleanup = () => {
      floorHologramSystem.cleanup();
      wallHologramSystem.cleanup();
      keyListener.cleanup?.();
      debugKeyListener.cleanup?.();
    };
  };

  // Create the p5 instance with the sketch and container ID
  const p5Instance = new p5(sketch, canvasContainerId);

  // Return the p5 instance with additional methods
  return p5Instance;
}
