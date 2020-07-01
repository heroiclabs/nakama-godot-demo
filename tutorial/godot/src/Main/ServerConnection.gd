extends Node

signal chat_message_received(username, text)
signal user_joined(username)
signal user_left(username)

# Nakama read permissions
enum ReadPermissions { NO_READ, OWNER_READ, PUBLIC_READ }
# Nakama write permissions
enum WritePermissions { NO_WRITE, OWNER_WRITE }

# Unique server key, as written in docker-compose.yml.
const KEY_SERVER := "nakama_godot_demo"

var _session: NakamaSession
var _client := Nakama.create_client(KEY_SERVER, "127.0.0.1", 7350, "http")
var _socket: NakamaSocket
var _world_id: String
# Lists other clients present in the game world we connect to.
var _presences := {}
var _channel_id := ""


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
func connect_to_server_async() -> int:
	_socket = Nakama.create_socket_from(_client)
	var result: NakamaAsyncResult = yield(_socket.connect_async(_session), "completed")
	if not result.is_exception():
		# warning-ignore:return_value_discarded
		_socket.connect("closed", self, "_on_NakamaSocket_closed")
		# warning-ignore:return_value_discarded
		_socket.connect("received_channel_message", self, "_on_NamakaSocket_received_channel_message")
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_presence", self, "_on_NakamaSocket_received_match_presence")
		return OK
	return ERR_CANT_CONNECT


# Gets the id of a match being played or lets the server create it, joins the match, and stores the
# players in the match in a dictionary.
func join_world_async() -> Dictionary:
	var world: NakamaAPI.ApiRpc = yield(
		_client.rpc_async(_session, "get_world_id", ""), "completed"
	)
	if not world.is_exception():
		_world_id = world.payload

	# Request to join the match through the NakamaSocket API.
	var match_join_result: NakamaRTAPI.Match = yield(
		_socket.join_match_async(_world_id), "completed"
	)

	if match_join_result.is_exception():
		var exception: NakamaException = match_join_result.get_exception()
		printerr("Error joining the match: code %s - %s" % [exception.status_code, exception.message])

	# If the request worked, we get a list of presences, that is to say, a list of clients in that
	# match.
	for presence in match_join_result.presences:
		_presences[presence.user_id] = presence
	return _presences


# Requests the server to save the `characters` array.
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


# Requests a list of characters from the server and converts the JSON response to an array of
# dictionaries with the form { name, color }.
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
		characters = decoded
	return characters


# Joins the "world" discussion channel and stored its id in `_channel_id`
func join_chat_async() -> int:
	var chat_join_result: NakamaRTAPI.Channel = yield(
		_socket.join_chat_async("world", NakamaSocket.ChannelType.Room, false, false), "completed"
	)
	if not chat_join_result.is_exception():
		_channel_id = chat_join_result.id
		return OK
	else:
		return ERR_CONNECTION_ERROR


# Sends a text message
func send_text_async(text: String) -> int:
	if not _socket:
		return ERR_UNAVAILABLE

	if _channel_id == "":
		printerr("Can't sent text message to the chat: variable `_channel_id` is not set.")
		return

	var result: NakamaRTAPI.ChannelMessageAck = yield(
		_socket.write_chat_message_async(_channel_id, {"msg": text}), "completed"
	)
	return ERR_CONNECTION_ERROR if result.is_exception() else OK


# Free the socket when the connection was closed.
func _on_NakamaSocket_closed() -> void:
	_socket = null


func _on_NamakaSocket_received_channel_message(message: NakamaAPI.ApiChannelMessage) -> void:
	if message.code != 0:
		return

	var content: Dictionary = JSON.parse(message.content).result
	emit_signal("chat_message_received", message.username, content.msg)


func _on_NakamaSocket_received_match_presence(new_presences: NakamaRTAPI.MatchPresenceEvent) -> void:
	for user in new_presences.leaves:
		#warning-ignore: return_value_discarded
		_presences.erase(user.user_id)
		emit_signal("user_left", user.username)

	for user in new_presences.joins:
		_presences[user.user_id] = user
		emit_signal("user_joined", user.username)

