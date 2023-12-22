; Changes to room layouts are applied in this file (some changes applied all the time, some
; conditionally).
;
; In addition to the changes here, some room files (in the "rooms" directory) have been modified
; directly, particularly for more complicated changes, and changes that affect only one season (in
; Seasons). Such rooms that have been changed in Seasons are:
;
; - 09d: Woods of Winter screen with tons of snow piles. Winter version was changed to prevent
;        softlocks. A snow "ledge" was added.
; - 0d0: D7 entrance, winter version. Removed 2 snow tiles by the right ledge, so that jumping off
;        the ledge doesn't look so weird.
; - 01d: D4 entrance, all versions. Changed deep water to shallow water to avoid being stranded
;        when exiting the dungeon in specific situations.
; - 0b2: Spool Swamp, spring. Changed some water current directions so that the player doesn't get
;        stuck in the area when entering from the east.
; - 091/0a1: Spool Swamp, spring. Changed deep water on the floodgate keyhole screen, and in the
;        room below it, with shallow water, so that the player can get back from the Subrosia
;        portal.
; - 0a9/0b9: Eyeglass Lake, summer. Changed deep water to shallow water to prevent a softlock with
;        default winter + summer rod + no flippers.
; - 0b9: Eyeglass Lake, summer. Replaced the stairs outside the portal with a railing, since if the
;        player jumps off they fall into lost woods. Instead add a ledge to the left side of the
;        platform, so that entering the portal without feather and resetting the season to summer
;        isn't a softlock.
; - 001: Tarm Ruins, winter version. Removed snow pile to prevent softlock when armos statue is
;        pushed to the left without shovel.
; - 07f: Holly's house, winter version. Removed snow pile outside so that shovel isn't required to
;        leave.
; - 056: Natzu region, Ricky/Moosh versions. Removed switch tile to prevent waterway from being
;        blocked (although really it's the removal of the interaction that prevents it).
;
; CROSSITEMS-related changes:
;
; - 5ca: Cave to Goron Mountain. Without any changes, it is possible to use the L-1 switch hook from
;        the bottom side, but not from the top side. To prevent softlocks, extra bushes have been
;        added.

applyRandoTileChanges:
	ld a,(wActiveGroup)
	ld b,a
	ld a,(wActiveRoom)
	ld c,a
	ld hl,@tileSubTable

@searchForChange:
	ld e,3
	call searchDoubleKey
	ret nc

	; Bit 4 ($10) = always do the substitution (ROOMFLAG_VISITED). In theory we wouldn't need to
	; check this manually. But there are rare instances where this function runs before
	; ROOMFLAG_VISITED gets set.
	ld a,(hl)
	cp $10
	jr z,@applyChange

	; $f3 = dungeon entrance Rando only
	cp $f3
	jr nz,+
	ld a,RANDO_CONFIG_DUNGEON_ENTRANCES
	call checkRandoConfig
	ret z
	jr @applyChange
+
	; Any other case: treat it as a bitmask against the room flags
	push hl
	call getThisRoomFlags
	pop hl
	and (hl)
	ret z

@applyChange:
	inc hl
	ld d,>wRoomLayout
	ld e,(hl)
	inc hl
	ldi a,(hl)
	ld (de),a
	jr @searchForChange


; Single-tile change data format: group; room; flags; yx; tile.
; "flags" are usually $10 (ROOMFLAG_VISITED) which applies the change always.
; If "flags" is $f3, then it is a special case which only applies when dungeon entrances are
; randomized.
@tileSubTable:

.ifdef ROM_SEASONS
	.db $00, $01, $01, $52, $04 ; permanently remove flower outside D6 when cut
	.db $00, $25, $10, $32, $3a ; add ledge down from temple remains lower portal
	.db $00, $25, $10, $33, $cf ; ^
	.db $00, $25, $10, $34, $4b ; ^
	.db $00, $5c, $10, $64, $48 ; extend moblin keep railing as chokepoint for warning
	.db $00, $5c, $10, $74, $53 ; ^
	.db $00, $9a, $10, $14, $12 ; remove rock across pit blocking exit from D5
	.db $00, $8a, $10, $66, $64 ; ^ but add rock at bottom of cliff to block ricky
	.db $00, $9a, $10, $34, $04 ; remove bush next to rosa portal
	.db $00, $b0, $10, $21, $13 ; remove spool swamp pits to prevent winter softlock
	.db $00, $b0, $10, $51, $13 ; cont.
	.db $00, $8d, $f3, $18, $04 ; D2 alt entrance removal (entrance rando only)
	.db $00, $8e, $f3, $12, $04 ; D2 alt entrance removal (entrance rando only)
	.db $05, $ca, $10, $84, $20 ; bushes in goron mountain cave
	.db $05, $ca, $10, $88, $20 ; bushes in goron mountain cave
	.db $ff

.else
	.db $01, $48, $10, $45, $d7 ; portal south of past maku tree
	.db $05, $bc, $10, $7e, $31 ; goron's hiding place (make wall visibly bombable)
	.db $00, $83, $10, $43, $a4 ; remove rock outside present D2
	.db $03, $0f, $10, $66, $f9 ; water in past d6 entrance made shallow to prevent softlock
	.db $00, $24, $02, $49, $63 ; seal left side of bridge to symmetry city
	.db $00, $24, $02, $59, $63 ; ^
	.db $00, $24, $02, $69, $63 ; ^
	.db $00, $24, $02, $79, $73 ; ^
	.db $ff
.endif
