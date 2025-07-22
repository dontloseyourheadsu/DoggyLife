// canvas-interop.js  (only one createRoomCanvas now)
import { createRoomCanvas } from "../../../canvas/room-canvas.js";

// Global reference to the current p5 canvas instance
let currentP5Instance = null;

/**
 * Initializes the p5.js canvas based on the provided canvas data.
 * @param {Object} canvasData - The data containing canvas type and container ID.
 */
export function initializeP5Canvas(canvasData) {
  const side = Math.min(window.innerWidth, window.innerHeight) * 0.8;
  if (canvasData.canvasType === "room") {
    currentP5Instance = createRoomCanvas(
      side,
      side,
      canvasData.canvasContainerId,
      canvasData.additionalData
    );
  }
}

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
  if (!currentP5Instance) {
    console.error("No p5 instance available for hologram control");
    return;
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
  if (!currentP5Instance) {
    console.error("No p5 instance available for hologram control");
    return;
  }

  currentP5Instance.disableAllHolograms();
};

/**
 * Global function to select a hologram item (called from C#)
 * @param {string} itemId - The ID of the selected item
 * @param {string} itemName - The name of the selected item
 * @param {string} itemType - The type of the item (bed, shelf, couch, window, painting)
 */
window.selectHologramItem = function (itemId, itemName, itemType) {
  if (!currentP5Instance) {
    console.error("No p5 instance available for hologram item selection");
    return;
  }

  console.log(
    `Hologram item selected: ${itemName} (${itemId}) - Type: ${itemType}`
  );

  // For now, this is a placeholder for future functionality
  // The selected item information is available for the hologram systems to use
  if (currentP5Instance.setSelectedHologramItem) {
    currentP5Instance.setSelectedHologramItem(itemId, itemName, itemType);
  }
};

/**
 * Global function to clear hologram item selection (called from C#)
 */
window.clearHologramItemSelection = function () {
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
