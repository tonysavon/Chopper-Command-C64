/*
at each frame the camera procedure checks the Chopper X position in world coordinates and chases a target.
the target is not exactly the chopper, which would cause player to be centered on screen, but a point in space that is in front of the chopper.
this makes sure that the camera is aware of where the chopper is facing and puts him nicely at one end of the viewport.
C = Chopper, T = Camera Target [         ] = Viewport
Chopper facing right: [ C   T     ]
Chopper facing left:  [     T   C ]
Finally the speed at which the camera chases the target is proportional to the distance from the target, which makes the effect smoother and more natural looking.
while doing all this we must take care of the wraparound at $a00:
If target is at position $80 and camera is at position $980, we don't want to move left by $900 pixels, but rather right by $100
*/
camera:
{
	chase:
				//first, let's compute the target
				//camera moves at a speed that is equal to the distance in pixel from the target / 256
				
				//p0tmp computes the target 
	
				lda #24
				
				ldx facing
				beq !skp+
				
				lda #320-72
		
			!skp:
				//now accumulator contains the desired target in the viewport distance
				//we don't just put it there, we slowly get there from the current target.
				
				//sta sub1 + 1
				cmp sub1 + 1
				beq !ok+
				
				bcs !mustincrease+
				
				lda sub1 + 1
				sec
				sbc #8
				sta sub1 + 1
				jmp !ok+
				
			!mustincrease:	
				lda #8
				clc
				adc sub1 + 1
				sta sub1 + 1
				
			!ok:				

				sec
				lda xpos + 1
		sub1:	sbc #24
				sta p0tmp + 1
				lda xpos + 2
				sbc #0
				sta p0tmp + 2

			
				//p0tmp is the target.
				//the first thing we need to do is to measure the distance between the camera and the target
			
				//compute the two distances. Left and right
					
				lda p0tmp + 1
				sec
				sbc camera_x + 1
				sta p0tmp + 3
				lda p0tmp + 2
				sbc camera_x + 2
				sta p0tmp + 4

		
				lda camera_x + 1
				sec
				sbc p0tmp + 1
				sta p0tmp + 5
				lda camera_x + 2
				sbc p0tmp + 2
				sta p0tmp + 6
				
			

				//where do we need to go?
				lda p0tmp + 4
				cmp p0tmp + 6
				bcs !left+
				
				//right
				lda p0tmp + 1
				sec
				sbc camera_x + 1
				sta p0tmp + 3
				lda p0tmp + 2
				sbc camera_x + 2
				sta p0tmp + 4
				
				lsr p0tmp + 4
				ror p0tmp + 3
				
				lsr p0tmp + 4
				ror p0tmp + 3
				
				lda p0tmp + 3
		
				clc
				adc camera_x + 1
				sta camera_x + 1
				lda camera_x + 2
				adc p0tmp + 4
				sta camera_x + 2
	
				jmp !next+
				
				
		!left:		
				
				lda camera_x + 1
				sec
				sbc p0tmp + 1
				sta p0tmp + 3
				lda camera_x + 2 
				sbc p0tmp + 2
				sta p0tmp + 4
				
				
		
				lsr p0tmp + 4
				ror p0tmp + 3	
			
				lsr p0tmp + 4
				ror p0tmp + 3	
				
			!skp:
				
				lda camera_x + 1
				sec
				sbc p0tmp + 3
				sta camera_x + 1
				lda camera_x + 2
				sbc p0tmp + 4
				sta camera_x + 2
	
				
				jmp !next+
										
		!next:	

				lda camera_x + 1
				and #7
				eor #7
				ora #$d0
				sta hwscroll
			
				lda camera_x + 1
				alr #7 * 2
				eor #7				
				ora #$d0
				sta clouds_hwscroll 
				
				lda camera_x + 1
				sec
				sbc #<[$0a00 / 2 - 160]
				sta radar.pixelviewport
				lda camera_x + 2
				sbc #>[$0a00 / 2 - 160]
				bpl !+
				clc
				adc #$0a
			!:
				sta radar.pixelviewport + 1	

					
				rts
									
}