import { createRoomCanvas } from "../../../canvas/room-canvas.js";

// Global reference to the current p5 canvas instance
var currentP5Instance = null;

// Make currentP5Instance globally accessible for room-interop.js
window.getCurrentP5Instance = () => {
  // Prioritize window.currentRoomP5Instance which gets set when the room canvas is created
  const instance = window.currentRoomP5Instance || currentP5Instance;
  console.log(
    "getCurrentP5Instance - using window.currentRoomP5Instance:",
    !!window.currentRoomP5Instance
  );
  console.log(
    "getCurrentP5Instance - fallback currentP5Instance:",
    !!currentP5Instance
  );
  console.log(
    "getCurrentP5Instance - returning instance with _canvasId:",
    instance?._canvasId
  );
  return instance;
};

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

    // Set the global window reference so room-interop.js can access the correct instance
    window.currentRoomP5Instance = currentP5Instance;
    console.log(
      "✅ Set window.currentRoomP5Instance to new room canvas instance"
    );
  }
}

// Export the currentP5Instance so other modules can access it
export { currentP5Instance };
