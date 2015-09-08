@ECHO OFF

del chrono_msu1.sfc

copy chrono_original.sfc chrono_msu1.sfc

set BASS_ARG=
if "%~1" == "resume" set BASS_ARG=-d RESUME_EXPERIMENT

bass %BASS_ARG% -o chrono_msu1.sfc chrono_msu1_music.asm