function playMusic() {
  var audio = document.getElementById("audio-tag");
  audio.play();
}

function changeTrack(track) {
  var audio = document.getElementById("audio-tag");
  audio.src = "music/" + track + ".mp3";
  audio.play();
}

function getBoundingClientRect(element) {
  return element.getBoundingClientRect();
}

// Function to set up the resize event handler
window.setupResizeHandler = function (dotNetHelper) {
  window.addEventListener("resize", function () {
    // Get the window dimensions
    const width = window.innerWidth;
    const height = window.innerHeight;

    // Call the .NET method with the dimensions
    dotNetHelper.invokeMethodAsync("OnBrowserResize", width, height);
  });
};

// Function to get the current window size and call back to .NET
window.getWindowSize = function (dotNetHelper) {
  const width = window.innerWidth;
  const height = window.innerHeight;

  // Call the .NET method with the dimensions
  dotNetHelper.invokeMethodAsync("SetCanvasSize", width, height);
};

// Audio control functions
window.muteAudio = function () {
  var audio = document.getElementById("audio-tag");
  if (audio) {
    audio.muted = true;
    console.log("Audio muted");
  } else {
    console.log("Audio element not found");
  }
};

window.unmuteAudio = function () {
  var audio = document.getElementById("audio-tag");
  if (audio) {
    audio.muted = false;
    // If audio was paused, also play it
    if (audio.paused) {
      audio.play().catch((err) => console.log("Error playing audio:", err));
    }
    console.log("Audio unmuted");
  } else {
    console.log("Audio element not found");
  }
};

window.isAudioMuted = function () {
  var audio = document.getElementById("audio-tag");
  return audio ? audio.muted : true;
};

// P5.js rendering integration functions
let dotNetRef = null;

// Initialize DotNet reference for callbacks from JS to C#
window.initializeP5DotNetReference = function (reference) {
  dotNetRef = reference;
  console.log("DotNet reference initialized for p5.js");
};

// Create p5.js canvas in the specified container
window.initializeP5Canvas = function (containerId, width, height) {
  // First include p5-renderer.js script if not already loaded
  if (!window.createP5RoomRenderer) {
    console.log("Loading p5-renderer.js script");
    const script = document.createElement("script");
    script.src = "js/p5-renderer.js";
    script.onload = function () {
      window.createP5RoomRenderer(containerId, width, height);
    };
    document.head.appendChild(script);
  } else {
    window.createP5RoomRenderer(containerId, width, height);
  }
};

// Request room data from C#
window.requestRoomData = async function () {
  if (dotNetRef) {
    try {
      const roomData = await dotNetRef.invokeMethodAsync("GetRoomDataForP5");
      window.updateRoomSettings(roomData);
      return true;
    } catch (err) {
      console.error("Error requesting room data:", err);
      return false;
    }
  }
  return false;
};

// Update room settings from C#
window.updateRoomSettings = function (roomData) {
  if (window.updateRoomColors) {
    window.updateRoomColors(
      roomData.floorLightColor,
      roomData.floorDarkColor,
      roomData.wallLightColor,
      roomData.wallDarkColor
    );
  }
};
