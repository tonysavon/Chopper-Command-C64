/*
Enemies move within an horizontal range of 256 pixels, centered in the central truck of one of the four convoys
The original Activision game moves the enemies quite randomly. Horizontally, they go end to end thorugh this range, but they can also randomly change their direction.
Planes are slightly faster than the helicopters in their horizontal movement, but helicopters move vertically a bit more "aggressively".
This aspect is quickly lost as you progress through the first waves as all enemies max out in their craziness scale and behave identically.
In fact, enemies top speed is a function of the level. 
My implementation, recreates the origina logic, which was slotted to cope with memory limitations, but allows for finer tuning
When an enemy initiates a movement, the horizontal speed is (f(direction) + f(level) + boost) pixels per second. 
	boost is 0 or 1 pixel per frame, according to a random value.
	f(direction) = 1 if going right, 0 if going left. This is because the "world" moves left at 1 pixel per frame anyway and this compensates it
Shooting happens also randomly but r-test is so frequent that it ends up feeling more like "whoever can, shoots"
I don't particularly love this aspect, but it is a landmark feature of the original, therefore it stays.
*/

enemies:
{
	.label STATUS_PLANE = 		%10000000	//plane or chopper. 0 = chopper, 1 = plane
	.label STATUS_ALIVE 	 = 	%01000000	//alive
	.label STATUS_XDIRECTION = 	%00000001	//going left or right. 0 = goes right, 1 goes left 
	.label STATUS_YDIRECTION = 	%00000010	//going up or down. 0 = goes down, 1 = goes up 
	.label STATUS_YMOVES	 =  %00000100	//moves vertically. 1 = moves vertically in the direction of STATUS_YDIRECTION, 0 = still
	.label STATUS_XBOOST	 =  %00001000	//has a boost in horizontal speed. 0 = no boost, 1 = boost.
	.label STATUS_YBOOST	 =  %00010000	//has a boost in vertical speed. 0 = no boost, 1 = boost.
	.label STATUS_EXPLODING	 =  %00100000   //if the enemy is exploding it won't interact with the rest of the world.	
	 
	//call at level start to place the enemies
	deploy:
			ldx #12
			stx nenemies
	
			dex
		!:
			lda #0
			sta xdelta_sub,x
			sta ydelta_sub,x
			sta enemy_clock,x
			
			lda enemypos_init_l,x
			sta xpos_l,x
			lda enemypos_init_h,x
			sta xpos_h,x
			
			jsr random_
			anc #63
			adc #32
			sta xdelta,x
			lda random_.random + 1
			anc #127
			adc xdelta,x
							//it'll be a random numeber between 32 and 224
			sta xdelta,x
			
			lda random_.random + 0
			anc #15
			adc #4			//range 4-19 on a possible movement range of 0-24
			sta ydelta,x	
			
			lda random_.random + 2
			and #[STATUS_PLANE | STATUS_XDIRECTION | STATUS_YDIRECTION]
			ora #STATUS_ALIVE
			sta status,x
			
			dex
			bpl !-			
			
			lda #$20  //jsr
			sta updateonly
						
			rts

		//First part of the AI of the enemies.
		update:
			//first we move the centre of gravity one pixel to the left, so the motion range is in sync with the vans
			ldx #11
			lda #$ff
		!:	dcp xpos_l,x
			beq !luf+ 
		!next:
			dex
			bpl !-
			jmp !displ+
		!luf:	
			dcp xpos_h,x
			beq !wrap+
			jmp !next-
			
		!wrap:
			lda #$09
			sta xpos_h,x
			lda #$ff
			sta xpos_l,x
			jmp !next-

			
			
			
		//draws the enemies. It can also apply the second part of the AI				
		draw:	
		!displ:	

			lda #[empty_sprite & $3fff] / 64
			
			sta sprf + 5
			sta sprf + 6
			sta sprf + 7
			
			lda #$ff
			sta reverselut
			sta reverselut + 1
			sta reverselut + 2
			
			
			//we need to account for the border.
			lda camera_x + 1
			sec
			sbc #24
			sta p0tmp + 2
			lda camera_x + 2
			sbc #0
			sta p0tmp + 3
	
			ldy #11 //loop on enemies
			ldx #2  //loop on hw spr
		!displayloop:
			lda status,y
			and #STATUS_ALIVE | STATUS_EXPLODING
			bne !alive+
			jmp !next+
		!alive:
			lda xpos_l,y
			clc
			adc xdelta,y
			sta p0tmp
			lda xpos_h,y
			adc #0
			sta p0tmp + 1
			
			sec
			lda	p0tmp
			sbc p0tmp + 2 //camera_x + 1
			sta p0tmp 
			lda p0tmp + 1
			sbc p0tmp + 3 //camera_x + 2
			
			bpl !skp+
			
			clc
			adc #$0a
			jmp !noov+
			
			//sta p0tmp + 1
		!skp:	
			cmp #$0a
			bcc !noov+
			
			//lda p0tmp + 1
			sbc #$0a
			
		!noov:	
			sta p0tmp + 1
			
			cmp #>348 //#>336 
			bcc !ondisplay+			
			beq !skp+
			jmp !next+
	!skp:	lda p0tmp
			cmp #<348 //<336
			bcc !ondisplay+
			jmp !next+
		
		!ondisplay:
			tya 
			sta reverselut,x
			
			//first, check if it's exploding
			lda status,y
			and #STATUS_EXPLODING
			beq !skp+
			//inc $d020
			lda enemies.enemy_clock,y
			alr #6
			eor #3
			adc #[explosion_sprite & $3fff] / 64
			sta sprf + 5,x
			lda #1
			sta sprc + 5,x
			lda enemies.enemy_clock,y
			sec
			sbc #1
			sta enemies.enemy_clock,y
			bne !nodone+
			lda #0
			sta status,y
			
		!nodone:	
			jmp !pos+
			
		!skp:	
			lda status,y
			//and #STATUS_PLANE
			bmi !plane+
		//heli
			lda #1
			sta sprc + 5,x
	
			lda enemy_clock,y
			beq !rot+
			sec
			sbc #2
			sta enemy_clock,y
			lda #[enemy2_sprite & $3fff] / 64 + 2
			sta sprf + 5,x
			jmp !pos+
				
		!rot:	
			lda clock
			alr #%00000010
			adc #[enemy2_sprite & $3fff] / 64
			sta sprf + 5,x
			lda status,y
			anc #STATUS_XDIRECTION
			beq !pos+
			lda sprf + 5,x
			adc #3
			sta sprf + 5,x
			jmp !pos+
					
		!plane:
			lda #6
			sta sprc + 5,x
			lda enemy_clock,y
			beq !skp+
			sec
			sbc #1
			sta enemy_clock,y
			lsr
			lsr
		!skp:
			clc			
			adc #[enemy1_sprite & $3fff] / 64
			sta sprf + 5,x
			lda status,y
			anc #STATUS_XDIRECTION
			beq !pos+
			lda sprf + 5,x
			adc #4
			sta sprf + 5,x	
		!pos:
			
			lda p0tmp
			sta sprxl + 5,x
			lda p0tmp + 1
			sta sprxh + 5,x 
			
			lda enemies.ypos,y
			clc
			adc enemies.ydelta,y
			sta spry + 5,x

			//now we must also apply the second part of the AI, unless the craft is exploding
		
			lda enemies.status,y
			and #STATUS_EXPLODING
			bne !skp+
			
	updateonly:		
			jsr move_enemy	//this can be forced off by writing $2c (bit opcode) to updateonly  			
	!skp:	
			
		!next:
			dex
			bpl !+
		
			ldx #2
		!:	
			dey
			bmi !done+
			jmp !displayloop-	
		!done:

			rts


	move_enemy:
	
			//can it shoot
			lda bullet.alive
			ora bullet.alive + 1
			bne !next+	//all bullets are already on display
			
			jsr random_
			lda random_.random
	shootprob:		
			cmp #4	//this is changed at level init 
			
			bcs !next+
			
			jsr bullet.fire
	
		!next:	
			lda #0
			sta p0tmp + 4 //extra boost x
			sta p0tmp + 5 //y
			lda status,y 
			and #STATUS_XBOOST
			beq !skp+
			inc p0tmp + 4
		!skp:	
			lda status,y 
			and #STATUS_YBOOST
			beq !skp+
			inc p0tmp + 5			
		!skp:	
			
			//dont move if first part of flipping animation is ongoing
			lda enemy_clock,y
			cmp #8
			bcs !next+
		
			lda status,y
			and #STATUS_XDIRECTION
			bne !left+
		//right
			lda xdelta_sub,y
			clc
			adc enemy_level_xspeed
			sta xdelta_sub,y
			lda xdelta,y
			adc enemy_level_xspeed + 1
			adc #1
			adc p0tmp + 4
			sta xdelta,y
			cmp #255 - 2 - ENEMY_MAX_XSPEED
			bcc !testflip+
			jmp !flip+
			
		!left:
			lda xdelta_sub,y
			sec
			sbc enemy_level_xspeed
			sta xdelta_sub,y
			lda xdelta,y
			sbc enemy_level_xspeed + 1
			sbc p0tmp + 4
			sta xdelta,y
			cmp #ENEMY_MAX_XSPEED + 2 
			bcs !testflip+
			jmp !flip+	
			
		!testflip:
			jsr random_
			cmp status,y	
			bne !next+
			
		!flip:
			jsr random_
			and #STATUS_XBOOST
			sta xb + 1
			lda status,y
			and #$ff - STATUS_XBOOST
			eor #STATUS_XDIRECTION
		xb: ora #$00
			sta status,y	

			lda #16	//make sure it's even
			sta enemy_clock,y
						
		!next:	//take care of vertical behavior
		
			lda status,y
			and #STATUS_YMOVES
			bne !moves+
			jmp !testflip+
			
		!moves:	
			lda status,y
			and #STATUS_YDIRECTION
			beq !up+
			//down
			lda ydelta_sub,y
			clc
			adc enemy_level_yspeed
			sta ydelta_sub,y
			lda ydelta,y
			adc enemy_level_yspeed + 1
			//adc #1
			adc p0tmp + 5
			sta ydelta,y
			cmp #32 - 4 - ENEMY_MAX_YSPEED
			bcc !testflip+
			jmp !flip+
			
		!up:
			lda ydelta_sub,y
			sec
			sbc enemy_level_yspeed
			sta ydelta_sub,y
			lda ydelta,y
			sbc enemy_level_yspeed + 1
			sbc p0tmp + 5
			sta ydelta,y
			cmp #ENEMY_MAX_YSPEED + 1 
			bcs !testflip+
			
			jmp !flip+	
			
		!testflip: //vertically we test two things: changing from still to moving, and direction.
			jsr random_ 
			ora #STATUS_ALIVE  //the alive bit is always one in status,y, because the enemy is alive. so p = 1/128
			cmp status,y	
			bne !nostillchange+
			//a change must occour.
			lda status,y
			eor #STATUS_YMOVES
			sta status,y
		!nostillchange:
			//check if we at least flip direction
			jsr random_
			cmp status,y
			bne !next+

		!flip:
			jsr random_
			and #STATUS_YBOOST
			sta yb + 1
			lda status,y
			and #$ff - STATUS_YBOOST
			eor #STATUS_YDIRECTION
		yb: ora #$00
			sta status,y	
			
	
	!next:		
	
			rts		
						
			
	.const init_list = List()
		.for (var group = 0; group < 4; group ++)
			.for (var i = 0; i < 3; i++)
				.eval init_list.add($0000 + $180 + $280 * group - 48)

	enemypos_init_l:
	.fill 12,<init_list.get(i)
	enemypos_init_h:
	.fill 12,>init_list.get(i)
		
	
	//left end of the enemy motion range
	xpos_l:
	.fill 12,0
	
	xpos_h:
	.fill 12,0
		
	ypos:
	.for (var i = 0; i < 4; i++)
	{
		.byte MINY, MINY + 32, MINY + 64
	}
	
	
	xdelta:	//current position within the motion range
	.fill 12,0
	
	xdelta_sub: //subpixel accuracy for xdelta
	.fill 12,0
	
	ydelta:
	.fill 12,0
	
	ydelta_sub:
	.fill 12,0
	
	enemy_clock:
	.fill 12,0 //used for enemy animations
	
	status:
	.fill 12,0
	
	
	reverselut:	//this associates the hw sprite number (0-2) to the enemy logical number (0-11)
	.fill 3, $ff //ff means it's not associated

}	



