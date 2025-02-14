randoInitializeStartingEquipment:
	push hl
	ld hl, rando_startingRings
	ld de, wRingsObtained
	ld b, 8
	call copyMemory

	ld hl, rando_startingDungeonSmallKeys
	ld de, wDungeonSmallKeys
	ld b, wTradeItem-wDungeonSmallKeys
	call copyMemory

.ifdef ROM_SEASONS
	ld a, (rando_startingInsertedJewels)
	ld (wInsertedJewels), a
	ld hl, rando_startingSwitchHookLevel
	ld de, wSwitchHookLevel
	ld b, 3
	call copyMemory
.else
	ld a, (rando_startingNumSlates)
	ld (wNumSlates), a
	ld hl, rando_startingSlingshotLevel
	ld de, wSlingshotLevel
	ld b, 4
	call copyMemory
.endif

	pop hl
	ret

;;
; Called after all other file initialization is done
randoInitializeFile:
	; Global flags
	push hl
	ld hl,@initialGlobalFlags
@loop:
	ldi a,(hl)
	cp a,$ff
	jr z,@done
	push hl
	call setGlobalFlag
	pop hl
	jr @loop
@done:
	pop hl

	; animal vars
	ld a,(randovar_animalCompanion)
	ld (wAnimalCompanion),a
	ld a,$ff
	ld (wCompanionTutorialTextShown),a

	; give L-3 ring box
	ld hl,wObtainedTreasureFlags + TREASURE_RING_BOX / 8
	set (TREASURE_RING_BOX & 7),(hl)
	ld a,$03
	ld (wRingBoxLevel),a

	; Initial satchel / slingshot / seed shooter selection
	ld a,(randovar_initialSeedType)
	ld (wSatchelSelectedSeeds),a
	ld (wShooterSelectedSeeds),a
	ld (wSlingshotSelectedSeeds),a

.ifdef ROM_SEASONS
	; room flags 4 | 6
	ld a,$50
	ld (wPresentRoomFlags+$a7),a ; start

	; room flags 3 | 5 | 6 | 7
	ld a,$e8
	ld (wPresentRoomFlags+$9a),a ; rosa portal

	; room flags 6 | 7
	ld a,$c0
	ld (wPresentRoomFlags+$98),a ; troupe
	ld (wPresentRoomFlags+$cb),a ; first rosa encounter

	; room flag 6
	ld a,$40
	ld (wPresentRoomFlags+$00),a ; d6 entrance
	ld (wPresentRoomFlags+$1d),a ; d4 entrance
	ld (wPresentRoomFlags+$60),a ; d3 entrance
	ld (wPresentRoomFlags+$8a),a ; d5 entrance
	ld (wPresentRoomFlags+$8d),a ; d2 entrance
	ld (wPresentRoomFlags+$96),a ; d1 entrance
	ld (wPresentRoomFlags+$9b),a ; sokra stump
	ld (wPresentRoomFlags+$b6),a ; impa's house
	ld (wPresentRoomFlags+$d0),a ; d7 entrance
	ld (wPresentRoomFlags+$e9),a ; sokra in town
	ld (wPastRoomFlags+$00),a ; d8 entrance
	ld (wPastRoomFlags+$29),a ; temple of seasons "gate"
	ld (wPastRoomFlags+$2a),a ; winter tower
	ld (wPastRoomFlags+$53),a ; strange brothers stealing feather

	; room flag 5 (item obtained)
	ld a,$20
	ld (wPastRoomFlags+$60),a ; strange brothers hiding spot

	; Fix initial season
	ld hl,bank1.roomPackSeasonTable+$10 ; North Horon season
	ld e,:bank1.roomPackSeasonTable
	call readByte
	ld a,e
	ld (wDeathRespawnBuffer.stateModifier),a

	; linked start item (RANDO-TODO)
	;ld a,(wIsLinkedGame)
	;or a
	;call nz,giveLinkedStartItem

.else ; ROM_AGES

	; RANDO-TODO: Decide what to do with linked game stuff
	;ld a,(wIsLinkedGame)
	;or a
	;jr z,++
	;ld a,GLOBALFLAG_GOT_RING_FROM_ZELDA
	;call setGlobalFlag
