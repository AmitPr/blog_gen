import 'package:blog_gen/blog_gen.dart' as blog_gen;
import 'package:blog_gen/src/config.dart';

void main(List<String> arguments) async {
  print('Loading Configuration File...');
  var config = await CONFIG.load();
  print('Configuration Loaded');
  print('Preparing output directory...');
  blog_gen.prepareOutputDirectory(config);
  print('Rendering posts to output directory...');
  var posts = blog_gen.processPosts(config);
  print('Finished rendering posts');
  print('Generating index.html...');
  blog_gen.generateIndex(config, posts);
}
