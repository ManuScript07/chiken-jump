
# Chiken Jump

A mobile game about jumping on shadows, made with **Godot**.

A rotating 3D structure casts shadows on a wall. Those shadows become the platforms you move and jump on. As the structure turns, the level changes shape.

Collect stars to keep the timer alive. You start with **20 seconds**, and each star adds **1.5 seconds**. Collect a whole wave to spawn more stars.

Falling off the level, getting crushed, or running out of time ends the run.

## Screenshots

<p align="center">
  <img
    src="https://github.com/user-attachments/assets/4db622a1-bc91-4d32-953d-c420ea0951bb"
    alt="Chiken Jump gameplay screenshot 1"
    width="260"
    height="463"
  />
  <img
    src="https://github.com/user-attachments/assets/29e24100-4f81-417b-835a-bc6c4f134ee6"
    alt="Chiken Jump gameplay screenshot 2"
    width="260"
    height="463"
  />
  <img
    src="https://github.com/user-attachments/assets/eb7c6510-425e-4c90-b88a-127e3caf7700"
    alt="Chiken Jump gameplay screenshot 3"
    width="260"
    height="463"
  />
</p>

## Run the project

1. Install **Godot 4.7.2**.
2. Import `project.godot`.
3. Press **F5** to start the game.

## Controls

### Mobile

Use the two direction buttons to move and the round jump button to jump. The pause button opens the menu.

### Desktop

| Action | Controls |
|--------|----------|
| Move left / right | **A / D** or **← / →** |
| Jump | **Space**, **W**, or **↑** |
| Pause | **Escape** |

In the pause menu, use left and right to change the selection, and jump to confirm.

## Android

The game uses a **portrait layout**.

See the [APK build instructions](docs/ANDROID_BUILD.md) to build it for Android.

## Change the level

Open `scenes/levels/reference_installation.tscn` in Godot to move, resize, or add figures.

### Configuration & documentation

- [Time limit and star bonus](scripts/run_session.gd)
- [Rotation speeds and star waves](scripts/wave_director.gd)
- [Level editing guide](docs/LEVEL_AUTHORING.md)
- [Development notes and tests](docs/DEVELOPMENT.md)

## Inspiration

The shadow mechanic was inspired by [this video](https://imginn.com/p/DeB5R7DhJjC/).
