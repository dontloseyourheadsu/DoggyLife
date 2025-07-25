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

      // Bed colors
      mattress: "#F5F5DC",
      mattressLight: "#FFFACD",
      mattressDark: "#E6E6FA",
      sheet: "#87CEEB",
      sheetLight: "#B0E0E6",
      sheetDark: "#4682B4",
      pillow: "#FFE4E1",
      pillowLight: "#FFF0F5",
      pillowDark: "#F0E68C",
      blanket: "#DDA0DD",
      blanketLight: "#E6E6FA",
      blanketDark: "#9370DB",
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

    console.log(
      `Bed scaling: ${this.scaleX.toFixed(2)} x ${this.scaleY.toFixed(
        2
      )} x ${this.scaleZ.toFixed(2)}`
    );
    console.log(
      `Size mapping: width=${this.sizeX} (scale ${this.scaleX.toFixed(
        2
      )}), height=${this.sizeZ} (scale ${this.scaleY.toFixed(2)}), depth=${
        this.sizeY
      } (scale ${this.scaleZ.toFixed(2)})`
    );
  }

  updateSize(sizeX, sizeY, sizeZ) {
    super.updateSize(sizeX, sizeY, sizeZ);
    this.calculateDimensions();
  }

  draw(p5Instance) {
    const p = p5Instance;

    console.log(
      "Drawing bed at position:",
      this.position,
      "with scales:",
      this.scaleX,
      this.scaleY,
      this.scaleZ
    );

    p.push();
    p.translate(this.position.x, this.position.y, this.position.z);

    // Apply scaling
    p.scale(this.scaleX, this.scaleY, this.scaleZ);

    // Adjust position to center the bed properly
    p.translate(0, -20, 0);

    this.drawBedFrame(p);
    this.drawMattress(p);
    this.drawSheets(p);
    this.drawPillows(p);
    this.drawBlanket(p);

    p.pop();
  }

  drawBedFrame(p) {
    p.push();

    const woodColor = this.parseColor(this.colors.wood);
    const woodLightColor = this.parseColor(this.colors.woodLight);
    const woodDarkColor = this.parseColor(this.colors.woodDark);
    const mattressLightColor = this.parseColor(this.colors.mattressLight);

    // Bed legs
    p.fill(woodDarkColor[0], woodDarkColor[1], woodDarkColor[2]);
    p.push();
    p.translate(-80, 20, 120);
    p.box(15, 40, 15);
    p.pop();
    p.push();
    p.translate(80, 20, 120);
    p.box(15, 40, 15);
    p.pop();
    p.push();
    p.translate(-80, 20, -120);
    p.box(15, 40, 15);
    p.pop();
    p.push();
    p.translate(80, 20, -120);
    p.box(15, 40, 15);
    p.pop();

    // Frame
    this.drawPixelCube(
      p,
      -80,
      0,
      0,
      15,
      25,
      240,
      woodColor,
      woodLightColor,
      woodDarkColor
    );
    this.drawPixelCube(
      p,
      80,
      0,
      0,
      15,
      25,
      240,
      woodColor,
      woodLightColor,
      woodDarkColor
    );
    this.drawPixelCube(
      p,
      0,
      0,
      120,
      160,
      25,
      15,
      woodColor,
      woodLightColor,
      woodDarkColor
    );

    this.drawBedHeadboard(p);
    p.pop();
  }

  drawBedHeadboard(p) {
    p.push();
    p.translate(0, -40, -120);

    const woodColor = this.parseColor(this.colors.wood);
    const woodLightColor = this.parseColor(this.colors.woodLight);
    const woodDarkColor = this.parseColor(this.colors.woodDark);
    const mattressLightColor = this.parseColor(this.colors.mattressLight);

    this.drawPixelCube(
      p,
      0,
      0,
      0,
      170,
      80,
      20,
      woodColor,
      woodLightColor,
      woodDarkColor
    );

    p.push();
    p.translate(0, -45, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      160,
      10,
      15,
      woodLightColor,
      mattressLightColor,
      woodColor
    );
    p.pop();

    p.push();
    p.translate(-70, -10, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      30,
      60,
      18,
      woodDarkColor,
      woodColor,
      woodDarkColor
    );
    p.pop();

    p.push();
    p.translate(70, -10, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      30,
      60,
      18,
      woodDarkColor,
      woodColor,
      woodDarkColor
    );
    p.pop();

    p.pop();
  }

  drawMattress(p) {
    p.push();
    p.translate(0, -15, 0);

    const mattressColor = this.parseColor(this.colors.mattress);
    const mattressLightColor = this.parseColor(this.colors.mattressLight);
    const mattressDarkColor = this.parseColor(this.colors.mattressDark);

    this.drawPixelCube(
      p,
      0,
      0,
      0,
      160,
      20,
      220,
      mattressColor,
      mattressLightColor,
      mattressDarkColor
    );

    p.fill(mattressDarkColor[0], mattressDarkColor[1], mattressDarkColor[2]);
    p.push();
    p.translate(0, -12, 0);
    p.box(150, 2, 210);
    p.pop();

    for (let i = -60; i <= 60; i += 40) {
      for (let j = -80; j <= 80; j += 40) {
        p.push();
        p.translate(i, -12, j);
        p.box(8, 2, 8);
        p.pop();
      }
    }

    p.pop();
  }

  drawSheets(p) {
    p.push();
    p.translate(0, -25, 0);

    const sheetColor = this.parseColor(this.colors.sheet);
    const sheetLightColor = this.parseColor(this.colors.sheetLight);
    const sheetDarkColor = this.parseColor(this.colors.sheetDark);

    this.drawPixelCube(
      p,
      0,
      0,
      0,
      155,
      8,
      215,
      sheetColor,
      sheetLightColor,
      sheetDarkColor
    );

    p.fill(sheetDarkColor[0], sheetDarkColor[1], sheetDarkColor[2]);
    p.push();
    p.translate(20, -6, 40);
    p.box(120, 2, 3);
    p.pop();
    p.push();
    p.translate(-30, -6, -20);
    p.box(100, 2, 3);
    p.pop();
    p.push();
    p.translate(10, -6, -60);
    p.box(80, 2, 3);
    p.pop();

    p.pop();
  }

  drawPillows(p) {
    const pillowColor = this.parseColor(this.colors.pillow);
    const pillowLightColor = this.parseColor(this.colors.pillowLight);
    const pillowDarkColor = this.parseColor(this.colors.pillowDark);

    for (let side of [-40, 40]) {
      p.push();
      p.translate(side, -40, -80);
      this.drawPixelCube(
        p,
        0,
        0,
        0,
        60,
        15,
        40,
        pillowColor,
        pillowLightColor,
        pillowDarkColor
      );

      p.fill(pillowDarkColor[0], pillowDarkColor[1], pillowDarkColor[2]);
      p.push();
      p.translate(0, -9, 0);
      p.box(50, 2, 30);
      p.pop();

      p.push();
      p.translate(25, -5, 15);
      p.box(4, 8, 4);
      p.pop();
      p.push();
      p.translate(-25, -5, -15);
      p.box(4, 8, 4);
      p.pop();

      p.pop();
    }
  }

  drawBlanket(p) {
    p.push();
    p.translate(0, -35, 20);

    const blanketColor = this.parseColor(this.colors.blanket);
    const blanketLightColor = this.parseColor(this.colors.blanketLight);
    const blanketDarkColor = this.parseColor(this.colors.blanketDark);

    this.drawPixelCube(
      p,
      0,
      0,
      0,
      140,
      12,
      160,
      blanketColor,
      blanketLightColor,
      blanketDarkColor
    );

    p.push();
    p.translate(0, -8, 70);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      130,
      8,
      20,
      blanketDarkColor,
      blanketColor,
      blanketDarkColor
    );
    p.pop();

    p.fill(blanketDarkColor[0], blanketDarkColor[1], blanketDarkColor[2]);
    for (let i = -50; i <= 50; i += 25) {
      p.push();
      p.translate(i, -8, 0);
      p.box(2, 2, 140);
      p.pop();
    }

    p.push();
    p.translate(50, -8, -60);
    p.rotateZ(p.PI / 6);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      30,
      6,
      25,
      blanketLightColor,
      blanketColor,
      blanketDarkColor
    );
    p.pop();

    p.pop();
  }
}
