; Some extra variables that should be set by the randomizer. (This is in bank 0.)

; This gets written to wAnimalCompanion upon file initialization
randovar_animalCompanion:
	.db SPECIALOBJECTID_RICKY

; Determines default cursor position for satchel / shooter / slingshot, and which seeds you get upon
; obtaining any of those items. This should be the same as the starting tree's seeds.
randovar_initialSeedType:
	.db $00

; Boolean options will be written here and can be accessed with the "checkRandoConfig" function. See
; "constants/rando.s" for values.
randoConfig:
	.db %00000000

; rando variables to change behavior of hard-to-get heart pieces
; bit 0 - if set, maple will always drop her heart piece when encountered until it is picked up
; bit 1 - if set, the first gasha nut harvested will yield the heart piece
randovar_forceDrops:
	.db $00

; rando variables to change goal behavior
; bits 0-3 - number of essences to get Maku seed
randovar_goal:
	.db $08
