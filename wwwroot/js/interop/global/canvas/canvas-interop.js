// canvas-interop.js  (only one createRoomCanvas now)
import { createRoomCanvas } from "../../../canvas/room-canvas.js";

/**
 * Initializes the p5.js canvas based on the provided canvas data.
 * @param {Object} canvasData - The data containing canvas type and container ID.
 */
export function initializeP5Canvas(canvasData) {
    const side = Math.min(window.innerWidth, window.innerHeight) * 0.8;
    if (canvasData.canvasType === "room") {
        createRoomCanvas(
        side,
        side,
        canvasData.canvasContainerId,
        canvasData.additionalData
    );
  }
}
