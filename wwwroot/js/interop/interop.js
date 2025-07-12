// Helper functions for the dog animation system
window.getP5DogState = function () {
  if (window.P5DogAnimation) {
    const dog = window.P5DogAnimation.getDog("main");
    if (dog) {
      return {
        state: dog.currentState,
        position: {
          x: dog.x,
          y: dog.y,
          z: dog.z,
        },
        scale: dog.scale,
        frame: dog.currentFrame,
      };
    }
  }
  return null;
};

// Initialize dog animation system
window.initializeDogAnimation = function () {
  // This function can be called from C# to ensure the dog animation system is loaded
  if (!window.P5DogAnimation) {
    const script = document.createElement("script");
    script.src = "js/p5-dog-animation.js";
    document.head.appendChild(script);
    return new Promise((resolve) => {
      script.onload = () => resolve(true);
    });
  }
  return Promise.resolve(true);
};
