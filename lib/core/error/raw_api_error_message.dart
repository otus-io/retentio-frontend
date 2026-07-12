/// Extracts a raw API or client error string for cubit/bloc state.
///
/// UI layers should pass the result to [ApiErrorMessages.resolve].
String rawApiErrorMessage(Object error) {
  final text = error.toString().trim();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length).trim();
  }
  return text;
}
