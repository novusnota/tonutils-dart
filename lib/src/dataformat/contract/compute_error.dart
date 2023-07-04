class ComputeError extends Error {
  String message;
  int exitCode;
  String? debugLogs;
  String? logs;

  ComputeError(this.message, this.exitCode, {this.debugLogs, this.logs});
}
