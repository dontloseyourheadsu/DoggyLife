/**
 * Changes the currently playing music track.
 * @param {*} track 
 */
function changeTrack(track) {
    let audio = document.getElementById("audio-tag");
    audio.src = "music/" + track + ".mp3";
    audio.play();
}

/**
 * Mutes the audio element if it exists.
 */
function muteAudio() {
    let audio = document.getElementById("audio-tag");
    if (audio) {
        audio.muted = true;
        console.log("Audio muted");
    } else {
        console.log("Audio element not found");
    }
};

/** 
 * Unmutes the audio element and plays it if it was paused.
 */
function unmuteAudio() {
    let audio = document.getElementById("audio-tag");
  
    // Check if the audio element exists
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