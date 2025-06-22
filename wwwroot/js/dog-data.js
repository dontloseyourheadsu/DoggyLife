// Dog sprite data
window.dogSprites = {
  // Paths to different dog sprites
  dogTypes: [
    "images/dogs/dog1.png", // White dog
    "images/dogs/dog2.png", // Beagle
    "images/dogs/dog3.png", // Brown dog
    "images/dogs/dog4.png", // Orange dog
  ],

  // Default dog type index
  currentDogType: 0,

  // Get current dog sprite path
  getCurrentDogSprite: function () {
    return this.dogTypes[this.currentDogType];
  },

  // Change to next dog type
  nextDogType: function () {
    this.currentDogType = (this.currentDogType + 1) % this.dogTypes.length;
    return this.getCurrentDogSprite();
  },
};
