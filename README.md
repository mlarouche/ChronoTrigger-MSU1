# Chrono Trigger MSU-1
Version 1.1
by DarkShock

This hack adds CD quality audio to Chrono Trigger using the MSU-1 chip invented by byuu.

The hack has been tested on bsnes-plus v073+1, higan 096 and SD2SNES. BSNES 070, 075 is NOT RECOMMENDED, use bsnes-plus v073.

For those playing on SD2SNES, you need to exit to its menu using the L+R+Select+X shortcut in order to save your game.

Note that there are two patches:
1. `chrono_msu1.ips` for emulators prior to higan v096 and SD2SNES without resume support.
2. `chrono_msu1_resume.ips` for higan v096 and up and SD2SNES with resume support.

If you hate the fact that dungeon music restarts at the beginning with no-resume patch, delete chrono_msu1-69.pcm.

## Installation
1. Buy the [Chrono Trigger Symphony](http://www.thechronosymphony.com/) albums (volumes 1 through 3) in FLAC format ().
   1. Extract each album to a sub-directory under this directory with a name similar to `Chrono Trigger Symphony Vol X (FLAC)` where `X` is the volume number. For example, volume 1 should be extracted to a folder named `Chrono Trigger Symphony Vol 1 (FLAC)`
2. Run `make_music_pack.bat` to create the music pack.
3. Create a copy of your original ROM named `chrono_msu1.sfc`.
4. Patch the ROM using Lunar IPS or Floating IPS (http://www.smwcentral.net/?p=viewthread&t=78938).

Please support the original author of the album. I know some sites will host the complete music pack in PCM format, I do not endorse them at all.

### Original ROM specs
CHRONO TRIGGER
U.S.A.
4194304 Bytes (32.0000 Mb)
Interleaved/Swapped: No
Backup unit/emulator header: No
Version: 1.0
Checksum: Ok, 0x788c (calculated) == 0x788c (internal)
Inverse checksum: Ok, 0x8773 (calculated) == 0x8773 (internal)
Checksum (CRC32): 0x2d206bf7

## Using higan
1. Launch it using higan.
2. Go to `%USERPROFILE%\Emulation\Super Famicom\chrono_msu1.sfc` in Windows Explorer.
3. Rename `program.rom` to `chrono_msu1.sfc`.
4. Copy `manifest.bml` and the .pcm file there.
5. Launch the game.

## Using on SD2SNES
1. Rename the patched ROM file to `chrono_msu1.sfc`.
2. Drop the ROM file, `chrono_msu1.msu`, and the .pcm files in any folder under the root folder of the SD2SNES' SD card. (I really suggest creating a separate folder)
3. Launch the game and voil�, enjoy !

## Credits
* DarkShock - ASM hacking & coding, music editing
* Blake Robinson - Music reorchestration

### Special Thanks:
* Geiger - Chrono Trigger documentation
* zarradeth - Chrono Trigger music engine documentation

## Compiling

To compile the hack you need:
* [bass v14](https://web.archive.org/web/20140710190910/http://byuu.org/files/bass_v14.tar.xz)
* [flac](https://xiph.org/flac/download.html)
* [sox](http://sox.sourceforge.net/)
* [wav2msu](https://github.com/mlarouche/wav2msu)

To distribute the hack you need:
* [uCON64](http://ucon64.sourceforge.net/)
* [7-Zip](http://www.7-zip.org/)

### Scripts
* `create_pcm.bat` Creates the .pcm from the WAV files.
* `decode_flac.bat` Decodes the FLAC from the Chrono Trigger Symphony albums.
* `edit_audio.bat` Edits the audio using SoX.
* `distribute.bat` Distributes the patch.
* `make_music_pack.bat` Calls required batch scripts for creating the music pack.
* `make.bat` Assembles the patch.
* `make_all.bat` Does everything.
