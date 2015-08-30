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

constant ENDING_MUSIC($3F)
constant EPOCH_1999AD_MUSIC($50)

// =============
// = Variables =
// =============
// Game Variables
variable musicCommand($1E00)
variable musicRequested($1E01)
variable targetVolume($1E02)

// My own variables
variable currentSong($7E1EE0)
variable fadeCount($7E1EE1)
variable fadeVolume($7E1EE2)
variable fadeStep($7E1EE4)
variable counter($7E1EE6)
variable frameCounter($7E1EE8)
variable inCombatHack($7E1EE9)

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

// Bike Race ending camera animation fix
// This is a lazy destructive hijack to the compressed code
// Original code check if the song has started:
// 7e475c lda $2143
// 7e475f and #$0f
// 7e4761 beq $4771 
seek($C3257B)
	lda.b #$01
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

// Epoch 1999 AD and Ending timing fix
seek($C30C28)
SoundCheckSuccessful:
	// Equivalent to bra $0bb5
	db $80,$8B
	jsl MSU_EpochAndEndingFix
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
	
// Fix for in normal combat with custom music, wrong sfx
// Tell the SPC routine to always load the data
seek($C70A8B)
	jmp $0A96
	
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

// Pause during battle
seek($CD3E54)
	jsl MSU_Main

// Unpause during battle
seek($CD3E70)
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
	
	sep #$30 // Set all registers to 8 bit mode
	
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
if {defined RESUME_EXPERIMENT} {
	jsr MSU_PlayMusic
} else {
	jsr MSU_ResumeMusic
}
	
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
	bcs .CallOriginalRoutine
	bcc .DoNotCallSPCRoutine
+
	// Pause/unpause during battle
	cmp.b #$F5
	bne +
	jsr MSU_PauseUnpause
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
	cmp currentSong
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
	
if {defined RESUME_EXPERIMENT} {
	ldx musicCommand
	cpx #$11
	bne .SetAudioControl
	
	// Add resume flag
	ora.b #$4
.SetAudioControl:
}

	sta MSU_AUDIO_CONTROL
	
	// Set volume
	lda.b #FULL_VOLUME
	sta.l MSU_AUDIO_VOLUME
	sta fadeVolume+1

	// Only store current song if we were able to play the song
	lda.w musicRequested
	sta currentSong
	
	// Set SPC music to silence and disable any fade if any was active
	lda #$00
	sta.w musicRequested
	sta fadeCount
	
	// Reset counter for Epoch 1999AD and Ending
	sta counter
	sta counter+1
	sec
	bra .Exit

.SongAlreadyPlaying:
	clc
.Exit:
	rts
	
.StopMSUMusic:
	lda.b #$00
	sta MSU_AUDIO_CONTROL
	sta.l MSU_AUDIO_VOLUME
	sta currentSong
	sec
	bra .Exit
}

scope MSU_ResumeMusic: {
	lda #$00
	sta inCombatHack
	
	lda MSU_STATUS
	and.b #MSU_STATUS_TRACK_MISSING
	bne .CallOriginalCode

	lda.w musicRequested
	cmp currentSong
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
if {defined RESUME_EXPERIMENT} {
	lda.b #$4
	sta MSU_AUDIO_CONTROL
	
	jml MSU_PlayMusic
} else {
	lda.w musicRequested
	cmp.b #BATTLE1_MUSIC
	beq .PauseMSUMusic
	
	jml MSU_PlayMusic
	
.PauseMSUMusic:
	lda #$01
	sta inCombatHack
	
	lda MSU_STATUS
	and.b #MSU_STATUS_TRACK_MISSING
	bne +
	
	lda.b #$00
	sta MSU_AUDIO_CONTROL
+
	sec
	rts
}

}

