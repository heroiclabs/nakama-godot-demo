# Autoloaded class that manages in and out bound messages from game client to Nakama server
# Anything that has to do with communicating with the server is done here, where the 
# authentication session, client and socket are stored.
# Helper static classes are used to sequester code and make this one a little leaner, since it's
# otherwise quite large.
# Like Nakama, async methods are marked with `_async` and must be yielded to get a return value.
#
# Example yielded method:
#
# ```gdscript
# var result: int = yield(Connection.login_async(email, password), "completed")
# if result == OK:
# 	print("Authenticated")
# ```

extends Node

# Custom operational codes for state messages. Nakama built in codes are <= 0
enum OpCodes {
	# When the client reports a change in position
	UPDATE_POSITION = 1,
	# When the client reports a change in horizontal directional input
	UPDATE_INPUT,
	# When the server reports the tick's state, 10 times a second.
	UPDATE_STATE,
	# When the client reports that their character jumped
	UPDATE_JUMP,
	# When the client reports that they selected a character and are spawning in,
	# or the server that a different client has spawned a character in
	DO_SPAWN,
	# When a client reports that they changed color to the server, or the server
	# that a different client has changed color.
	UPDATE_COLOR,
	# When the server reports the initial game state to the client
	INITIAL_STATE
}

# Nakama read permissions
enum ReadPermissions { NO_READ, OWNER_READ, PUBLIC_READ }

# Nakama write permissions
enum WritePermissions { NO_WRITE, OWNER_WRITE }

# Server key. Must be unique.
const KEY := "wondrous_hippos"

# Collection in the storage for data that pertains to player's info
const COLLECTION := "player_data"

# Key within the storage collection for where the character list is stored
const CHARACTERS_KEY := "characters"

# Key within the storage collection for hwere the last logged in character was
const LAST_CHARACTER_KEY := "last_character"

# Emitted when the `presences` Dictionary has changed by joining or leaving clients
signal presences_changed

# Emitted when the server has sent an updated game state. 10 times per second.
signal state_updated(positions, inputs)

# Emitted when the server has been informed of a change in color by another client
signal color_updated(id, color)

# Emitted when the server has received a new chat message into the world channel
signal chat_message_received(sender_id, sender_name, message)

# Emitted when the server has received the game state dump for all connected characters
signal initial_state_received(positions, inputs, colors, names)

# Emitted when the server has been informed of a new character having been selected and is ready to spawn in
signal character_spawned(id, color)

# String that contains the error message whenever any of the functions that yield return != OK
var error_message := ""

# Dictionary with user_id for keys and NakamaPresence for values.
var presences := {}

# Nakama authentication session, recovered or generated via email:password
var _session: NakamaSession

# Nakama client through which sessions are created, sockets connected, and storage accessed.
var _client := Nakama.create_client(KEY, "127.0.0.1", 7350, "http")

# Nakama socket through which the live game world is interacted with.
var _socket: NakamaSocket

# The ID of the match the game world is associated with
var _world_id: String

# The ID of the world chat channel
var _channel_id: String


# Async coroutine. Authenticates a new session via email and password, and
# creates a new account when it did not previously exist, then initializes _session.
# Returns OK or a nakama error code. Stores error messages in `Connection.error_message`
func register_async(email: String, password: String) -> int:
	var new_session: NakamaSession = yield(
		_client.authenticate_email_async(email, password, email, true), "completed"
	)

	var parsed_result := _parse_exception(new_session)
	if parsed_result == OK:
		_session = new_session
		SessionFileWorker.write_auth_token(email, _session.token, password)
	else:
		error_message = error_message.replace("Username", "Email")

	return parsed_result


# Async coroutine. Authenticates a new session via email and password, but will
# not try to create a new account when it did not previously exist, then
# initializes _session. If a session previously existed in `AUTH`, will try to
# recover it without needing the authentication server. 
# Returns OK or a nakama error code. Stores error messages in `Connection.error_message`
func login_async(email: String, password: String) -> int:
	var token := SessionFileWorker.recover_session_token(email, password)
	if not token == "":
		var new_session: NakamaSession = _client.restore_session(token)
		if new_session.valid and not new_session.expired:
			_session = new_session
			yield(get_tree(), "idle_frame")
			return OK

	# If previous session is unavailable, invalid or expired
	var new_session: NakamaSession = yield(
		_client.authenticate_email_async(email, password, null, false), "completed"
	)

	var parsed_result := _parse_exception(new_session)
	if parsed_result == OK:
		_session = new_session
		SessionFileWorker.write_auth_token(email, _session.token, password)

	return parsed_result


