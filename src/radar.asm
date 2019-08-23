//the radar is 128 pixels wide and it should cover $a00 (2560) possible x positions.
//We are working with fat pixels, which means that we reall have 64 possible x offsets in the radar.
//Therefore each fat pixel corresponds to 40 pixels on the map.
//We must divide by 40: that's like divided by 8 (three shifts) and then divide by 5, for which we already have a divtable

radar:
{

		init:
				lda #>radar_map
				sta p0radar + 1
		
				ldx #0
				lda #0
			!:	sta radar_map,x
				inx
				bne !-
			
			
				ldx #[radar_data_end - radar_data_start] - 1
			!:	sta radar_data_start,x
				dex
				bpl !-	
				
				rts
				
	plot:
				lda clock
				and #1
				beq plot_friends
				jmp plot_foes
				 					
				
	plot_friends:				
	
				//plot the hero, unless it's gameover
				lda lives
				bne !skp+
				jmp !plotvans+
		!skp:
				lda hero_previous_addr
				sta p0radar
				ldx hero_previous_off
				
				ldy hero_previous_y
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				
				lda xpos + 1
				sta p0tmp
				lda xpos + 2
				sta p0tmp + 1
				:toradarx() 
				tax
				sta hero_previous_off
				lda p0radar
				sta hero_previous_addr
				
				lda ypos
				sec
				sbc #MINY
				lsr
				lsr
				lsr
				
				sta hero_previous_y
				tay
				
				lda (p0radar),y
				ora friendormask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				ora friendormask,x
				sta (p0radar),y
				
		!plotvans:			
				//first erase the old ones
				
				lda vans_previous_addr
				sta p0radar
				lda vans_previous_off
				sta p0tmp + 2
				
				lda #0
				sta p0tmp + 3
			
				!:	
				ldx p0tmp + 2
			.for (var i = 0; i < 4; i++)	
			{
				ldy #12
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				lda p0radar
				clc
				adc #64
				sta p0radar
			}

				
				lda #3
				sec
				isc p0tmp + 3
				
				beq !done+
				
				lda p0tmp + 2
				clc
				adc #2
				cmp #4
				bcc !skp+
				sbc #4
				tax
				lda p0radar
				clc
				adc #16
				sta p0radar
				txa
		!skp:	sta p0tmp + 2	
				
				jmp !-
			!done:
					

				//now draw them
				lda vans.xpos_l
				sta p0tmp
				lda vans.xpos_h
				sta p0tmp + 1
				:toradarx() 
				tax
				sta vans_previous_off
				sta p0tmp + 2
				
				lda p0radar
				sta vans_previous_addr
				
				lda #0
				sta p0tmp + 3 //loops on vans within a group				
				
			!:	
				lda p0tmp + 3
				sta p0tmp + 4 //loops on logical van number
				
				ldx p0tmp + 2
			.for (var i = 0; i < 4; i++)	
			{
				ldy p0tmp + 4
				lda vans.status,y
				beq !skp+
			
				ldy #12
				lda (p0radar),y
				ora friendormask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				ora friendormask,x
				sta (p0radar),y
				
			!skp:
				lda p0tmp + 4
				clc
				adc #3
				sta p0tmp + 4
					
				lda p0radar
				clc
				adc #64
				sta p0radar
			}
					
				inc p0tmp + 3
				lda p0tmp + 3
				cmp #3
				beq !done+
				
				lda p0tmp + 2
				clc
				adc #2
				cmp #4
				bcc !skp+
				sbc #4
				tax
				lda p0radar
				clc
				adc #16
				sta p0radar
				txa
		!skp:	sta p0tmp + 2	
				
				jmp !-
			!done:
			
				rts
	
				
	plot_foes:

				ldx #11
		!:		stx p0tmp + 2 //loops on enemies
				
				lda enemies.status,x
				and #enemies.STATUS_ALIVE
				bne !ok+
				jmp !ne+
			!ok:
				//erase previous position
				lda enemy_previous_addr,x
				sta p0radar
				lda enemy_previous_off,x
				
				ldy enemy_previous_y,x
	
				tax
				
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				
				//draw new position
				ldx p0tmp + 2
				
				lda enemies.xpos_l,x
				clc
				adc enemies.xdelta,x
				sta p0tmp
				lda enemies.xpos_h,x
				adc #0
				cmp #$0a
				bcc !skp+
				sbc #$0a
			!skp:	
				sta p0tmp + 1
				:toradarx()
				
				sta p0tmp + 3
				
				sta enemy_previous_off,x
				lda p0radar
				sta enemy_previous_addr,x
				
				lda enemies.ypos,x
				clc
				adc enemies.ydelta,x
				sec
				sbc #MINY
				lsr
				lsr
				lsr
				
				sta enemy_previous_y,x
				tay
				
				ldx p0tmp + 3
				lda (p0radar),y
				ora enemyormask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				ora enemyormask,x
				sta (p0radar),y				
		
				ldx p0tmp + 2
		!ne:	dex
				bmi !done+
				jmp !-
	!done:
				rts			
	
radar_data_start:
	
	hero_previous_addr:
	.byte 0		
	hero_previous_off:
	.byte 0
	hero_previous_y:
	.byte 0
	
									
	vans_previous_addr:
	.byte 0
	vans_previous_off:
	.byte 0 
		
	enemy_previous_addr:
	.fill 12, 0		
	enemy_previous_off:
	.fill 12, 0
	enemy_previous_y:
	.fill 12, 0
	
	pixelviewport:
	.byte 0,0

radar_data_end:	
}



//load p0tmp, p0tmp + 1 with object's word x-coordinate ($0-$a00). 
//Returns the pixel offset in the radar in the accumulator (0-63), adjusted in the viewport
//sets p0tmp + 2, p0tmp + 3 with the char memory address at y = 0, which means we can just use (p0tmp + 2),y to plot
.macro toradarx()
{
				sec
				lda p0tmp
				sbc radar.pixelviewport
				sta p0tmp
				lda p0tmp + 1
				sbc radar.pixelviewport + 1
				bpl !+
				clc
				adc #$0a
			!:  
				lsr
				ror p0tmp
				lsr
				ror p0tmp
				lsr 
				ror p0tmp
				sta p0tmp + 1
				
				lda p0tmp
				clc
				adc #<div5
				sta pixsrc + 1
				lda p0tmp + 1
				adc #>div5
				sta pixsrc + 2

	pixsrc:		lda div5
				

				sta p0tmp
			
			/*	lsr
				lsr //char column
				asl
				asl
				asl
				asl
			*/
				//the following is equivalent
				and #%00111100
				asl
				asl	
				
				sta p0radar
				
				lda p0tmp
				and #3

}


//the following are global, as we use them pretty much everywhere.

friendormask:
.byte %11000000
.byte %00110000
.byte %00001100
.byte %00000011

enemyormask:
.byte %10000000
.byte %00100000
.byte %00001000
.byte %00000010

andmask:
.byte %00111111
.byte %11001111
.byte %11110011
.byte %11111100
