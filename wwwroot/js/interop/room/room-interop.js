/**
 * Global function to enable hologram mode (called from C#)
 * @param {number} x - X position
 * @param {number} y - Y position
 * @param {number} z - Z position
 * @param {number} width - Width of hologram
 * @param {number} height - Height of hologram
 * @param {number} depth - Depth of hologram
 * @param {string} type - Type of hologram ("floor" or "wall")
 */
window.enableHologramMode = function (x, y, z, width, height, depth, type) {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for hologram control");
    return;
  }

  // Disable all holograms first (only one can be active at a time)
  if (currentP5Instance.disableAllHolograms) {
    currentP5Instance.disableAllHolograms();
  }

  const position = { x, y, z };
  const size = { width, height, depth };

  if (type === "floor") {
    currentP5Instance.enableFloorHologram(position, size);
  } else if (type === "wall") {
    currentP5Instance.enableWallHologram(position, size, "back");
  }
};

/**
 * Global function to disable hologram mode (called from C#)
 */
window.disableHologramMode = function () {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for hologram control");
    return;
  }

  if (currentP5Instance.disableAllHolograms) {
    currentP5Instance.disableAllHolograms();
  }
};

/**
 * Global function to select a hologram item (called from C#)
 * @param {string} itemId - The ID of the selected item
 * @param {string} itemName - The name of the selected item
 * @param {string} itemType - The type of the item (bed, shelf, couch, window, painting)
 * @param {number} sizeX - Width for both floor and wall items
 * @param {number} sizeY - Height for wall items, depth for floor items
 * @param {number} sizeZ - Depth for floor items, width for wall items (alternative dimension)
 */
/**
 * Global function to select hologram item (called from C#)
 * @param {string} itemId - The ID of the selected item
 * @param {string} itemName - The name of the selected item
 * @param {string} itemType - The type of the item (bed, shelf, couch, window, painting)
 * @param {number} sizeX - X dimension
 * @param {number} sizeY - Y dimension
 * @param {number} sizeZ - Z dimension
 */
window.selectHologramItem = function (
  itemId,
  itemName,
  itemType,
  sizeX,
  sizeY,
  sizeZ
) {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for hologram item selection");
    return;
  }

  console.log(
    `Selected hologram item: ${itemName} (${itemId}) - Type: ${itemType} - Size: ${sizeX}x${sizeY}x${sizeZ}`
  );

  // Set the selected item with size information
  console.log("currentP5Instance:", currentP5Instance);
  console.log("currentP5Instance._canvasId:", currentP5Instance?._canvasId);
  console.log(
    "setSelectedHologramItem function exists:",
    !!currentP5Instance?.setSelectedHologramItem
  );

  if (currentP5Instance.setSelectedHologramItem) {
    console.log("Calling setSelectedHologramItem...");
    try {
      currentP5Instance.setSelectedHologramItem(
        itemId,
        itemName,
        itemType,
        sizeX,
        sizeY,
        sizeZ
      );
      console.log("setSelectedHologramItem completed successfully");
    } catch (error) {
      console.error("Error calling setSelectedHologramItem:", error);
    }
  } else {
    console.error("setSelectedHologramItem function not found on p5Instance!");
  }
};

/**
 * Global function to clear hologram item selection (called from C#)
 */
window.clearHologramItemSelection = function () {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for hologram item selection");
    return;
  }

  console.log("Hologram item selection cleared");

  // Clear the selected item
  if (currentP5Instance.clearSelectedHologramItem) {
    currentP5Instance.clearSelectedHologramItem();
  }

  // DON'T disable all holograms - we want to keep hologram mode active for placing more items
};

/**
 * Global function to get current hologram item data (called from C#)
 * Returns null if no item is selected or no hologram is active
 */
