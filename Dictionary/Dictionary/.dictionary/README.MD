# path/to/file
```
~/Library/Dictionaries
```

# package
```
zip - ./file.dictionary |split -b 20m -a 3 - file.dictionary.zip.
```

# unpackage
```
tar -xvf <(cat file.dictionary.001 ...) -C "$HOME/Library/Dictionaries"
```
