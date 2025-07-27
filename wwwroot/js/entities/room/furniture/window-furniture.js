// Window Furniture for DoggyLife
import { BaseFurniture } from "./base-furniture.js";

export class WindowFurniture extends BaseFurniture {
  constructor(sizeX, sizeY, sizeZ) {
    super(sizeX, sizeY, sizeZ);

    // Calculate proportional dimensions based on size
    this.calculateDimensions();
  }

  getDefaultColors() {
    return {
      // Frame colors
      frame: "#8B4513",
      frameLight: "#CD853F",
      frameDark: "#654321",
      frameVeryDark: "#3E2723",

      // Glass colors
      glass: "#87CEEB", // Light blue glass
      glassLight: "#B0E0E6", // Lighter blue for highlights
      glassDark: "#4682B4", // Darker blue for shadows

      // Window details
      sill: "#A0522D", // Brown window sill
      sillLight: "#DEB887",
      sillDark: "#8B4513",

      // Handle/latch
      handle: "#C0C0C0", // Silver handle
      handleLight: "#E5E5E5",
      handleDark: "#808080",
    };
  }

  calculateDimensions() {
    // Base proportions for a window (reference: 120x150x20)
    // For wall items: sizeX = width, sizeY = height, sizeZ = depth
    const baseWidth = 120;
    const baseHeight = 150;
    const baseDepth = 20;

    // Calculate scale factors based on desired vs original size
    this.scaleX = this.sizeX / baseWidth; // sizeX is width for wall items
    this.scaleY = this.sizeY / baseHeight; // sizeY is height for wall items
    this.scaleZ = this.sizeZ / baseDepth; // sizeZ is depth for wall items
  }

  updateSize(sizeX, sizeY, sizeZ) {
    super.updateSize(sizeX, sizeY, sizeZ);
    this.calculateDimensions();
  }

  draw(p5Instance) {
    const p = p5Instance;

    p.push();
    p.translate(this.position.x, this.position.y, this.position.z);

    // Apply rotation for wall orientation
    p.rotateY(this.rotation);
    
    // Apply scaling
    p.scale(this.scaleX, this.scaleY, this.scaleZ);

    // Position the window to project into the room from the wall surface
    // Move it forward along the local Z-axis (which points into the room after rotation)
    p.translate(0, 0, 15); // Move forward from wall surface into the room

    // Draw the window
    this.drawWindow(p);

    p.pop();
  }

  drawWindow(p) {
    // Use the base dimensions - scaling is handled by the draw() method
    const width = 120; // Base width
    const height = 150; // Base height
    const depth = 20; // Base depth

    // Draw layers from back to front for proper visibility
    
    // 1. Wooden frame (back layer)
    this.drawWoodenFrame(p);

    // 2. Blue glass area (middle layer) 
    this.drawGlassArea(p);

    // 3. Wooden cross sticks (front layer)
    this.drawCrossSticks(p);
  }

  drawWoodenFrame(p) {
    // Use base dimensions
    const width = 120;
    const height = 150;
    const depth = 20;

    const frameColor = this.parseColor(this.colors.frame);
    const frameDarkColor = this.parseColor(this.colors.frameDark);

    // Main wooden border frame (deepest layer)
    p.push();
    p.fill(frameColor[0], frameColor[1], frameColor[2]);
    p.translate(0, 0, -depth * 0.2); // Push back
    p.box(width, height, depth * 0.6);
    p.pop();

    // Frame shadow/depth
    p.push();
    p.fill(frameDarkColor[0], frameDarkColor[1], frameDarkColor[2]);
    p.translate(0, 0, -depth * 0.4);
    p.box(width * 0.95, height * 0.95, depth * 0.2);
    p.pop();
  }

  drawGlassArea(p) {
    // Use base dimensions
    const width = 120;
    const height = 150;
    const depth = 20;

    const glassColor = this.parseColor(this.colors.glass);

    // Blue glass rectangle in the center (middle layer)
    p.push();
    p.fill(glassColor[0], glassColor[1], glassColor[2]);
    p.translate(0, 0, 0); // Center layer
    p.box(width * 0.8, height * 0.8, depth * 0.2);
    p.pop();
  }

  drawCrossSticks(p) {
    // Use base dimensions
    const width = 120;
    const height = 150;
    const depth = 20;

    const frameColor = this.parseColor(this.colors.frame);

    // Vertical wooden stick (front layer)
    p.push();
    p.fill(frameColor[0], frameColor[1], frameColor[2]);
    p.translate(0, 0, depth * 0.2); // Front layer
    p.box(width * 0.05, height * 0.8, depth * 0.4);
    p.pop();

    // Horizontal wooden stick (front layer)
    p.push();
    p.fill(frameColor[0], frameColor[1], frameColor[2]);
    p.translate(0, 0, depth * 0.2); // Front layer
    p.box(width * 0.8, height * 0.05, depth * 0.4);
    p.pop();
  }
}
