// Bed Furniture for DoggyLife
import { BaseFurniture } from "./base-furniture.js";

export class BedFurniture extends BaseFurniture {
  constructor(sizeX, sizeY, sizeZ) {
    super(sizeX, sizeY, sizeZ);

    // Calculate proportional dimensions based on size
    this.calculateDimensions();
  }

  getDefaultColors() {
    return {
      // Wood colors
      wood: "#8B4513",
      woodLight: "#CD853F",
      woodDark: "#654321",
      woodVeryDark: "#3E2723",

      // Improved bed colors based on the example
      mattress: "#E6E6FA", // White/cream mattress base
      mattressLight: "#F0F0FF", // Lighter cream for highlights
      mattressDark: "#D8BFD8", // Darker cream for shadows and quilting
      sheet: "#87CEEB",
      sheetLight: "#B0E0E6",
      sheetDark: "#4682B4",
      pillow: "#FFE4E1",
      pillowLight: "#FFF0F5",
      pillowDark: "#FFC0CB", // Pink tint for texture
      blanket: "#4682B4", // Blue blanket base
      blanketLight: "#87CEEB", // Light blue for pattern
      blanketDark: "#2F4F4F", // Dark blue for quilting pattern
    };
  }

  calculateDimensions() {
    // Base proportions for a bed (reference: original was roughly 170x100x240)
    // For floor items: sizeX = width, sizeY = depth, sizeZ = height
    const baseWidth = 170;
    const baseHeight = 100;
    const baseDepth = 240;

    // Calculate scale factors based on desired vs original size
    this.scaleX = this.sizeX / baseWidth; // sizeX is width for floor items
    this.scaleY = this.sizeZ / baseHeight; // sizeZ is height for floor items
    this.scaleZ = this.sizeY / baseDepth; // sizeY is depth for floor items
  }

  updateSize(sizeX, sizeY, sizeZ) {
    super.updateSize(sizeX, sizeY, sizeZ);
    this.calculateDimensions();
  }

  draw(p5Instance) {
    const p = p5Instance;

    p.push();
    p.translate(this.position.x, this.position.y, this.position.z);

    // Apply rotation around Y-axis
    p.rotateY(this.rotation);

    // Apply scaling
    p.scale(this.scaleX, this.scaleY, this.scaleZ);

    // Draw the bed
    this.drawBed(p);

    p.pop();
  }

  drawBed(p) {
    // Use the base dimensions - scaling is handled by the draw() method
    const width = 170; // Base width
    const height = 100; // Base height
    const depth = 240; // Base depth

    // Bed frame base
    p.push();
    const bedFrameColor = this.parseColor(this.colors.wood);
    p.fill(bedFrameColor[0], bedFrameColor[1], bedFrameColor[2]);
    p.translate(0, height * 0.2, 0);
    p.box(width * 0.7, height * 0.2, depth * 0.83);
    p.pop();

    // Bed frame legs (chunky pixel style)
    const legPositions = [
      [-width * 0.29, height * 0.4, -depth * 0.35],
      [width * 0.29, height * 0.4, -depth * 0.35],
      [-width * 0.29, height * 0.4, depth * 0.35],
      [width * 0.29, height * 0.4, depth * 0.35],
    ];

    const bedFrameDarkColor = this.parseColor(this.colors.woodDark);
    legPositions.forEach((pos) => {
      p.push();
      p.fill(bedFrameDarkColor[0], bedFrameDarkColor[1], bedFrameDarkColor[2]);
      p.translate(pos[0], pos[1], pos[2]);
      p.box(width * 0.09, height * 0.4, width * 0.09);
      p.pop();
    });

    // Headboard (low-poly, chunky)
    p.push();
    p.fill(bedFrameColor[0], bedFrameColor[1], bedFrameColor[2]);
    p.translate(0, -height * 0.2, -depth * 0.35);
    p.box(width * 0.7, height * 0.8, width * 0.09);
    p.pop();

    // Quilted white mattress
    this.drawQuiltedMattress(p);

    // Pillows with texture
    this.drawTexturedPillows(p);

    // Blanket with quilted pattern
    this.drawQuiltedBlanket(p);
  }

