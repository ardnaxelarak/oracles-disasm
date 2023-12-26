; gfx-related stuff here. Namespace "bank3f".

;;
; Overrides the sprite data loaded for certain interactions. This is mostly used for "non-treasure"
; interactions that depict treasures, like the ones in shops.
;
; @param	hl	Pointer to interactionData (may be modified)
checkLoadCustomSprite:
	push af
	push bc
	push hl
	ld e,Interaction.id
	ld a,(de)
	ld b,a
	inc e
	ld a,(de) ; subid
	ld c,a
	ld e,$02
	ld hl,customSpriteLookupTable
	call searchDoubleKey
	jr nc,@done

	ldi a,(hl)
	ld c,a
	ld b,(hl)
	pop hl

	bit 7,b
	jr z,+
	res 7,b
	ld h,b
	ld l,c
	call jpHl
	call lookupItemSpriteWithoutProgression
	jr ++
+
	callab rando.lookupItemSlot
	call lookupItemSpriteWithProgression
++
	pop bc
	pop af
	ret

@done:
	pop hl
	pop bc
	pop af
	ret

;;
; This is called from the "interactionSetAnimation" function. This gets the ID of the object,
; modified for the purpose of using a different animation table. This is used for objects that
; imitate the appearance of INTERACID_TREASURE, but which don't normally share its animation table.
;
; The combination of the functions "checkLoadCustomSprite" and "interactionGetIDForAnimationTable"
; will collectively do the work of overriding the graphics for any objects that are supposed to look
; like randomized treasures, aside from actual treasure objects.
;
; NOTE: This is called every time an interaction's animation frame needs to be loaded, even for
; unmodified objects. If it begins to cause lag then this may need to be re-examined.
;
; @param	d	Interaction object
; @param[out]	e	Interaction ID, modified for the purpose of using a different animation table
interactionGetIDForAnimationTable:
	push bc
	ld e,Interaction.id
	ld a,(de)
	ld b,a
	inc e
	ld a,(de)
	ld c,a
	ld e,$02
	ld hl,customSpriteLookupTable
	call searchDoubleKey
	jr nc,@normal

	; It's a special case; use the animation table for INTERACID_TREASURE
	ld e,INTERACID_TREASURE
	jr @ret

@normal:
	; It's not a special case; return the unmodified interaction ID
	ld e,b

@ret:
	pop bc
	ret

;;
; Same as below but without accounting for item progression.
lookupItemSpriteWithoutProgression:
	callab treasureData.getTreasureDataSpriteWithoutProgression
	jr +++

;;
; @param	bc	Treasure object ID to get graphics for
; @param[out]	hl	Address of sprite data (pointing somewhere in "data/{game}/interactionData.s")
lookupItemSpriteWithProgression:
	callab treasureData.getTreasureDataSprite
+++
	ld a,e
	ld hl,interaction60SubidData
	rst_addDoubleIndex
	ld a,e
	rst_addAToHl
	ret


; Modify this table to make certain interactions load different graphics based on the randomized
; item.
;
; Format:
; - Interaction ID
; - SubID
; - Item slot to use for gfx (little-endian word)
customSpriteLookupTable:

.ifdef ROM_SEASONS

	dbbw INTERACID_HEROS_CAVE_SWORD_CHEST, $00, rando.seasonsSlot_d0SwordChest
	dbbw INTERACID_SHOP_ITEM,              $00, rando.seasonsSlot_membersShop1
	dbbw INTERACID_SHOP_ITEM,              $02, rando.seasonsSlot_membersShop2
	dbbw INTERACID_SHOP_ITEM,              $05, rando.seasonsSlot_membersShop3
	dbbw INTERACID_SHOP_ITEM,              $0d, rando.seasonsSlot_shop150Rupees
	dbbw INTERACID_GET_ROD_OF_SEASONS,     $02, rando.seasonsSlot_templeOfSeasons
	dbbw INTERACID_SUBROSIAN_SHOP,         $00, rando.seasonsSlot_subrosiaMarket1stItem
	dbbw INTERACID_SUBROSIAN_SHOP,         $04, rando.seasonsSlot_subrosiaMarket2ndItem
	dbbw INTERACID_SUBROSIAN_SHOP,         $0d, rando.seasonsSlot_subrosiaMarket5thItem
	dbbw INTERACID_STEALING_FEATHER,       $00, $8000 | setStolenFeatherSprite
	dbbw INTERACID_LOST_WOODS_SWORD,       $00, rando.seasonsSlot_lostWoods
	.db $ff


setStolenFeatherSprite:
	ld b,TREASURE_FEATHER
	ld a,(wFeatherLevel)
	dec a
	ld c,a
	ret

.else; ROM_AGES

	dbbw INTERACID_MISCELLANEOUS_1,    $0b, rando.agesSlot_chevalsInvention
	dbbw INTERACID_MISCELLANEOUS_1,    $0c, rando.agesSlot_chevalsTest
	dbbw INTERACID_SHOP_ITEM,          $0d, rando.agesSlot_shop150Rupees
	dbbw INTERACID_DECORATION,         $08, rando.agesSlot_libraryPresent
	dbbw INTERACID_DECORATION,         $07, rando.agesSlot_libraryPast
	dbbw INTERACID_ACCESSORY,          $3e, rando.agesSlot_wildTokayGame
	dbbw INTERACID_ACCESSORY,          $14, rando.agesSlot_hiddenTokayCave
	dbbw INTERACID_ACCESSORY,          $15, rando.agesSlot_hiddenTokayCave
	dbbw INTERACID_SMALL_KEY_ON_ENEMY, $31, rando.agesSlot_d8_stalfos
	.db $ff

.endif

;;
; Overrides the sprite data loaded for certain parts. This is currently only
; used for Maple's drop, which depicts a treasure
;
; @param	hl	Pointer to partData (left untouched)
; @param[out]	a	Pointer to gfx index to load for the sprite
partCheckLoadCustomSprite:
	push hl
	ld e,Part.id
	ld a,(de)
	cp a,PARTID_ITEM_FROM_MAPLE_2
	jp nz,@done
	inc e
	ld a,(de) ; subid
	cp a,$00
	jp nz,@done

	push bc
	ld bc,rando.commonSlot_mapleItem
	callab rando.lookupItemSlot
	call lookupItemSpriteWithProgression
	pop bc
	ldi a,(hl)

	push af
	ld e,Part.var36 ; set to oamTileIndexBase to use later
	ldi a,(hl)
	res 7,a
	ld (de),a

	inc e ; var37, set to oamFlags to use later
	ld a,(hl)
	swap a
	and $0F
	ld (de),a

	inc e ; var38, set to animation index to use later
	ld a,(hl)
	and $0F
	ld hl,@mapTreasureToPart
	rst_addAToHl
	ld a,(hl)
	ld (de),a
	pop af

	pop hl
	inc hl
	ret

@done:
	pop hl
	ldi a,(hl)
	ret

@mapTreasureToPart:
	.db $00 $00 $03 $02 $00 $00 $04 $00
	.db $00 $00 $05 $00 $00 $04 $00 $00