window.getCurrentHologramItemData = function () {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for hologram item data");
    return null;
  }

  // Get the selected hologram item
  const selectedItem = currentP5Instance.getSelectedHologramItem
    ? currentP5Instance.getSelectedHologramItem()
    : null;

  console.log(
    "getCurrentHologramItemData - selectedItem from p5Instance:",
    selectedItem
  );

  if (!selectedItem) {
    console.warn("No hologram item currently selected");
    return null;
  }

  // Get the active hologram system to determine placement type and get position/rotation
  const floorHologram = currentP5Instance.getFloorHologramSystem();
  const wallHologram = currentP5Instance.getWallHologramSystem();

  let hologramData = null;

  if (floorHologram && floorHologram.enabled && floorHologram.currentHologram) {
    hologramData = {
      placementType: "floor",
      position: { ...floorHologram.currentHologram.position },
      rotation: floorHologram.currentHologram.rotation || 0,
      size: { ...floorHologram.currentHologram.size },
      wall: null,
    };
  } else if (
    wallHologram &&
    wallHologram.enabled &&
    wallHologram.currentHologram
  ) {
    hologramData = {
      placementType: "wall",
      position: { ...wallHologram.currentHologram.position },
      rotation: wallHologram.getWallRotation
        ? wallHologram.getWallRotation(wallHologram.currentWall)
        : 0,
      size: { ...wallHologram.currentHologram.size },
      wall: wallHologram.currentWall,
    };
  }

  if (!hologramData) {
    console.warn("No active hologram system found");
    return null;
  }

  // Combine item data with hologram data
  const result = {
    itemId: selectedItem.itemId || selectedItem.id, // Handle both property names
    itemName: selectedItem.itemName || selectedItem.name, // Handle both property names
    itemType: selectedItem.itemType || selectedItem.type, // Handle both property names
    sizeX: selectedItem.sizeX,
    sizeY: selectedItem.sizeY,
    sizeZ: selectedItem.sizeZ,
    positionX: hologramData.position.x,
    positionY: hologramData.position.y,
    positionZ: hologramData.position.z,
    rotation: hologramData.rotation,
    placementType: hologramData.placementType,
    wall: hologramData.wall,
  };

  console.log("Current hologram item data:", result);
  return result;
};

/**
 * Global function to load placed items from C# and render them in the room
 * @param {Array} placedItems - Array of placed item objects from the database
 */
window.loadPlacedItems = function (placedItems) {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for loading placed items");
    return;
  }

  if (currentP5Instance.loadPlacedItems) {
    currentP5Instance.loadPlacedItems(placedItems);
    console.log(`Loaded ${placedItems.length} placed items into the room`);
  }
};

/**
 * Global function to add a newly placed item to the room (called after saving to database)
 * @param {Object} placedItem - The placed item object from the database
 */
window.addPlacedItemToRoom = function (placedItem) {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for adding placed item");
    return;
  }

  if (currentP5Instance.addPlacedItem) {
    currentP5Instance.addPlacedItem(placedItem);
    console.log(`Added placed item to room: ${placedItem.itemName}`);
  }
};

/**
 * Global function to remove a placed item from the room (called when deleting from database)
 * @param {number} itemId - The ID of the placed item to remove
 */
window.removePlacedItemFromRoom = function (itemId) {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for removing placed item");
    return;
  }

  if (currentP5Instance.removePlacedItem) {
    const removed = currentP5Instance.removePlacedItem(itemId);
    if (removed) {
      console.log(`Removed placed item from room: ID ${itemId}`);
    } else {
      console.warn(`Failed to remove placed item from room: ID ${itemId}`);
    }
  }
};

/**
 * Global function to clear all placed items from the room
 */
window.clearAllPlacedItemsFromRoom = function () {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for clearing placed items");
    return;
  }

  if (currentP5Instance.clearAllPlacedItems) {
    currentP5Instance.clearAllPlacedItems();
    console.log("Cleared all placed items from room");
  }
};

/**
 * Global function to check if an item is already placed and get its data
 * @param {string} itemId - The ID of the item to check
 * @param {string} itemType - The type of the item to check
 * @returns {Object|null} The placed item data if found, null otherwise
 */
window.getExistingPlacedItem = function (itemId, itemType) {
  const currentP5Instance = window.getCurrentP5Instance
    ? window.getCurrentP5Instance()
    : null;
  if (!currentP5Instance) {
    console.error("No p5 instance available for checking placed items");
    return null;
  }

  if (currentP5Instance.getPlacedItems) {
    const placedItems = currentP5Instance.getPlacedItems();
    // Find existing item by itemId and itemType
    const existingItem = placedItems.find(
      (item) => item.itemId === itemId && item.itemType === itemType
    );

    if (existingItem) {
      console.log(`Found existing placed item: ${existingItem.itemName}`);
      return existingItem;
    }
  }

  return null;
};
