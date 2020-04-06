extends Node

const CONFIG := "user://config.ini"
const KEY := "defaultkey"
const AUTH := "user://auth"
const COLLECTION := "player_data"
const CHARACTERS_KEY := "characters"
const LAST_CHARACTER_KEY := "last_character"

enum OpCodes {
	UPDATE_POSITION = 1,
	UPDATE_INPUT,
	UPDATE_STATE,
	UPDATE_JUMP,
	DO_SPAWN,
	UPDATE_COLOR,
	INITIAL_STATE
}

enum ReadPermissions { NO_READ, OWNER_READ, PUBLIC_READ }

enum WritePermissions { NO_WRITE, OWNER_WRITE }

signal connected
signal disconnected
signal error(error)
signal presences_changed
signal state_updated(positions, inputs)
signal color_updated(id, color)
signal chat_message_received(sender_id, sender_name, message)
signal initial_state_received(positions, inputs, colors, names)
signal character_spawned(id, color)

var session: NakamaSession
var client := Nakama.create_client(KEY, "127.0.0.1", 7350, "http")
var error_message := ""
var socket: NakamaSocket
var presences := {}
var world_id: String
var channel_id: String


func register(email: String, password: String) -> int:
	var new_session: NakamaSession = yield(
		client.authenticate_email_async(email, password, email, true), "completed"
	)

	var parsed := _parse_exception(new_session)
	if parsed == OK:
		session = new_session
		_write_auth_token(email, session.token, password)
	else:
		error_message = error_message.replace("Username", "Email")

	return parsed


func login(email: String, password: String) -> int:
	var file := File.new()
	var error := file.open_encrypted_with_pass(AUTH, File.READ, password)
	if error == OK:
		var auth_email := file.get_line()
		var auth_token := file.get_line()
		file.close()
		if auth_email == email:
			var new_session: NakamaSession = client.restore_session(auth_token)
			if new_session.valid and not new_session.expired:
				session = new_session
				yield(get_tree(), "idle_frame")
				return OK

	var new_session: NakamaSession = yield(
		client.authenticate_email_async(email, password, null, false), "completed"
	)

	var parsed := _parse_exception(new_session)
	if parsed == OK:
		session = new_session
		_write_auth_token(email, session.token, password)

	return parsed


func connect_to_server() -> int:
	socket = Nakama.create_socket_from(client)

	var result: NakamaAsyncResult = yield(socket.connect_async(session), "completed")
	var parsed := _parse_exception(result)
	if parsed == OK:
		#warning-ignore: return_value_discarded
		socket.connect("connected", self, "_on_socket_connected")
		#warning-ignore: return_value_discarded
		socket.connect("closed", self, "_on_socket_closed")
		#warning-ignore: return_value_discarded
		socket.connect("received_error", self, "_on_socket_error")
		#warning-ignore: return_value_discarded
		socket.connect("received_match_presence", self, "_on_new_match_presence")
		#warning-ignore: return_value_discarded
		socket.connect("received_match_state", self, "_on_Received_Match_State")
		#warning-ignore: return_value_discarded
		socket.connect("received_channel_message", self, "_on_Received_Channel_message")

	return parsed


func save_email(email: String) -> void:
	var file := ConfigFile.new()
	#warning-ignore: return_value_discarded
	file.load(CONFIG)
	file.set_value("connection", "last_email", email)
	#warning-ignore: return_value_discarded
	file.save(CONFIG)


func get_last_email() -> String:
	var file := ConfigFile.new()
	#warning-ignore: return_value_discarded
	file.load(CONFIG)

	if file.has_section_key("connection", "last_email"):
		return file.get_value("connection", "last_email")
	else:
		return ""


func clear_last_email() -> void:
	var file := ConfigFile.new()
	#warning-ignore: return_value_discarded
	file.load(CONFIG)
	file.set_value("connection", "last_email", "")
	#warning-ignore: return_value_discarded
	file.save(CONFIG)


func join_world() -> int:
	if not world_id:
		var world: NakamaAPI.ApiRpc = yield(
			client.rpc_async(session, "get_world_id", ""), "completed"
		)
		var parsed := _parse_exception(world)
		if not parsed == OK:
			return parsed
		world_id = world.payload

	var match_join_result: NakamaRTAPI.Match = yield(socket.join_match_async(world_id), "completed")
	var parsed := _parse_exception(match_join_result)
	if parsed == OK:
		for presence in match_join_result.presences:
			presences[presence.user_id] = presence

		var chat_join_result: NakamaRTAPI.Channel = yield(
			socket.join_chat_async("world", NakamaSocket.ChannelType.Room, false, false),
			"completed"
		)
		parsed = _parse_exception(chat_join_result)
		channel_id = chat_join_result.id

	return parsed


