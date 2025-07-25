// Base Furniture Class for DoggyLife
export class BaseFurniture {
  constructor(sizeX, sizeY, sizeZ, colors) {
    // Size properties (dimensions in 3D space)
    this.sizeX = sizeX; // Width
    this.sizeY = sizeY; // Height
    this.sizeZ = sizeZ; // Depth

    // Color scheme for the furniture
    this.colors = colors || this.getDefaultColors();

    // Position in 3D space (will be set by hologram system)
    this.position = { x: 0, y: 0, z: 0 };
  }

  // Abstract method - to be implemented by subclasses
  getDefaultColors() {
    throw new Error("getDefaultColors must be implemented by subclass");
  }

  // Set the position of the furniture
  setPosition(x, y, z) {
    this.position = { x, y, z };
  }

  // Update the size of the furniture
  updateSize(sizeX, sizeY, sizeZ) {
    this.sizeX = sizeX;
    this.sizeY = sizeY;
    this.sizeZ = sizeZ;
  }

  // Abstract method - to be implemented by subclasses
  draw(p5Instance) {
    throw new Error("draw must be implemented by subclass");
  }

  // Helper method for drawing a pixel-style cube with shading
  drawPixelCube(
    p5Instance,
    x,
    y,
    z,
    w,
    h,
    d,
    baseColor,
    lightColor,
    darkColor
  ) {
    const p = p5Instance;

    p.push();
    p.translate(x, y, z);

    // Front face (lighter)
    p.fill(lightColor);
    p.push();
    p.translate(0, 0, d / 2);
    p.plane(w, h);
    p.pop();

    // Right face (base color)
    p.fill(baseColor);
    p.push();
    p.rotateY(p.PI / 2);
    p.translate(0, 0, w / 2);
    p.plane(d, h);
    p.pop();

    // Top face (lighter)
    p.fill(lightColor);
    p.push();
    p.rotateX(p.PI / 2);
    p.translate(0, 0, h / 2);
    p.plane(w, d);
    p.pop();

    // Left face (darker)
    p.fill(darkColor);
    p.push();
    p.rotateY(-p.PI / 2);
    p.translate(0, 0, w / 2);
    p.plane(d, h);
    p.pop();

    // Bottom face (darker)
    p.fill(darkColor);
    p.push();
    p.rotateX(-p.PI / 2);
    p.translate(0, 0, h / 2);
    p.plane(w, d);
    p.pop();

    // Back face (darker)
    p.fill(darkColor);
    p.push();
    p.translate(0, 0, -d / 2);
    p.plane(w, h);
    p.pop();

    p.pop();
  }

  // Helper method to convert hex color to RGB array
  hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result
      ? [
          parseInt(result[1], 16),
          parseInt(result[2], 16),
          parseInt(result[3], 16),
        ]
      : [255, 255, 255];
  }

  // Helper method to parse color (hex string or RGB array)
  parseColor(color) {
    if (typeof color === "string") {
      return this.hexToRgb(color);
    }
    return color;
  }
}
