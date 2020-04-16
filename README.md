# Nakama Godot Demo

This demo shows how to use [Nakama](https://heroiclabs.com/) with the [Nakama Godot client](https://github.com/heroiclabs/nakama-godot).

It features and showcases:

- Authentication, sessions, and disconnection.
- [Game storage](https://heroiclabs.com/docs/storage-collections/).
- Sockets and managing connections.
- [Real-time chat](https://heroiclabs.com/docs/social-realtime-chat/).
- In-app [notifications](https://heroiclabs.com/docs/social-in-app-notifications/) with popups.
- Character color customization.
- Platforming mechanics, an area where players can jump and interact with one another.

## Testing the project

To test the project, you need first to install the server and get it running, then run two instances of Godot.

To install and start the server:

1. Install Docker.
   - [On Windows](https://docs.docker.com/docker-for-windows/install/).
   - [On Mac](https://docs.docker.com/docker-for-mac/install/).
   - [On Ubuntu](https://docs.docker.com/engine/install/ubuntu/): `sudo apt install docker docker-compose`.
1. Open your terminal and navigate to the `nakama/` directory.
1. Run the command `docker-compose -f docker-compose.yml up` or run `boot.bat` in Windows.

Docker should automatically download, then install Nakama and CockroachDB for you before starting the local server. The server should emit the message "Startup done".

Then, to test the project in Godot, you need to open or run the project in two separate instances.

### Registering and logging in

To log into the game, you need first to register a dummy local account. To do so, on the initial game screen:

1. Click on the "register" button.
2. Enter any email and password.
   - The email doesn't need to exist, but it needs to be of the form `email@domain.extension`. For example, `test@test.com` would work.
   - The password needs to contain at least 8 characters.

Once you registered an account, you can log in, create a new character, and enter the game.

## Using the Nakama admin area

Nakama's server provides a web admin interface to see, modify, or purge users and other game data. To access it:

1. Start the Nakama server.
1. Navigate to http://127.0.0.1:7351/ in your web browser.
1. Log into the platform. The default admin user's login is `admin` and its password is `password`.