func get_player_characters() -> Array:
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(
		client.read_storage_objects_async(
			session,
			DataReadIdBuilder.make().with_request(COLLECTION, CHARACTERS_KEY, session.user_id).build()
		),
		"completed"
	)

	var parsed := _parse_exception(storage_objects)

	if not parsed == OK:
		return []

	var characters := []
	if storage_objects.objects.size() > 0:
		var decoded: Array = JSON.parse(storage_objects.objects[0].value).result.characters
		for character in decoded:
			var color_values: Array = character.color.replace('"', '').split(",")
			var name: String = character.name
			characters.append(
				{name = name, color = Color(color_values[0], color_values[1], color_values[2])}
			)

	return characters


func create_player_character(color: Color, name: String) -> int:
	var availability: NakamaAPI.ApiRpc = yield(
		client.rpc_async(session, "register_character_name", name), "completed"
	)
	var parsed := _parse_exception(availability)
	if not parsed == OK:
		return parsed
	var is_available := availability.payload == "1"

	if is_available:
		var characters: Array = yield(get_player_characters(), "completed")
		characters.append({name = name, color = JSON.print(color)})
		var result: int = yield(_write_player_characters(characters), "completed")
		return result
	else:
		return ERR_UNAVAILABLE


func update_player_character(color: Color, name: String) -> int:
	var characters: Array = yield(get_player_characters(), "completed")
	var do_update := false
	for i in range(characters.size()):
		if characters[i].name == name:
			characters[i].color = JSON.print(color)
			do_update = true
			break
	if do_update:
		var result: int = yield(_write_player_characters(characters), "completed")
		print(result)
		return result
	else:
		return OK


func delete_player_character(idx: int) -> int:
	var characters: Array = yield(get_player_characters(), "completed")
	var character: Dictionary = characters[idx]
	yield(client.rpc_async(session, "remove_character_name", character.name), "completed")
	characters.remove(idx)
	var result: int = yield(_write_player_characters(characters), "completed")
	return result


func get_last_player_character() -> Dictionary:
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(
		client.read_storage_objects_async(
			session,
			DataReadIdBuilder.make().with_request(COLLECTION, LAST_CHARACTER_KEY, session.user_id).build()
		),
		"completed"
	)

	var parsed := _parse_exception(storage_objects)

	if not parsed == OK or storage_objects.objects.size() == 0:
		return {}

	var character := {}

	var decoded: Dictionary = JSON.parse(storage_objects.objects[0].value).result
	var color_values: Array = decoded.color.replace('"', "").split(",")
	var name: String = decoded.name

	character["name"] = name
	character["color"] = Color(color_values[0], color_values[1], color_values[2])

	var characters: Array = yield(get_player_characters(), "completed")
	for c in characters:
		if c.name == character["name"]:
			return character

	return {}


func store_last_player_character(name: String, color: Color) -> int:
	var character := {name = name, color = JSON.print(color)}
	var result: NakamaAPI.ApiStorageObjectAcks = yield(
		client.write_storage_objects_async(
			session,
			DataWriteIdBuilder.make().with_request(COLLECTION, LAST_CHARACTER_KEY, ReadPermissions.OWNER_READ, WritePermissions.OWNER_WRITE, JSON.print(character)).build()
		),
		"completed"
	)
	var parsed := _parse_exception(result)
	return parsed


func send_player_color_update(color: Color) -> void:
	var payload := {id = session.user_id, color = color}
	socket.send_match_state_async(world_id, OpCodes.UPDATE_COLOR, JSON.print(payload))


func send_position_update(position: Vector2) -> void:
	var payload := {id = session.user_id, pos = {x = position.x, y = position.y}}
	socket.send_match_state_async(world_id, OpCodes.UPDATE_POSITION, JSON.print(payload))


func send_direction_update(input: float) -> void:
	var payload := {id = session.user_id, inp = input}
	socket.send_match_state_async(world_id, OpCodes.UPDATE_INPUT, JSON.print(payload))


func send_jump() -> void:
	var payload := {id = session.user_id}
	socket.send_match_state_async(world_id, OpCodes.UPDATE_JUMP, JSON.print(payload))


func send_spawn(color: Color, name: String) -> void:
	var payload := {id = session.user_id, col = JSON.print(color), nm = name}
	socket.send_match_state_async(world_id, OpCodes.DO_SPAWN, JSON.print(payload))


