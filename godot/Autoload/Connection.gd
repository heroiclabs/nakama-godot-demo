extends Node

const CONFIG := "user://config.ini"
const KEY := "defaultkey"

enum OpCodes {
	UPDATE_POSITION = 1,
	UPDATE_INPUT,
	UPDATE_STATE,
	UPDATE_JUMP
}

enum ReadPermissions {
	NO_READ,
	OWNER_READ,
	PUBLIC_READ
}

enum WritePermissions {
	NO_WRITE,
	OWNER_WRITE
}

signal connected
signal disconnected
signal error(error)
signal presences_changed
signal state_updated(positions, inputs)

var session: NakamaSession
var client := Nakama.create_client(KEY, "127.0.0.1", 7350, "http")
var error_message := ""
var socket: NakamaSocket
var username: String setget , _get_username
var presences := {}
var world_id: String


func register(email: String, password: String, _username: String, color: Color) -> int:
	var new_session: NakamaSession = yield(client.authenticate_email_async(email, password, _username, true), "completed")
	
	var parsed := _parse_exception(new_session)
	if parsed == OK:
		session = new_session
		var object_id := NakamaWriteStorageObject.new("player_data", "color", ReadPermissions.PUBLIC_READ, WritePermissions.OWNER_WRITE, JSON.print({color=color}), "*")
		var result: NakamaAPI.ApiStorageObjectAcks = yield(client.write_storage_objects_async(session, [object_id]), "completed")
		parsed = _parse_exception(result)
		
	return parsed


func login(email: String, password: String) -> int:
	var new_session: NakamaSession = yield(client.authenticate_email_async(email, password, null, false), "completed")
	
	var parsed := _parse_exception(new_session)
	if parsed == OK:
		session = new_session
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
		var world: NakamaAPI.ApiRpc = yield(client.rpc_async(session, "get_world_id", ""), "completed")
		var parsed := _parse_exception(world)
		if not parsed == OK:
			return parsed
		world_id = world.payload
	
	var match_join_result: NakamaRTAPI.Match = yield(socket.join_match_async(world_id), "completed")
	var parsed := _parse_exception(match_join_result)
	if parsed == OK:
		for presence in match_join_result.presences:
			presences[presence.user_id] = presence
	
	return parsed


func get_player_color(id: String) -> Color:
	var object_id := NakamaStorageObjectId.new("player_data", "color", id)
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(client.read_storage_objects_async(session, [object_id]), "completed")
	var parsed := _parse_exception(storage_objects)
	if parsed == OK:
		var decoded: Dictionary = JSON.parse(storage_objects.objects[0].value).result
		var color_values: Array = decoded.color.split(",")
		
		return Color(color_values[0], color_values[1], color_values[2])
	else:
		return Color.white


func get_player_colors(ids: Array) -> Dictionary:
	var object_ids := []
	for id in ids:
		var object_id := NakamaStorageObjectId.new("player_data", "color", id)
		object_ids.append(object_id)
	var storage_objects: NakamaAPI.ApiStorageObjects = yield(client.read_storage_objects_async(session, object_ids), "completed")
	var parsed := _parse_exception(storage_objects)
	if parsed == OK:
		var output := {}
		for storage_object in storage_objects.objects:
			var decoded: Dictionary = JSON.parse(storage_object.value).result
			var color_values: Array = decoded.color.split(",")
			output[storage_object.user_id] = Color(color_values[0], color_values[1], color_values[2])
		
		return output
	return {}


func send_position_update(position: Vector2) -> void:
	var payload := {id=session.user_id, pos={x= position.x, y= position.y}}
	socket.send_match_state_async(world_id, OpCodes.UPDATE_POSITION, JSON.print(payload))


func send_direction_update(input: float) -> void:
	var payload := {id=session.user_id, inp=input}
	socket.send_match_state_async(world_id, OpCodes.UPDATE_INPUT, JSON.print(payload))


func send_jump() -> void:
	var payload := {id=session.user_id}
	socket.send_match_state_async(world_id, OpCodes.UPDATE_JUMP, JSON.print(payload))


func _parse_exception(result: NakamaAsyncResult) -> int:
	if result.is_exception():
		var exception: NakamaException = result.get_exception()
		error_message = exception.message
		return exception.status_code
	else:
		return OK


func _on_socket_connected() -> void:
	emit_signal("connected")


func _on_socket_closed() -> void:
	emit_signal("disconnected")
	socket.disconnect("connected", self, "_on_socket_connected")
	socket.disconnect("closed", self, "_on_socket_closed")
	socket.disconnect("received_error", self, "_on_socket_error")


func _on_socket_error(error: String) -> void:
	emit_signal("error", error)


func _get_username() -> String:
	return session.username


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
