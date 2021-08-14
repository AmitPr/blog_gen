import 'package:blog_gen/src/config.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:blog_gen/src/post.dart';

void prepareOutputDirectory(CONFIG config) {
  var outputDirectory = Directory(config.outputDirectory);
  if (outputDirectory.existsSync()) {
    outputDirectory.deleteSync(recursive: true);
  }
  outputDirectory.createSync();
}

List<Post> processPosts(CONFIG config) {
  var contentDirectory = Directory(config.contentDirectory);
  var p = path.Context(current: contentDirectory.absolute.path);
  var posts = <Post>[];
  for (var entity in contentDirectory.listSync(recursive: true)) {
    var fileName = p.basename(entity.path);
    // The path inside the content directory.
    var relativePath = p.relative(entity.absolute.path);
    if (config.ignoredFiles.contains(fileName)) continue;
    // Handle markdown files
    if (entity is File && fileName.endsWith('.md')) {
      posts.add(
        Post(
          entity.readAsStringSync(),
          p.dirname(relativePath),
        ),
      );
    }
    // Handle all other files
    else if (entity is File) {
      var outputFilePath = path.join(config.outputDirectory, relativePath);
      File(outputFilePath).createSync(recursive: true);
      entity.copySync(outputFilePath);
    }
  }
  posts.sort((a, b) =>
      a.attributes['createdAt'].compareTo(b.attributes['createdAt']) * -1);
  posts.forEach(
    (post) {
      File(path.join(config.outputDirectory, post.path, 'index.html'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          config.jinjaEnv.getTemplate('post_template.html').render(
                CONFIG: config.config,
                post: post.attributes,
              ),
        );
    },
  );
  return posts;
}

void generateIndex(config, posts) {
  File(path.join(config.outputDirectory, 'index.html'))
    ..createSync(recursive: true)
    ..writeAsStringSync(
      config.jinjaEnv.getTemplate('index_template.html').render(
            CONFIG: config.config,
            posts: posts.map((p) => p.attributes),
          ),
    );
  File(path.join(config.outputDirectory, 'search.json'))
    ..createSync(recursive: true)
    ..writeAsStringSync(
      config.jinjaEnv.getTemplate('search_template.jinja').render(
            CONFIG: config.config,
            posts: posts.map((p) => p.attributes),
          ),
    );
}
