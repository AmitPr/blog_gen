import datetime
import dateutil.parser as dateparser
# Data Model for each blog post
class Post:
    author: str = property(lambda self: self.attributes["author"])
    title: str = property(lambda self: self.attributes["title"])
    description: str = property(lambda self: self.attributes["description"])
    tags: str = property(lambda self: self.attributes["tags"].split(", "))
    createdAt: datetime.datetime = property(lambda self: dateparser.parse(self.attributes["createdAt"]))
    url: str = property(lambda self: self.file_path)

    def __init__(self, file_content, file_path):
        attributes,content = file_content.split("---",1)
        attributes=attributes.strip()
        self.attributes = dict([attribute.split(": ",1) for attribute in attributes.split("\n")])
        self.file_path = file_path
        self.content = content