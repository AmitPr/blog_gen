import configparser
import os
from posixpath import split
import shutil
import sys

from marko import Markdown
from marko.ext.codehilite import CodeHilite
from marko.ext.gfm import GFM
from jinja2 import Environment, FileSystemLoader, select_autoescape

from author_model import Author
from post_model import Post


class Main:
    def __init__(self, **kwargs):
        self.config = configparser.ConfigParser()
        try:
            config_path = os.path.join(
                os.getcwd(), kwargs.get('--config', 'config.ini'))
            if os.path.exists(config_path):
                self.config.read(config_path)
            else:
                raise FileNotFoundError()
        except Exception as e:
            print("[FATAL]: Error reading config file")
            print(e)
            sys.exit(1)
        
        #Verify that the directories are configured correctly
        self.content_dir = self.config.get('DEFAULT', 'ContentDirectory')
        if not self.content_dir:
            raise ValueError("[FATAL]: No content directory specified")
        self.content_dir = os.path.join(os.getcwd(), self.content_dir)
        if not os.path.exists(self.content_dir):
            raise FileNotFoundError("[FATAL]: Content directory not found")

        self.output_dir = self.config.get('DEFAULT', 'OutputDirectory')
        if not self.output_dir:
            raise ValueError("[FATAL]: No output directory specified")
        self.output_dir = os.path.join(os.getcwd(), self.output_dir)

        # Load an author object
        self.author = Author(
            self.config.get('Author', 'Name'),
            self.config.get('Author', 'Icon'),
            self.config.get('Author', 'URL')
        )
        formatter = Markdown(extensions=[GFM(), CodeHilite(wrapcode=True)])
        # formatter.use(GFM())
        jinja_vars = {
            'author': self.author,
            'constants': {
                'siteName': self.config.get('SiteInfo', 'Name'),
                'siteDescription': self.config.get('SiteInfo', 'Description'),
                'siteIcon': self.config.get('SiteInfo', 'Icon'),
            },
            'utils': {
                'markdown': lambda content: formatter.convert(content),
            }
        }

        # Create Jinja2 Environment
        self.template_dir = self.config.get('DEFAULT', 'TemplateDirectory')
        if not self.template_dir:
            raise ValueError("[FATAL]: No template directory specified")

        self.env = Environment(
            loader=FileSystemLoader(os.path.join(os.getcwd(), self.template_dir)),
            autoescape=select_autoescape()
        )
        self.env.globals.update(jinja_vars)

        self.clear_output_dir()
        self.load_posts()

        self.render_content()

    def clear_output_dir(self):
        if os.path.exists(self.output_dir):
            shutil.rmtree(self.output_dir)
        os.makedirs(self.output_dir)

    def load_posts(self):
        self.posts = []
        # Recursively walk through the content directory, and add posts
        for root, dirs, files in os.walk(self.content_dir):
            for file in files:
                if file.endswith('.md'):
                    with open(os.path.join(root, file), 'r') as f:
                        type_str = f.readline().strip().split(':',1)[
                            1].strip()
                        if type_str == 'post':
                            self.posts.append(
                                Post(''.join(f.readlines()), os.path.relpath(root,self.content_dir)))
        self.posts.sort(key=lambda x: x.createdAt, reverse=True)
        self.env.globals['posts'] = self.posts

    def render_content(self):
        ignored_files = self.config.get('OutputSettings', 'IgnoredFiles').strip().split(',')
        jinja_files = self.config.get('OutputSettings', 'JinjaFileExtensions').strip().split(',')
        post_template = self.env.get_template('post_template.html')

        for post in self.posts:
            post_path = os.path.join(
                self.output_dir, os.path.basename(post.file_path), 'index.html')
            os.makedirs(os.path.dirname(post_path))
            with open(post_path, 'w') as f:
                f.write(post_template.render(post=post))
        for root, dirs, files in os.walk(self.content_dir):
            for file in files:
                if '.'+file.split('.')[-1] in ignored_files or file.endswith('.md'):
                    continue
                file_path = os.path.join(root, file)
                target_path = os.path.join(self.output_dir,os.path.relpath(file_path,self.content_dir))
                os.makedirs(os.path.dirname(target_path), exist_ok=True)
                if '.'+file.split('.')[-1] in jinja_files:
                    with open(file_path, 'r') as f:
                        content = f.read()
                    with open(target_path, 'w') as f:
                        f.write(self.env.from_string(content).render())
                else:
                    shutil.copy(file_path, target_path)
        index_path = os.path.join(self.output_dir, 'index.html')
        with open(index_path, 'w') as f:
            f.write(self.env.get_template('index_template.html').render())



if __name__ == '__main__':
    if len(sys.argv) < 2:
        main = Main()
    else:
        main = Main(**dict(arg.split('=') for arg in sys.argv[1:]))
