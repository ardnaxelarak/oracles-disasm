rando_startingRings:
	.dsb 8, $00

; following memory are consecutive in ram

rando_startingDungeonSmallKeys:
	.dsb NUM_DUNGEONS, $00

rando_startingDungeonBossKeys:
	.dsb NUM_DUNGEONS_DIV_8, $00

rando_startingDungeonCompasses:
	.dsb NUM_DUNGEONS_DIV_8, $00

rando_startingDungeonMaps:
	.dsb NUM_DUNGEONS_DIV_8, $00

rando_startingInventory:
	.dsb INVENTORY_CAPACITY+2, $00

rando_startingObtainedTreasureFlags:
	.dsb $10, $00

rando_startingLinkHealth:
	.db $0C

rando_startingLinkMaxHealth:
	.db $0C

rando_startingNumHeartPieces:
	.db $00

rando_startingNumRupees:
	.dw $0000

.ifdef ROM_SEASONS
	rando_startingNumOreChunks:
		.dw $0000
.endif

rando_startingShieldLevel:
	.db $00
rando_startingNumBombs:
	.db $00
rando_startingMaxBombs:
	.db $10
rando_startingSwordLevel:
	.db $00
rando_startingNumBombchus:
	.db $00
rando_startingSeedSatchelLevel:
	.db $00
rando_startingFluteIcon:
	.db $00

.ifdef ROM_AGES
	rando_startingSwitchHookLevel:
		.db $00
	rando_startingSelectedHarpSong:
		.db $00
	rando_startingBraceletLevel:
		.db $00
.else ; ROM_SEASONS
	rando_startingObtainedSeasons:
		.db $00
	rando_startingBoomerangLevel:
		.db $00
	rando_startingMagnetGlovePolarity:
		.db $00
	rando_startingSlingshotLevel:
		.db $00
	rando_startingFeatherLevel:
		.db $00
.endif

rando_startingNumEmberSeeds:
	.db $00
rando_startingNumScentSeeds:
	.db $00
rando_startingNumPegasusSeeds:
	.db $00
rando_startingNumGaleSeeds:
	.db $00
rando_startingNumMysterySeeds:
	.db $00
rando_startingNumGashaSeeds:
	.db $00
rando_startingEssencesObtained:
	.db $00

; end consecutive ram

.ifdef ROM_AGES
	rando_startingNumSlates:
		.db $00
.else
	rando_startingInsertedJewels:
		.db $00
.endif

; another consecutive block of ram (cross items)

.ifdef ROM_SEASONS
	rando_startingSwitchHookLevel:
		.db $00
	rando_startingBraceletLevel:
		.db $00
	rando_startingSelectedHarpSong:
		.db $00
.else
	rando_startingSlingshotLevel:
		.db $00
	rando_startingBoomerangLevel:
		.db $00
	rando_startingFeatherLevel:
		.db $00
	rando_startingObtainedSeasons:
		.db $00
.endif
