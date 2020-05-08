#!/usr/bin/env bash
#
# Description:
# Starts the docker server and runs two instances the demo project: one editor instance, and one
# game instance.

THIS_DIRECTORY=$(dirname "$0")

tmux new -s "nakama_godot" -d -n "Nakama Godot demo" docker-compose -f "$THIS_DIRECTORY"/docker-compose.yml up \; split-window -v godot "$THIS_DIRECTORY"/../godot/project.godot \; split-window -h godot --path "$THIS_DIRECTORY"/../godot \; attach
