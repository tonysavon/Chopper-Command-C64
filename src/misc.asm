//this is the classic vblank. For all those cases where panelvsync is not needed  			
vsync:
{
				bit $d011
				bmi * -3
				bit $d011
				bpl * -3
				rts
}			


//this erases the entire game area, except the vans row. It is 13 charline (520 chars)
eraseplayarea:
{
				ldx #103
				lda #32
			!:	
				.for (var i=0; i < 5; i++) 
					sta $0400 + 6 * 40 + 104 * i,x 
		
				dex
				bpl !-
				rts
}

					
//32 bit random number generator
random_:
{
		        asl random
		        rol random+1
		        rol random+2
		        rol random+3
		        bcc nofeedback
		        lda random
		        eor #$b7
		        sta random
		        lda random+1
		        eor #$1d
		        sta random+1
		        lda random+2
		        eor #$c1
		        sta random+2
		        lda random+3
		        eor #$04
		        sta random+3
		nofeedback:
        		rts

random: .byte $ff,$ff,$ff,$ff
}

.macro LoadSprites(fname,start,n)
{
	.const sf = LoadBinary(fname)
	.fill 64 * n, sf.get(start * 64 + i)
}


flip_sprite:
{
			init:
				ldx #0
			!:	lda #0
				sta sprmir,x
				txa
				
				.for (var i = 0; i < 8; i++)
				{
					asl
					ror sprmir,x
				}
				
				inx
				bne !-
				rts
					
			//load x with the source sprite number, y with the destination sprite number		

			flip:			
				stx src1 + 2
				lda #0
				lsr src1 + 2
				ror
				lsr src1 + 2
				ror
				sta src1 + 1
				
				sty dst1 + 2
				lda #0
				lsr dst1 + 2
				ror
				lsr dst1 + 2
				ror
				sta dst1 + 1
									
			
				ldy src1 + 1
				iny 
				sty src2 + 1
				iny
				sty src3 + 1
					
				ldy dst1 + 1
				iny 
				sty dst2 + 1
				iny
				sty dst3 + 1
	
				ldy src1 + 2
				sty src2 + 2
				sty src3 + 2
	
				ldy dst1 + 2
				sty dst2 + 2
				sty dst3 + 2

			
				ldx #$3c //bottom left byte offset
		!:		
							
		src1:	ldy $e000,x
				lda sprmir,y
		src3:	ldy $e002,x	
		dst3:	sta $e002,x
			lda sprmir,y
		dst1:	sta $e000,x
	
		src2:	ldy $e001,x
			lda sprmir,y
		dst2:	sta $e001,x
				
				txa
				axs #$03 //dex * 3. We save 2 cycles.
					
				bpl !-
	
				rts

			
	sprmir:
		.fill $100,0					
					
}


//Displays the  Get Ready and Game Over animations
//load A with 0 for getready or 1 for gameover, then call init
//call play once per frame to animate
bigsign:
{
			
			init:		
				sta type			
				
				lda #0
				sta sclock
			
				//clears the destination area
				ldx #71
			!:	
				.for (var i = 0; i < 4; i++)
					sta bigsign_area + i * 72,x	
				dex
				bpl !-
				
				//place 36 (empty) chars on screen, like this
				//00 02 04 ... 34
				//01 03 05 ... 35
				ldx #0
				
				lda #BIGSIGNCHAR
				clc
			!:	sta $0400 + 12 * 40 + 11,x
				adc #1
				sta $0400 + 13 * 40 + 11,x
				adc #1
				inx
				cpx #18 //this will also clear the carry for all the iteration but the last one
				bne !-
				
				// make everything white
				lda #1
				ldx #17
			!:	sta $d800 + 12 * 40 + 11,x
				sta $d800 + 13 * 40 + 11,x
				dex
				bpl !-
				rts
				
				//call once per frame			
			play:
				lda sclock
				cmp #32
				bcs !done+
				
				and #1
				bne !incdone+
				
				ldx #0
				
				lda sclock
				lsr
				tax
				
				lda type
				bne !skp+
				
				jsr scrgr
				jmp !incdone+
		!skp:	jsr scrgo
					
			!incdone:	
				inc sclock
			!done:
				rts	
				
		scrgr:	
				
				ldy #0
			!:
				.for (var i = 0; i < 18; i ++)
				{
					lda getreadymap + 32 * i,x
					sta bigsign_area + 16 * i,y
				}
				iny
				inx
				cpy #16
				bne !-
				rts
			
		scrgo:	
				
				ldy #0
			!:
				.for (var i = 0; i < 18; i ++)
				{
					lda gameovermap + 32 * i,x
					sta bigsign_area + 16 * i,y
				}
				iny
				inx
				cpy #16
				bne !-
				rts		
				
	type:
		.byte 0						
	sclock:
		.byte 0				
}