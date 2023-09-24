import 'dart:io';
import 'dart:convert' show Encoding;

main() {
  var gitroot = Process.runSync(
    'git',
    [
      'rev-parse',
      '--show-toplevel',
    ],
    stdoutEncoding: Encoding.getByName('utf-8'),
  ).stdout as String;

  var version = File(gitroot.trim() + '/pubspec.yaml')
      .readAsLinesSync()
      .firstWhere((line) {
        return line.contains('version:', 0);
      })
      .split(':')[1]
      .trim();

  // TODO: check the changelog for the version to be present
  // TODO: create a tag if not exists: git tag v<version>
  // TODO: git push origin <tag>
}
