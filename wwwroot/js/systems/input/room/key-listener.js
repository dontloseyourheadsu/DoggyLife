export class KeyListener {
  // Keeps track of key states
  keys = {};
  dogAI;
  
  listenKeysDown(p5Instance, dogAI) {
    this.dogAI = dogAI;
    p5Instance.canvas.addEventListener("keydown", (e) => {
      this.keys[e.key] = true;

      // One-time key actions
      switch (e.key) {
        case "t":
        case "T":
          // Toggle dog AI
          this.dogAI.toggle();
          break;
      }
    });
  }

  listenKeysUp(p5Instance) {
    p5Instance.canvas.addEventListener("keyup", (e) => {
      this.keys[e.key] = false;
    });
  }
}
