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