  drawQuiltedMattress(p) {
    // Use base dimensions
    const width = 170;
    const height = 100;
    const depth = 240;

    const mattressColor = this.parseColor(this.colors.mattress);
    const mattressDarkColor = this.parseColor(this.colors.mattressDark);
    const mattressLightColor = this.parseColor(this.colors.mattressLight);

    // Main mattress base - position ABOVE the bed frame
    p.push();
    p.fill(mattressColor[0], mattressColor[1], mattressColor[2]);
    p.translate(0, height * 0.1, 0); // Position above the bed frame
    p.box(width * 0.58, height * 0.15, depth * 0.75);
    p.pop();

    // Quilted diamond pattern using small boxes
    const diamondSize = width * 0.12;
    const rows = Math.max(4, Math.floor(depth * 0.033));
    const cols = Math.max(2, Math.floor(width * 0.023));

    for (let i = 0; i < cols; i++) {
      for (let j = 0; j < rows; j++) {
        let x = (i - cols / 2 + 0.5) * diamondSize;
        let z =
          (j - rows / 2 + 0.5) * diamondSize + (i % 2) * (diamondSize / 2);

        // Alternate colors for quilted pattern
        let colorChoice;
        if ((i + j) % 2 === 0) {
          colorChoice = mattressDarkColor;
        } else {
          colorChoice = mattressLightColor;
        }

        p.push();
        p.fill(colorChoice[0], colorChoice[1], colorChoice[2]);
        p.translate(x, height * 0.06, z); // Position above mattress base
        p.box(width * 0.07, height * 0.03, width * 0.07);
        p.pop();

        // Add small indent in center for tufted look
        if ((i + j) % 3 === 0) {
          p.push();
          p.fill(
            mattressDarkColor[0],
            mattressDarkColor[1],
            mattressDarkColor[2]
          );
          p.translate(x, height * 0.04, z); // Position above quilted pattern
          p.box(width * 0.023, height * 0.01, width * 0.023);
          p.pop();
        }
      }
    }

    // Mattress edge piping - position above mattress
    p.push();
    p.fill(mattressDarkColor[0], mattressDarkColor[1], mattressDarkColor[2]);
    p.translate(0, height * 0.18, 0); // Position above mattress
    p.box(width * 0.6, height * 0.02, depth * 0.76);
    p.pop();

    // Side texture lines for fabric look
    const sideLines = [
      {
        x: -width * 0.28,
        y: height * 0.14, // Adjust Y position
        z: 0,
        w: width * 0.023,
        h: height * 0.08,
        d: depth * 0.75,
      },
      {
        x: width * 0.28,
        y: height * 0.14, // Adjust Y position
        z: 0,
        w: width * 0.023,
        h: height * 0.08,
        d: depth * 0.75,
      },
      {
        x: 0,
        y: height * 0.14, // Adjust Y position
        z: -depth * 0.37,
        w: width * 0.58,
        h: height * 0.08,
        d: width * 0.023,
      },
      {
        x: 0,
        y: height * 0.14, // Adjust Y position
        z: depth * 0.37,
        w: width * 0.58,
        h: height * 0.08,
        d: width * 0.023,
      },
    ];

    sideLines.forEach((line) => {
      p.push();
      p.fill(mattressDarkColor[0], mattressDarkColor[1], mattressDarkColor[2]);
      p.translate(line.x, line.y, line.z);
      p.box(line.w, line.h, line.d);
      p.pop();
    });
  }

