import { Dog } from '../entities/room/dog';

export function createRoomCanvas(canvasWidth, canvasHeight, canvasContainerId, roomData) {
    const sketch = (p) => {
      // Room rendering data
      let roomSize = 400;
      let tileSize = 50;
      let floorTiles = 8;

      let roomSettings = {
        // Room default colors
        floorLightColor: [220, 220, 220],
        floorDarkColor: [180, 180, 180],
        wallLightColor: [200, 150, 150],
        wallDarkColor: [160, 120, 120],
      };

      let roomBounds = {
        minX: -200,
        maxX: 200,
        minZ: -200,
        maxZ: 200,
        floorY: 200,
      };

      // Camera settings
      let cameraDistance = 325;
      let cameraAngle = Math.PI / 4;
      let cameraHeight = -270;

      // Debug settings
      let debugMode = false;

      let debugCameraDistance = 500;
      let debugCameraAngleX = 0;
      let debugCameraAngleY = 0;
      let isDragging = false;
      let lastMouseX = 0;
      let lastMouseY = 0;

      // Physics data
      let lastUpdateTime = 0;

      // Input data
      let keys = {};

      p.setup = () => {
        // Start the p5.js canvas with the specified dimensions and container
        p.createCanvas(canvasWidth, canvasHeight, p.WEBGL).parent(canvasContainerId);
        p.angleMode(p.RADIANS);

        // Initial perspective
        updatePerspective();

          // Creates a dog instance
          let dog = new Dog();
          dog.initializeDog();
      };

      p.draw = () => {};

        /**
         * Updates the perspective of the canvas based on the current dimensions.
         */
        function updatePerspective() {
            const fov = p.TWO_PI / 3.8;
            const aspect = p.width / p.height;
            const near = 0.1;
            const far = 5000;
            p.perspective(fov, aspect, near, far);
        }
    };

    // Create the p5 instance with the sketch and container ID
    return new p5(sketch, canvasContainerId);
}