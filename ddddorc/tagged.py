import os
import io
import ssl
import uuid
import time
import tkinter
from urllib import request
from PIL import Image, ImageTk


class Tk:
    def __init__(self, url, imagePath=None):
        if imagePath is None or imagePath == "":
            imagePath = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tagged")

        self.imgTk = None
        self.imgByte = None
        self.imagePath = imagePath
        self.url = url

        self.tk = tkinter.Tk()
        self.tk.title("TAG")
        self.tk.geometry("300x200")
        self.tk.columnconfigure(0, weight=1)
        self.tk.columnconfigure(1, weight=1)
        self.tk.rowconfigure(0, weight=1, minsize=80)
        self.tk.rowconfigure(1, weight=1, minsize=20)
        self.tk.rowconfigure(2, weight=1, minsize=20)

        self.image = tkinter.Label(self.tk)
        self.image.grid(row=0, column=0, rowspan=2, columnspan=2)

        self.entry = tkinter.Entry(self.tk, width=10)
        self.entry.grid(row=1, column=0, sticky="se")

        self.buttonOK = tkinter.Button(self.tk, text="OK", bd=3, command=self.tagOK)
        self.buttonOK.grid(row=1, column=1, sticky="sw")
        self.buttonNext = tkinter.Button(self.tk, width=15, text="NEXT", bd=3, command=self.tagNext)
        self.buttonNext.grid(row=2, column=0, columnspan=2)

        self.tk.bind('<Return>', self.pressKey)
        self.tk.bind('<Down>', self.pressKey)

        self.tagNext()
        self.tk.mainloop()

    def pressKey(self, key):
        if key.keysym in ["Down"]:
            self.tagNext()
        elif key.keysym in ["Return"]:
            self.tagOK()

    def tagOK(self):
        try:
            self.buttonOK.config(state="disabled", relief="sunken")
            text = self.entry.get().strip()
            assert len(text) > 0 and len(self.imgByte) > 128
            name = str("{}_{}.jpg").format(text, uuid.uuid4().hex)
            if not os.path.exists(self.imagePath):
                os.makedirs(self.imagePath)
            file = os.path.join(self.imagePath, name)
            fp = open(file=file, mode="wb")
            fp.write(self.imgByte)
            fp.close()
        except Exception as e:
            pass
        finally:
            self.buttonOK.config(state="active", relief="raised")
            self.tagNext()

    def tagNext(self):
        try:
            self.buttonNext.config(state="disabled", relief="sunken")
            imgByte = self.download(url=self.url)
            if isinstance(imgByte, bytes):
                self.imgByte = imgByte
                with io.BytesIO() as buffer:
                    buffer.write(imgByte)
                    buffer.seek(0)
                    self.imgTk = ImageTk.PhotoImage(Image.open(buffer))
                    self.image.config(image=self.imgTk)
        except Exception as e:
            pass
        finally:
            self.entry.delete(0, tkinter.END)
            self.buttonNext.config(state="active", relief="raised")
            self.tk.update()

    def download(self, url: str):
        while '{UUID}' in url or '{TIME}' in url or '{TIME13}' in url:
            if '{UUID}' in url:
                url = url.replace('{UUID}', str(uuid.uuid4()), 1)
            elif '{TIME}' in url:
                url = url.replace('{TIME}', str(int(time.time())), 1)
            elif '{TIME13}' in url:
                url = url.replace('{TIME13}', str(int(time.time() * 1000)), 1)
            else:
                break
        hdr = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:128.0) Gecko/20100101 Firefox/128.0",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US",
            "Accept-Encoding": "",
        }
        try:
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            req = request.Request(url=url, headers=hdr)
            with request.urlopen(req, context=ssl_context) as response:
                assert response.getcode() == 200
                content = response.read()
                return content
        except Exception as e:
            content = None
        return content


if __name__ == "__main__":
    url = "https://api-global.adspower.net/sys/user/passport/get-verify-img?verify_uuid={UUID}&random={UUID}"
    tk = Tk(url=url)

