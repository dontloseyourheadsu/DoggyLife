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
  if (currentP5Instance.setSelectedHologramItem) {
    currentP5Instance.setSelectedHologramItem(
      itemId,
      itemName,
      itemType,
      sizeX,
      sizeY,
      sizeZ
    );
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
};