  drawTexturedPillows(p) {
    // Use base dimensions
    const width = 170;
    const height = 100;
    const depth = 240;

    const pillowColor = this.parseColor(this.colors.pillow);
    const pillowDarkColor = this.parseColor(this.colors.pillowDark);

    // Left pillow - solid with subtle texture overlay
    p.push();
    p.fill(pillowColor[0], pillowColor[1], pillowColor[2]);
    p.translate(-width * 0.175, height * 0.08, -depth * 0.27); // Position above mattress
    p.box(width * 0.146, height * 0.08, depth * 0.083);
    p.pop();

    // Left pillow texture detail (small accent)
    p.push();
    p.fill(pillowDarkColor[0], pillowDarkColor[1], pillowDarkColor[2]);
    p.translate(-width * 0.175, height * 0.04, -depth * 0.27); // Position above pillow
    p.box(width * 0.117, height * 0.01, depth * 0.063);
    p.pop();

    // Right pillow - solid with subtle texture overlay
    p.push();
    p.fill(pillowDarkColor[0], pillowDarkColor[1], pillowDarkColor[2]);
    p.translate(width * 0.175, height * 0.08, -depth * 0.27); // Position above mattress
    p.box(width * 0.146, height * 0.08, depth * 0.083);
    p.pop();

    // Right pillow texture detail
    p.push();
    p.fill(pillowColor[0], pillowColor[1], pillowColor[2]);
    p.translate(width * 0.175, height * 0.04, -depth * 0.27); // Position above pillow
    p.box(width * 0.117, height * 0.01, depth * 0.063);
    p.pop();
  }

  drawQuiltedBlanket(p) {
    // Use base dimensions
    const width = 170;
    const height = 100;
    const depth = 240;

    const blanketColor = this.parseColor(this.colors.blanket);
    const blanketDarkColor = this.parseColor(this.colors.blanketDark);
    const blanketLightColor = this.parseColor(this.colors.blanketLight);

    // Main blanket base - position above mattress
    p.push();
    p.fill(blanketColor[0], blanketColor[1], blanketColor[2]);
    p.translate(0, height * 0.12, depth * 0.083); // Position above mattress
    p.box(width * 0.467, height * 0.04, depth * 0.5);
    p.pop();

    // Quilted diamond pattern for blanket
    const diamondSize = width * 0.088;
    const rows = Math.max(3, Math.floor(depth * 0.029));
    const cols = Math.max(2, Math.floor(width * 0.023));

    for (let i = 0; i < cols; i++) {
      for (let j = 0; j < rows; j++) {
        let x = (i - cols / 2 + 0.5) * diamondSize;
        let z =
          (j - rows / 2 + 0.5) * diamondSize + (i % 2) * (diamondSize / 2);

        // Create quilted diamond pattern with 3 colors
        let colorChoice;
        let pattern = (i + j) % 3;
        if (pattern === 0) {
          colorChoice = blanketColor;
        } else if (pattern === 1) {
          colorChoice = blanketDarkColor;
        } else {
          colorChoice = blanketLightColor;
        }

        p.push();
        p.fill(colorChoice[0], colorChoice[1], colorChoice[2]);
        p.translate(x, height * 0.15, depth * 0.083 + z); // Position above blanket base
        p.box(width * 0.058, height * 0.01, width * 0.058);
        p.pop();

        // Add stitching lines
        if ((i + j) % 2 === 0) {
          p.push();
          p.fill(blanketDarkColor[0], blanketDarkColor[1], blanketDarkColor[2]);
          p.translate(x, height * 0.155, depth * 0.083 + z); // Position above quilted pattern
          p.box(width * 0.07, height * 0.005, width * 0.0058);
          p.pop();

          p.push();
          p.fill(blanketDarkColor[0], blanketDarkColor[1], blanketDarkColor[2]);
          p.translate(x, height * 0.155, depth * 0.083 + z); // Position above quilted pattern
          p.box(width * 0.0058, height * 0.005, width * 0.07);
          p.pop();
        }
      }
    }

    // Blanket border/hem - position above blanket
    p.push();
    p.fill(blanketDarkColor[0], blanketDarkColor[1], blanketDarkColor[2]);
    p.translate(0, height * 0.155, depth * 0.083); // Position above blanket
    p.box(width * 0.479, height * 0.005, depth * 0.508);
    p.pop();
  }
}
