arch snes.cpu

// MSU memory map I/O
constant MSU_STATUS($002000)
constant MSU_ID($002002)
constant MSU_AUDIO_TRACK_LO($002004)
constant MSU_AUDIO_TRACK_HI($002005)
constant MSU_AUDIO_VOLUME($002006)
constant MSU_AUDIO_CONTROL($002007)

// SPC communication ports
constant SPC_COMM_0($2140)
constant SPC_COMM_1($2141)
constant SPC_COMM_2($2142)
constant SPC_COMM_3($2143)

// MSU_STATUS possible values
constant MSU_STATUS_TRACK_MISSING($8)
constant MSU_STATUS_AUDIO_PLAYING(%00010000)
constant MSU_STATUS_AUDIO_REPEAT(%00100000)
constant MSU_STATUS_AUDIO_BUSY($40)
constant MSU_STATUS_DATA_BUSY(%10000000)

// SNES Multiply register
constant SNES_MUL_OPERAND_A($004202)
constant SNES_MUL_OPERAND_B($004203)
constant SNES_DIV_DIVIDEND_L($004204)
constant SNES_DIV_DIVIDEND_H($004205)
constant SNES_DIV_DIVISOR($004206)
constant SNES_DIV_QUOTIENT_L($004214)
constant SNES_DIV_QUOTIENT_H($004215)
constant SNES_MUL_DIV_RESULT_L($004216)
constant SNES_MUL_DIV_RESULT_H($004217)

// Constants
constant FULL_VOLUME($FF)
constant DUCKED_VOLUME($30)

constant BATTLE1_MUSIC($45)
constant THEME_LOOP($18)
constant THEME_ATTRACT($54)

// =============
// = Variables =
// =============
// Game Variables
variable musicCommand($1E00)
variable musicRequested($1E01)
variable targetVolume($1E02)

// My own variables
variable currentSong($1EE0)
variable fadeState($1EE1)
variable fadeVolume($1EE2)
variable fadeTarget($1EE4)
variable fadeStep($1EE6)

// fadeState possibles values
constant FADE_STATE_IDLE($00)
constant FADE_STATE_FADEOUT($01)
constant FADE_STATE_FADEIN($02)

// **********
// * Macros *
// **********
// seek converts SNES HiROM address to physical address
macro seek(variable offset) {
  origin (offset & $3FFFFF)
  base offset
}

macro CheckMSUPresence(labelToJump) {
	lda MSU_ID
	cmp.b #'S'
	bne {labelToJump}
}

macro WaitMulResult() {
	nop
	nop
	nop
	nop
}

macro WaitDivResult() {
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
}

// ========================
// = Original code hijack =
// ========================

// NMI hijack
seek($00FF10)
	jml MSU_UpdateLoop

// Wait for song to finish command
seek($C03CC6)
	jsl MSU_WaitSongFinish
	nop
	nop
	nop
	nop

// Wait for song to start (found when switching characters on overworld)
seek($C2CBE0)
	jsl MSU_WaitSongStart
	nop
	nop
	nop
	nop

// Wait for title screen fix
// This chunk of code is copied into RAM
// by the decompression routine, that's why
// it got a db $80 in the middle
seek($C335AF)
	nop
	db $80
	jsl MSU_WaitSongStart
	nop
	nop

// Epoch 1999 AD sound check
seek($C30C28)
SoundCheckSuccessful:
	// Equivalent to bra $0bb5
	db $80,$8B
	jsl MSU_EpochMode7Fix
	bcs SoundCheckSuccessful
	rts

// Epoch 1999 AD event modification
// This is a destructive modification
// Remove syncronisation with music in the event
seek($FA96B1)
	// 10 10 is Event Command Jump Forward ten bytes
	// This is compressed data so the modification is
	// replicated 3 times
	db $10, $10, 0, 0, 0
	
// Relevant calls to $C70004
// Found via hex editor by searching for JSL $C70004

seek($C01B73)
	jsl MSU_Main
	
// Entering area
seek($C01B8B)
	jsl MSU_Main
	
// Entering battle
seek($C01BCE)
	jsl MSU_Main
	
seek($C01C2A)
	jsl MSU_Main
	
// Exiting battle
seek($C01C3A)
	jsl MSU_Main
	
seek($C01C52)
	jsl MSU_Main
	
seek($C01CA9)
	jsl MSU_Main
	
seek($C01CB7)
	jsl MSU_Main
	
seek($C01CCF)
	jsl MSU_Main
	
// Called during attract
seek($C03C43)
	jsl MSU_Main
	
seek($C03C69)
	jsl MSU_Main
	
seek($C03CB4)
	jsl MSU_Main
	
seek($C161DF)
	jsl MSU_Main
	
seek($C20462)
	jsl MSU_Main
	
seek($C223F9)
	jsl MSU_Main
	
seek($C22F49)
	jsl MSU_Main
	
seek($C2CBF3)
	jsl MSU_Main
	
seek($C2CC09)
	jsl MSU_Main
	
seek($C309D1)
	jsl MSU_Main
	
