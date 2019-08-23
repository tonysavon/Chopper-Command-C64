hero:
{
	//inits all the member variables of the hero "class" 
	//the chopper uses two sprites (0 and 1)
	//it also inits viewport variable because every time we init the chopper we must also init the viewport
	init:
	
			//chopper color
			lda #7
			sta sprc
			sta sprc + 1
	
			
			lda #0
			sta camera_x
			sta camera_x + 1
			
			sta xpos
			sta xpos + 1
		
			sta speed
			sta speed + 1

			sta facing

			sta flipclock

			sta shadowd01f
			sta shadowd01e
			
			sta beam.active
			sta beam.active + 1
								
			lda #$08
			sta testcollisions.dontcheck //we also init invincibility for the enemies here
			
			//grant 64 frames of invincibility wheneer the hero is initialized 
			lda #$3f
			sta invincibility
			//and make it blink!
			lda #1
			sta blink
					
			//viewport is slightly ahead of the chopper, so while get ready is on display the camera gently catches up	
			lda #$00
			sta xpos + 2
			lda #$01
			sta camera_x + 2
				
			lda #128	//vertically "kinda" centered
			sta ypos
		
			rts
		
			//translates controls into actions	
	update:
			lda ypos
			sta spry 
			sta spry + 1 
	
			sec
			lda xpos + 1
			sbc camera_x + 1
			sta p0tmp
			lda xpos + 2
			sbc camera_x + 2
			sta p0tmp + 1
			
			lda p0tmp
			clc
			adc #24
			sta sprxl + 0
			lda p0tmp + 1
			adc #0
			sta sprxh + 0
			
			lda p0tmp
			clc
			adc #48
			sta sprxl + 1
			lda p0tmp + 1
			adc #0
			sta sprxh + 1
		!skp:
		
			lda flipclock
			beq !regular+
			
			dec flipclock
			lda #[hero_sprite & $3fff] / 64 + 8 //flipping frame
			clc
			jmp !str+
			
			
		!regular:
			lda clock
			//and #1
			//asl
			and #%00000010
			sta p0tmp
			lda facing
			asl
			asl
			adc p0tmp
		
			adc #[hero_sprite & $3fff] / 64
			
	!str:		
			sta sprf
			adc #1
			sta sprf + 1
			 	
	!next:		
						
			rts 
						
}

//plays the rotor sound, whose speed changes according to chopper speed. Hence, it needs special cares
rotor:
{
			dec rotor_clock
			bpl !skp+
			
			:sfx(sfx_rotor,0)
			
			lda speed + 1
			lsr 
			
			sta p0tmp
			
			lda #8
			sec
			sbc p0tmp
			sta rotor_clock
		!skp:	
			
			rts
			
rotor_clock:
.byte 0			
}