//there are 12 trucks. 4 convoys of 3 trucks. They move as a single object, but we still store all 12 of them for sake of consistency
//there are never more than three vans on screen at the same time, which would be awesome if we were using sprites. But we can't.

vans:
{
	deploy:
			ldx #12
			stx nvans
			dex
		!:
			lda vanpos_init_l,x
			sta xpos_l,x
			lda vanpos_init_h,x
			sta xpos_h,x
			lda #1
			sta status,x	
			dex
			bpl !-
							
			rts
			
	update:
	
			
			//first move the vans
			//we move all of them, regardless of their status, because it's not worth checking if they are alive at this stage 	
			
			ldx #11
			lda #$ff
		!:	dcp vans.xpos_l,x
			beq !luf+ 
		!next:
			dex
			bpl !-
			jmp !displ+
		!luf:	
			dcp vans.xpos_h,x
			beq !wrap+
			jmp !next-
			
		!wrap:
			lda #$09
			sta vans.xpos_h,x
			lda #$ff
			sta vans.xpos_l,x
			jmp !next-
				
		draw:
		
		!displ:
		
			lda #0
			sta hwsp + 1 //loop on "hw" pseudo sprites
		
			lda #$ff
			sta reverselut
			sta reverselut + 1
			sta reverselut + 2	
	
			//first calculate the hwscroll offset for all the vans (because the gap between vans is a multiple of 8 pixels)
		
			sec
			lda vans.xpos_l
			sbc camera_x + 1
			and #$07
			ora #$d0
			
			sta vanscroll
		
			//erase row
			ldx #39
			lda #32
		!:	sta $0400 + 19 * 40,x
			dex
			bpl !-
		
			lda clock
			alr #%00000100  //and + lsr and carry clear as a result so adc is safe
			adc #VANCHAR	//we flip between the two frames of the animation every 8 frames
			sta van_frame + 1
			
			//the vans are two chars wide. one char is hidden by the left border in 38 columns mode, but we still need to account for the other one
			//so we consider the viewport 41 chars wide instead of 38-40
			lda camera_x + 1
			sec
			sbc #8
			sta p0tmp + 2
			lda camera_x + 2
			sbc #0
			sta p0tmp + 3
			
			ldx #11 //loop on vans
		!:
			lda status,x
			beq !next+
		
			sec
			lda vans.xpos_l,x
			sbc p0tmp + 2
			sta p0tmp 
			lda vans.xpos_h,x
			sbc p0tmp + 3
			
			bpl !skp+
			
			clc
			adc #$0a
			jmp !noov+
			
			//sta p0tmp + 1
		!skp:	
			cmp #$0a
			bcc !noov+
			
			//lda p0tmp + 1
			sbc #$0a
			
		!noov:	
			sta p0tmp + 1
			
			cmp #>320 
			bcc !ondisplay+			
			bne !next+
			lda p0tmp
			cmp #<320
			bcs !next+
		
		!ondisplay:
	hwsp:	ldy #0
			txa
			sta reverselut,y

			
					
	   		lda p0tmp
	   		lsr p0tmp + 1
	   		ror
	   		lsr p0tmp + 1
	   		ror
	   		lsr p0tmp + 1
	   		ror
	   		
	   		sta pseudox,y
	   		inc hwsp + 1
	   		
	   		clc
	   		adc #<[$0400 + 19 * 40 - 1]
	   		sta p0tmp
	   		lda p0tmp + 1
	   		adc #>[$0400 + 19 * 40 - 1]
	   		sta p0tmp + 1
	   		ldy #0
	  van_frame:
	   		lda #VANCHAR
	   		sta (p0tmp),y
	   		iny
	   		ora #1 //this is like adding 1 to Accumulator, because VANCHAR is aligned to 16 bytes.
	   		sta (p0tmp),y
	   		
		!next:
			dex
			bpl !-	
		!done:
			//we have drawn all the vans. Chances are that the char at position (18,39) is "dirty" with the front of the first van on screen
			//that would be under the border, so normally we wouldn't need to worry about that, but it could still trigger collisions with the enemy
			//so let's erase it for good measure
			lda #32
			sta $0400 + 19 * 40 - 1
		
			rts
			
	.const init_list = List()
		.for (var group = 0; group < 4; group ++)
			.for (var i = 0; i < 3; i++)
				.eval init_list.add($0000 + $180 + $280 * group + i * 80)
		
	vanpos_init_l:
	.fill 12,<init_list.get(i)
	vanpos_init_h:
	.fill 12,>init_list.get(i)			
			
	xpos_l:		//pixels
	.fill 12,0
	xpos_h:
	.fill 12,0

	status:
	.fill 12,0
	
	vanscroll:
	.byte $c0
	
	pseudox:
	.fill 3, 0
	
	reverselut:
	.fill 3, $ff
	
}		


