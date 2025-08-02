import { Dog } from "../entities/room/dog.js";
import { DogAI } from "../systems/ai/room/dog-ai.js";
import { DebugKeyListener } from "../systems/input/room/debug-listener.js";
import { KeyListener } from "../systems/input/room/key-listener.js";
import { RoomRenderer } from "../systems/drawing/room/room-renderer.js";
import { FloorHologramSystem } from "../entities/room/floor-hologram.js";
import { WallHologramSystem } from "../entities/room/wall-hologram.js";
import { BaseHologramSystem } from "../entities/room/base-hologram.js";

export function createRoomCanvas(
  canvasWidth,
  canvasHeight,
  canvasContainerId,
  combinedData
) {
  // Destructure the combined data to get room data and placed items
  const roomData =
    combinedData?.roomData || combinedData?.RoomData || combinedData;
  const initialPlacedItems =
    combinedData?.placedItems || combinedData?.PlacedItems || [];

  console.log("*** ROOM-CANVAS createRoomCanvas called with:");
  console.log("- roomData:", roomData);
  console.log("- initialPlacedItems:", initialPlacedItems.length, "items");

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

    // Placed items management
    let placedItems = []; // Array to store all placed furniture items

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

      // Load initial placed items if provided
      if (initialPlacedItems && initialPlacedItems.length > 0) {
        console.log(
          `*** ROOM-CANVAS setup: Loading ${initialPlacedItems.length} initial placed items`
        );
        // Call async function without awaiting in setup
        loadInitialPlacedItems(initialPlacedItems).catch(console.error);
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

      // Render placed items (furniture that has been placed in the room)
      renderPlacedItems(p5Instance);

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

    /**
     * Render all placed items in the room
     */
    function renderPlacedItems(p5Instance) {
      if (placedItems.length > 0) {
        console.log(`*** RENDERING ${placedItems.length} placed items ***`);

        placedItems.forEach((item, index) => {
          if (item.furniture) {
            console.log(
              `Rendering placed item ${index}: ${
                item.data.itemName || item.data.ItemName
              } at position:`,
              item.furniture.position
            );

            // Draw a bright debug marker at furniture position
            p5Instance.push();
            p5Instance.translate(
              item.furniture.position.x,
              item.furniture.position.y,
              item.furniture.position.z
            );
            p5Instance.fill(255, 0, 0); // Bright red
            p5Instance.noStroke();
            p5Instance.sphere(10); // Debug marker
            p5Instance.pop();

            // Render the actual furniture
            item.furniture.draw(p5Instance);
          } else {
            console.warn(`Placed item ${index} has no furniture object:`, item);
          }
        });
      }
    }

    /**
     * Create a furniture object from placed item data
     */
    async function createFurnitureFromPlacedItem(placedItem) {
      try {
        let furnitureClass;

        if (
          placedItem.placementType === "floor" ||
          placedItem.PlacementType === "floor"
        ) {
          // Floor items
          const itemType = placedItem.itemType || placedItem.ItemType;
          switch (itemType) {
            case "bed":
              const { BedFurniture } = await import(
                "/js/entities/room/furniture/bed-furniture.js"
              );
              furnitureClass = BedFurniture;
              break;
            case "shelf":
              const { ShelfFurniture } = await import(
                "/js/entities/room/furniture/shelf-furniture.js"
              );
              furnitureClass = ShelfFurniture;
              break;
            case "couch":
              const { CouchFurniture } = await import(
                "/js/entities/room/furniture/couch-furniture.js"
              );
              furnitureClass = CouchFurniture;
              break;
            default:
              console.warn(`Unknown floor furniture type: ${itemType}`);
              return null;
          }
        } else if (
          placedItem.placementType === "wall" ||
          placedItem.PlacementType === "wall"
        ) {
          // Wall items
          const itemType = placedItem.itemType || placedItem.ItemType;
          switch (itemType) {
            case "window":
              const { WindowFurniture } = await import(
                "/js/entities/room/furniture/window-furniture.js"
              );
              furnitureClass = WindowFurniture;
              break;
            case "painting":
              const { PaintingFurniture } = await import(
                "/js/entities/room/furniture/painting-furniture.js"
              );
              furnitureClass = PaintingFurniture;
              break;
            default:
              console.warn(`Unknown wall furniture type: ${itemType}`);
              return null;
          }
        } else {
          const placementType =
            placedItem.placementType || placedItem.PlacementType;
          console.warn(`Unknown placement type: ${placementType}`);
          return null;
        }

        if (furnitureClass) {
          console.log(
            `*** Creating furniture from placed item data:`,
            placedItem
          );

          const sizeX = placedItem.sizeX || placedItem.SizeX;
          const sizeY = placedItem.sizeY || placedItem.SizeY;
          const sizeZ = placedItem.sizeZ || placedItem.SizeZ;
          const posX = placedItem.positionX || placedItem.PositionX;
          const posY = placedItem.positionY || placedItem.PositionY;
          const posZ = placedItem.positionZ || placedItem.PositionZ;
          const rotation = placedItem.rotation || placedItem.Rotation;

          console.log(
            `*** Furniture size: ${sizeX}x${sizeY}x${sizeZ}, position: (${posX}, ${posY}, ${posZ}), rotation: ${rotation}`
          );

          const furniture = new furnitureClass(sizeX, sizeY, sizeZ);

          furniture.setPosition(posX, posY, posZ);
          furniture.setRotation(rotation);

          console.log(
            `*** Created furniture with position:`,
            furniture.position,
            `rotation:`,
            furniture.rotation
          );

          return furniture;
        }
      } catch (error) {
        console.error(
          `Error creating furniture for ${
            placedItem.itemType || placedItem.ItemType
          }:`,
          error
        );
      }

      return null;
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
      console.log("*** ROOM-CANVAS setSelectedHologramItem called with:", {
        itemId,
        itemName,
        itemType,
        sizeX,
        sizeY,
        sizeZ,
      });

      selectedHologramItem = {
        itemId: itemId,
        itemName: itemName,
        itemType: itemType,
        sizeX: sizeX,
        sizeY: sizeY,
        sizeZ: sizeZ,
      };

      console.log(
        "*** ROOM-CANVAS selectedHologramItem set to:",
        selectedHologramItem
      );

      const hologramSize = calculateHologramSize(itemType, sizeX, sizeY, sizeZ);

      // Update active hologram system with new size
      if (floorHologramSystem.enabled) {
        floorHologramSystem.setSize(
          hologramSize.width,
          hologramSize.height,
          hologramSize.depth
        );

        // Set the selected furniture item for floor hologram
        if (
          itemType === "bed" ||
          itemType === "shelf" ||
          itemType === "couch"
        ) {
          floorHologramSystem.setSelectedItem(
            itemId,
            itemName,
            itemType,
            sizeX,
            sizeY,
            sizeZ
          );
        }
      }
      if (wallHologramSystem.enabled) {
        wallHologramSystem.setSize(
          hologramSize.width,
          hologramSize.height,
          hologramSize.depth
        );

        // Set the selected furniture item for wall hologram
        if (itemType === "window" || itemType === "painting") {
          wallHologramSystem.setSelectedItem(
            itemId,
            itemName,
            itemType,
            sizeX,
            sizeY,
            sizeZ
          );
        }
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
      console.log(
        "clearSelectedHologramItem called, current item:",
        selectedHologramItem
      );
      selectedHologramItem = null;

      // Clear selected items from hologram systems
      floorHologramSystem.clearSelectedItem();
      wallHologramSystem.clearSelectedItem();
    };

    p5Instance.getSelectedHologramItem = () => {
      console.log(
        "*** ROOM-CANVAS getSelectedHologramItem called, returning:",
        selectedHologramItem
      );
      return selectedHologramItem;
    };

    // Store the p5Instance globally so interop functions can access it
    // Do this right after defining all our custom functions
    p5Instance._canvasId = "room-canvas-" + Date.now();
    console.log(
      "*** ROOM-CANVAS storing p5Instance with ID:",
      p5Instance._canvasId
    );
    window.currentRoomP5Instance = p5Instance;

    // Helper function to load initial placed items during setup
    async function loadInitialPlacedItems(initialItemsData) {
      console.log(
        `*** ROOM-CANVAS: Loading ${initialItemsData.length} initial placed items`
      );
      placedItems = []; // Clear existing items

      for (const itemData of initialItemsData) {
        console.log(
          `*** Creating initial furniture for ${
            itemData.itemName || itemData.ItemName
          } (${itemData.itemType || itemData.ItemType})`
        );
        const furniture = await createFurnitureFromPlacedItem(itemData);
        if (furniture) {
          placedItems.push({
            id: itemData.Id || itemData.id, // Handle both Pascal and camel case
            data: itemData,
            furniture: furniture,
          });
          console.log(
            `*** Successfully created initial furniture for ${
              itemData.itemName || itemData.ItemName
            }`
          );
        } else {
          console.warn(
            `*** Failed to create initial furniture for ${
              itemData.itemName || itemData.ItemName
            }`
          );
        }
      }

      console.log(
        `*** ROOM-CANVAS: Loaded ${placedItems.length} initial placed items into room canvas`
      );
    }

    // Placed items management functions
    p5Instance.loadPlacedItems = async (placedItemsData) => {
      console.log(
        `RoomCanvas JS: Loading ${placedItemsData.length} placed items`
      );
      placedItems = []; // Clear existing items

      for (const itemData of placedItemsData) {
        console.log(
          `RoomCanvas JS: Creating furniture for ${itemData.itemName} (${itemData.itemType})`
        );
        const furniture = await createFurnitureFromPlacedItem(itemData);
        if (furniture) {
          placedItems.push({
            id: itemData.Id || itemData.id, // Handle both Pascal and camel case
            data: itemData,
            furniture: furniture,
          });
          console.log(
            `RoomCanvas JS: Successfully created furniture for ${itemData.itemName}`
          );
        } else {
          console.warn(
            `RoomCanvas JS: Failed to create furniture for ${itemData.itemName}`
          );
        }
      }

      console.log(
        `RoomCanvas JS: Loaded ${placedItems.length} placed items into room canvas`
      );
    };

    p5Instance.addPlacedItem = async (placedItemData) => {
      const furniture = await createFurnitureFromPlacedItem(placedItemData);
      if (furniture) {
        placedItems.push({
          id: placedItemData.Id || placedItemData.id, // Handle both Pascal and camel case
          data: placedItemData,
          furniture: furniture,
        });
        console.log(
          `Added placed item to room canvas: ${placedItemData.itemName}`
        );
      }
    };

    p5Instance.removePlacedItem = (itemId) => {
      const index = placedItems.findIndex((item) => item.id === itemId);
      if (index !== -1) {
        const removedItem = placedItems.splice(index, 1)[0];
        console.log(
          `Removed placed item from room canvas: ${removedItem.data.itemName}`
        );
        return true;
      }
      return false;
    };

    p5Instance.clearAllPlacedItems = () => {
      placedItems = [];
      console.log("Cleared all placed items from room canvas");
    };

    p5Instance.getPlacedItems = () => {
      return placedItems.map((item) => item.data);
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

  // Return the p5 instance
  return p5Instance;
}
