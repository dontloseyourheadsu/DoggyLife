export class RoomRenderer {
    p5;
    tileSize;
    roomSize = 400;
    floorTiles = 8;

    roomBounds = {
      minX: -200,
      maxX: 200,
      minZ: -200,
      maxZ: 200,
      floorY: 200,
    };

    roomSettings = {
      // Room default colors
      floorLightColor: [220, 220, 220],
      floorDarkColor: [180, 180, 180],
      wallLightColor: [200, 150, 150],
      wallDarkColor: [160, 120, 120],
    };

    constructor(p5Instance, roomData, roomSize = 400) {
        this.p5 = p5Instance;
        this.roomSize = roomSize;

        this.setRoomColors(roomData);
        this.tileSize = this.roomSize / this.floorTiles;

        this.roomBounds = {
            minX: -this.roomSize / 2,
            maxX: this.roomSize / 2,
            minZ: -this.roomSize / 2,
            maxZ: this.roomSize / 2,
            floorY: this.roomSize / 2,
        };
    }

    /**
     * Sets the room colors based on the provided room data.
     * @param {*} roomData 
     */
    setRoomColors (roomData) {
      this.roomSettings.floorLightColor = this.convertColor(roomData.floorLightColor);
      this.roomSettings.floorDarkColor = this.convertColor(roomData.floorDarkColor);
      this.roomSettings.wallLightColor = this.convertColor(roomData.wallLightColor);
      this.roomSettings.wallDarkColor = this.convertColor(roomData.wallDarkColor);
    }

    /**
     * Converts a color string in the format 'R,G,B' to an array [r,g,b].
     * @param {*} colorString 
     * @returns {Array} An array containing the RGB values. 
     */
    convertColor(colorString) {
      // Color string expected in format 'R,G,B'
      const parts = colorString.split(",");
      return [
        parseInt(parts[0], 10),
        parseInt(parts[1], 10),
        parseInt(parts[2], 10),
      ];
    }

    drawRoom = function () {
      this.drawFloor();
      this.drawWalls();
    };

    drawFloor() {
      this.p5.push();
        
      this.p5.translate(0, this.roomSize / 2, 0); // Move floor down slightly

      for (let x = 0; x < this.floorTiles; x++) {
        for (let z = 0; z < this.floorTiles; z++) {
          this.p5.push();

          let posX = (x - this.floorTiles / 2 + 0.5) * this.tileSize;
          let posZ = (z - this.floorTiles / 2 + 0.5) * this.tileSize;
          this.p5.translate(posX, 0.5, posZ); // Add slight Y offset to avoid Z-fighting

          if ((x + z) % 2 === 0) {
            this.p5.fill(
              this.roomSettings.floorLightColor[0],
              this.roomSettings.floorLightColor[1],
              this.roomSettings.floorLightColor[2]
            );
          } else {
            this.p5.fill(
              this.roomSettings.floorDarkColor[0],
              this.roomSettings.floorDarkColor[1],
              this.roomSettings.floorDarkColor[2]
            );
          }

          this.p5.noStroke();
          this.p5.rotateX(this.p5.HALF_PI); // Rotate to lie flat
          this.p5.plane(this.tileSize, this.tileSize);

          this.p5.pop();
        }
      }

      this.p5.pop();
    };

    drawWalls() {
      this.drawBackWall();
      this.drawLeftWall();
    };

    drawBackWall() {
      this.p5.push();
      this.p5.translate(0, 0, -this.roomSize / 2);
      this.p5.rotateY(0); // Face forward

      let stripeWidth = 40;
      let numStripes = Math.ceil(this.roomSize / stripeWidth);

      for (let i = 0; i < numStripes; i++) {
        this.p5.push();

        let x = (i - numStripes / 2 + 0.5) * stripeWidth;
        this.p5.translate(x, 0, 0.5); // Slight offset to avoid overlap

        if (i % 2 === 0) {
          this.p5.fill(
            this.roomSettings.wallLightColor[0],
            this.roomSettings.wallLightColor[1],
            this.roomSettings.wallLightColor[2]
          );
        } else {
          this.p5.fill(
            this.roomSettings.wallDarkColor[0],
            this.roomSettings.wallDarkColor[1],
            this.roomSettings.wallDarkColor[2]
          );
        }

        this.p5.noStroke();
        this.p5.rotateY(this.p5.PI); // Ensure correct orientation
        this.p5.plane(stripeWidth, this.roomSize);

        this.p5.pop();
      }

      this.p5.pop();
    };

    drawLeftWall() {
      this.p5.push();
      this.p5.translate(-this.roomSize / 2, 0, 0);
      this.p5.rotateY(this.p5.HALF_PI); // Face inward like back wall

      let stripeWidth = 40;
      let numStripes = Math.ceil(this.roomSize / stripeWidth);

      for (let i = 0; i < numStripes; i++) {
        this.p5.push();

        let x = (i - numStripes / 2 + 0.5) * stripeWidth;
        this.p5.translate(x, 0, 0.5); // Slight forward offset

        if (i % 2 === 0) {
          this.p5.fill(
            this.roomSettings.wallLightColor[0],
            this.roomSettings.wallLightColor[1],
            this.roomSettings.wallLightColor[2]
          );
        } else {
          this.p5.fill(
            this.roomSettings.wallDarkColor[0],
            this.roomSettings.wallDarkColor[1],
            this.roomSettings.wallDarkColor[2]
          );
        }

        this.p5.noStroke();
        this.p5.plane(stripeWidth, this.roomSize);

        this.p5.pop();
      }

      this.p5.pop();
    };

}