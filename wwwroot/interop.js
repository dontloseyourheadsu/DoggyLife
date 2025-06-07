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
};

// Function to set up the resize event handler
window.setupResizeHandler = function (dotNetHelper) {
    window.addEventListener('resize', function() {
        // Get the window dimensions
        const width = window.innerWidth;
        const height = window.innerHeight;
        
        // Call the .NET method with the dimensions
        dotNetHelper.invokeMethodAsync('OnBrowserResize', width, height);
    });
};

// Function to get the current window size and call back to .NET
window.getWindowSize = function (dotNetHelper) {
    const width = window.innerWidth;
    const height = window.innerHeight;
    
    // Call the .NET method with the dimensions
    dotNetHelper.invokeMethodAsync('SetCanvasSize', width, height);
};