// Shelf Furniture for DoggyLife
import { BaseFurniture } from "./base-furniture.js";

export class ShelfFurniture extends BaseFurniture {
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

      // Shelf specific colors
      interior: "#2F1B14",
      interiorLight: "#5D4037",
      handle: "#FFD700",
      handleLight: "#FFF8DC",
      handleDark: "#B8860B",

      // Items on shelf colors
      lamp: "#F4A460",
      lampLight: "#FFDAB9",
      book: "#8B0000",
      bookLight: "#CD5C5C",
    };
  }

  calculateDimensions() {
    // Base proportions for a shelf (reference: nightstand was 80x120x60, but shelf should be wider and shallower)
    // For floor items: sizeX = width, sizeY = depth, sizeZ = height
    const baseWidth = 100;
    const baseHeight = 80;
    const baseDepth = 30;

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

    // Adjust position to center the shelf properly
    p.translate(0, -10, 0);

    this.drawShelfBody(p);
    this.drawShelfShelves(p);
    this.drawShelfLegs(p);
    this.drawShelfItems(p);

    p.pop();
  }

  drawShelfBody(p) {
    p.push();

    const woodColor = this.parseColor(this.colors.wood);
    const woodLightColor = this.parseColor(this.colors.woodLight);
    const woodDarkColor = this.parseColor(this.colors.woodDark);
    const woodVeryDarkColor = this.parseColor(this.colors.woodVeryDark);
    const interiorColor = this.parseColor(this.colors.interior);
    const interiorLightColor = this.parseColor(this.colors.interiorLight);

    // Main body frame
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      100,
      80,
      30,
      woodColor,
      woodLightColor,
      woodDarkColor
    );

    // Back panel
    p.push();
    p.translate(0, 0, -13);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      96,
      76,
      4,
      woodDarkColor,
      woodColor,
      woodVeryDarkColor
    );
    p.pop();

    // Interior compartments
    for (let yOffset of [-20, 20]) {
      p.push();
      p.translate(0, yOffset, -5);
      p.fill(interiorColor[0], interiorColor[1], interiorColor[2]);
      p.box(92, 30, 20);
      p.fill(
        interiorLightColor[0],
        interiorLightColor[1],
        interiorLightColor[2]
      );
      p.translate(0, 0, -8);
      p.box(88, 26, 2);
      p.pop();
    }

    p.pop();
  }

  drawShelfShelves(p) {
    const woodColor = this.parseColor(this.colors.wood);
    const woodLightColor = this.parseColor(this.colors.woodLight);
    const woodDarkColor = this.parseColor(this.colors.woodDark);

    // Top shelf
    p.push();
    p.translate(0, -45, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      105,
      6,
      35,
      woodLightColor,
      this.parseColor(this.colors.lampLight),
      woodColor
    );
    p.pop();

    // Middle shelf
    p.push();
    p.translate(0, 0, -5);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      96,
      4,
      20,
      woodColor,
      woodLightColor,
      woodDarkColor
    );
    p.pop();

    // Bottom base
    p.push();
    p.translate(0, 45, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      105,
      6,
      35,
      woodColor,
      woodLightColor,
      woodDarkColor
    );
    p.pop();
  }

  drawShelfLegs(p) {
    const woodDarkColor = this.parseColor(this.colors.woodDark);
    const woodColor = this.parseColor(this.colors.wood);
    const woodVeryDarkColor = this.parseColor(this.colors.woodVeryDark);

    const legPositions = [
      [-45, 55, 12],
      [45, 55, 12],
      [-45, 55, -12],
      [45, 55, -12],
    ];

    for (let [x, y, z] of legPositions) {
      p.push();
      p.translate(x, y, z);
      this.drawPixelCube(
        p,
        0,
        0,
        0,
        6,
        15,
        6,
        woodDarkColor,
        woodColor,
        woodVeryDarkColor
      );
      p.pop();
    }
  }

  drawShelfItems(p) {
    const lampColor = this.parseColor(this.colors.lamp);
    const lampLightColor = this.parseColor(this.colors.lampLight);
    const handleDarkColor = this.parseColor(this.colors.handleDark);
    const bookColor = this.parseColor(this.colors.book);
    const bookLightColor = this.parseColor(this.colors.bookLight);
    const woodDarkColor = this.parseColor(this.colors.woodDark);
    const woodColor = this.parseColor(this.colors.wood);
    const woodLightColor = this.parseColor(this.colors.woodLight);
    const woodVeryDarkColor = this.parseColor(this.colors.woodVeryDark);
    const handleColor = this.parseColor(this.colors.handle);
    const handleLightColor = this.parseColor(this.colors.handleLight);

    // Small lamp on top shelf
    p.push();
    p.translate(-30, -60, 5);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      8,
      6,
      8,
      lampColor,
      lampLightColor,
      handleDarkColor
    );
    p.translate(0, -8, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      2,
      10,
      2,
      lampLightColor,
      handleLightColor,
      lampColor
    );
    p.translate(0, -8, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      12,
      6,
      12,
      lampLightColor,
      handleLightColor,
      lampColor
    );
    p.pop();

    // Books on top shelf
    p.push();
    p.translate(20, -55, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      15,
      3,
      10,
      bookColor,
      bookLightColor,
      woodDarkColor
    );
    p.translate(1, -4, -1);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      13,
      3,
      9,
      woodDarkColor,
      woodColor,
      woodVeryDarkColor
    );
    p.translate(-2, -4, 2);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      12,
      3,
      8,
      bookColor,
      bookLightColor,
      woodDarkColor
    );
    p.pop();

    // Small decorative items on middle shelf
    p.push();
    p.translate(-25, -15, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      8,
      4,
      6,
      handleColor,
      handleLightColor,
      handleDarkColor
    );
    p.pop();

    p.push();
    p.translate(15, -15, 2);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      6,
      5,
      6,
      lampColor,
      lampLightColor,
      handleDarkColor
    );
    p.pop();

    // Small box on middle shelf
    p.push();
    p.translate(0, -15, -8);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      10,
      6,
      8,
      woodColor,
      woodLightColor,
      woodDarkColor
    );
    p.translate(0, -4, 0);
    p.fill(woodLightColor[0], woodLightColor[1], woodLightColor[2]);
    p.box(8, 2, 6);
    p.pop();
  }
}
