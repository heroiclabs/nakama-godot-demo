extends Node

const GAME_VERSION = "0.1.0"
# Unique server key, as written in docker-compose.yml.
const KEY_SERVER := "nakama_godot_demo"

var _session: NakamaSession
var _client := Nakama.create_client(KEY_SERVER, "127.0.0.1", 7350, "http")
var _socket: NakamaSocket
var _world_id: String
#
# Lists other clients present in the game world we connect to.
var _presences := {}


# Authenticates a user, creating an account if necessary.
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


# Creates and store a socket from the client object, then requests a connection from the server.
func connect_to_server_async() -> void:
	_socket = Nakama.create_socket_from(_client)
	var result: NakamaAsyncResult = yield(
		_socket.connect_async(_authenticator.session), "completed"
	)
	if not result.is_exception():
		_socket.connect("closed", self, "_on_NakamaSocket_closed")


# Gets the id of a match being played or lets the server create it, joins the match, and stores the
# players in the match in a dictionary.
func join_world_async() -> void:
	var world: NakamaAPI.ApiRpc = yield(
		_client.rpc_async(_session, "get_world_id", ""), "completed"
	)
	if not world.is_exception():
		_world_id = world.payload

	# Request to join the match through the NakamaSocket API.
	var match_join_result: NakamaRTAPI.Match = yield(
		_socket.join_match_async(_world_id), "completed"
	)
	# If the request worked, we get a list of presences, that is to say, a list of clients in that
	# match.
	if not match_join_result.is_exception():
		for presence in match_join_result.presences:
			presences[presence.user_id] = presence


# Requests the server to save the `characters` array.
func write_characters_async(characters := []) -> void:
	var result: NakamaAPI.ApiStorageObjectAcks = yield(
		_client.write_storage_objects_async(
			_session,
			[
				NakamaWriteStorageObject.new(
					"player_data",
					"characters",
					ReadPermissions.OWNER_READ,
					WritePermissions.OWNER_WRITE,
					JSON.print({characters = characters}),
					GAME_VERSION
				)
			]
		),
		"completed"
	)


# Requests a list of characters from the server and
func get_characters_async() -> Array:
	var characters := []
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(
		_client.read_storage_objects_async(
			_session, [NakamaStorageObjectId.new("player_data", "characters", _session.user_id)]
		),
		"completed"
	)

	if storage_objects.objects:
		var decoded: Array = JSON.parse(storage_objects.objects[0].value).result.characters
		for character in decoded:
			var name: String = character.name
			characters.append(
				{ name = name, color = Converter.color_string_to_color(character.color) }
			)
	return characters


# Free the socket when the connection was closed.
func _on_NakamaSocket_closed() -> void:
	_socket = null
