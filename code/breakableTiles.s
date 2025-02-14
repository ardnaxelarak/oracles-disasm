;;
; This is always called from the tryToBreakTile function in bank 0.
;
; @param	bc	Position of tile to try to break
; @param	ff8f	Type of breakage (digging, sword slashing). Set bit 7 if no tiles
;			should be modified, in that case this function will only check if
;			it can be broken.
; @param[out]	hFF8D	4th parameter from "breakableTileModes"
; @param[out]	hFF8E	The interaction ID to create when the tile is destroyed
; @param[out]	hFF92	Former tile index
; @param[out]	hFF93	Tile position
; @param[out]	cflag	Set if the tile was broken (or can be broken).
;
; Internal variables:
;  ff8d-ff8e: values read from breakableTileModes
;  ff90: Y
;  ff91: X
;
tryToBreakTile_body:
	ld a,b
	and $f0
	or $08
	ldh (<hFF90),a
	ld a,c
	and $f0
	or $08
	ldh (<hFF91),a

	call getTileAtPosition
	ldh (<hFF92),a
	ld e,a
	ld a,l
	ldh (<hFF93),a

	ld hl,breakableTileCollisionTable
.ifdef ROM_AGES
	call lookupCollisionTable_paramE
.else
	push bc
	call getSomariaBlockIndex
	ld a,b
	cp e
	jr z,@somaria
	call lookupCollisionTable_paramE
	pop bc
	jr +

@somaria:
	ld hl,caneBreakableTileData
	pop bc
	jr ++
+
.endif
	ret nc

	; hl = breakableTileModes + a*5
	ld e,a
	add a
	ld hl,breakableTileModes
	rst_addDoubleIndex
	ld a,e
	rst_addAToHl
++
	ldh a,(<hFF8F)
	ld e,a
	and $1f
	call checkFlag
	ret z
	rl e
	ret c

	inc hl
	inc hl
	ldi a,(hl)
	swap a
	and $0f
	ldh (<hFF8D),a
	ldi a,(hl)
	ldh (<hFF8E),a
	push de
	ld a,(hl)
	or a
	jr z,@doneSettingTile

.ifdef ROM_AGES
	ldh a,(<hFF92)
	cp TILEINDEX_SWITCH_DIAMOND
	jr z,@useOriginalLayout

	ld a,(wActiveCollisions)
	cp $02
	jr z,@activeCollisions1Or2
	cp $01
	jr nz,@useGivenValue

.else; ROM_SEASONS
	ld a,(wActiveGroup)
	cp $03
	jr c,@useGivenValue
.endif

@activeCollisions1Or2:
	; Check value $10 (a kind of pot). What's the significance?
	ldh a,(<hFF92)
	cp TILEINDEX_MOVING_POT
	jr nz,@useGivenValue

@useOriginalLayout:
	; Check the original layout of the room, set the tile to its original
	; value if it was non-solid
	ldh a,(<hFF93)
	push hl
	call getTileIndexFromRoomLayoutBuffer
	pop hl
	jr nc,@setTile

@useGivenValue:
	ldh a,(<hFF93)
	ld c,a
	ld b,(hl)
	call setTileInRoomLayoutBuffer
	ld a,(hl)

@setTile:
	call setTile

	; RANDO: On the screen before Seasons D6 entrance, make the spring flower disappear permanently
	; by setting a bit when it's destroyed. (This bit will be checked elsewhere.)
.ifdef ROM_SEASONS
	ld bc,$0100
	call compareRoom
	jr nz,+
	ldh a,(<hFF93) ; Position
	cp $52
	jr nz,+
	call getThisRoomFlags
	set 0,(hl)
+
.endif

@doneSettingTile:
.ifdef ROM_AGES
	ldh a,(<hFF92)
	cp TILEINDEX_SOMARIA_BLOCK
	jr z,@somariaBlock
.else
	call getSomariaBlockIndex
	ldh a,(<hFF92)
	cp b
	jr z,@somariaBlock
.endif

	cp TILEINDEX_SIGN
	ld hl,wTotalSignsDestroyed
	call z,incHlRefWithCap

	ldh a,(<hFF8E)
	rlca
	ldh a,(<hFF92)
	call c,updateRoomFlagsForBrokenTile

	ldh a,(<hFF8E)
	bit 6,a
	ld a,SND_SOLVEPUZZLE
	call nz,playSound

	ld hl,wccaa
	ldh a,(<hFF93)
	cp (hl)
	jr nz,+

	ld (hl),$ff
	jr ++
+
	ldh a,(<hFF8D)
	or a
	call nz,func_483d
++
	ldh a,(<hFF8F)
	or a
	jr z,@done
	cp $0c
	jr z,@done
	cp $08
	jr z,@done
	cp $12
	ldh a,(<hFF8E)
	call nz,makeInteractionForBreakableTile
@done:
	pop de
	scf
	ret

@somariaBlock:
	ld c,ITEMID_18
	call findItemWithID
	jr nz,@done

	call @deleteSomariaBlock
	call findItemWithID_startingAfterH
	jr nz,@done

	call @deleteSomariaBlock
	jr @done

;;
; @param	h	Somaria block to slate for deletion
@deleteSomariaBlock:
	ld l,Item.state
	ld a,(hl)
	cp $03
	ret nz

	ld l,Item.var2f
	set 5,(hl)
	ret

;;
; Makes an interaction for a breakable tile at the item's location.
; The effect that will be made is based on the Item.var03 variable.
itemMakeInteractionForBreakableTile:
	ld h,d
	ld l,Item.yh
	ldi a,(hl)
	ldh (<hFF90),a
	inc l
	ldi a,(hl)
	ldh (<hFF91),a
	ld l,Item.var03
	ld a,(hl)
;;
makeInteractionForBreakableTile:
	and $1f
	cp $1f
	ret z

	ld c,a
	call getFreeInteractionSlot
	ret nz

	ld a,c
	and $0f
	ldi (hl),a
	ld a,c
	and $10
	swap a
	ldi (hl),a
	ld a,(w1Link.direction)
	ld l,Interaction.direction
	ldi (hl),a
	swap a
	rrca
	ldi (hl),a
	inc l
	ldh a,(<hFF90)
	ldi (hl),a
	inc l
	ldh a,(<hFF91)
	ldi (hl),a
	ret

;;
; @param	a	Item drop type?
func_483d:
	push hl
	call decideItemDrop
	jr z,@done

	; RANDO: 25% chance to replace item drops from destroyed tiles with gale seeds, if you have
	; none. Just to be nice, since warping out of one-ways is in logic in Seasons.
	ld a,TREASURE_GALE_SEEDS
	call checkTreasureObtained
	jr nc,++
	or a ; Number of gale seeds
	jr nz,++
	call getRandomNumber
	cp $40
	jr nc,++
	ld c,$08
++
	call getFreePartSlot
	jr nz,@done

	ld (hl),PARTID_ITEM_DROP
	inc l
	ld (hl),c
	ld l,Part.yh
	ldh a,(<hFF90)
	ldi (hl),a
	inc l
	ldh a,(<hFF91)
	ld (hl),a
	ld a,(w1Link.direction)
	swap a
	rrca
	ld l,Part.angle
	ld (hl),a
	ld l,Part.var03
	ld a,c
	cp $0f
	jr nz,+
	ld (hl),$02
+
	ldh a,(<hFF8F)
	cp $06
	jr nz,@done
	inc (hl)
@done:
	pop hl
	ret
