// Initialize p5 sketch in instance mode
window.createP5RoomRenderer = function (containerId, width, height) {
  // Create new sketch
  p5Instance = new p5(function (p) {

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