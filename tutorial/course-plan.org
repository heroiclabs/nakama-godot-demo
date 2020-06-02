#+TITLE: Course planning

Plan for the tutorial series based on the demo.

* The project

This section covers basic information about the project.

** Requirements

*** Audience

*Developers* who use Godot but are not familiar with Nakama, and who have little-to-no experience with networking.

*** Difficulty

*Intermediate*. Coding network games requires some solid programming foundation.

*** Pre-requisites

- Being comfortable with GDScript code.
- Being comfortable using the editor.
- Good programming foundations, being comfortable with the concepts of classes, objects, loops, etc.

*** Cover the following Nakama features

1. [[https://heroiclabs.com/docs/godot1.client1.guide/#sessions][Authentication]] and Session tokens
   + Connecting.
   + Staying authenticated.
   + Disconnecting.
2. Basic [[https://heroiclabs.com/docs/storage1.collections/][game storage]]
3. Explain the difference between the client object and the socket object
4. Sockets, and how to manage the connection
5. Socket API features
   + Real-time [[https://heroiclabs.com/docs/social-realtime-chat/][chat]]
   + In-app [[https://heroiclabs.com/docs/social-in-app-notifications/][notifications]]

Cover the features through these parts of the demo:

1. Authentication
   + Log in screen.
   + Create account screen.
   + Entering and leaving the character selection screen.
2. Game storage
   + Storing and retrieving data: Creating a character, storing their name, color.
   + Changing data:
3. Basic storage: The server remembers the user's selected character, name, and
  last location.
4. Notifications indicate when other players join or leave the room.
5. The users can chat via an on-screen chat box inspired by MMO games.

** Teaching style

Each tutorial first covers the basics of a feature, then, it shows how the works in the context of the complete game demo.

The learners can also access all presented code snippets in the documentation.

We use optional type hints in the code for better error reporting.

*** The basics

The first part shows the simplest code to use the feature, step-by-step, in a dedicated file. The user doesn't have to download any starting project and can type along.

For example, here would be the first step for authentication: starting with the bare minimum, without handling errors.

#+BEGIN_SRC gdscript
var session: NakamaSession

var _client := Nakama.create_client(KEY, "127.0.0.1", 7350, "http")


func authenticate_async(email: String, password: String) -> int:
	session = yield(
		_client.authenticate_email_async(email, password, email, true), "completed"
	)
#+END_SRC

For the other steps, see [[*Authentication][Authentication]]

*** In context.

* Topics

[[file:../docs/packets.md::Packets and storage data structures][Packets reference]]

** Resources

Head to the [[https://heroiclabs.com/docs/][Nakama Documentation]] for detailed examples on how to use Nakama. As a Godot user, you want to look at the [[https://heroiclabs.com/docs/godot-client-guide/][Godot Client Guide]], and at all pages starting from [[https://heroiclabs.com/docs/authentication/][Authentication]]. All the code examples have a /Godot/ tab to see them in GDScript.

The [[https://heroiclabs.com/docs/runtime-code-basics/][Runtime Code]] section of the documentation focuses on server-side code, written in either lua or go.

The full Nakama Godot client code has docstring or doc-comments. You can *Ctrl* *Click* any method from Nakama in the Godot script editor to jump to its source code and read its documentation.

** Installing and setting up Nakama with Godot

Text instructions are here: https://heroiclabs.com/docs/install-docker-quickstart/

This lesson is a guide to get you started using Nakama as soon as possible using [[https://www.docker.com/][docker]] and docker-compose.

What is docker? From the Nakama documentation:

#+begin_quote
Docker is an open source containerization tool that lets you create multiple distinct Linux environments, each separate from the other.

In a Docker container you run a suite of tools to do a particular job; in this case we’ll have one container running Nakama and another running CockroachDB. You can think of Docker containers as lightweight virtual machines.
#+end_quote

*** Installing docker and docker-compose

On Ubuntu:

#+BEGIN_EXAMPLE sh
sudo apt install docker.io docker-compose
#+END_EXAMPLE

For Windows 10 Pro and Mac, you can install docker desktop: https://www.docker.com/get-started

*** Setting up Nakama with docker

 https://heroiclabs.com/docs/install-docker-quickstart/


Create a directory named ~nakama/~ and add a ~docker-compose.yml~ file in it: https://heroiclabs.com/docs/install-docker-quickstart/#running-nakama-with-docker-compose

Set the unique server key in Nakama: [[file:../nakama/docker-compose.yml::exec /nakama/nakama --name nakama1 --database.address root@cockroachdb:26257 --socket.server_key "nakama_godot_demo"][docker-compose.yml: server_key]]

Run ~docker-compose up~ in the directory containing the ~docker-compose.yml~ file. The first time you do so, docker will download images for the database cockroachdb, the nakama server, and boot them both.

Once you read a message looking like this, the nakama server is up:

#+begin_example sh
nakama         | {"level":"info","ts":"2020-05-11T20:45:53.793Z","msg":"Startup done"}
#+end_example

You should now be able to access the Nakama admin interface:

- Open a web browser.
- In the address bar, enter ~http://127.0.0.1:7351/~, the default address of the interface when running the server locally.
- Enter the default credentials to log in:
  + username: ~admin~
  + password: ~password~

*** Getting started with Godot

Create a new Godot project.

Download the Nakama client from the [[https://github.com/heroiclabs/nakama-godot/releases][GitHub releases]] or the asset library.

Register Nakama.gd as an autoload.

** Authentication

*** Resources

- [[file:../godot/src/Autoload/ServerConnection.gd::func register_async(email: String, password: String) -> int:][Authentication methods]]
- [[file:../godot/src/Autoload/Delegates/Authenticator.gd::Delegate class that handles logging in and registering accounts. Holds the][Authenticator]]
- For UI and front-end: see the login and register forms

*** The basics

**** Minimal example

Create a new script ~ServerConnection.gd~ and register it as an /Autoload/ in the /Project Settings -> Autoload/ tab.

Authenticates a user with an email and a password. If the credentials don't exist, creates an account for the player. Uses the player's email address as their username.

Note the KEY constant here: it must match the key you wrote in your docker-compose.yml file.

#+BEGIN_EXAMPLE gdscript
const KEY := "nakama_godot_demo"

var session: NakamaSession

var _client := Nakama.create_client(KEY, "127.0.0.1", 7350, "http")


func authenticate_async(email: String, password: String) -> int:
	session = yield(
		_client.authenticate_email_async(email, password, email, true), "completed"
	)
#+END_EXAMPLE

*** Authenticating and creating new accounts automatically

We can expand on the same code to check for errors. If the authenticate request worked, we can assign the ~new_session~ to the ~_session~.

#+BEGIN_EXAMPLE gdscript
const KEY := "nakama_godot_demo"

var _session: NakamaSession
var _client := Nakama.create_client(KEY, "127.0.0.1", 7350, "http")


func authenticate_async(email: String, password: String) -> int:
	var result := OK
	var new_session: NakamaSession = yield(
		_client.authenticate_email_async(email, password, email, true), "completed"
	)
	if not new_session.is_exception():
		_session = new_session
	else:
		result = new_session.get_exception().status_code
	return result
#+END_EXAMPLE

You can test that code like so:

#+BEGIN_EXAMPLE gdscript
func request_authentication() -> void:
	var email := "test@test.com"
	var password := "password"

	print_debug("Authenticating user %s." % email)
	var result: int = yield(server_connection.authenticate_async(email, password), "completed")

	if result == OK:
		print_debug("Authenticated user %s successfully." % email)
	else:
		print_debug("Could not authenticate user %s." % email)
#+END_EXAMPLE


*** In context

**** Resources

Show the RegisterForm, LoginForm, and their callbacks in MainMenu:

- [[file:~/Repositories/nakama-godot-demo/godot/src/Main/MainMenu.gd::func _on_LoginAndRegister_login_pressed(email: String, password: String, do_remember_email: bool) -> void:][_on_LoginAndRegister_login_pressed()]]
- [[file:~/Repositories/nakama-godot-demo/godot/src/Main/MainMenu.gd::func authenticate_user_async(email: String, password: String, do_remember_email := false) -> int:][MainMenu.authenticate_user_async()]]

**** Using a helper class to handle errors

Show the [[file:~/Repositories/nakama-godot-demo/godot/src/Autoload/Delegates/ExceptionHandler.gd::class_name ExceptionHandler][ExceptionHandler]].

Any request to the server may fail, so you want to handle errors. In the final demo project, we creates an ~ExceptionHandler~ helper class to process exceptions in server requests. The class converts the exception into an integer that represents an error codes, like the global constant ~ERR_CONNECTION_ERROR~.

The ~ExceptionHandler.parse_exception()~ method returns the value of the ~OK~ constant if the request worked. Otherwise, it stores an error message in its ~error_message~ property. You can use it to display an error to the user.

**** Overview of LoginAndRegister in the demo

Run through how the ~MainMenu~'s code structure with ~LoginAndRegister~. The interface only emits signals to which ~MainMenu~ connects.

Below is the authentication logic.  adds a loop that attempts to authenticate up to three times

#+BEGIN_EXAMPLE gdscript
# MainMenu.gd
const MAX_REQUEST_ATTEMPTS := 3
var _server_request_attempts := 0


func authenticate_user(email: String, password: String, do_remember_email := false) -> int:
	var result := -1

	login_and_register.is_enabled = false
	while result != OK:
		if _server_request_attempts == MAX_REQUEST_ATTEMPTS:
			break
		_server_request_attempts += 1
		result = yield(ServerConnection.login_async(email, password), "completed")

	if result == OK:
		if do_remember_email:
			ServerConnection.save_email(email)
		open_character_menu()
	else:
		login_and_register.status = "Error code %s: %s" % [result, ServerConnection.error_message]
		login_and_register.is_enabled = true

	_server_request_attempts = 0
	return result
#+END_EXAMPLE

Here's the code to remember the user's email in ~ServerConnection~. It's stored locally in a ~.ini~ file.

#+BEGIN_EXAMPLE gdscript
# ServerConnection
func save_email(email: String) -> void:
	EmailConfigWorker.save_email(email)


class EmailConfigWorker:
	const CONFIG := "user://config.ini"

	# Saves the email to the config file.
	static func save_email(email: String) -> void:
		var file := ConfigFile.new()
		file.load(CONFIG)
		file.set_value("connection", "last_email", email)
		file.save(CONFIG)
#+END_EXAMPLE

**** Storing and reusing the user's auth token

Storing the auth token on the user's computer to restore session. For more information, see: [[file:../godot/src/Autoload/Delegates/Authenticator.gd][Authenticator.SessionFileWorker]]

#+BEGIN_EXAMPLE gdscript
class SessionFileWorker:
	const AUTH := "user://auth"

	static func write_auth_token(email: String, token: String, password: String) -> void:
		var file := File.new()

		#warning-ignore: return_value_discarded
		file.open_encrypted_with_pass(AUTH, File.WRITE, password)

		file.store_line(email)
		file.store_line(token)

		file.close()

	static func recover_session_token(email: String, password: String) -> String:
		var file := File.new()
		var error := file.open_encrypted_with_pass(AUTH, File.READ, password)

		if error == OK:
			var auth_email := file.get_line()
			var auth_token := file.get_line()
			file.close()

			if auth_email == email:
				return auth_token

		return ""
#+END_EXAMPLE

Using the ~SessionFileWorker~ to store and recover the auth token.

#+BEGIN_EXAMPLE gdscript
func login_async(email: String, password: String) -> int:
	var token := SessionFileWorker.recover_session_token(email, password)
	if token != "":
		var new_session: NakamaSession = _client.restore_session(token)
		if new_session.valid and not new_session.expired:
			session = new_session
			yield(Engine.get_main_loop(), "idle_frame")
			return OK

	# If previous session is unavailable, invalid or expired
	var new_session: NakamaSession = yield(
		_client.authenticate_email_async(email, password, null, false), "completed"
	)
	var parsed_result := _exception_handler.parse_exception(new_session)
	if parsed_result == OK:
		session = new_session
		SessionFileWorker.write_auth_token(email, session.token, password)

	return parsed_result
#+END_EXAMPLE

**** About coroutines

All functions named ~*_async~ are coroutines in our project. Coroutines are routines (functions) that can co-operate, passing control to one another. In other words, coroutines allow you to pause functions in the middle of their execution and wait for others to return control to them.

We don’t have a keyword like ~await~ or promises yet in GDScript. In case you've never used these features in other languages, promises allow you to have a proxy object to keep moving forward with your code even if you didn't get the resulting value from a long computation or while you’re waiting for data from a server.

In GDScript, using the yield keyword returns a ~GDScriptFunctionState~ object that stores information about the executed function. It provides a method to resume the function’s execution and a ~completed~ signal that tells you when the function returned. This is why we can ~yield~ on a function call and wait for the ~completed~ signal to be emitted. It is the completed signal of the newly created ~GDScriptFunctionState~ object.

For more information, read [[https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html#coroutines-with-yield][Coroutines with yield]] in the Godot documentation.

** Creating and connecting to a socket using a session (connect to server async)

*** Resources

[[file:../godot/src/Autoload/ServerConnection.gd::func connect_to_server_async() -> int:][Live server connection (connecting to a socket)]]

*** The basics

The snippets below and following examples build upon previous ones.

To connect to the server, we have to first request Nakama to create a socket. A socket is a communication link between the client and the server. It's an end-point that allows the server and the client to communicate with one-another.

We create the socket from our previously-created client object. Then, we connect to the server using the socket.

As with any client-server communication, the sockets' methods are coroutines, and they return a result from the request.

#+BEGIN_EXAMPLE gdscript
var _socket: NakamaSocket


func connect_to_server_async() -> void:
	# Create and store a socket from the client object.
	_socket = Nakama.create_socket_from(_client)

	# Try to connect to the running Nakama server through the socket.
	var result: NakamaAsyncResult = yield(
		_socket.connect_async(_session), "completed"
	)
#+END_EXAMPLE

The ~NakamaSocket~ has some signals to which you can connect. They allow you to receive messages, new connections, and to handle errors:

#+BEGIN_EXAMPLE gdscript
func connect_to_server_async() -> void:
	_socket = Nakama.create_socket_from(_client)

	var result: NakamaAsyncResult = yield(
		_socket.connect_async(_session), "completed"
	)
	if not result.is_exception():
		_socket.connect("connected", self, "_on_NakamaSocket_connected")
		_socket.connect("closed", self, "_on_NakamaSocket_closed")
		_socket.connect("received_error", self, "_on_NakamaSocket_received_error")
		_socket.connect("received_match_presence", self, "_on_NakamaSocket_received_match_presence")
		_socket.connect("received_match_state", self, "_on_NakamaSocket_received_match_state")
		_socket.connect("received_channel_message", self, "_on_NamakaSocket_received_channel_message")
#+END_EXAMPLE

For example, when the socket closed, you can free the object. The ~NakamaSocket~ class extends ~Reference~. Instances of this class are automatically freed when there's no reference to them:

#+BEGIN_EXAMPLE gdscript
func connect_to_server_async() -> int:
# ...
	if not result.is_exception():
		_socket.connect("closed", self, "_on_NakamaSocket_closed")
# ...


func _on_NakamaSocket_closed() -> void:
	_socket = null
#+END_EXAMPLE

*** In context

See the log out button in [[../godot/src/UI/Menus/Characters/CharacterMenu.tscn][CharacterMenu]] and socket callbacks in ~ServerConnection~. See [[file:../godot/src/Autoload/ServerConnection.gd::func _on_NakamaSocket_connected() -> void:][ServerConnection's socket callbacks]].

Note: when you close Godot, the Nakama client data cleans up by itself, closing the connection with the server.

** Responding to successful connection: joining a game match

This tutorial builds upon the previous two.

It shows how to create a match on the game server and let players join it. You can also allow clients to create a new match and to host it, allowing other clients to join it. This is the example shown in the documentation. We chose to show you how to do it with an authoritative server.

https://heroiclabs.com/docs/gameplay-multiplayer-realtime/

*** Resources

- [[file:../godot/src/Autoload/ServerConnection.gd::func join_world_async() -> void:][Joining the world]]
- [[file:../nakama/modules/world_rpc.lua::local function get_world_id(_, _)][Nakama server's get_world_id() RPC]]

*** The basics

Joining a game world involves code both on the client and on the server through a Remote Procedure Call (RPC).

Remote Procedure Calls are procedures (functions) exposed from the server to the client, and that the client can call remotely. They are generally requests for the server to do something specific or to provide the client with some information, outside of the game loop.

The exact code you need in your game depends on the way you implement your server's game logic. Our example only contains one world or level created on the server that players can join. But even so, our server code builds the foundation for having a list of worlds, each world being any place, big or small, where players can interact. For example, a world could be a dungeon instance in an MMORPG, a large open world with hundreds of players, a team match in a First-Person Shooter, or a lobby where players wait together.

Creating and joining worlds, or matches in Nakama's terminology, is done through the [[https://heroiclabs.com/docs/gameplay-multiplayer-realtime/][realtime-multiplayer API]].

To join a world, we first ask the server to give us a world's ID through an RPC:

#+BEGIN_EXAMPLE gdscript
# The properties come from previous tutorials.
var _session: NakamaSession

var _client := Nakama.create_client(KEY, "127.0.0.1", 7350, "http")
var _socket: NakamaSocket


func join_world_async() -> void:
	var world: NakamaAPI.ApiRpc = yield(
		_client.rpc_async(_session, "get_world_id", ""), "completed"
	)
#+END_EXAMPLE

The ~rpc_async()~ method of the ~NakamaClient~ called a registered function on the server, here named ~get_world_id~ and that doesn't take any parameter.

We define that function in one of our server's module. You can do so in go or lua, we chose lua. See [[../nakama/modules/world_rpc.lua]]

The first argument of the ~nakama.match_create~ below refers to a lua module the server uses to manage the match. In this case, it's ~world_control~, from the file [[file:../nakama/modules/world_control.lua::-- Module that controls the game world. The world's state is updated every `tickrate` in the][world_control.lua]]. That module has special functions that define our game's main loop. Nakama recognizes them automatically from their name and hooks onto them. They're like the ~_ready()~, ~_process()~, etc. of Godot.

#+BEGIN_EXAMPLE lua
local nakama = require("nakama")

-- Returns the first existing match in namaka's match list or creates one if there is none.
local function get_world_id(_, _)
    local matches = nakama.match_list()
    local current_match = matches[1]

    if current_match == nil then
        return nakama.match_create("world_control", {})
    else
        return current_match.match_id
    end
end

nakama.register_rpc(get_world_id, "get_world_id")
#+END_EXAMPLE

The function gets the current match list from nakama and extracts the first one. If it is ~nil~ we create a new match, otherwise, we return the existing match ID. So in this example, you can only create and join one match. To have multiple matches in parallel, you would work with the match list.

For more information on running code on the server, see the runtime code documentation: https://heroiclabs.com/docs/runtime-code-basics/

To have an authoritative server managing matches, you need to implement specific functions defined in the Match Handler API: https://heroiclabs.com/docs/gameplay-multiplayer-server-multiplayer/#match-handler-api

Handling errors.

#+BEGIN_EXAMPLE gdscript
var _world_id: String setget _no_set
# Lists other clients present in the game world we connect to.
var _presences := {} setget _no_set


func join_world_async() -> void:
	var world: NakamaAPI.ApiRpc = yield(
		_client.rpc_async(_authenticator.session, "get_world_id", ""), "completed"
	)

	if not world.is_exception():
		_world_id = world.payload
#+END_EXAMPLE

Joining the world created by the server.

#+BEGIN_EXAMPLE gdscript
func join_world_async() -> void:
# ...

	# Requesting to join the match through the NakamaSocket API
	var match_join_result: NakamaRTAPI.Match = yield(
		_socket.join_match_async(_world_id), "completed"
	)
	# If the request worked, we get a list of presences, that is to say, a list of clients in that
	# match.
	if not match_join_result.is_exception():
		for presence in match_join_result.presences:
			_presences[presence.user_id] = presence
#+END_EXAMPLE

*** In context

See the transition from the CharacterMenu to MainMenu. For each presence in the ~presences~ dictionary, we create a character and use signals to update it when we get new information from the server:

- [[file:../godot/src/Autoload/ServerConnection.gd::func _on_NakamaSocket_received_match_presence(new_presences: NakamaRTAPI.MatchPresenceEvent) -> void:][ServerConnection._on_NakamaSocket_presences_changed]]
- [[file:../godot/src/Main/GameWorld.gd::func join_world(][Joining the game world in GameWorld.gd]]
- [[file:../godot/src/Main/GameWorld.gd::func _on_ServerConnection_presences_changed() -> void:][GameWorld._on_ServerConnection_presences_changed]]


** Storing data from client, storing data from server

- See functions that use the ~_storage_worker~ delegate class in ~ServerConnection~, for example: [[file:../godot/src/Autoload/ServerConnection.gd::func store_last_player_character_async(name: String, color: Color) -> int:][Store last player character]]
- Also see [[file:../godot/src/Autoload/Delegates/StorageWorker.gd::Class that ServerConnection delegates work to. Stores and fetches data in and out][StorageWorker]]

*** The basics

To read or write data to the Nakama storage, you need to use the ~NakamaClient~ API. ~write_storage_objects_async()~ takes your session and a list of ~NakamaWriteStorageObject~ objects. Each object is part of a collection and writes to a given key, each a string identifier. You can specify read and write permissions, and finally pass the data as a serialized JSON string, and an optional version number.

#+BEGIN_EXAMPLE gdscript
# Nakama read permissions
enum ReadPermissions { NO_READ, OWNER_READ, PUBLIC_READ }
# Nakama write permissions
enum WritePermissions { NO_WRITE, OWNER_WRITE }

func write_characters_async(characters := []) -> void:
	yield(
		_client.write_storage_objects_async(
			_session,
			[
				NakamaWriteStorageObject.new(
					"player_data",
					"characters",
					ReadPermissions.OWNER_READ,
					WritePermissions.OWNER_WRITE,
					JSON.print({characters = characters}),
					""
				)
			]
		),
		"completed"
	)

#+END_EXAMPLE

You can use the version number to update a player's data in new game releases and ensure backwards compatibility.

To read data, there's a method named ~read_storage_objects_async~ that takes your session and an array of ~NakamaStorageObjectId~ objects as arguments. It returns ~ApiStorageObjects~ , a container for data serialized as JSON, results over which you can loop and extract data.

#+BEGIN_EXAMPLE gdscript
func get_characters_async() -> Array:
	var characters := []
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(
		_client.read_storage_objects_async(
			_session, [NakamaStorageObjectId.new("player_data", "characters", _session.user_id)]
		),
		"completed"
	)

	#...
	return characters
#+END_EXAMPLE

Here's how to decode storage objects. The ~storage_objects.objects~ below is an array of JSON strings. We use ~JSON.parse~ to parse them.

As we define the data stored on the server ourselves, the way you will parse or process it depends entirely on your game.

#+BEGIN_EXAMPLE gdscript
func get_characters_async() -> Array:
	var characters := []
	# ...
	if storage_objects.objects:
		var decoded: Array = JSON.parse(storage_objects.objects[0].value).result.characters
		for character in decoded:
			var name: String = character.name
			characters.append(
				{ name = name, color = Converter.color_string_to_color(character.color) }
			)
	return characters
#+END_EXAMPLE

*** In context

In the demo, we use a delegate class, [[file:../godot/src/Autoload/Delegates/StorageWorker.gd::Class that ServerConnection delegates work to. Stores and fetches data in and out][StorageWorker]]. This is to keep the storage-related code grouped together in a single file. In the demo, it's still a small class, but it's one that's bound to grow a lot in a complete game project. It also has a clear responsibility: work with the server's storage, requesting read and write operations.

Writing example.

#+BEGIN_EXAMPLE gdscript
func _write_player_characters_async(characters: Array) -> void:
	var result: NakamaAPI.ApiStorageObjectAcks = yield(
		_client.write_storage_objects_async(
			_session,
			[
				NakamaWriteStorageObject.new(
					COLLECTION,
					KEY_CHARACTERS,
					ReadPermissions.OWNER_READ,
					WritePermissions.OWNER_WRITE,
					JSON.print({characters = characters}),
					""
				)
			]
		),
		"completed"
	)
#+END_EXAMPLE

Reading example.

#+BEGIN_EXAMPLE gdscript
func get_player_characters_async() -> Array:
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(
		_client.read_storage_objects_async(
			_session, [NakamaStorageObjectId.new(COLLECTION, KEY_CHARACTERS, _session.user_id)]
		),
		"completed"
	)

	if storage_objects.is_exception():
		return []

	var characters := []
	if storage_objects.objects.size() > 0:
		var decoded: Array = JSON.parse(storage_objects.objects[0].value).result.characters
		for character in decoded:
			var name: String = character.name
			characters.append({name = character.name, color = character.color})
	return characters
#+END_EXAMPLE


** Sending/receiving messages, and joining/responding in chat

Joining the chat happens in ~ServerConnection.join_world_async()~ in our game.

All the send_ methods and _received signals and their callbacks

*** The basics

To join a chat room you can call ~NakamaSocket.join_chat_async()~. It takes the id of the socket as a string as its first argument, followed by a channel type from the ~NakamaSocket.ChannelType~ enum.

The last two arguments are optional. In the call below, they respectively tell the server to not store messages and to not hide the user.

#+begin_example gdscript
var chat_join_result: NakamaRTAPI.Channel = yield(
	_socket.join_chat_async("world", NakamaSocket.ChannelType.Room, false, false),
	"completed"
)
#+end_example

If the request succeeds, ~chat_join_result.id~ gives you the joined chat channel's unique id, which you need to send chat messages. You can store it in a variable.

To write a message to the chat, call ~NakamaSocket.write_chat_message_async()~. The chat message should be in a dictionary with a ~"msg"~ key. The ~write_chat_message_async()~ method converts it to JSON.

#+begin_example gdscript
func send_text_async(text: String) -> void:
	var data := {"msg": text}
	var message_response: NakamaRTAPI.ChannelMessageAck = yield(
		_socket.write_chat_message_async(_channel_id, data), "completed"
	)
#+end_example

Other clients need to listen to new messages. You can do so by connecting to the ~NakamaSocket.received_channel_message~ signal.

#+begin_example gdscript
signal chat_message_received(sender_id, message)


func _on_NamakaSocket_received_channel_message(message: NakamaAPI.ApiChannelMessage) -> void:
	var content: Dictionary = JSON.parse(message.content).result
	emit_signal("chat_message_received", message.sender_id, content.msg)
#+end_example

*** In context

- [[file:../godot/src/Autoload/ServerConnection.gd::func send_text_async(text: String) -> int:][ServerConnection.send_text_async()]]
- [[file:../godot/src/Autoload/ServerConnection.gd::func _on_NamakaSocket_received_channel_message(message: NakamaAPI.ApiChannelMessage) -> void:][ServerConnection._on_NamakaSocket_received_channel_message()]]
- [[file:../godot/src/Main/GameWorld.gd::func _on_ServerConnection_chat_message_received(sender_id: String, message: String) -> void:][GameWorld._on_ServerConnection_chat_message_received()]]

As the chat is in the only game world in our demo, we join the chat in ~ServerConnection.join_world_async()~.

#+begin_example gdscript
var _channel_id: String 


func join_world_async() -> void:
    # ...
	if not result.is_exception():
        # ...
		var chat_join_result: NakamaRTAPI.Channel = yield(
			_socket.join_chat_async("world", NakamaSocket.ChannelType.Room, false, false),
			"completed"
		)
		_channel_id = chat_join_result.id
#+end_example

* To cover

** Difference between NakamaClient and the NakamaSocket objects

The NakamaClient is the interface from which clients communicate with the server in a more indirect way. It allows to call to a user's storage, contact RPC functions, etc. That's why it can just be created even when you're not connected. From the client, you create an authentication session, and a socket.

The NakamaSocket, on the other hand, is the live connection, the pulsing direct channel between a game's server and the game client's code.

For more info: [[https://heroiclabs.com/docs/unity-client-guide/][Unity tutorial]]

** Authoritative server

When creating multiplayer games, unless played on a local network, the server should always have the last word on what is happening in the game.

We need to do that so all players stay synchronized and can play together. Another important reason is to prevent players from cheating or exploiting the game's code. In commercial online games, there is a lot of code engineered to prevent cheating as much as possible, a difficult task.

In our example game, the server updates the game's state only 10 times per second. This limits the server's load and the bandwidth consumption. On each tick, the server calculates where each character should be and sends the information to each client. The clients receive the updates with delays and at different times, depending on their location or the quality of their internet connection, for example.

On the client's side, you can end up with a few frames without any new information coming. In our demo, we project each player's motion linearly projection to keep the game moving until server updates come in. Godot's Tween node smoothly interpolates between each character's last known position and their projected motion for us.

*** Skips in the characters' motion

If you test the project with two instances of the game, you will notice some hiccups in the non-player-controlled characters' motion.
