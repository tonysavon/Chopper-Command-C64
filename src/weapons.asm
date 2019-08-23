//friendly fire is just a nice laser beam.
//now, unlike the other objects in game, laser beams follow screen coordinates, rather than world coordinates
//this makes things much easier on the cpu side, and the parallax discrepancies are not noticeable because the beam is very fast.
//this is also consistent with the way the original draws the beam
//there are a maximum of two beams on screen at the same time. 
beam:
{
	
		fire:
				lda timer
				beq !canfire+
				rts 		//sorry, dude, you can't shoot
	
		!canfire:
	
				:sfx(sfx_fire,1)
		
				lda #10		//you can shooot maximum one laser shot every 10 frames. (5 rounds per second on PAL)
				sta timer	
		
				lda flipflop	//which cof the two cannons is available?
				eor #1
				sta flipflop
				tax
				
				lda #1
				sta active,x
					
				lda spry
				sec
				sbc #31
				lsr
				lsr
				lsr
		
				sta y0,x
				
				lda spry
				sec
				sbc #31
				and #7
				lsr
				clc
				adc #BEAMCHAR
				sta char,x
						
				lda sprxl
				clc
				adc #4
				pha
				lda sprxh
				//and #1
				adc #0
				lsr
				pla
				ror
				lsr
				lsr
				
				
				// now we have the x offset in chars 
				sta x0,x
				lda #4
				sta size,x	
				
				lda #$00
				sta age,x
				
				lda facing
				sta direction,x
				
				beq !firesright+
				
				//fires left
				lda x0,x
				sec
				sbc #2
				jmp !doneadjusting+
				
			!firesright:
				lda x0,x
				clc
				adc #1
			!doneadjusting:
				sta x0,x
				
				rts
							
				
		update:
				lda timer
				beq !skp+
				dec timer
				
			!skp:	
		
				ldx #1
		!beamloop:		 
				lda active,x
				bne !ok+ 
				jmp !next+
			!ok:	
				ldy y0,x
				lda screen40l,y
				sta wp0tmp
				sta wp0tmp + 4
				lda screen40h,y
				sta wp0tmp + 1
				clc
				adc #>[$d800 - $0400]
				sta wp0tmp + 5
				ldy x0,x
				
				lda size,x
				clc
				adc #1
				sta wp0tmp + 2
				
				
				lda direction,x
				beq !right+
		//left	
				lda #32 //empty char
			!:	sta (wp0tmp),y
				dey
				bmi !doneerasing+
				dec wp0tmp + 2
				bne !-
				jmp !doneerasing+	
		
				
				//one possible optimization here would be to only erase the delta
				//but the original does it this way, and so do we!
				//there's plenty of rastertime available anyway, so no point in making code too complicate
		!right:		
				//first thing to do, erase the old beam
				lda #32 //empty char
			!:	sta (wp0tmp),y
				iny
				cpy #40
				beq !doneerasing+
				dec wp0tmp + 2
				bne !-
				
	
			!doneerasing:	
				lda size,x
				clc
				adc #2
				sta size,x
				cmp #34
				bcc !ok+
			!deactivate:
				lda #0
				sta active,x
				jmp !next+
			!ok:
				//update age and color
				ldy age,x
				cpy #10
				beq !ok+
				iny
				inc age,x
			!ok:
				lda gradient,y
				sta col2 + 1
				sta col1 + 1	
			//update beam position and size
				lda direction,x
				beq !right+
			//left
				lda x0,x
				sec
				sbc #2
				sta x0,x
				cmp #2
				bcs !ok+
				jmp !deactivate-	
			!right:	
				lda x0,x
				clc
				adc #2
				sta x0,x
				cmp #35
				bcc !ok+
				jmp !deactivate-	
			!ok:
				//draw the new beam
				tay
				lda size,x
				sta wp0tmp + 2
				lda char,x
				sta chr1 + 1
				sta chr2 + 1
				
				lda direction,x
				beq !right+
			//left
				
					
			!:	
			chr1: lda #$00
				sta (wp0tmp),y
			col1: lda #$00
				sta (wp0tmp + 4),y
				dey
				beq !doneplotting+
				dec wp0tmp + 2
				bne !-
				jmp !doneplotting+
			!right:	
			!:
			chr2: lda #$00
				sta (wp0tmp),y
			col2: lda #$00
				sta (wp0tmp + 4),y
				iny
				cpy #39
				beq !doneplotting+
				dec wp0tmp + 2
				bne !-
			!doneplotting:	
							
			!next:	
				dex
				bmi !done+
				jmp !beamloop-
			!done:
				rts		
			
	timer:
	.byte 0
	
	flipflop:
	.byte 0
	
	active:
	.byte 0,0
	
	y0:	//vertical offset in chars
	.byte 0,0
	
	char: //4 possible chars for the beam, according to the vertical offset
	.byte 0,0
	
	x0:	//horizontal offset of the inner end of the beam in chars
	.byte 0,0
	
	direction:	//0 = shooting right, 1 = shooting left
	.byte 0,0	
	
	size:
	.byte 0,0 //this also works as a clock.
	
	age:
	.byte 0,0 //how long the beam has been on display, which also affects its length 
	
	
	gradient:
	//beam colors
	.byte 0, $06,$06,$06,$06,$0e,$0e,$0e,$03,$03,$01

}