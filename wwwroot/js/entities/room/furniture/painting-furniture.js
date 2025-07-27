// Painting Furniture for DoggyLife
import { BaseFurniture } from "./base-furniture.js";

export class PaintingFurniture extends BaseFurniture {
  constructor(sizeX, sizeY, sizeZ) {
    super(sizeX, sizeY, sizeZ);

    // Calculate proportional dimensions based on size
    this.calculateDimensions();
  }

  getDefaultColors() {
    return {
      // Frame colors
      frame: "#8B4513", // Brown wooden frame
      frameLight: "#CD853F",
      frameDark: "#654321",
      frameVeryDark: "#3E2723",

      // Canvas/painting colors
      canvas: "#FFF8DC", // Cream canvas base
      canvasLight: "#FFFAF0",
      canvasDark: "#F5DEB3",

      // Paint colors for the artwork
      paintPrimary: "#4682B4", // Steel blue
      paintSecondary: "#228B22", // Forest green
      paintAccent: "#DC143C", // Crimson
      paintHighlight: "#FFD700", // Gold
      
      // Signature area
      signature: "#2F2F2F", // Dark gray for signature
      signatureLight: "#696969",
    };
  }

  calculateDimensions() {
    // Base proportions for a painting (reference: 100x120x15)
    // For wall items: sizeX = width, sizeY = height, sizeZ = depth
    const baseWidth = 100;
    const baseHeight = 120;
    const baseDepth = 15;

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

    // Position the painting to project into the room from the wall surface
    // Move it forward along the local Z-axis (which points into the room after rotation)
    p.translate(0, 0, 10); // Move forward from wall surface into the room

    // Draw the painting
    this.drawPainting(p);

    p.pop();
  }

  drawPainting(p) {
    // Use the base dimensions - scaling is handled by the draw() method
    const width = 100; // Base width
    const height = 120; // Base height
    const depth = 15; // Base depth

    // Draw layers from back to front for proper visibility
    
    // 1. Wooden frame border (back layer)
    this.drawWoodenFrame(p);

    // 2. Blue canvas background (middle layer)
    this.drawCanvas(p);

    // 3. Green mountains (front layer)
    this.drawMountains(p);
  }

  drawWoodenFrame(p) {
    // Use base dimensions
    const width = 100;
    const height = 120;
    const depth = 15;

    const frameColor = this.parseColor(this.colors.frame);
    const frameDarkColor = this.parseColor(this.colors.frameDark);

    // Main wooden frame border (deepest layer)
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

  drawCanvas(p) {
    // Use base dimensions
    const width = 100;
    const height = 120;
    const depth = 15;

    const paintPrimary = this.parseColor(this.colors.paintPrimary);

    // Blue rectangle canvas (middle layer)
    p.push();
    p.fill(paintPrimary[0], paintPrimary[1], paintPrimary[2]);
    p.translate(0, 0, 0); // Center layer
    p.box(width * 0.8, height * 0.8, depth * 0.2);
    p.pop();
  }

  drawMountains(p) {
    // Use base dimensions
    const width = 100;
    const height = 120;
    const depth = 15;

    const mountainColor = this.parseColor(this.colors.paintSecondary); // Green

    // Left mountain (triangle as elongated pyramid) - front layer
    p.push();
    p.fill(mountainColor[0], mountainColor[1], mountainColor[2]);
    p.translate(-width * 0.2, height * 0.1, depth * 0.2); // Front layer
    
    // Create triangle by scaling a cone
    p.scale(1, 2, 0.2); // Make it flat and tall
    p.cone(width * 0.15, height * 0.3, 8); // 8 sides for better triangle look
    p.pop();

    // Right mountain (triangle as elongated pyramid) - front layer
    p.push();
    p.fill(mountainColor[0], mountainColor[1], mountainColor[2]);
    p.translate(width * 0.15, height * 0.05, depth * 0.2); // Front layer
    
    // Create triangle by scaling a cone
    p.scale(1, 2.5, 0.2); // Make it flat and taller
    p.cone(width * 0.18, height * 0.35, 8); // 8 sides for better triangle look
    p.pop();
  }
}
