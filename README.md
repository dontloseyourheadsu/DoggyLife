# DoggyLife

DoggyLife is a charming pet caring simulation game developed using the Godot Engine. Players can adopt a dog, interact with it in a customizable room, and play exciting minigames to earn rewards.

## 🎮 Play Online

You can play the latest web build of the game here:
**[https://doggylife.netlify.app/](https://doggylife.netlify.app/)**

## 📂 Project Structure

The repository is organized into source assets and the Godot project itself.

### Root Directory
- **aseprite/**: Contains the source `.aseprite` files for pixel art assets (characters, decorations, UI).
- **DoggyLifeGodot/**: The main Godot 4 project folder.

### Godot Project (`DoggyLifeGodot/`)
The game logic and assets are structured as follows:

- **scenes/**: The core gameplay scenes.
  - **room/**: The main hub where the player interacts with the dog and manages decorations.
  - **catch-the-ball/**: A minigame where the dog plays fetch.
  - **fish-capture/**: A fishing minigame.
  - **menus/**: UI scenes for main menu, settings, etc.
- **shared/**: Reusable components and scenes used across different parts of the game.
- **storage/**: Scripts managing persistent data (`player_data.gd`) and global settings (`global_settings.gd`).
- **sprites/**: Exported image assets used in the game.
- **ui/**: User interface elements like buttons and icons.
- **music/** & **fonts/**: Audio and typography assets.

## 🌟 Features

- **Pet Interaction**: Take care of your virtual dog.
- **Minigames**:
  - **Catch the Ball**: A timing-based game to play fetch.
  - **Fish Capture**: A fishing activity to gather resources.
- **Room Customization**: Decorate the dog's room with various items.
- **Economy**: Earn coins and points through gameplay to unlock new items.

## 🛠️ Development

This project is built with **Godot 4**. To edit the project:
1. Import the `DoggyLifeGodot/project.godot` file into the Godot Editor.
2. The main entry point is typically the Main Menu scene or the Room scene.