//the enemy bullet-pair is done with two identical sprites. Initially they overlap.
//after a while, they split and move only vertically.
//this means that the bullets share the same horizontal position all through their lifetime
//uses p0tmp + 4, + 5
bullet:
{

	fire:
			//if we are here, we expect that y contains the logical enemy number, and x the sprite number
	
			lda #1
			sta alive
			sta alive + 1
			
			lda #0
			sta xdir
			sta ydir		
	
			jsr random_
			lsr
		
			sta stage //random duration of stage one of the bullet, 0-127 frames	
		
			bcc !skp+
				
			ror ydir	//50% chance of also moving vertically (in the direction of the player)

		
			lda spry
			cmp spry,x
			bcs !skp+
			inc ydir  //if hero chopper flies higher than enemy, bullet goes up.
			
		!skp:
			
		
			lda sprxh
			lsr
			lda sprxl
			ror
			sta p0tmp + 4
			
			lda sprxh,x
			lsr
			lda sprxl,x
			ror
			cmp p0tmp + 4
			
			bcc !skp+
		
			inc xdir
		
		!skp:
			lda enemies.ypos,y
			clc
			adc enemies.ydelta,y
			
			sta ypos
			sta ypos + 1
			
			lda enemies.xpos_l,y
			clc
			adc enemies.xdelta,y
			sta xpos_l
			lda enemies.xpos_h,y
			adc #0
			sta xpos_h 
			
			rts		
	

	update:
	{
			lda #[empty_sprite & $3fff] / 64
			sta sprf + 3
			sta sprf + 4	
	

			lda alive
			ora alive + 1
			bne !ok+
			
			rts
			
		!ok:
			
			lda	stage
			beq !stage2+
			bmi !stage2+
			
			sec
			sbc bulletspeed
			sta stage
			
			bcs !skp+
			
			lda #0
			sta stage
		!skp:
			
			lda xdir
			bne !left+

			//goes right
			lda xpos_l
			clc
			adc bulletspeed //#2
			sta xpos_l
			
			lda xpos_h
			adc #0
			cmp #$0a
			
			bcc !skp+
			sbc #$0a
		!skp:
			sta xpos_h
			jmp !next+
			
		!left:
			lda xpos_l
			sec
			sbc bulletspeed //#2
			sta xpos_l
			
			lda xpos_h
			sbc #0
			bpl !skp+
			adc #$0a
		!skp:	
			sta xpos_h					
		
		!next: //vertical movement
			lda ydir
			bpl !disp+ // no vertical movement
			bne !up+
		//down
			
			inc ypos
			inc ypos + 1
			lda ypos
			cmp #MAXY - 8
			bcc !disp+
			lda #0
			sta stage
			jmp !disp+
		!up:
			dec ypos
			dec ypos + 1
			lda ypos
			cmp #MINY + 8
			bcs !disp+
			lda #0
			sta stage
			jmp !disp+
					
		!stage2:			
			
			lda alive
			beq !skp+
			lda ypos
			sbc #4
			sta ypos
			cmp #MINY - 8
			bcs !skp+
			lda #0
			sta alive
		!skp:
			lda alive + 1
			beq !skp+
			bmi !skp+ 	//alive + 1 > 127 means the bullet sprite must be used for an explosion	
			lda ypos + 1
			adc #4
			sta ypos + 1
			cmp #MAXY + 8
			bcc !skp+	
			lda #0
			sta alive + 1
		!skp:
			jmp !disp+	
		
		!disp:
				
			//we need to account for the border.
			lda camera_x + 1
			sec
			sbc #24
			sta p0tmp + 2
			lda camera_x + 2
			sbc #0
			sta p0tmp + 3
	

			ldx #1  //loop on hw spr
		!displayloop:
			lda alive,x
			beq !next+
			
			sec
			lda	xpos_l
			sbc p0tmp + 2 //camera_x + 1
			sta p0tmp 
			lda xpos_h
			sbc p0tmp + 3 //camera_x + 2
			
			bpl !skp+
			
			clc
			adc #$0a
			jmp !noov+
			
			//sta p0tmp + 1
		!skp:	
			cmp #$0a
			bcc !noov+
			
			//lda p0tmp + 1
			sbc #$0a
			
		!noov:	
			sta p0tmp + 1
			
			cmp #>348 // #>336 
			bcc !ondisplay+			
			beq !lc+
		!notondisplay:
			lda #0
			sta alive,x
			jmp !next+
			
		!lc:	
			lda p0tmp
			cmp #<348
			bcc !ondisplay+
			jmp !notondisplay-	
		
			
			!ondisplay:

			lda p0tmp
			sta sprxl + 3,x
			lda p0tmp + 1
			sta sprxh + 3,x 
			
			lda ypos,x
			sta spry + 3,x
			
			lda #$0d
			sta sprc + 3,x
	!next:		
			dex
			bpl !displayloop-	
			
			
			ldx #[bullet_sprites & $3fff] / 64 + 1
			lda alive
			beq !b2+
			lda stage
			beq !small+
			dex
		!small:
			stx sprf + 3	
			
			
		!b2:
			ldx #[bullet_sprites & $3fff] / 64 + 1
			lda alive + 1
			beq !done+
			bmi !exp+
			lda stage
			beq !small+
			
			dex
		!small:
			stx sprf + 4
			jmp !done+
			
		!exp:
			lda #0
			sta sprc + 4
			
			lda explosionframe
			sta sprf + 4
			
			clc
			adc #1
			cmp #[explosion_sprite & $3fff] / 64 + 4
			bcc !ok+
			
			lda #0
			sta alive + 1
			
			lda #[explosion_sprite & $3fff] / 64
			
		!ok:	
			sta explosionframe	
			
		!done:
			rts
	
		}
			
		stage:	// the bullets are joined if stage > 0, otherwise they are moving vertically.
		.byte 0 

		xpos_l:
		.byte 0
		xpos_h:
		.byte 0
		
		ypos: 
		.byte 0,0
		
		alive:
		.byte 0,0
		
		//0 goes right, 1 goes left. A bullet always moves horizontally if stage >0
		xdir:
		.byte 0
		//0 goes down, 1 goes up, >=128 it doesn't move vertically
		ydir:
		.byte 0
		
		explosionframe:
		.byte [explosion_sprite & $3fff] / 64
}