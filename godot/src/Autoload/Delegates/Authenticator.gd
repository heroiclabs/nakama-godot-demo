# Delegate class that handles logging in and registering accounts. Holds the 
# authenticated session that ServerConnection uses to send messages or create a socket.
class_name Authenticator
extends Reference

var session: NakamaSession setget _no_set
var _client: NakamaClient setget _no_set
var _exception_handler: ExceptionHandler setget _no_set


func _init(client: NakamaClient, exception_handler: ExceptionHandler) -> void:
	_client = client
	_exception_handler = exception_handler


# Asynchronous coroutine. Authenticates a new session via email and password, and
# creates a new account when it did not previously exist, then initializes session.
# Returns OK or a nakama error code. Stores error messages in `ServerConnection.error_message`
func register_async(email: String, password: String) -> int:
	var new_session: NakamaSession = yield(
		_client.authenticate_email_async(email, password, email, true), "completed"
	)

	var parsed_result := _exception_handler.parse_exception(new_session)
	if parsed_result == OK:
		session = new_session
		SessionFileWorker.write_auth_token(email, session.token, password)
	else:
		_exception_handler.error_message = _exception_handler.error_message.replace(
			"Username", "Email"
		)

	return parsed_result


# Asynchronous coroutine. Authenticates a new session via email and password, but will
# not try to create a new account when it did not previously exist, then
# initializes session. If a session previously existed in `AUTH`, will try to
# recover it without needing the authentication server. 
# Returns OK or a nakama error code. Stores error messages in `ServerConnection.error_message`
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


func cleanup() -> void:
	session = null


func _no_set(_value) -> void:
	pass


# Helper class to manage functions that relate to local files that have to do with
# authentication or login parameters, such as remembering email.
class SessionFileWorker:
	const AUTH := "user://auth"

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
