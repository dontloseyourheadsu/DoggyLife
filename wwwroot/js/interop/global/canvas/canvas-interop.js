import { createRoomCanvas } from "../../../canvas/room-canvas.js";

// Global reference to the current p5 canvas instance
var currentP5Instance = null;

// Make currentP5Instance globally accessible for room-interop.js
window.getCurrentP5Instance = () => currentP5Instance;

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

// Import room-interop after setting up the helper function
import "../../room/room-interop.js";

// Export the currentP5Instance so other modules can access it
export { currentP5Instance };