# Async coroutine. Connects the socket to the live server.
# Returns OK or a nakama error number. Error messages are stored in `Connection.error_message`
func connect_to_server_async() -> int:
	_socket = Nakama.create_socket_from(_client)

	var result: NakamaAsyncResult = yield(_socket.connect_async(_session), "completed")
	var parsed_result := _parse_exception(result)
	if parsed_result == OK:
		#warning-ignore: return_value_discarded
		_socket.connect("connected", self, "_on_socket_connected")
		#warning-ignore: return_value_discarded
		_socket.connect("closed", self, "_on_socket_closed")
		#warning-ignore: return_value_discarded
		_socket.connect("received_error", self, "_on_socket_error")
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_presence", self, "_on_new_match_presence")
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_state", self, "_on_Received_Match_State")
		#warning-ignore: return_value_discarded
		_socket.connect("received_channel_message", self, "_on_Received_Channel_message")

	return parsed_result


# Saves the email in the config file.
func save_email(email: String) -> void:
	SessionFileWorker.save_email(email)


# Gets the last email from the config file, or a blank string if missing.
func get_last_email() -> String:
	return SessionFileWorker.get_last_email()


# Removes the last email from the config file
func clear_last_email() -> void:
	SessionFileWorker.clear_last_email()


func get_user_id() -> String:
	if _session:
		return _session.user_id
	return ""


# Async coroutine. Joins the match representing the world and the global chat
# room. Will get the match ID from the server through a remote procedure (see world_rpc.lua).
# Returns OK, a nakama error number, or ERR_UNAVAILABLE if the socket is not connected.
# Stores any error message in `Connection.error_message`
func join_world_async() -> int:
	if not _socket:
		error_message = "Server not connected."
		return ERR_UNAVAILABLE
	
	if not _world_id:
		var world: NakamaAPI.ApiRpc = yield(
			_client.rpc_async(_session, "get_world_id", ""), "completed"
		)
		
		var parsed_result := _parse_exception(world)
		if not parsed_result == OK:
			return parsed_result
		
		_world_id = world.payload

	var match_join_result: NakamaRTAPI.Match = yield(_socket.join_match_async(_world_id), "completed")
	
	var parsed_result := _parse_exception(match_join_result)
	
	if parsed_result == OK:
		for presence in match_join_result.presences:
			presences[presence.user_id] = presence

		var chat_join_result: NakamaRTAPI.Channel = yield(
			_socket.join_chat_async("world", NakamaSocket.ChannelType.Room, false, false),
			"completed"
		)
		parsed_result = _parse_exception(chat_join_result)
		
		_channel_id = chat_join_result.id

	return parsed_result


# Async coroutine. Gets the list of characters belonging to the user out of
# server storage.
# Returns an Array of {name: String, color: Color} dictionaries.
# Returns an empty array if there is a failure or if no characters are found.
func get_player_characters_async() -> Array:
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(
		_client.read_storage_objects_async(
			_session,
			DataReadIdBuilder.make().with_request(COLLECTION, CHARACTERS_KEY, _session.user_id).build()
		),
		"completed"
	)

	var parsed_result := _parse_exception(storage_objects)

	if not parsed_result == OK:
		return []

	var characters := []
	
	if storage_objects.objects.size() > 0:
		var decoded: Array = JSON.parse(storage_objects.objects[0].value).result.characters
		
		for character in decoded:
			var name: String = character.name
			
			characters.append(
				{
					name = name,
					color = Converter.color_string_to_color(character.color)
				}
			)

	return characters