++
	; Mark dimitri tokay island event as finished
	ld a,$03
	ld (wDimitriState),a

	; maku tree state (vanished)
	ld a,$01
	ld (wMakuTreeState),a

	; room flags 3 | 6 | 7
	ld a,$c8
	ld (wPresentRoomFlags + <ROOM_AGES_039),a ; Big intro cutscene

	; room flag 7
	ld a,$80
	ld (wPastRoomFlags + <ROOM_AGES_1bb),a ; linked crescent island rosa encounter (1)

	; room flags 5 | 6
	ld a,$60
	ld (wPastRoomFlags + <ROOM_AGES_1cb),a ; linked crescent island rosa encounter (2)

	; room flag 6
	ld a,$40
	ld (wPresentRoomFlags + <ROOM_AGES_02e),a ; inside graveyard poe's grave
	ld (wPresentRoomFlags + <ROOM_AGES_03a),a ; nayru's house
	ld (wPresentRoomFlags + <ROOM_AGES_059),a ; triangle stone
	ld (wPresentRoomFlags + <ROOM_AGES_06a),a ; first encounter with impa
	ld (wPresentRoomFlags + <ROOM_AGES_07a),a ; start
	ld (wPresentRoomFlags + <ROOM_AGES_07b),a ; graveyard kids
	ld (wPresentRoomFlags + <ROOM_AGES_07c),a ; graveyard poe
	ld (wPastRoomFlags    + <ROOM_AGES_120),a ; ralph encounter on talus peaks
	ld (wPastRoomFlags    + <ROOM_AGES_197),a ; ralph encounter near rafton
	ld (wPastRoomFlags    + <ROOM_AGES_1f6),a ; top of black tower, south of stairs
	ld (wPastRoomFlags    + <ROOM_AGES_1aa),a ; tokays mugging Link
	ld (wPastRoomFlags    + <ROOM_AGES_1a8),a ; "raftwreck" cutscene
	; Note: Used to disable maku tree cutscenes here, but that's done by modifying the script
	; instead ("remoteMakuCutsceneScript").

	; room flag 5
	ld a,$20
	ld (wGroup2Flags      + <ROOM_AGES_2e3),a ; remove link's stolen bombs in tokay hut

	; room flag 3
	ld a,$08
	ld (wPresentRoomFlags + <ROOM_AGES_025),a ; foreman
	ld (wPastRoomFlags    + <ROOM_AGES_113),a ; symmetry city "middle house"

	; room flag 1
	ld a,$02
	ld (wPresentRoomFlags + <ROOM_AGES_024),a ; bridge to symmetry (bridge sealed while flag is set)

	; room flag 0
	ld a,$01
	ld (wPresentRoomFlags + <ROOM_AGES_038),a ; maku tree (present)
	ld (wPastRoomFlags    + <ROOM_AGES_176),a ; black tower entrance

	; for the lols
	ld a,$0f
	ld (wObtainedSeasons),a

.endif ; ROM_AGES
	ret


.ifdef ROM_SEASONS

@initialGlobalFlags:
	.db GLOBALFLAG_INTRO_DONE
	.db GLOBALFLAG_WITCHES_1_SEEN
	.db $ff

.else; ROM_AGES

@initialGlobalFlags:
	.db GLOBALFLAG_INTRO_DONE
	.db GLOBALFLAG_0c
	.db GLOBALFLAG_WON_FAIRY_HIDING_GAME
	.db GLOBALFLAG_CAN_BUY_FLUTE
	.db GLOBALFLAG_TALKED_TO_OCTOROK_FAIRY
	.db GLOBALFLAG_GOT_FLUTE
	.db GLOBALFLAG_FOREST_UNSCRAMBLED
	.db GLOBALFLAG_BOUGHT_BRACELET_FROM_TOKAY
	.db GLOBALFLAG_BOUGHT_FEATHER_FROM_TOKAY
	.db GLOBALFLAG_3d
	.db GLOBALFLAG_RALPH_ENTERED_PORTAL
	.db GLOBALFLAG_ENTER_PAST_CUTSCENE_DONE
	.db GLOBALFLAG_TALKED_TO_CHEVAL
	.db GLOBALFLAG_RALPH_ENTERED_BLACK_TOWER
	.db $ff

.endif
