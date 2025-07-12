import { Dog } from '../entities/room/dog';
import { DogAI } from '../systems/ai/room/dog-ai';
import { DebugKeyListener } from '../systems/input/room/debug-listener';
import { KeyListener } from "../systems/input/room/key-listener";
import { RoomRenderer } from '../systems/drawing/room/room-renderer';

export function createRoomCanvas(
  canvasWidth,
  canvasHeight,
  canvasContainerId,
  roomData
) {
  const sketch = (p5Instance) => {

    // Camera settings
    let cameraDistance = 325;
    let cameraAngle = Math.PI / 4;
    let cameraHeight = -270;

    // Room renderer instance
    let roomRenderer = new RoomRenderer(p5Instance, roomData, 400); 

    // Dog rendering data
    let dog = new Dog();
    let dogAI = new DogAI(dog);

    // Physics data
    let lastUpdateTime = 0;

    // Debug mode settings
    let debugKeyListener = new DebugKeyListener(false);

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
    };

    p5Instance.draw = () => {
      p5Instance.background(50);

      // Calculate delta time for animation
      const timeNowInSeconds = p5Instance.millis() / 1000;
      const deltaTime = timeNowInSeconds - lastUpdateTime;
      lastUpdateTime = timeNowInSeconds;

      // Update dog AI or keep position if AI is disabled
      let dogUpdatedPosition = dogAI && dogAI.enabled
        ? dogAI.update(deltaTime)
        : dog.position;

      // TODO: Insert Floor and Wall Hologram updates
      if (window.HologramSystem) {
        window.HologramSystem.update(deltaTime);
      }
      // Update wall hologram system if available
      if (window.WallHologramSystem) {
        window.WallHologramSystem.update(deltaTime);
      }

      // TODO: Implement bellow p methods for p5Instance
      p5Instance.ambientLight(60);
      p5Instance.directionalLight(255, 255, 255, -1, 0.5, -1);
      updateCamera();
      roomRenderer.draw();

      // Update dog position
      dog.move(dogUpdatedPosition, deltaTime);
      dog.render(p5Instance, cameraAngle);
    };

    function updateCamera() {
      // Update perspective projection
      updatePerspective();

      if (debugMode) {
        // Debug camera with free movement
        const x =
          debugKeyListener.debugCameraDistance *
          Math.cos(debugKeyListener.debugCameraAngleX) *
          Math.cos(debugKeyListener.debugCameraAngleY);
        const y = debugKeyListener.debugCameraDistance * Math.sin(debugKeyListener.debugCameraAngleX);
        const z =
          debugKeyListener.debugCameraDistance *
          Math.cos(debugKeyListener.debugCameraAngleX) *
          Math.sin(debugKeyListener.debugCameraAngleY);

        // Use debug camera looking at the center (0,0,0)
        p.camera(x, y, z, 0, 0, 0, 0, 1, 0);
      } else {
        // Original fixed camera
        let x = cameraDistance * Math.cos(cameraAngle);
        let z = cameraDistance * Math.sin(cameraAngle);
        p.camera(x, cameraHeight, z, 0, 0, 0, 0, 1, 0);
      }
    };

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
  };

  // Create the p5 instance with the sketch and container ID
  return new p5(sketch, canvasContainerId);
}
