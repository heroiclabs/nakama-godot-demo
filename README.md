# Nakama Godot Client demo

A small multiplayer platformer area where players can jump around and chat.

## Starting the server

1. Install Docker
2. Browse to ./nakama/
3. Run the command `docker-compose -f docker-compose.yml up` (run boot.bat in windows)

Nakama and CockroachDB should be auto-installed and the server started. The message 'Startup done' should be emitted by the server.

## Godot

Run the default scene/LoginAndRegister.tscn scene.

Register and create a new character.