# Creates a new character on the player's account. Will ask the server if the name
# is available beforehand, then will register the name and create the character into
# storage if so.
# Returns OK when successful, a nakama error code, or ERR_UNAVAILABLE if the name
# is already taken.
func create_player_character_async(color: Color, name: String) -> int:
	var availability_response: NakamaAPI.ApiRpc = yield(
		_client.rpc_async(_session, "register_character_name", name), "completed"
	)
	
	var parsed_result := _parse_exception(availability_response)
	
	if not parsed_result == OK:
		return parsed_result
	
	var is_available := availability_response.payload == "1"

	if is_available:
		var characters: Array = yield(get_player_characters_async(), "completed")
		
		characters.append({name = name, color = JSON.print(color)})
		
		var result: int = yield(_write_player_characters_async(characters), "completed")
		
		return result
	else:
		return ERR_UNAVAILABLE


# Update the character's color in storage with the repalcement color.
# Returns OK, or a nakama error code.
func update_player_character_async(color: Color, name: String) -> int:
	var characters: Array = yield(get_player_characters_async(), "completed")
	
	var do_update := false
	for i in range(characters.size()):
		if characters[i].name == name:
			characters[i].color = JSON.print(color)
			
			do_update = true
			
			break
	
	if do_update:
		var result: int = yield(_write_player_characters_async(characters), "completed")
		return result
	else:
		return OK


# Async coroutine. Delete the character at the specified index in the array from
# player storage. Returns OK, a nakama error code, or ERR_PARAMETER_RANGE_ERROR 
# if the index is too large or is invalid.
func delete_player_character_async(idx: int) -> int:
	var characters: Array = yield(get_player_characters_async(), "completed")
	
	if idx >= 0 and idx < characters.size():
		var character: Dictionary = characters[idx]
		yield(_client.rpc_async(_session, "remove_character_name", character.name), "completed")
		characters.remove(idx)
		
		var result: int = yield(_write_player_characters_async(characters), "completed")
		return result
	else:
		return ERR_PARAMETER_RANGE_ERROR


# Async coroutine. Get the last logged in character from the server, if any.
# Returns a {name: String, color: Color} dictionary, or an empty dictionary if no
# character is found, or something goes wrong.
func get_last_player_character_async() -> Dictionary:
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(
		_client.read_storage_objects_async(
			_session,
			DataReadIdBuilder.make().with_request(COLLECTION, LAST_CHARACTER_KEY, _session.user_id).build()
		),
		"completed"
	)

	var parsed_result := _parse_exception(storage_objects)
	var character := {}

	if not parsed_result == OK or storage_objects.objects.size() == 0:
		return character

	var decoded: Dictionary = JSON.parse(storage_objects.objects[0].value).result

	character["name"] = decoded.name
	character["color"] = Converter.color_string_to_color(decoded.color)

	var characters: Array = yield(get_player_characters_async(), "completed")
	for c in characters:
		if c.name == character["name"]:
			return character

	return {}


# Async coroutine. Put the last logged in character into player storage on the server.
# Returns OK, or a nakama error code.
func store_last_player_character_async(name: String, color: Color) -> int:
	var character := {name = name, color = JSON.print(color)}
	
	var result: NakamaAPI.ApiStorageObjectAcks = yield(
		_client.write_storage_objects_async(
			_session,
			DataWriteIdBuilder.make().with_request(COLLECTION, LAST_CHARACTER_KEY, ReadPermissions.OWNER_READ, WritePermissions.OWNER_WRITE, JSON.print(character)).build()
		),
		"completed"
	)
	
	var parsed_result := _parse_exception(result)
	return parsed_result


# Sends a message to the server stating a change in color for the client.
func send_player_color_update(color: Color) -> void:
	if _socket:
		var payload := {id = _session.user_id, color = color}
		_socket.send_match_state_async(_world_id, OpCodes.UPDATE_COLOR, JSON.print(payload))


# Sends a message to the server stating a change in position for the client.
func send_position_update(position: Vector2) -> void:
	if _socket:
		var payload := {id = _session.user_id, pos = {x = position.x, y = position.y}}
		_socket.send_match_state_async(_world_id, OpCodes.UPDATE_POSITION, JSON.print(payload))


# Sends a message to the server stating a change in horizontal input for the client.
func send_direction_update(input: float) -> void:
	if _socket:
		var payload := {id = _session.user_id, inp = input}
		_socket.send_match_state_async(_world_id, OpCodes.UPDATE_INPUT, JSON.print(payload))


