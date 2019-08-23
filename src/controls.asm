
//we don't use 2 complement math in this game, but rather the num + sign format. 
//it wastes one byte for each variable and it's slower for adc and sbc, but it's much faster when it comes to translating results to screen coordinates
//We need few macros and functions to handle this weird format though
//

//adds an immediate 8 bit value to a 16 bit signed number
.macro s16u8adcIMM(sign,num1,num2)
{
		lda sign
		beq simpleadd
		//it's negative, so we have to do a subtraction.
		sec 
		lda num1
		sbc #num2
		sta num1
		bcs ok // still negative, exit
		lda num1+1 //we should now decrement num1+1
		beq reset // check if zero first (decrementing would wrap arouund)
		dec num1+1
		bcc ok // this branch is always taken, because we are here because the carry is clear
reset:	
		sec
		lda #$00
		sbc num1
		sta num1
		lda #$00
		sta sign
		sec
		bcs ok		
		
simpleadd: // num1 is positive, just add
		clc
		lda num1
		adc #num2
		sta num1
		bcc ok
		inc num1+1
ok:					
}


//subtracts an immediate 8 bit value from a 16 bit signed integer 
.macro s16u8sbcIMM(sign,num1,num2)
{
		lda sign
		bne simpleadd // if it's negative, doing a sub is like leaving the sign unaltered and doing add
		//it's positive, so we have to do a simple sbc
		sec 
		lda num1
		sbc #num2
		sta num1
		bcs ok // still negative, exit
		lda num1+1 //we should now decrement num1+1
		beq reset // check if zero first (decrementing would wrap arouund)
		dec num1+1
		bcc ok // this branch is always taken, because we are here because the carry is clear
		
reset:	
		sec
		lda #$00
		sbc num1
		sta num1
		lda #$01
		sta sign
		//dec sign 
		sec
		bcs ok	
		
simpleadd: // num1 is negative, just add
		clc
		lda num1
		adc #num2
		sta num1
		bcc ok
		inc num1+1
ok:							
}



controls:
{

				lda $dc00
				
				jsr readjoy
				lda #$00
				rol
				sta fire
				
				//first check y
				
				cpy #0
				beq !horizontal+
				cpy #$ff
				beq !goesup+
		//goes down
				
				ldy ypos
				cpy #MAXY
				bcs !horizontal+
				iny 	
				sty ypos
				jmp !horizontal+ 
			!goesup:
			
				ldy ypos
				cpy #MINY
				beq !horizontal+
				dey
				sty ypos
				
		!horizontal:		
				
				cpx #1
				beq !right+
				
				cpx #0
				bne !left+
				
				jmp !decelerate+
				
		!left:
				lda #1
				cmp facing
				beq !skp+
				sta facing
				lda #4
				sta flipclock
			!skp:	
				:s16u8sbcIMM(speed_sign,speed,ACCELERATION)		
				jmp !clamp+	
		!right:
				lda #0
				cmp facing
				beq !skp+
				sta facing
				lda #4
				sta flipclock
			!skp:
				:s16u8adcIMM(speed_sign,speed,ACCELERATION)
				
		!clamp:		
				lda speed + 1
				cmp #MAXSPEED
				bcc !updatex+
				
				lda #MAXSPEED
				sta speed + 1
				
				lda #0
				sta speed		
				jmp !updatex+
				
		!decelerate:
				lda speed
				ora speed + 1
				bne !moves+
				jmp !button+  //no need to update
		!moves:		
				sec
				lda speed
				sbc #DECELERATION
				sta speed
				lda speed + 1
				sbc #0
				sta speed + 1
				bcs !ok+
				lda #0
				sta speed
				sta speed + 1
				
			!ok:	
				jmp !updatex+						
		
		
		!updatex:
				lda speed_sign
				bne !left+
				
				clc
				lda xpos
				adc speed
				sta xpos
				lda xpos + 1
				adc speed + 1
				sta xpos + 1
				lda xpos + 2
				adc #0
				sta xpos + 2
				//we must wrap around at #$0c00  to $200
				cmp #$0a
				bcc !ok+
			!fix:	
				//sec
				lda xpos + 1
				sbc #$00
				sta xpos + 1
				lda xpos + 2
				sbc #$0a
				sta xpos + 2
				
				sec
				lda camera_x + 1
				sbc #$00
				sta camera_x + 1
				lda camera_x + 2
				sbc #$0a
				sta camera_x + 2
				
			!ok:	
				jmp !button+
				
		!left:
				sec
				lda xpos
				sbc speed
				sta xpos
				lda xpos + 1
				sbc speed + 1
				sta xpos + 1
				lda xpos + 2
				sbc #0
				sta xpos + 2
						
				bcs !ok+
	
				//we must wrap around at #$0000 -> $0a00
				
				lda xpos + 1
				adc #$00
				sta xpos + 1
				lda xpos + 2
				adc #$0a
				sta xpos + 2
				
				clc
				lda camera_x + 1
				adc #$00
				sta camera_x + 1
				lda camera_x + 2
				adc #$0a
				sta camera_x + 2
				
			!ok:
				jmp !button+
				
				
				
						
		!button:
				lda fire
				bne !next+
			
				jsr beam.fire
		!next:			
				rts
				
fire:
.byte 0
}
			

readjoy:
{
		
		djrrb:	ldy #0        
				ldx #0       
				lsr           
				bcs djr0      
				dey          
		djr0:	lsr           
				bcs djr1      
				iny           
		djr1:	lsr           
				bcs djr2      
				dex           
		djr2:	lsr           
				bcs djr3      
				inx           
		djr3:	lsr           
				rts
}					