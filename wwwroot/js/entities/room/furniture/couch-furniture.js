// Couch Furniture for DoggyLife
import { BaseFurniture } from "./base-furniture.js";

export class CouchFurniture extends BaseFurniture {
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

      // Couch colors
      couchBase: "#8B4513",
      couchLight: "#CD853F",
      couchDark: "#654321",
      couchShadow: "#3E2723",
      cushion: "#A0522D",
      cushionLight: "#DEB887",
      cushionDark: "#8B4513",
    };
  }

  calculateDimensions() {
    // Base proportions for a couch (reference: original was 280x80x100)
    // The original couch was designed with these dimensions
    const baseWidth = 280;
    const baseHeight = 80;
    const baseDepth = 100;

    // Calculate scale factors based on desired vs original size
    this.scaleX = this.sizeX / baseWidth;
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

    // Adjust position to center the couch properly (original was offset)
    p.translate(0, -10, 0);

    this.drawCouchBase(p);
    this.drawArmrest(p, -120, 0, 0);
    this.drawArmrest(p, 120, 0, 0);
    this.drawCouchBackrest(p);
    this.drawSeatCushions(p);
    this.drawBackCushions(p);

    p.pop();
  }

  drawCouchBase(p) {
    p.push();

    const baseColor = this.parseColor(this.colors.couchDark);
    const shadowColor = this.parseColor(this.colors.couchShadow);

    p.fill(baseColor[0], baseColor[1], baseColor[2]);
    p.translate(0, 20, 0);
    p.box(280, 20, 100);

    p.fill(shadowColor[0], shadowColor[1], shadowColor[2]);
    // Legs
    p.translate(-120, 20, -40);
    p.box(15, 30, 15);
    p.translate(240, 0, 0);
    p.box(15, 30, 15);
    p.translate(0, 0, 80);
    p.box(15, 30, 15);
    p.translate(-240, 0, 0);
    p.box(15, 30, 15);

    p.pop();
  }

  drawArmrest(p, x, y, z) {
    p.push();
    p.translate(x, y, z);

    const baseColor = this.parseColor(this.colors.couchBase);
    const lightColor = this.parseColor(this.colors.couchLight);
    const darkColor = this.parseColor(this.colors.couchDark);
    const cushionLightColor = this.parseColor(this.colors.cushionLight);
    const shadowColor = this.parseColor(this.colors.couchShadow);

    this.drawPixelCube(
      p,
      0,
      -10,
      0,
      40,
      60,
      80,
      baseColor,
      lightColor,
      darkColor
    );

    p.push();
    p.translate(0, -45, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      35,
      10,
      75,
      lightColor,
      cushionLightColor,
      baseColor
    );
    p.pop();

    p.push();
    p.translate(x > 0 ? 15 : -15, -20, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      10,
      40,
      70,
      darkColor,
      baseColor,
      shadowColor
    );
    p.pop();

    p.pop();
  }

  drawCouchBackrest(p) {
    p.push();
    p.translate(0, -30, -35);

    const baseColor = this.parseColor(this.colors.couchBase);
    const lightColor = this.parseColor(this.colors.couchLight);
    const darkColor = this.parseColor(this.colors.couchDark);
    const cushionLightColor = this.parseColor(this.colors.cushionLight);

    this.drawPixelCube(
      p,
      0,
      0,
      0,
      240,
      80,
      25,
      baseColor,
      lightColor,
      darkColor
    );

    p.push();
    p.translate(0, -45, 0);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      220,
      10,
      20,
      lightColor,
      cushionLightColor,
      baseColor
    );
    p.pop();

    p.pop();
  }

  drawSeatCushions(p) {
    const cushionColor = this.parseColor(this.colors.cushion);
    const cushionLightColor = this.parseColor(this.colors.cushionLight);
    const cushionDarkColor = this.parseColor(this.colors.cushionDark);

    // Left cushion
    p.push();
    p.translate(-60, -15, 10);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      100,
      25,
      70,
      cushionColor,
      cushionLightColor,
      cushionDarkColor
    );

    p.fill(cushionDarkColor[0], cushionDarkColor[1], cushionDarkColor[2]);
    p.translate(0, -15, 0);
    p.box(90, 2, 60);
    p.translate(0, 0, 25);
    p.box(90, 2, 10);
    p.translate(0, 0, -50);
    p.box(90, 2, 10);
    p.pop();

    // Right cushion
    p.push();
    p.translate(60, -15, 10);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      100,
      25,
      70,
      cushionColor,
      cushionLightColor,
      cushionDarkColor
    );

    p.fill(cushionDarkColor[0], cushionDarkColor[1], cushionDarkColor[2]);
    p.translate(0, -15, 0);
    p.box(90, 2, 60);
    p.translate(0, 0, 25);
    p.box(90, 2, 10);
    p.translate(0, 0, -50);
    p.box(90, 2, 10);
    p.pop();
  }

  drawBackCushions(p) {
    const cushionColor = this.parseColor(this.colors.cushion);
    const cushionLightColor = this.parseColor(this.colors.cushionLight);
    const cushionDarkColor = this.parseColor(this.colors.cushionDark);

    // Left back cushion
    p.push();
    p.translate(-60, -35, -25);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      90,
      50,
      15,
      cushionColor,
      cushionLightColor,
      cushionDarkColor
    );
    p.fill(cushionDarkColor[0], cushionDarkColor[1], cushionDarkColor[2]);
    p.translate(0, 0, 10);
    p.box(8, 8, 3);
    p.pop();

    // Right back cushion
    p.push();
    p.translate(60, -35, -25);
    this.drawPixelCube(
      p,
      0,
      0,
      0,
      90,
      50,
      15,
      cushionColor,
      cushionLightColor,
      cushionDarkColor
    );
    p.fill(cushionDarkColor[0], cushionDarkColor[1], cushionDarkColor[2]);
    p.translate(0, 0, 10);
    p.box(8, 8, 3);
    p.pop();
  }
}