seek($C30BE9)
	jsl MSU_Main
	
// Title Screen
seek($C31647)
	jsl MSU_Main

seek($CD03AB)
	jsl MSU_Main
	
seek($CD0D70)
	jsl MSU_Main
	
seek($CD0D81)
	jsl MSU_Main
	
// Hijack for music in attract mode
seek($DB6E03)
	db THEME_ATTRACT
seek($FA24A4)
	db THEME_ATTRACT
seek($FA28FA)
	db THEME_ATTRACT
seek($FA4925)
	db THEME_ATTRACT
seek($FA4962)
	db THEME_ATTRACT
seek($FA659C)
	db THEME_ATTRACT

// ============
// = MSU Code =
// ============
seek($C5F370)
scope MSU_Main: {
	php
// Backup A and Y in 16bit mode
	rep #$30
	pha
	phx
	phy
	phd
	phb
	
	sep #$20 // Set all registers to 8 bit mode
	
	CheckMSUPresence(.CallOriginalRoutine)
	
	lda.w musicCommand
	// Play Music
	cmp.b #$10
	bne +
	jsr MSU_PlayMusic
	bcs .CallOriginalRoutine
	bcc .DoNotCallSPCRoutine
+
	// Resume
	cmp.b #$11
	bne +
	jsr MSU_ResumeMusic
	bcs .CallOriginalRoutine
	bcc .DoNotCallSPCRoutine
+
	// Interrupt
	cmp.b #$14
	bne +
	jsr MSU_PauseMusic
	bcs .CallOriginalRoutine
	bcc .DoNotCallSPCRoutine
+
	// Fade
	cmp.b #$81
	bne +
	jsr MSU_PrepareFade
+
// Call original routine
.CallOriginalRoutine:
	// Restore original theme when MSU-1 is not present
	lda.b #$10
	cmp.w musicCommand
	bne Original
	lda.b #THEME_ATTRACT
	cmp.w musicRequested
	bne Original
	
	lda.b #THEME_LOOP
	sta.w musicRequested
	
Original:
	rep #$30
	plb
	pld
	ply
	plx
	pla
	plp
	
	jsl $C70004
	rtl
	
.DoNotCallSPCRoutine:
	rep #$30
	plb
	pld
	ply
	plx
	pla
	plp
	rtl
}

scope MSU_PlayMusic: {
	lda.w musicRequested
	beq .StopMSUMusic
	cmp.b #$FF
	beq .SongAlreadyPlaying
	cmp.w currentSong
	beq .SongAlreadyPlaying
	sta MSU_AUDIO_TRACK_LO
	lda.b #$00
	sta MSU_AUDIO_TRACK_HI

.CheckAudioStatus:
	lda MSU_STATUS
	
	and.b #MSU_STATUS_AUDIO_BUSY
	bne .CheckAudioStatus
	
	// Check if track is missing
	lda MSU_STATUS
	and.b #MSU_STATUS_TRACK_MISSING
	bne .StopMSUMusic

	// Play the song
	lda.w musicRequested
	jsr TrackNeedLooping
	sta MSU_AUDIO_CONTROL
	
	// Set volume
	lda.b #FULL_VOLUME
	sta.w MSU_AUDIO_VOLUME
	sta.w fadeVolume
	
	// Only store current song if we were able to play the song
	lda.w musicRequested
	sta currentSong
	
	// Set SPC music to silence and disable any fade if any was active
	lda #$00
	sta $1E01
	sta.w fadeState
	sec
	bra .Exit

.SongAlreadyPlaying:
	clc
.Exit:
	rts
	
.StopMSUMusic:
	lda.b #$00
	sta MSU_AUDIO_CONTROL
	sta MSU_AUDIO_VOLUME
	sta.w currentSong
	sec
	bra .Exit
}

scope MSU_ResumeMusic: {
	lda MSU_STATUS
	and.b #MSU_STATUS_TRACK_MISSING
	bne .CallOriginalCode

	lda.w musicRequested
	cmp.w currentSong
	beq +
	
	jmp MSU_PlayMusic
	
+
	sta currentSong
	lda.b #$03
	sta MSU_AUDIO_CONTROL
	
	// Play silence after resuming music to
	// reload correct SFX samples
	lda.b #$10
	sta.w musicCommand
	lda.b #$00
	sta.w musicRequested
.CallOriginalCode:
	sec
	rts
}

scope MSU_PauseMusic: {
	lda.w musicRequested
	cmp.b #BATTLE1_MUSIC
	beq .PauseMSUMusic
	
	jml MSU_PlayMusic
	
.PauseMSUMusic:
	lda MSU_STATUS
	and.b #MSU_STATUS_TRACK_MISSING
	bne +
	
	lda.b #$00
	sta MSU_AUDIO_CONTROL
+
	sec
	rts
}