# Sends a message to the server stating a jump from the client.
func send_jump() -> void:
	if _socket:
		var payload := {id = _session.user_id}
		_socket.send_match_state_async(_world_id, OpCodes.UPDATE_JUMP, JSON.print(payload))


# Sends a message to the server stating the client is spawning in after character selection.
func send_spawn(color: Color, name: String) -> void:
	if _socket:
		var payload := {id = _session.user_id, col = JSON.print(color), nm = name}
		_socket.send_match_state_async(_world_id, OpCodes.DO_SPAWN, JSON.print(payload))


# Sends a chat message to the server to be broadcast to others in the channel.
# Returns OK, a nakama error message, or ERR_UNAVAILABLE if the socket is not connected.
func send_text_async(text: String) -> int:
	if not _socket:
		return ERR_UNAVAILABLE
	
	var data := {"msg": text}
	
	var message_response: NakamaRTAPI.ChannelMessageAck = yield(
		_socket.write_chat_message_async(_channel_id, data), "completed"
	)
	
	var parsed_result := _parse_exception(message_response)
	if parsed_result != OK:
		emit_signal(
			"chat_message_received", "", "SYSTEM", "Error code %s: %s" % [parsed_result, error_message]
		)

	return parsed_result


# Helper function to turn a result into an exception if something went wrong.
func _parse_exception(result: NakamaAsyncResult) -> int:
	if result.is_exception():
		var exception: NakamaException = result.get_exception()
		error_message = exception.message
		
		return exception.status_code
	else:
		return OK


# Async coroutine. Writes the player's characters into storage on the server.
# Returns OK or a nakama error code.
func _write_player_characters_async(characters: Array) -> int:
	var result: NakamaAPI.ApiStorageObjectAcks = yield(
		_client.write_storage_objects_async(
			_session,
			DataWriteIdBuilder.make().with_request(COLLECTION, CHARACTERS_KEY, ReadPermissions.OWNER_READ, WritePermissions.OWNER_WRITE, JSON.print({characters = characters})).build()
		),
		"completed"
	)
	
	var parsed_result := _parse_exception(result)
	return parsed_result


# Raised when the socket is closed.
func _on_socket_closed() -> void:
	_clean_up_socket()


# Raised when the socket reports something's gone wrong.
func _on_socket_error(error: String) -> void:
	error_message = error
	_clean_up_socket()


# Helper function to disconnect socket signals.
func _clean_up_socket() -> void:
	#warning-ignore: return_value_discarded
	_socket.disconnect("connected", self, "_on_socket_connected")
	#warning-ignore: return_value_discarded
	_socket.disconnect("closed", self, "_on_socket_closed")
	#warning-ignore: return_value_discarded
	_socket.disconnect("received_error", self, "_on_socket_error")
	#warning-ignore: return_value_discarded
	_socket.disconnect("received_match_presence", self, "_on_new_match_presence")
	#warning-ignore: return_value_discarded
	_socket.disconnect("received_match_state", self, "_on_Received_Match_State")
	#warning-ignore: return_value_discarded
	_socket.disconnect("received_channel_message", self, "_on_Received_Channel_message")

	_socket = null


# Raised when the server reports presences have changed.
func _on_new_match_presence(new_presences: NakamaRTAPI.MatchPresenceEvent) -> void:
	for leave in new_presences.leaves:
		#warning-ignore: return_value_discarded
		presences.erase(leave.user_id)
	
	for join in new_presences.joins:
		if not join.user_id == _session.user_id:
			presences[join.user_id] = join
	
	emit_signal("presences_changed")


# Raised when the server receives a custom message from the server.
func _on_Received_Match_State(match_state: NakamaRTAPI.MatchData) -> void:
	var code := match_state.op_code
	var raw := match_state.data
	
	match code:
		OpCodes.UPDATE_STATE:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var positions: Dictionary = decoded.pos
			var inputs: Dictionary = decoded.inp

			emit_signal("state_updated", positions, inputs)
		
		OpCodes.UPDATE_COLOR:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var id: String = decoded.id
			var color := Converter.color_string_to_color(decoded.color)

			emit_signal("color_updated", id, color)
		
		OpCodes.INITIAL_STATE:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var positions: Dictionary = decoded.pos
			var inputs: Dictionary = decoded.inp
			var colors: Dictionary = decoded.col
			var names: Dictionary = decoded.nms
			
			for k in colors.keys():
				colors[k] = Converter.color_string_to_color(colors[k])

			emit_signal("initial_state_received", positions, inputs, colors, names)
		
		OpCodes.DO_SPAWN:
			var decoded: Dictionary = JSON.parse(raw).result
			
			var id: String = decoded.id
			var color := Converter.color_string_to_color(decoded.col)
			
			emit_signal("character_spawned", id, color)


