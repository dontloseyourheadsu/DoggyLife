export class DebugKeyListener {
    active = false;
    isDragging = false;

    debugCameraDistance = 500;
    debugCameraAngleX = 0;
    debugCameraAngleY = 0;

    lastMouseX = 0;
    lastMouseY = 0;

    constructor(active = false) { 
        this.active = active;
    }

    listenMouseDown(p5Instance) {
      // Mouse press
      p5Instance.canvas.addEventListener("mousedown", (e) => {
        this.isDragging = true;
        this.lastMouseX = e.clientX;
        this.lastMouseY = e.clientY;
        e.preventDefault();
      });
    }

    listenMouseUp(p5Instance) {
        // Mouse release
        p5Instance.canvas.addEventListener("mouseup", (e) => {
            this.isDragging = false;
            e.preventDefault();
        });
    }

    listenMouseMove(p5Instance) {
        p5Instance.canvas.addEventListener("mousemove", (e) => {
            if (this.isDragging) {
                const deltaX = e.clientX - this.lastMouseX;
                const deltaY = e.clientY - this.lastMouseY;

                // Update camera angles based on mouse movement
                this.debugCameraAngleY += deltaX * 0.01; // Horizontal rotation
                this.debugCameraAngleX += deltaY * 0.01; // Vertical rotation

                // Clamp vertical rotation to prevent flipping
                this.debugCameraAngleX = Math.max(
                    -Math.PI / 2 + 0.1,
                    Math.min(Math.PI / 2 - 0.1, this.debugCameraAngleX)
                );

                this.lastMouseX = e.clientX;
                this.lastMouseY = e.clientY;
            }
        });
    }

    listenWheel(p5Instance) {
        // Mouse wheel for zooming
        p5Instance.canvas.addEventListener("wheel", (e) => {
          e.preventDefault();
          const zoomFactor = e.deltaY > 0 ? 1.1 : 0.9;
          this.debugCameraDistance *= zoomFactor;

          // Clamp zoom distance
          this.debugCameraDistance = Math.max(
            50,
            Math.min(2000, this.debugCameraDistance)
          );
        });
    }
}