func send_text(text: String) -> int:
	var data := {"msg": text}
	var message_ack: NakamaRTAPI.ChannelMessageAck = yield(
		socket.write_chat_message_async(channel_id, data), "completed"
	)
	var parsed := _parse_exception(message_ack)
	if parsed != OK:
		emit_signal(
			"chat_message_received", "", "SYSTEM", "Error code %s: %s" % [parsed, error_message]
		)

	return parsed


func _parse_exception(result: NakamaAsyncResult) -> int:
	if result.is_exception():
		var exception: NakamaException = result.get_exception()
		error_message = exception.message
		return exception.status_code
	else:
		return OK


func _write_player_characters(characters: Array) -> int:
	var result: NakamaAPI.ApiStorageObjectAcks = yield(
		client.write_storage_objects_async(
			session,
			DataWriteIdBuilder.make().with_request(COLLECTION, CHARACTERS_KEY, ReadPermissions.OWNER_READ, WritePermissions.OWNER_WRITE, JSON.print({characters = characters})).build()
		),
		"completed"
	)
	var parsed := _parse_exception(result)
	return parsed


func _write_auth_token(email: String, token: String, password: String) -> void:
	var file := File.new()
	#warning-ignore: return_value_discarded
	file.open_encrypted_with_pass(AUTH, File.WRITE, password)
	file.store_line(email)
	file.store_line(token)
	file.close()


func _on_socket_connected() -> void:
	emit_signal("connected")


func _on_socket_closed() -> void:
	emit_signal("disconnected")
	_clean_up_socket()


func _clean_up_socket() -> void:
	#warning-ignore: return_value_discarded
	socket.disconnect("connected", self, "_on_socket_connected")
	#warning-ignore: return_value_discarded
	socket.disconnect("closed", self, "_on_socket_closed")
	#warning-ignore: return_value_discarded
	socket.disconnect("received_error", self, "_on_socket_error")
	#warning-ignore: return_value_discarded
	socket.disconnect("received_match_presence", self, "_on_new_match_presence")
	#warning-ignore: return_value_discarded
	socket.disconnect("received_match_state", self, "_on_Received_Match_State")
	#warning-ignore: return_value_discarded
	socket.disconnect("received_channel_message", self, "_on_Received_Channel_message")

	socket = null


func _on_socket_error(error: String) -> void:
	emit_signal("error", error)
	_clean_up_socket()


func _on_new_match_presence(new_presences: NakamaRTAPI.MatchPresenceEvent) -> void:
	for leave in new_presences.leaves:
		#warning-ignore: return_value_discarded
		presences.erase(leave.user_id)
	for join in new_presences.joins:
		if not join.user_id == session.user_id:
			presences[join.user_id] = join
	emit_signal("presences_changed")


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
			var color_values: Array = decoded.color.replace('"', "").split(",")
			var color := Color(color_values[0], color_values[1], color_values[2])

			emit_signal("color_updated", id, color)
		OpCodes.INITIAL_STATE:
			var decoded: Dictionary = JSON.parse(raw).result
			var positions: Dictionary = decoded.pos
			var inputs: Dictionary = decoded.inp
			var colors: Dictionary = decoded.col
			var names: Dictionary = decoded.nms
			for k in colors.keys():
				var color_values: Array = colors[k].replace('"', "").split(",")
				colors[k] = Color(color_values[0], color_values[1], color_values[2])

			emit_signal("initial_state_received", positions, inputs, colors, names)
		OpCodes.DO_SPAWN:
			var decoded: Dictionary = JSON.parse(raw).result
			var id: String = decoded.id
			var color_values: Array = decoded.col.replace('"', "").split(",")
			var color := Color(color_values[0], color_values[1], color_values[2])
			emit_signal("character_spawned", id, color)


func _on_Received_Channel_message(message: NakamaAPI.ApiChannelMessage) -> void:
	if message.code == 0:
		var sender_id: String = message.sender_id
		var content: Dictionary = JSON.parse(message.content).result
		var username: String = message.username
		emit_signal("chat_message_received", sender_id, username, content.msg)


class DataReadIdBuilder:
	extends Reference

	var _ids := []

	static func make() -> DataReadIdBuilder:
		return DataReadIdBuilder.new()

	func with_request(collection: String, key: String, id: String) -> DataReadIdBuilder:
		_ids.append(NakamaStorageObjectId.new(collection, key, id))
		return self

	func build() -> Array:
		return _ids


class DataWriteIdBuilder:
	extends Reference

	var _ids := []

	static func make() -> DataWriteIdBuilder:
		return DataWriteIdBuilder.new()

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

	func build() -> Array:
		return _ids
