@ECHO OFF

del chrono_msu1.sfc

copy chrono_original.sfc chrono_msu1.sfc

set BASS_ARG=
if "%~1" == "emu" set BASS_ARG=-d EMULATOR_VOLUME

bass %BASS_ARG% -o chrono_msu1.sfc chrono_msu1_music.asm