scope MSU_PrepareFade: {
	rep #$20
	lda #$0000
	sep #$20
	// musicRequested = Fade Time
	lda.w musicRequested
	beq .SetVolumeImmediate
	
	// fadeStep = (targetVolume-fadeVolume)/fadeTime
	lda.w targetVolume
	sta.w fadeTarget
	
	rep #$20
	sec
	sbc.w fadeVolume
	// If carry is set, the result is a positive number
	bcs +
	
	// Reverse sign of the result (which in two-complements)
	// A negative result means a fade-out
	eor #$FFFF
	inc
	
	sep #$30
	ldx.b #FADE_STATE_FADEOUT
	stx.w fadeState
	bra .DoDivision
+
	sep #$30
	ldx.b #FADE_STATE_FADEIN
	stx.w fadeState
.DoDivision:
	// Do division using SNES division support
	sta $4204 // low
	stz $4205 // high byte
	lda.w musicRequested // fadeTime
	sta $4206
	
	// Wait 16 CPU cycles
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	// Result in 4214 / 4215
	lda $4214
	beq .ResetToIdle
	sta fadeStep
	bra .Exit

.SetVolumeImmediate:
	lda.w targetVolume
	sta.w fadeVolume
	sta MSU_AUDIO_VOLUME
.Exit:
	rts
.ResetToIdle:
	lda.b #FADE_STATE_IDLE
	sta.w fadeState
	sta.w fadeStep
	bra .SetVolumeImmediate
}

scope TrackNeedLooping: {
	// 1.01 A Premonition
	cmp.b #48
	beq .noLooping
	// 1.02 Theme of Chrono Trigger (Attract)
	cmp.b #THEME_ATTRACT
	beq .noLooping
	// 1.03 Morning Glow
	cmp.b #15
	beq .noLooping
	// 1.10 Good Night
	cmp.b #43
	beq .noLooping
	// 1.14 Huh ?!
	cmp.b #37
	beq .noLooping
	// 1.16 A Prayer for the Wayfarer
	cmp.b #36
	beq .noLooping
	// 2.02 Mystery from the Past
	cmp.b #46
	beq .noLooping
	// 2.12 Fanfare 2
	cmp.b #28
	beq .noLooping
	// 2.15 Fanfare 3
	cmp.b #61
	beq .noLooping
	// 2.22 Fiedlord's Keep
	cmp.b #72
	beq .noLooping
	lda.b #$03
	rts
.noLooping:
	lda.b #$01
	rts
}

scope MSU_UpdateLoop: {
	php
	rep #$20
	pha
	
	sep #$20

	CheckMSUPresence(.CallNMI)
	
	lda.w fadeState
	beq .CallNMI
	
	cmp.b #FADE_STATE_FADEOUT
	beq .FadeOutUpdate
	cmp.b #FADE_STATE_FADEIN
	beq .FadeInUpdate
	bra .CallNMI
	
.FadeOutUpdate:
	lda.w fadeVolume
	sec
	rep #$20
	sbc.w fadeStep
	cmp.w fadeTarget
	bpl +
	sep #$20
	lda fadeTarget
+
	sep #$20
	sta.w fadeVolume
	sta MSU_AUDIO_VOLUME
	cmp.w fadeTarget
	beq .SetToIdle
	bra .CallNMI

.FadeInUpdate:
	lda.w fadeVolume
	clc
	rep #$20
	adc.w fadeStep
	cmp.w fadeTarget
	bcc +
	sep #$20
	lda fadeTarget
+
	sep #$20
	sta.w fadeVolume
	sta MSU_AUDIO_VOLUME
	cmp.w fadeTarget
	beq .SetToIdle
	bra .CallNMI
	
.SetToIdle:
	lda.b #FADE_STATE_IDLE
	sta.w fadeState
	
.CallNMI:
	rep #$20
	pla
	plp
	jml $000500
}

scope MSU_WaitSongStart: {
	php
	rep #$20
	pha
	
	sep #$20

	CheckMSUPresence(.OriginalCode)
	
	rep #$20
	pla
	plp
	rtl
	
.OriginalCode:
	rep #$20
	pla
	plp
	
	// Original code
-
	lda $2143
	and.b #$0F
	beq -
	
	rtl
}

scope MSU_WaitSongFinish: {
	php
	rep #$20
	pha
	
	sep #$20
	CheckMSUPresence(.OriginalCode)
	
	lda MSU_STATUS
	and.b #(MSU_STATUS_AUDIO_PLAYING|MSU_STATUS_AUDIO_REPEAT)
	bne +
	inx
+
	rep #$20
	pla
	plp
	rtl
	
.OriginalCode:
	rep #$20
	pla
	plp
	
	lda $2143
	and.b #$0F
	bne +
	inx
+
	rtl
}

scope MSU_EpochMode7Fix: {
	rep #$20
	pha
	sep #$20
	
	CheckMSUPresence(.OriginalCode)
	
	rep #$20
	pla
	sec
	rtl
	
.OriginalCode:
	rep #$20
	pla
-
	sep #$20
	lda SPC_COMM_2
	cmp SPC_COMM_2
	bne -
	
	and.b #$0F
	cmp ($20)
	bpl .RoutineSuccessful
	rep #$20
	dec $20
	clc
	rtl
	
.RoutineSuccessful:
	sec
	rtl
}