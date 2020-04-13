class_name ExceptionHandler
extends Reference

var error_message: String


# Helper function to turn a result into an exception if something went wrong.
func parse_exception(result: NakamaAsyncResult) -> int:
	if result.is_exception():
		var exception: NakamaException = result.get_exception()
		error_message = exception.message

		return exception.status_code
	else:
		return OK