# Raised when the server receives a new chat message.
func _on_Received_Channel_message(message: NakamaAPI.ApiChannelMessage) -> void:
	if message.code == 0:
		var sender_id: String = message.sender_id
		var content: Dictionary = JSON.parse(message.content).result
		var username: String = message.username
		
		emit_signal("chat_message_received", sender_id, username, content.msg)


# Helper class to build NakamaStorageObjectId for reading from server storage.
# Uses the builder pattern.
class DataReadIdBuilder:
	extends Reference

	var _ids := []

	# Makes a new builder
	static func make() -> DataReadIdBuilder:
		return DataReadIdBuilder.new()

	# Adds a request to the builder.
	func with_request(collection: String, key: String, id: String) -> DataReadIdBuilder:
		_ids.append(NakamaStorageObjectId.new(collection, key, id))
		return self

	# Returns the finished read ids.
	func build() -> Array:
		return _ids


# Helper class to build NakamaWriteStorageObject for writing to server storage
class DataWriteIdBuilder:
	extends Reference

	var _ids := []

	# Makes a new builder
	static func make() -> DataWriteIdBuilder:
		return DataWriteIdBuilder.new()

	# Adds a write request to the builder.
	func with_request(
		collection: String,
		key: String,
		permission_read: int,
		permission_write: int,
		value: String,
		version: String = ""
	) -> DataWriteIdBuilder:
		_ids.append(
			NakamaWriteStorageObject.new(
				collection, key, permission_read, permission_write, value, version
			)
		)
		return self

	# Returns the finished write ids.
	func build() -> Array:
		return _ids


# Helper class to manage functions that relate to local files that have to do with
# authentication or login parameters, such as remembering email.
class SessionFileWorker:
	const CONFIG := "user://config.ini"
	const AUTH := "user://auth"
	
	# Saves the email to the config file.
	static func save_email(email: String) -> void:
		var file := ConfigFile.new()
		#warning-ignore: return_value_discarded
		file.load(CONFIG)
		file.set_value("connection", "last_email", email)
		#warning-ignore: return_value_discarded
		file.save(CONFIG)
	
	# Gets the last email from the config file, or a blank string.
	static func get_last_email() -> String:
		var file := ConfigFile.new()
		#warning-ignore: return_value_discarded
		file.load(CONFIG)
	
		if file.has_section_key("connection", "last_email"):
			return file.get_value("connection", "last_email")
		else:
			return ""

	# Removes the last email from the config file.
	static func clear_last_email() -> void:
		var file := ConfigFile.new()
		#warning-ignore: return_value_discarded
		file.load(CONFIG)
		file.set_value("connection", "last_email", "")
		#warning-ignore: return_value_discarded
		file.save(CONFIG)
	
	
	# Write an encrypted file containing the email and token.
	static func write_auth_token(email: String, token: String, password: String) -> void:
		var file := File.new()
		#warning-ignore: return_value_discarded
		file.open_encrypted_with_pass(AUTH, File.WRITE, password)
		file.store_line(email)
		file.store_line(token)
		file.close()
	
	
	# Recover the session token from the authentication file.
	# When the user logs in again, they can try to recover their session using this
	# instead of going through the authentication server, provided it is not expired.
	# If another user tries to log in instead, the encryption will fail to read, or the
	# email will not match in the rare case passwords do.
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


# Helper class to convert values from the server into Godot values.
class Converter:
	# Turns a string in the format `"r,g,b,a"` to a Color. Alpha is skipped.
	static func color_string_to_color(color_string: String) -> Color:
		var color_values := color_string.replace('"', '').split(",")
		return Color(float(color_values[0]), float(color_values[1]), float(color_values[2]))
