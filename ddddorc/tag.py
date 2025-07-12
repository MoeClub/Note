import os
import tkinter
from PIL import Image, ImageTk

class Tk:
    def __init__(self, imagePath=None, imageOk="OK"):
        if imagePath is None or imagePath == "":
            imagePath = os.path.join(os.path.dirname(os.path.abspath(__file__)), "jpg")
        self.jpgs = [os.path.join(imagePath, x) for x in os.listdir(imagePath) if str(x).endswith(".jpg") and "-" not in x and "_" in x]
        self.index = 0
        self.OK = imageOk

        self.jpg = None
        self.imgTk = None

        self.tk = tkinter.Tk()
        self.tk.title("TAG FILE")
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

        self.buttonOK = tkinter.Button(self.tk, text="OK", command=self.tagOK)
        self.buttonOK.grid(row=1, column=1, sticky="sw")
        self.buttonNext = tkinter.Button(self.tk, width=15, text="NEXT", command=self.tagNext)
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
        text = self.entry.get().strip()
        if len(text) == 0:
            return
        _name = str("{}_{}").format(text, os.path.basename(self.jpg).split("_", 1)[-1])
        if self.OK:
            if not os.path.exists(os.path.join(os.path.dirname(os.path.abspath(self.jpg)), self.OK)):
                os.makedirs(os.path.join(os.path.dirname(os.path.abspath(self.jpg)), self.OK))
            okPath = os.path.join(os.path.dirname(os.path.abspath(self.jpg)), self.OK, _name)
        else:
            okPath = os.path.join(os.path.dirname(os.path.abspath(self.jpg)), _name)
        if os.path.exists(self.jpg):
            os.rename(self.jpg, okPath)
        self.tagNext()

    def tagNext(self):
        if self.index >= len(self.jpgs):
            return

        self.jpg = self.jpgs[self.index]
        _name = os.path.basename(self.jpg)
        self.tk.title(_name)
        preCode = _name.split("_", 1)[0]

        self.imgTk = ImageTk.PhotoImage(Image.open(self.jpg))
        self.image.config(image=self.imgTk)

        self.entry.delete(0, tkinter.END)
        self.entry.insert(0, preCode)

        self.index += 1
        if self.index >= len(self.jpgs):
            self.buttonNext.config(state="disabled")


if __name__ == "__main__":
    tk = Tk()
