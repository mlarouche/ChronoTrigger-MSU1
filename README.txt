Chrono Trigger MSU-1 hack
Version 1.0 (WIP)
by DarkShock

THIS IS A WORK IN PROGRESS !

This hack adds CD quality audio to Chrono Trigger using the MSU-1 chip invented by byuu. For next version I do hope to include the FMV from the PS1 version !

The hack has been tested on bsnes-plus v073+1, higan 094 and SD2SNES. BSNES 070, 075 is NOT RECOMMENDED, use bsnes-plus v073.

================
= Installation =
================
1. Buy Chrono Symphony album in FLAC format (http://www.thechronosymphony.com/). Extract them all to a folder.
2. Run make_music_pack.bat to create the music_pack
3. Create a copy of your original ROM named chrono_msu1.sfc
3. Patch the ROM using Lunar IPS or Floating IPS (http://www.smwcentral.net/?p=viewthread&t=78938)

Please support the original author of the album. I known some sites will host the complete music pack in PCM format, I do not endorse them at all.

Original ROM specs:
CHRONO TRIGGER
U.S.A.
4194304 Bytes (32.0000 Mb)
Interleaved/Swapped: No
Backup unit/emulator header: No
Version: 1.0
Checksum: Ok, 0x788c (calculated) == 0x788c (internal)
Inverse checksum: Ok, 0x8773 (calculated) == 0x8773 (internal)
Checksum (CRC32): 0x2d206bf7

===============
= Using higan =
===============
3. Launch it using higan
4. Go to %USERPROFILE%\Emulation\Super Famicom\chrono_msu1.sfc in Windows Explorer.
5. Rename program.rom to chrono_msu1.sfc
6. Copy manifest.bml and the .pcm file there
7. Launch the game

====================
= Using on SD2SNES =
====================
Drop the ROM file, chrono_msu1.msu and the .pcm files in any folder. (I really suggest creating a folder)
Launch the game and voilà, enjoy !

========
= TODO =
========
* Credits fix
* FMV from the PS1 version (Version 2.0)

Notes:
* Pause actually pause the music (only in Battle)
* In normal combat with custom music, wrong sfx (hunting grounds Prehistoric)

===========
= Credits =
===========
* DarkShock - ASM hacking & coding, music editing
* Blake Robinson - Music reorchestration

Special Thanks:
* Geiger - Chrono Trigger documentation
* zarradeth - Chrono Trigger music engine documentation

=============
= Compiling =
=============
Source is availabe on GitHub: https://github.com/mlarouche/ChronoTrigger-MSU1

To compile the hack you need

* bass v14 (https://web.archive.org/web/20140710190910/http://byuu.org/files/bass_v14.tar.xz)
* flac (https://xiph.org/flac/download.html)
* wav2msu (https://github.com/mlarouche/wav2msu)

To distribute the hack you need

* uCON64 (http://ucon64.sourceforge.net/)
* 7-Zip (http://www.7-zip.org/)

create_pcm.bat create the .pcm from the WAV files
decode_flac.bat decode the FLAC from the Chrono Symphony album
distribute.bat distribute the patch
make_music_pack.bat calls required bats for creating the music pack.
make.bat assemble the patch
make_all.bat does everything