// c5f478 
scope MSU_PrepareFade: {
	// musicRequested = timing, targetVolume 
	lda.w musicRequested
	sta fadeCount
	bne .ComputeFade
	
.SetVolumeImmediate:
	sta fadeCount
	sta fadeStep
	sta fadeStep+1
	sta fadeVolume
	
	lda.w targetVolume
	sta.l MSU_AUDIO_VOLUME
	sta fadeVolume+1

	bra .Exit
.ComputeFade:
	lda.w targetVolume
	sec
	sbc fadeVolume+1
	beq .SetVolumeImmediate
	php
	bcs .IsCarrySet
	
	eor #$FF
	inc
.IsCarrySet:
	// targetVolume / timing
	sta SNES_DIV_DIVIDEND_L
	lda #$00
	sta SNES_DIV_DIVIDEND_H
	lda musicRequested
	sta SNES_DIV_DIVISOR
	WaitDivResult()
	
	lda SNES_DIV_QUOTIENT_L
	sta fadeStep+1
	
	lda #$00
	sta SNES_DIV_DIVIDEND_L
	lda SNES_MUL_DIV_RESULT_L
	sta SNES_DIV_DIVIDEND_H
	lda musicRequested
	sta SNES_DIV_DIVISOR
	WaitDivResult()
	
	lda SNES_DIV_QUOTIENT_L
	sta fadeStep
	
	plp
	bcs .IsCarrySet2
	
	lda fadeStep
	eor #$FF
	sta fadeStep
	lda fadeStep+1
	eor #$FF
	sta fadeStep+1
	
	rep #$20
	lda fadeStep
	inc
	sta fadeStep
	sep #$20
	
.IsCarrySet2:
	stz fadeVolume
.Exit:
	rts
}

scope MSU_PauseUnpause: {
	lda MSU_STATUS
	and.b #MSU_STATUS_TRACK_MISSING
	bne .Exit
	
if {defined RESUME_EXPERIMENT} {
} else {
	lda inCombatHack
	bne .Exit
}

	lda.w musicRequested
	cmp.b #$F5
	bne .Unpause
	
.Pause:
	lda.b #$00
	sta MSU_AUDIO_CONTROL
	
	bra .Exit
.Unpause:
	lda.b #$03
	sta MSU_AUDIO_CONTROL
	
.Exit:
	rts
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
	// 3.14 To Far Away Times (Ending)
	cmp.b #63
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

	lda frameCounter
	inc
	sta frameCounter
	cmp.b #60
	bmi .CheckFade
	lda.b #$0
	sta frameCounter
	
	// Increment counter at each second (each 60 fps)
	// Will be used to fake timing for Epoch 1999 scene and ending
	rep #$20
	lda counter
	inc
	sta counter
	sep #$20
	
.CheckFade:
	lda frameCounter
	lsr
	bcs .CallNMI
	
	lda fadeCount
	beq .CallNMI
	
	dec
	sta fadeCount
	
	clc
	rep #$20
	lda fadeVolume
	adc fadeStep
	sta fadeVolume
	
	sep #$20
	lda fadeVolume+1
	sta MSU_AUDIO_VOLUME
	
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

scope MSU_EpochAndEndingFix: {
	sep #$20
	lda currentSong
	cmp.b #EPOCH_1999AD_MUSIC
	beq .Epoch
	cmp.b #ENDING_MUSIC
	beq .Ending
	
	jmp .RoutineSuccessful

.Epoch:
	rep #$20
	lda counter
	
	cmp #49
	bmi +
	sep #$20
	lda.b #5
	jmp .OriginalCheck
+
	cmp #21
	bmi +
	sep #$20
	lda.b #3
	jmp .OriginalCheck
+
	cmp #16
	bmi +
	sep #$20
	lda.b #2
	jmp .OriginalCheck
+
	cmp #7
	bmi +
	sep #$20
	lda.b #1
	jmp .OriginalCheck
+
	sep #$20
	lda.b #0
	jmp .OriginalCheck
	
.Ending:
	rep #$20
	lda counter
	
	cmp #280 // $118 or $1801 (little endian)
	bmi +
	sep #$20
	lda.b #$A
	bra .OriginalCheck
+
	cmp #253 // $FD 
	bmi +
	sep #$20
	lda.b #$9
	bra .OriginalCheck
+
	cmp #193 // $C1
	bmi +
	sep #$20
	lda.b #$8
	bra .OriginalCheck
+
	cmp #159 // $9F
	bmi +
	sep #$20
	lda.b #$7
	bra .OriginalCheck
+
	cmp #127 // $7F
	bmi +
	sep #$20
	lda.b #$6
	bra .OriginalCheck
+
	cmp #104 // $68
	bmi +
	sep #$20
	lda.b #$5
	bra .OriginalCheck
+
	cmp #77 // $4D
	bmi +
	sep #$20
	lda.b #$4
	bra .OriginalCheck
+
	cmp #45 // $2D
	bmi +
	sep #$20
	lda.b #$3
	bra .OriginalCheck
+
	cmp #24 // $18
	bmi +
	sep #$20
	lda.b #$2
	bra .OriginalCheck
+
	cmp #17 // $11
	bmi +
	sep #$20
	lda.b #$1
	bra .OriginalCheck
+
	sep #$20
	lda.b #$0
	bra .OriginalCheck
	
.OriginalCheck:
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