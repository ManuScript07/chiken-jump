# Chiken Jump

A mobile game about jumping on shadows, made with Godot.

A rotating 3D structure casts shadows on a wall. Those shadows become the platforms you move and jump on. As the structure turns, the level changes shape.

Collect stars to keep the timer alive. You start with 20 seconds, and each star adds 1.5 seconds. Collect a whole wave to spawn more stars. Falling off the level, getting crushed, or running out of time ends the run.

## Screenshots

<!-- Add screenshots here. -->

## Run the project

1. Install **Godot 4.7.2**.
2. Import `project.godot`.
3. Press **F5**.

## Controls

On a phone, use the two direction buttons and the round jump button. The pause button opens the menu.

On a computer, move with **A/D** or the arrow keys, jump with **Space**, **W**, or **Up**, and pause with **Escape**.

In the pause menu, left and right change the selection, and jump confirms it.

## Android

The game uses a portrait layout. See the [APK build instructions](docs/ANDROID_BUILD.md) to build it for Android.

## Change the level

Open `scenes/levels/reference_installation.tscn` in Godot to move, resize, or add figures.

- [Time limit and star bonus](scripts/run_session.gd)
- [Rotation speeds and star waves](scripts/wave_director.gd)
- [Level editing guide](docs/LEVEL_AUTHORING.md)
- [Development notes and tests](docs/DEVELOPMENT.md)

## Inspiration

The shadow mechanic was inspired by [this video](https://imginn.com/p/DeB5R7DhJjC/).
