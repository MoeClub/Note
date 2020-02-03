1. Install UltraEdit_18.00.0.66.dmg
2. Run Once and Close.
3. Run command:
```
printf '\x31\xC0\xFF\xC0\xC3\x90' | dd seek=$((0x74B480)) conv=notrunc bs=1 of=/Applications/UltraEdit.app/Contents/MacOS/UltraEdit
printf '\x31\xC0\xFF\xC0\xC3\x90' | dd seek=$((0x760900)) conv=notrunc bs=1 of=/Applications/UltraEdit.app/Contents/MacOS/UltraEdit
```
