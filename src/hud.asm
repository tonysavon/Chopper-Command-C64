//puts down score into sprites
update_score:
{
		.for (var s = 0; s < 2; s++)
		{
			ldx #0
		!:	lda score + s * 3,x
			asl
			asl
			asl
			tay	
			
			//ldy #0
			.for (var i = 0; i < 7; i++)
			{
				lda digits + i,y
				sta score_sprites + 2 * 3 + i * 3 + s * 64,x
			}
			inx
			cpx #3
			bne !-
		}	
			rts										
}

//add to score. Load A with the points x 100 to be added.
//000x00
add_score:
{
			ldy #0 //flag for extralives
	
			ldx #3 //back_counter on digits
		!:	clc
			adc score,x
			sta score,x
			cmp #$0a
			bcc !done+
			sbc #$0a
			sta score,x
			lda #1
			cpx #2
			bne !skp+
			
			iny

		!skp:	
			dex 
			bpl !- 
		//overflow!
			lda #9
			sta score
			sta score + 1
			sta score + 2
			sta score + 3
			sta score + 4
			sta score + 5
			
		!done:
			
			cpy #0
			beq !skp+
		
			lda lives
			cmp #6
			bcs !skp+
			inc lives
		!skp:	
			jmp update_score 
}
digits:
.import binary "../font/digits.bin"