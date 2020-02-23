#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author:  MoeClub.org

import tornado.web
import tornado.ioloop
import tornado.options
import tornado.httpserver
import json
import os
import time
import base64

MasterKey = ["MoeClub"]
SubPath = "Player"
RootPath = os.path.dirname(os.path.abspath(__file__))
DataPath = os.path.join(RootPath, "data")


class Utils:
    treelist = []
    treetime = 0

    @staticmethod
    def load(file, mode="r"):
        if "b" in mode:
            fd = open(file, mode)
        else:
            fd = open(file, mode, encoding="utf-8")
        data = fd.read()
        fd.close()
        return data

    @classmethod
    def b64(cls, file):
        data = cls.load(file=file)
        b64data = base64.b64encode(data.encode("utf-8"))
        return b64data.decode("utf-8")

    @classmethod
    def list(cls, dirname, second=15):
        if not os.path.exists(dirname):
            return ""
        if int(time.time()) - second >= cls.treetime:
            cls.treelist = []
            cls.tree(dirname=dirname)
            cls.treetime = int(time.time())
        return "\n".join(cls.treelist)

    @classmethod
    def tree(cls, dirname, padding="    ", Print=False):
        PRINTITEM1 = padding[:-1] + '+-' + os.path.basename(os.path.abspath(dirname)) + '/'
        cls.treelist.append(PRINTITEM1)
        if Print:
            print(PRINTITEM1)
        padding = padding + ' '
        files = os.listdir(dirname)
        count = 0
        for file in files:
            count += 1
            PRINTITEM2 = padding + '|'
            cls.treelist.append(PRINTITEM2)
            if Print:
                print(PRINTITEM2)
            path = dirname + os.sep + file
            if os.path.isdir(path):
                if count == len(files):
                    cls.tree(path, padding + ' ', Print)
                else:
                    cls.tree(path, padding + '|', Print)
            else:
                PRINTITEM3 = padding + '+-' + file
                cls.treelist.append(PRINTITEM3)
                if Print:
                    print(PRINTITEM3)


class MainHandler(tornado.web.RequestHandler):
    StaticFile = {}

    def check_argument(self, key):
        value = None
        if key in self.request.arguments:
            value = self.get_argument(key)
        return value

    def real_address(self):
        if 'X-Real-IP' in self.request.headers:
            self.request.remote_ip = self.request.headers['X-Real-IP']
        return self.request.remote_ip

    def WriteString(self, obj):
        if isinstance(obj, (str, int)):
            return obj
        elif isinstance(obj, (dict, list)):
            return json.dumps(obj, ensure_ascii=False)
        else:
            return obj

    def get(self, Item=None):
        try:
            self.real_address()
            assert Item and str(Item).strip()
            if Item == "list":
                data = Utils.list(DataPath)
                self.set_header("Content-Type", "text/plain; charset=utf-8")
                self.write(self.WriteString(data))
                self.finish()
                return
            print(Item)
            if str(Item).strip().lstrip("/").startswith("static/"):
                StaticPath = os.path.join(RootPath, Item)
                if os.path.exists(StaticPath):
                    if str(StaticPath).endswith(".js"):
                        self.set_header("Content-Type", "application/javascript; charset=utf-8")
                    elif str(StaticPath).endswith(".css"):
                        self.set_header("Content-Type", "text/css")
                    if StaticPath not in self.StaticFile:
                        self.StaticFile[StaticPath] = Utils.load(StaticPath, "rb")
                    self.finish(self.StaticFile[StaticPath])
                    self.flush()
                else:
                    self.set_status(404)
                    self.finish()
                return
            if not str(Item).strip().endswith(".m3u8"):
                Item = str(Item).strip() + ".m3u8"
            ItemPath = os.path.join(DataPath, Item)
            if os.path.exists(ItemPath):
                self.render("Player.html", PageTitle=str(Item).rstrip(".m3u8"), SubPath=str("/%s" % SubPath), PageData=Utils.b64(ItemPath))
            else:
                self.set_status(404)
                self.write("Not Found")
        except:
            self.set_status(400)
            self.write("Null")

    def post(self, Item=None):
        try:
            assert Item and str(Item).strip()
            assert str(Item) in MasterKey
            filesDict = self.request.files["file"]
            for FileItem in filesDict:
                if "filename" in FileItem and FileItem["filename"]:
                    ItemName = FileItem["filename"]
                else:
                    ItemName = "UN" + str(int(time.time())) + ".m3u8"
                FileSave = os.path.join(DataPath, ItemName)
                fd = open(FileSave, "wb")
                fd.write(FileItem["body"])
                fd.close()
            self.set_status(200)
            self.write("ok")
        except:
            self.set_status(400)
            self.write("fail")


class Web:
    @staticmethod
    def main():
        tornado.options.define("host", default='127.0.0.1', help="Host", type=str)
        tornado.options.define("port", default=5866, help="Port", type=int)
        tornado.options.parse_command_line()
        application = tornado.web.Application([(r"/%s/(?P<Item>.+)" % SubPath, MainHandler)], static_path=os.path.join(RootPath, "static"))
        http_server = tornado.httpserver.HTTPServer(application)
        http_server.listen(tornado.options.options.port)
        tornado.ioloop.IOLoop.instance().start()


if __name__ == "__main__":
    Web.main()

