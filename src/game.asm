/*
Chopper Command
Coded by Antonio Savona
*/

//#define DEBUG

//#define INVINCIBLE

.const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
.var kla = LoadBinary("../assets/splash.kla", KOALA_TEMPLATE)

.const p0start = $02
.var p0current = p0start
.function reservep0(n)
{
	.var result = p0current
	.eval p0current = p0current + n
	.return result
}

.const sid =  LoadSid("..\sid\chopper_command_c64.sid")

//allocates page zero
.const sprf  = reservep0(8)
.const sprxl = reservep0(8)
.const spry  = reservep0(8)
.const sprxh = reservep0(8)
.const sprc	 = reservep0(8) 

.const shadowd01f = reservep0(1)
.const shadowd01e = reservep0(1)

.const level = reservep0(1) 
.const enemy_level_xspeed = reservep0(2) // horizontal speed of the enemies, a function of the level
.const enemy_level_yspeed = reservep0(2) // vertical speed of the enemies, a function of the level
.const score = reservep0(6)


.const tozero = sprf
.const tozerosize = p0current //during init, we zero from sprxl to here

.const nenemies = reservep0(1)	//number of enemies left
.const nvans	= reservep0(1)  //number of trucks left
.const lives = reservep0(1)		//lives

//upon starting a mission, the chopper enjoys a little bit of invincibility.
.const invincibility = reservep0(1)	
//invincibility can be explicit (blink = 1) or not. when an enemy dies the player is granted 8 frames of invincibility
//to let the explosion animation run.
.const blink = reservep0(1)

.const camera_x = reservep0(3) 		//left hand side of the viewport, in pixels, with subpixel accuracy. 

.const clock = reservep0(1)			//frame counter. Used for several animations
.const xpos = reservep0(3)			//player position in pixel with subpixel accuracy
.const ypos = reservep0(1)			//player vertical position in pixel. No subpixel accuracy is required here as there's no vertical acceleration
.const speed_sign = reservep0(1) 	//0 = going right, 1 = going left
.const speed = reservep0(2) 		//speed in pixels per frame, with subpixel accuracy
.const facing = reservep0(1)		//were the chopper is facing
.const flipclock = reservep0(1)		//when the elicopter changes direction, a counter is used to keep track of how many frames the intermediate sprite has been on display
.const camera_target = reservep0(2)

.const bulletspeed = reservep0(1)

.const redraw = reservep0(1)		//signals that all the objects have been updated and screen can be updated too
.const hwscroll = reservep0(1)		//hw scroll (0..7)
.const clouds_hwscroll = reservep0(1)	//clouds part

.const p0tmp =  reservep0(8)
.const wp0tmp =  reservep0(8)

.const p0radar = reservep0(2)		//points somewhere within the charset

.const MAXY = 179 + 3
.const MINY = 84 + 3 				//make sure that maxy-miny = 96-1. That's 12 chars minus one pixel

.const ACCELERATION = %01000000		//you can play with this and enjoy a snappy or ultra un-responsive chopper. These default values seem to match the original's responsiveness
.const DECELERATION = %00010000

.const MAXSPEED = 6 				//helicopter max horizontal speed in pixels per frame. This can be altered as well, but high values will make it hard for the camera to catch up

.const ENEMY_MAX_XSPEED = 8 		//maximum pixel per frame speed for the enemies. Planes are 1 pixel per frame faster. Don't go too wild on this
.const ENEMY_MAX_YSPEED = 4 



// Place loading bitmap
.pc = $8000 "kla scrn"
.fill 1000,kla.getScreenRam(i)

.pc = $8400 "kla col"
.fill 1000,kla.getColorRam(i)

.pc = $a000 "kla bmp"
.fill 8000,kla.getBitmap(i)


.pc = $3800 "charset"
charset:
.const bgcharset = LoadBinary("..\bg\bg.imap")
.fill bgcharset.getSize(),bgcharset.get(i)
clouds_charset:
.const clcharset = LoadBinary("..\bg\clouds.imap")
.fill clcharset.getSize(),clcharset.get(i)
.align $8
radar_mountains:
.import binary "..\radar\mountains.imap"

.align $10
.const VANCHAR = (* - charset) / 8
van_char:
.const van_png = LoadPicture("..\sprites\charvan.png")
.for (var x = 0; x < 4; x++)
	.for (var y = 0; y < 8; y++) 
		.byte van_png.getSinglecolorByte(x,y)

.const BOTTOMBORDERCHAR = (* - charset) / 8
.byte %11111111
.byte %01010101
.byte %01010101
.byte %01010101
.byte %01010101
.byte %01010101
.byte %01010101
.byte %01010101

.const FULLBOTTOMCHAR = (* - charset) / 8
.fill 8, %01010101

.const BEAMCHAR = (* - charset) / 8 

.byte %11111111
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000

.byte %00000000
.byte %00000000
.byte %11111111
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000

.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %11111111
.byte %00000000
.byte %00000000
.byte %00000000

.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %00000000
.byte %11111111
.byte %00000000

//mastering the art of pixelling!

//this picture contains the large GAME OVER and GETREADY signs
.const grgo = LoadPicture("..\assets\grgo.png")

//target area for game over and get ready signs
bigsign_area:
.const BIGSIGNCHAR = (* - charset) / 8
.fill 18*2*8,0


//2 lines of 16 chars will do for the radar
.align $100
.const RADARMAPCHAR = (* - charset) / 8
radar_map:
.fill 16*2*8,0

.pc = $3400 + 40 * 17 "credits"

.text "             Adaptation by              "
.text "                                        "
.text "         A. Savona : Code               "
.text "            S. Day : Graphics           "
.text "          S. Cross : Music              "
.text "        F. Martins : Sfx                "
.text "                                        "
.text " Copyright 1982, 1984  Activision, Inc. " 

.pc = $2900 "sprites"
hero_sprite:
:LoadSprites("..\sprites\hero.bin",0,4)
.fill 4 * 64,0
:LoadSprites("..\sprites\hero.bin",8,2)

bullet_sprites:
.import binary "..\sprites\bullet.bin"
enemy1_sprite:
:LoadSprites("..\sprites\enemy1.bin",0,4)
.fill 4 * 64,0

enemy2_sprite:
:LoadSprites("..\sprites\enemy2.bin",0,3)
.fill 2 * 64,0

hud_chopper_sprite:
.import binary "..\sprites\hud_chopper.bin"
explosion_sprite:
.import binary "..\sprites\explosion.bin"

score_sprites:
.fill 64 * 2, 0


logo_sprites:
	.var logopic = LoadPicture("..\assets\activisionlogo2.png",List().add($0000ff, $000000, $ffffff, $5c4700))
	.for (var s=0;s<6;s++)
	{
		.for (var y=0; y<21; y++)
			.for (var x=0; x<3; x++)
				.byte logopic.getMulticolorByte(s*3 + x,y) 
		.byte 0
	}
logo_bars:
	.var barpic = LoadPicture("..\assets\activisionlogo_bands.png",List().add($0000ff, $ffffff))
	.for (var y=0; y<21; y++)
		.for (var x=0; x<3; x++)
			.byte barpic.getSinglecolorByte(x,y) 
	.byte 0

//a blank sprite is a convenient way of switching sprites off without messing around with $d015 too much	
empty_sprite:
.fill 64 , 0

.align $100 
.pc = * "bgpattern"
bgpattern:
.const bgmap = LoadBinary("..\bg\bg.iscr")
.const bgpattern_borderchar = bgmap.get(5 * 40)


.fill 20,bgmap.get(20 + i + 3 * 40)
.fill 40,bgmap.get(i + 3 * 40)
.fill 20,bgmap.get(i + 3 * 40)

//row 2
.fill 20,bgmap.get(20 + i + 4 * 40)
.fill 40,bgmap.get(i + 4 * 40)
.fill 20,bgmap.get(i + 4 * 40)


//cloud pattern
.align $100
cloudpattern:
.const clmap = LoadBinary("..\bg\clouds.iscr")
.for (var i=0; i<4; i++)
	.fill 16,clmap.get(i) +  [clouds_charset - charset]/8
.for (var i=0; i<4; i++)
	.fill 16,clmap.get(i + 16) +  [clouds_charset - charset]/8
	

//charmap and colormap for the bottom area. 5 charlines
bottom_charmap:

//first line, just a single line
.fill 40, BOTTOMBORDERCHAR

.fill 12, FULLBOTTOMCHAR
.fill 16, 32 				//this will be covered by mountains
.fill 12, FULLBOTTOMCHAR

.fill 12, FULLBOTTOMCHAR
.fill 16, RADARMAPCHAR + i * 2 				
.fill 12, FULLBOTTOMCHAR

.fill 12, FULLBOTTOMCHAR
.fill 16, RADARMAPCHAR + i * 2 + 1
.fill 12, FULLBOTTOMCHAR

.fill 12, FULLBOTTOMCHAR
.fill 16, 32
.fill 12, FULLBOTTOMCHAR

bottom_colormap:
.fill 40,8	//black as the char color, for the border
.fill 40,8 + 3 //cyan for the sky haze
.fill 120, 8 //black for everything else. We will use it for the map as well

//ok, here we go.	
.pc = $0801
:BasicUpstart(main)


.pc = $0820 "main"
main:			
				sei
				
				lda #$35
				sta $01
						    
		        jsr vsync
		          
		        //blank  
				lda #$0b
				sta $d011
	
				//clear sid and vic
				ldx #$3f
				lda #0
			!:	
				sta $d400,x
				sta $d000,x
				dex
				bpl !-
					
				//set MC color 1 and 2
				lda #$09
				sta $d022
				lda #$02
				sta $d023
				
				
				//init the sprites, mirroring them
				//normally there wouldn't be any need to do this, but we want to save few bytes after compression.
				//also, we can show off this clever sprite flipping function by yours truly
				
				jsr flip_sprite.init
				
				ldx #[hero_sprite & $3fff] / 64
				ldy #[hero_sprite & $3fff] / 64 + 5
				jsr flip_sprite.flip
				
				ldx #[hero_sprite & $3fff] / 64 + 1
				ldy #[hero_sprite & $3fff] / 64 + 4
				jsr flip_sprite.flip
				
				ldx #[hero_sprite & $3fff] / 64 + 2
				ldy #[hero_sprite & $3fff] / 64 + 7
				jsr flip_sprite.flip
				
				ldx #[hero_sprite & $3fff] / 64 + 3
				ldy #[hero_sprite & $3fff] / 64 + 6
				jsr flip_sprite.flip
				
				.for (var i = 0; i < 4; i++)
				{
					ldx #[enemy1_sprite & $3fff] / 64 + 0 + i
					ldy #[enemy1_sprite & $3fff] / 64 + 4 + i
					jsr flip_sprite.flip
				}
				
				.for (var i = 0; i < 2; i++)
				{
					ldx #[enemy2_sprite & $3fff] / 64 + 0 + i
					ldy #[enemy2_sprite & $3fff] / 64 + 3 + i
					jsr flip_sprite.flip
				}
				
						
				//disable NMI
				lda #<irq_bg0.any_rti    
		        sta $fffa       
		        lda #>irq_bg0.any_rti    
		        sta $fffb        
		        lda #$00        // stop Timer A
		        sta $DD0E       //
		        sta $DD04       // set Timer A to 0, after starting
		        sta $DD05       // NMI will occur immediately
		        lda #$81        //
		        sta $DD0D       // set Timer A as source for NMI
		        lda #$01        //
		        sta $DD0E       // start Timer A -> NMI
				
				
		        jsr showpic
		        
	
			ig:
				sei
				
				jsr splash
	
				jsr vsync
				lda #$0b
				sta $d011
				
				lda #$03
				sta $dd00
				
				lda #$d8
				sta $d016
				
				lda #%00011110
				sta $d018
				
				jsr clear_irq
				
				lda #<irq_bg0
				sta $fffe
				lda #>irq_bg0
				sta $ffff
				lda #69 //73
				sta $d012
				
				jsr init_game
				jsr init_playfield
				
				cli
				
			il:	
				jsr init_level	
				jsr enemies.deploy
				jsr vans.deploy		
			ih:
				jsr hero.init
	
				jsr getready
				
			gameloop:
	
				jsr controls
				jsr hero.update				
				jsr vans.update
				jsr enemies.update
				jsr bullet.update
				jsr radar.plot		
				//jsr beam.update	//this is done in irq, to prevent some tearing effect on screen. Also, bullets will nicely get off screen when you die
				jsr camera.chase
				jsr plot_mountains
				jsr rotor			
				jmp testcollisions //we cant jsr because testcollision can break out from this loop		
			returnfromtestcollisions:
				jmp testgamestatus //we cant jsr because testgamestatus can break out from this loop
			returnfromtestgamestatus:	
				inc clock
	
				jsr panelvsync	
			#if DEBUG
				jsr debug
			#endif	
				jmp gameloop	

//Tests some conditions that will break the main loop. Namely:
//-all enemies destroyed:   start new level
//-All vans destroyed:		game over
//-Player out of choppers:  game over 			
//furthermore, it checks for spacebar being pressed (pause) and then spacebar again (back to game)
//testgamestatus is inline because it must be able to break out from the main loop
testgamestatus:	
{
				lda score + 5
				cmp #9
				beq !gameover+ //"good" gameover
				
				lda nvans
				beq !gameover+ //bad gameover.
				
				lda nenemies
				beq levelup
				
				lda #239
				cmp $dc01 
				beq !pause+
				
				jmp returnfromtestgamestatus
				
			!gameover:
				jmp gameover	
				
			!pause:
			
			!:	jsr vsync	//wait for release
				cmp $dc01
				beq !-  
				
			!:	jsr vsync
				cmp $dc01
				bne !-
				
			!:	jsr vsync	//wait for release
				cmp $dc01
				beq !- 	
				
				jmp returnfromtestgamestatus
					
				
			levelup:
				
				//update score.
				//from the manual: Evrey time you complete a level, you get a bonus that is 100*level*ntrucksleft
			
				//wait some time with hero on display
				lda #0
				sta bullet.alive
				sta bullet.alive + 1
				
				lda #$1f
				jsr activewait
				
				jsr eraseplayarea
				
				lda #[empty_sprite & $3fff] / 64
				sta sprf + 2
				sta sprf + 3
				sta sprf + 4
				sta sprf + 5
				sta sprf + 6
				sta sprf + 7
				
				:sfx(sfx_bonus,2)
	
				lda level
				cmp #10
				bcc !ok+
				lda #9
			!ok:
				sta p0tmp + 7 //multiplier
				
				ldx #11 //loops on vans
			!v:	stx savex + 1
				lda vans.status,x
				beq !nextvan+
			
				lda #0
				sta vans.status,x
				
				jsr vans.draw
				jsr radar.plot_friends		
				
				lda p0tmp + 7
				sta p0tmp + 6
				
			!:	lda #1
				jsr add_score
				dec p0tmp + 6
				bpl !-
		
			!nextvan:
			
				ldx #$03
			!delay:
				jsr panelvsync
				dex
				bpl !delay-
				
			savex:
				ldx #0	
				dex
				bpl !v-
				
				ldx #$0f
			!:	jsr panelvsync
				dex
				bpl !-
				
				inc level
				jmp il	
}			


#if DEBUG
debug:
{

				lda camera_x + 2
				lsr
				lsr
				lsr
				lsr
				tax
				lda digimap,x
				sta $0402
				lda camera_x + 2
				and #$0f
				tax
				lda digimap,x
				sta $0403
				
				lda camera_x + 1
				lsr
				lsr
				lsr
				lsr
				tax
				lda digimap,x
				sta $0404
				lda camera_x + 1
				and #$0f
				tax
				lda digimap,x
				sta $0405
				
				
				lda xpos + 2
				lsr
				lsr
				lsr
				lsr
				tax
				lda digimap,x
				sta $0407
				lda xpos + 2
				and #$0f
				tax
				lda digimap,x
				sta $0408
				
				lda xpos + 1
				lsr
				lsr
				lsr
				lsr
				tax
				lda digimap,x
				sta $0409
				lda xpos + 1
				and #$0f
				tax
				lda digimap,x
				sta $040a
			
				
				lda nenemies
				and #$0f
				tax
				lda digimap,x
				sta $040c
			
				rts
			
digimap:
.fill 10, '0' + i
.fill 6, 'a'+ i			
}			
#endif

			
//we over overrid the classic vblank with this. Our blank really starts at the Radar, and we need all the rastertime we can have
panelvsync:
{
			!:	lda redraw
				beq !-				
				lda #0
				sta redraw
				rts
}		

	
//first in-game, raster irq.
//triggers right after score and life have been displayed and re-uses sprites for in-game objects
//it also performs all the $d021-$d022-$d023 tweaks to draw the sky gradient.
irq_bg0:
{
				sta savea + 1
				stx savex + 1
				sty savey + 1

#if DEBUG
	lda #%00011110
	sta $d018	
#endif					

	
				//place game sprites					
				lda #0
				.for (var i=0; i<8; i++)
				{
					ldx sprf + i
					stx $0400 + $3f8 + i
					ldx sprc + i
					stx $d027 + i
					ldx sprxl + i
					stx $d000 + i * 2
					ldx spry + i
					stx $d001 + i * 2
					ldx sprxh + i
					beq !skp+
					ora #[1 << i]
				!skp:		
				}	
				sta $d010
							
		
				lda #04	
				ldx #74
				cpx $d012
				bne *-3
				sta $d021
		
				lda hwscroll
				sta $d016		
		
				lda #$09
				sta $d022
				lda #$02
				sta $d023
				
				lda #$0e //badline
				ldx #5
			!:	dex
				bpl !-
				sta $d021
	
				//clear collision register
				lda $d01f
		
				lda #$ff	
				sta $d01b	//char priority
									
				lda #%00000000
				sta $d01d
		
				lda #$ff
				sta $d015
				
							
				lda #04	
				ldx #77
				cpx $d012
				bne *-3
				sta $d021		
				
				lda #$0e
				ldx #78
				cpx $d012
				bne *-3
				sta $d021
				
				lda #04
				ldx #79
				cpx $d012
				bne *-3
				sta $d021
				
				lda #08
				ldx #81
				cpx $d012
				bne *-3
				sta $d021
				
				lda #04
				ldx #82
				cpx $d012
				bne *-3
				sta $d021
			
				//badline, so active wait for the win
				lda #08
				ldx #7
			!:	dex
				bpl !-
				sta $d021
	
				lda #10
				ldx #84
				cpx $d012
				bne *-3
				sta $d021
				
				lda #$07
				ldx #85
				cpx $d012
				bne *-3
				sta $d021
				
				lda #13
				ldx #87
				cpx $d012
				bne *-3
				sta $d021
				
				lda #$01
				ldx #87
				cpx $d012
				bcs *-3
				sta $d021
				
				
				lda #08
				ldx #90
				cpx $d012
				bcs *-3
				sta $d021
		
				lda #$c0
				sta $d016
			
				//play music and effects
				jsr sid.play
				
				//reports to the game engine that objects have been placed and next frame can be calculated
				lda #1
				sta redraw
							
				lda #$d2-8
				sta $d012
				
				lda #<irq_vans
				sta $fffe
				lda #>irq_vans
				sta $ffff
	
				//ack irq			
				lsr $d019

	savey:	ldy #$00
	savea:	lda #$00
	savex:	ldx #$00
	any_rti:
			rti
}			
			

//triggers at the trucks line. uses hardware scrolling to move the vans, which are chars
irq_vans:
{
				pha
				lda vans.vanscroll
				sta $d016
				
				lda #$d3
				sta $d012
				
				lda #<irq_panel
				sta $fffe
				lda #>irq_panel
				sta $ffff
				
				lsr $d019
				pla
				rti		
}			
			
//triggers right before the HUD. takes care of setting sprites for the logo and adjusting colors for the radars.
//it also saves spr-spr and spr-bg registers, which will be used by the game engine to test various game conditions.
//Sprites can therefore be reused for the logo.
irq_panel:
{
				pha
				txa
				pha
				
	
				lda #$d0
				sta $d016
			
				lda #$00	
				sta $d01b	//sprite priority
				
				lda $d01f
				sta shadowd01f
					
				lda $d01e
				sta shadowd01e
				
				lda #$e0
				sta $d012
				
				lda #$1b
				sta $d011
				
				lda #<irq_panel2
				sta $fffe
				lda #>irq_panel2
				sta $ffff
				
				lsr $d019
				
				//set the sky color in radar
				lda #$0e
				sta $d021
	
				//place the logo
				ldx #$f0 //should be ee, but we do the play area of 13 pixels instead of 12, because we draw fat vertical pixels, and we want to prevent collision with logo sprites
				.for (var i = 2; i < 8; i++)
				{	
					stx $d001 + i * 2
					lda #24 + 11*8 + 24 * (i-2)
					sta $d000 + i * 2
				}
				ldx #[logo_sprites & $3fff] / 64
				.for (var i = 2; i < 8; i++)
				{	
					stx $0400 + $3f8 + i
					.if (i<7) 
						inx
				}
							
				//place bars
				lda #[logo_bars & $3fff] / 64
				sta $0400 + $3f8 + 1
				
				lda #$f3
				sta $d003
				lda #24 + 11*8 + 32
				sta $d002
				
				lda #%11111110
				sta $d015
				lda #%11111100
				sta $d01c	
				
				lda #$00
				sta $d010
				
				lda #0
				sta $d025
				lda #$09
				sta $d026		
				
				//we don't really need to set sprite color for all of them
				lda #1
				sta $d02a
				sta $d02b
				sta $d02c
				sta $d02d
								
				pla
				tax
				pla
				rti
}			
			

//more raster tweaks to set various colors in the panel
irq_panel2:
{
				pha
	
				lda #$08
				sta $d021
				
				lda #$f1
				sta $d012
				
				lda #$1b
				sta $d011
				
				lda #<irq_panel3
				sta $fffe
				lda #>irq_panel3
				sta $ffff
				
				lsr $d019
		
				lda #1
				//waste 56 cycles
				.fill 28, $ea
				sta $d023
				
				pla
				rti
}


//more of the same. The HUD is much more complicated than it seems
irq_panel3:
{
				pha
				lda #$02
				sta $d028
	
				lda #<irq_panel4
				sta $fffe
				lda #>irq_panel4
				sta $ffff
				lda #$f3 + 2
				sta $d012
				lsr $d019
				pla
				rti
}

//this draws the color bars of the activision logo. it needs several rastersplits as it's very colorful.
irq_panel4:
{
				sta savea + 1
				stx savex + 1
				sty savey + 1
	
				lda #$07
				ldx #$f3 + 2
			!:	cpx $d012
				beq !-
				sta $d028
				lda #$05 
				sta $d021
	
		
				lda #$0e
				ldx #$f3 + 4
			!:	cpx $d012
				bcs !-
			
				sta $d028
				lda #$06 
				sta $d021
				
				//here it's safe to update the beams on screen
				jsr beam.update
					
				lda #$08
				sta $d012
				
				lda #$1b
				sta $d011
				
				lda #<irq_top
				sta $fffe
				lda #>irq_top
				sta $ffff
				
				lsr $d019
				
		savea:	lda #$00	
		savex:	ldx #$00
		savey:	ldy #$00
				rti
}




//first irq on screen. Does the clouds parallax, plaes score and lives
irq_top:
{			
				pha
				txa
				pha
		#if DEBUG
		lda #%00010100
		sta $d018
		#endif
		
						
				lda #$0e
				sta $d021
		
				lda clouds_hwscroll
	#if DEBUG
				and #%11101111
	#endif
				sta $d016
						
				lda #$0b
				sta $d022
				lda #$0a
				sta $d023
				
				lda #<irq_bg0
				sta $fffe
				lda #>irq_bg0
				sta $ffff
				
				lda #69 // 73
				sta $d012
				
				lsr $d019
	
				lda #$00
				sta $d01c
				
				//place score
				lda #[score_sprites & $3fff] / 64
				sta $0400 + $3f8
				lda #[score_sprites & $3fff] / 64 + 1
				sta $0400 + $3f8 + 1
				
				lda #48
				.for (var i = 0; i < 8; i++)
					sta $d001 + i * 2
				
				lda #1
				sta $d027
				sta $d028	
					
				lda #7
				.for (var i = 2; i < 8; i++)
					sta $d027 + i
	
				
				ldx lives	
				lda centertable,x
				clc
				.for (var i = 2; i < 8; i++)
				{
					sta $d000 + 2 * i
					.if (i < 7)
						adc #16	
				}
				dex
				stx lleft + 1
				ldx #0	
				lda #[hud_chopper_sprite & $3fff] / 64
			!:
		lleft:	cpx #0
			
				bmi !ok+
				lda #[empty_sprite & $3fff] / 64
			!ok:	
				sta $0400 + $3f8 + 2,x
				inx
				cpx #6
				bne !- 
			!noleft:
			
			
					
				lda #$00
				sta $d010
				lda #$ff
				sta $d015
				
				lda #%00000011
				sta $d01d
				
				lda #160 - 24
				sta $d000
				lda #160 + 24
				sta $d002
			
	
					
				pla
				tax
				pla
				rti

	centertable:
	.fill 7,168+24-8*i
}			
		



getready:
{
				jsr eraseplayarea
	
				lda #0 //getready
				
				jsr bigsign.init
	
				lda #0
				sta bullet.alive
				sta bullet.alive + 1
				
				lda #$3f
				sta p0tmp + 7
				
				lda #$2c
				sta enemies.updateonly
				
			!:	
				jsr panelvsync
				
				jsr bigsign.play
				
				//jsr controls
				jsr hero.update				
				
				jsr vans.draw 
				jsr enemies.draw
				jsr bullet.update
				jsr radar.plot		
				//jsr beam.update
				jsr camera.chase
				jsr plot_mountains
				inc clock
				dec p0tmp + 7
				bne !-
							
				lda #$20
				sta enemies.updateonly
					
				jmp eraseplayarea
}


gameover:
{

				jsr eraseplayarea
	
				//erase player from radar
				lda radar.hero_previous_addr
				sta p0radar
				ldx radar.hero_previous_off
				
				ldy radar.hero_previous_y
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
					
				lda #1 //gameover
				
				jsr bigsign.init
	
				lda #$2f				
				sta p0tmp + 7 //we keep game over on screem for sometime before we check for button 
		
				lda #$2c
				sta enemies.updateonly
	
			!:	
				jsr panelvsync
				jsr bigsign.play
					
				//jsr controls
				//jsr hero.update				
				jsr vans.update
				jsr enemies.update
				jsr bullet.update
				jsr radar.plot		
				//jsr beam.update
				jsr camera.chase
				jsr plot_mountains
				inc clock
		
				dec p0tmp + 7
				bne !-
				
				lda #$20
				sta enemies.updateonly
				
			!:	lda #1
				jsr activewait
				
			!skp:
				lda $dc00
				and #%00010000
				bne !-
					
				jmp ig
			
}


//waits while updating chopper and screen animations.
//used to let some sfx steam off before we move to next event
//uses p0tmp + 7
//load A with the wait duration

activewait:
{
				sta p0tmp + 7 //we keep game over on screem for sometime before we check for button 
		
				lda #$2c
				sta enemies.updateonly
	
			!:	
				jsr panelvsync
				
				//jsr controls
				//jsr hero.update				
				jsr vans.update
				jsr enemies.update
				jsr bullet.update
				jsr radar.plot		
				//jsr beam.update
				jsr camera.chase
				jsr plot_mountains
				inc clock
		
				dec p0tmp + 7
				bne !-
				
				lda #$20
				sta enemies.updateonly
				
				rts
}


init_game:
{
			
				ldx #tozerosize -tozero -1
				lda #0
			!:	sta tozero,x
				dex
				bpl !-
		
				lda #3
				sta lives
				
				lda #00
				sta level
				
				rts		
}			
		

//setup level difficulty
init_level:
{

				lda #0
				sta enemy_level_xspeed
				lda level
				lsr
				ror enemy_level_xspeed
				clc
				adc #1
				cmp #ENEMY_MAX_XSPEED
				bcc !ok+
				lda #0
				sta enemy_level_xspeed
				lda #ENEMY_MAX_XSPEED
			!ok:
				sta enemy_level_xspeed + 1
				
				ldx enemy_level_xspeed
				lda enemy_level_xspeed + 1
				
				cmp #ENEMY_MAX_YSPEED
				bcc !ok+
				ldx #0
				lda #ENEMY_MAX_YSPEED
			!ok:
				stx enemy_level_yspeed
				sta enemy_level_yspeed + 1			
			
				
				lda level
				
				clc
				adc #3
				cmp #16
				bcc !ok+
				lda #16
			!ok:	
				sta enemies.shootprob + 1
				
				lda #2
				sta bulletspeed
				lda level
				cmp #4
				bcc !done+
				inc bulletspeed
				cmp #09
				bcc !done+
				inc bulletspeed
				cmp #14
				bcc !done+
				inc bulletspeed
				cmp #19
				bcc !done+
				inc bulletspeed
			!done:
				
				rts
}

init_playfield:
{

				ldx #0
				lda #32
			!:	sta $0400,x
				sta $0500,x
				sta $0600,x
				sta $0700,x
				inx
				bne !-
				
				
				ldx #119	
			!:
				lda #$08
				sta $d800 + 40 * 3,x
				lda #$08
				sta $d800,x
				dex	
				bpl !-
				
				ldx #39
			!:	lda #bgpattern_borderchar
				sta $0400 + 40 * 5,x	
				lda #0
				sta $d800 + 40 * 19,x //vans coolor
				dex
				bpl !-
		
				ldx #200
			!:	lda bottom_charmap-1,x
				sta $0400 + 40 * 20 -1,x
				lda bottom_colormap-1,x
				sta $d800 + 40 * 20 -1,x
				dex
				bne !-
					
				lda #[empty_sprite & $3fff] / 64
				ldx #7
			!:	
				sta sprf,x
				dex
				bpl !-	
					
				jsr update_score
				jsr radar.init
											
				rts
}
	

testcollisions:
{
				//test if we killed some enemy
	
				lda dontcheck
				beq !skp+
				dec dontcheck
				jmp !next+
				
			!skp:	
				
				lda shadowd01f //spr-bg collision
				sta p0tmp + 1
	
				and #%11100000 //hw sprites associated to enemies.
				beq !next+	   //not really needed, but most of the times no collision would be effective, so we might as well skip the bit-wise test
	
				ldx #2 //hw sprites
			!:
				asl p0tmp + 1
				bcc !nb+
				
				//an enemy was hit
				ldy enemies.reverselut,x
		
				sty savey + 1
				lda #2
				ldx enemies.status,y
				bmi !plane+
				lda #1
			!plane:
				jsr add_score
				dec nenemies
						
		savey:  ldy #0	
				lda enemies.status,y
				and #($ff - enemies.STATUS_ALIVE)
				ora #enemies.STATUS_EXPLODING
				sta enemies.status,y
				lda #7
				sta enemies.enemy_clock,y
			
				//we can destroy x because we are exiting the loop on x anyway
			
				lda radar.enemy_previous_addr,y
				sta p0radar
				ldx radar.enemy_previous_off,y
				
				lda radar.enemy_previous_y,y
	
				tay
			
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				
				lda #9 
				sta dontcheck
				lda #10
				sta invincibility
				
				:sfx(sfx_bexplosion,2)
				
				jmp !next+ //we can only kill one hw sprite per frame
				
			!nb:
				dex
				bpl !-
				
			!next:
			
				//test if a van has been hit
				//vans can only be hit by the second bullet, so if that's not alive, let's pass
				
				lda bullet.alive + 1
				beq !next+
				
				lda bullet.ypos + 1
				cmp #MAXY + 0
				bcc !next+
				
				//inc $d020
				
				//calculate bullet x position in chars
			
				lda sprxl + 4
				sec
				sbc #12 //accounts for the sprite x starting at -24 and the bullet being shifted 8 pixels into the sprite and being 4 pixels large
				sta p0tmp
				lda sprxh + 4
				sbc #0
				lsr
				lda p0tmp
				ror
				lsr
				lsr
			
				sta p0tmp
					
				//test active vans to see if one was hit
				ldx #2
			!:
				lda vans.reverselut,x			
				bmi !nextvan+
			
				ldy vans.pseudox,x
				cpy p0tmp
				beq !hit+
				iny
				cpy p0tmp
				beq !hit+
				iny
				cpy p0tmp
				beq !hit+
				
			!nextvan:	
				dex 
				bpl !-
				jmp !next+
				
				
			!hit:
				dec nvans
				tax
				lda #0
				sta vans.status,x
				
				lda #128 //special flag to signal bullet sprite being reused for the explosion
				sta bullet.alive + 1	
				
				:sfx(sfx_explosion,2)
				
			!next:
				//test if we died
							
				#if INVINCIBLE
				jmp !done+
				#endif
				
				lda invincibility
				beq !ok+
				dec invincibility
				
				lda blink
				bne !+
				jmp !done+
			!:	
				lda invincibility
				and #1
				
				asl
				adc #7
				sta sprc
				sta sprc + 1
			
				jmp !done+
			!ok:
				lda #0
				sta blink
				
				lda shadowd01e
				and #$3
				beq !testbg+
				
				//sorry hero, you hit a enemy or a bullet. Rest in pieces.
				//let's see if it's an enemy
				lda shadowd01e
				and #%11100000
				beq !itwasabullet+
				
				sta p0tmp + 1
				
				
				ldx #2 //hw sprites
			!:
				asl p0tmp + 1
				bcc !nb+
				
				//an enemy was hit
				ldy enemies.reverselut,x
		
				sty savey2 + 1
				lda #2
				ldx enemies.status,y
				bmi !plane+
				lda #1
			!plane:
				jsr add_score
				dec nenemies
						
		savey2:  ldy #0	
				lda enemies.status,y
				and #($ff - enemies.STATUS_ALIVE)
				ora #enemies.STATUS_EXPLODING
				sta enemies.status,y
				lda #7
				sta enemies.enemy_clock,y
			
				//we can destroy x because we are exiting the loop on x anyway
			
				lda radar.enemy_previous_addr,y
				sta p0radar
				ldx radar.enemy_previous_off,y
				
				lda radar.enemy_previous_y,y
	
				tay
			
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				iny
				lda (p0radar),y
				and andmask,x
				sta (p0radar),y
				
				lda #9 
				sta dontcheck
				lda #10
				sta invincibility
				
				:sfx(sfx_bexplosion,2)
				
				jmp death //we can only kill one hw sprite per frame
				
			!nb:
				dex
				bpl !-	
				
			!itwasabullet:	
				jmp death
				
				//if it crushed into a char it must be a van
			!testbg:		
				lda shadowd01f
				and #$3
				beq !done+		
				
				//understand which van we hit
				lda sprxl
				sec
				sbc #4
				
				sta p0tmp
				lda sprxh
				sbc #0
				lsr
				lda p0tmp
				ror
				lsr
				lsr
			
				sta p0tmp
					
				//test active vans
				ldx #2
			!:
				lda vans.reverselut,x			
				bmi !nextvan+
				
				
				lda vans.pseudox,x
				sec
				sbc p0tmp
				cmp #4
				bcc !hit+
				
				cmp #$fc
				
				bcs !hit+
				
				
			!nextvan:	
				dex 
				bpl !-
				jmp !done+
				
				
			!hit:
				
				dec nvans
				lda vans.reverselut,x
				tax
				lda #0
				sta vans.status,x
				
				lda sprxl
				clc
				adc #24
				sta sprxl + 4
				
				lda sprxh
				adc #0
				sta sprxh + 4
				lda spry
				clc
				adc #4
				sta spry + 4
			
				jsr vans.draw
				
				:sfx(sfx_explosion,2)
				
				lda #[explosion_sprite & $3fff] / 64
				sta sprf + 4
				lda #0
				sta sprc + 4
				
			!:	
				jsr vsync
				jsr vsync
				ldx sprf + 4
				inx
				cpx #[explosion_sprite & $3fff] / 64 + 4
				beq !ef+
				stx sprf + 4
				jmp !-
			!ef:
				lda #[empty_sprite & $3fff] / 64
				sta sprf + 4	
				jmp death
				
			!done:
				jmp returnfromtestcollisions
			
	dontcheck:
	.byte 0
}


death:
{
		
				lda #$2c
				sta enemies.updateonly
	
				lda #$20
				sta p0tmp + 7
			!:	inc sprc		//nice old-school color-cycle
				inc sprc + 1
				jsr enemies.draw
				jsr vsync
				dec p0tmp + 7
				bne !-		
				
				lda #$20
				sta enemies.updateonly
				
				//for the explosion we use the chopper sprites and the next two hw sprites, one of which is a bullet sprites, for a grand total of 4.
				//first remove bullets from screen:
				lda #[empty_sprite & $3fff] / 64
				sta sprf + 4
		
				:sfx(sfx_explosion,0)
						
				//store the upperleft corner of explosion
				lda sprxl
				clc
				adc #08 //
				sta p0tmp
				lda sprxh
				adc #0
				sta p0tmp + 1
				lda spry
				sec
				sbc #4
				sta p0tmp + 2
				
			
				jsr random_
				ldx #3
				
			!:	lda random_.random,x
				anc #15
				adc p0tmp 
				sta sprxl,x
				lda p0tmp + 1
				adc #0
				sta sprxh,x
				dex
				bpl !-
			
				jsr random_
				ldx #3
				
			!:	lda random_.random,x
				anc #15
				adc p0tmp + 2
				sta spry,x
				dex
				bpl !-
				
				lda #7
				sta sprc
				
				lda #$0f
				sta sprc + 1
				
				lda #$0e
				sta sprc + 2
				
				lda #$0d
				sta sprc + 3
				
				ldx #[explosion_sprite & $3fff] / 64
				stx sprf
				inx
				stx sprf + 1
				inx
				stx sprf + 2
				inx
				stx sprf + 3
				
				
				ldy #0
			!:	  
				tya
				and #3
				tax
				
				inc sprf,x
				lda sprf,x
				cmp	#[explosion_sprite & $3fff] / 64 + 4
				bne !skp+		
	
				lda #[explosion_sprite & $3fff] / 64
				sta sprf,x
				
				jsr random_
				anc #15
				adc p0tmp
				sta sprxl,x
				lda p0tmp + 1
				adc #0
				sta sprxh,x
				lda random_.random + 1
				anc #15
				adc p0tmp + 2
				sta spry,x
				
			!skp:	
			
				cpy #4
				bne !skp+
			
				:sfx(sfx_bexplosion,1)
				ldy #4
				
			!skp:	
				cpy #8
				bne !skp+
				
				:sfx(sfx_bexplosion,2)
				ldy #8
			!skp:
				jsr vsync
				iny
				cpy #$40
				bne !-
			
				
				lda #[empty_sprite & $3fff] / 64
				sta sprf
				sta sprf + 1
				sta sprf + 2
				sta sprf + 3
					
				dec lives
				bne !ok+
				jmp gameover
			!ok:				
				jmp ih
			
}

//game area is 320 chars = 2560 pixels. It's a larger than Full HD Game!
//ranges from $000 to $0a00
//this is also where the wraparound logic headache starts. 
plot_mountains:
{

				lda camera_x + 2
				bpl !skp+
				
				lda camera_x + 1
				clc
				adc #<[$0a00 - $500]
				sta p0tmp
				lda camera_x + 2
				adc #>[$0a00 - $500]
				
				jmp !shift+
				
			
				//if camera_x > $0800, we must reduce it by 1280, that is $0500  (any number that is lartger than $c00 - $800 and multiple of 40 would do), otherwise, upon dividing by 8, it'll be larger than $0100
			
		!skp:	cmp #$08
				bcc !ok+
				
				lda camera_x + 1
				sec
				sbc #$00
				sta p0tmp
				lda camera_x + 2
				sbc #$05
				jmp !shift+
				
		!ok:		
				lda camera_x + 1
				sta p0tmp
				
				lda camera_x + 2
		!shift:
				lsr
				ror p0tmp
				lsr
				ror p0tmp
				lsr
				ror p0tmp
				
				lda p0tmp	
				tax
				lda mod40,x
				
				sta bgsrc0 + 1
				clc
				adc #80
				sta bgsrc1 + 1
				
				ldx #38
				
		bgsrc0:	lda bgpattern,x
				sta $0400 + 3 * 40,x
		bgsrc1:	lda bgpattern + 80,x
				sta $0400 + 4 * 40,x
			
				dex
				bpl bgsrc0
				
				//now let's plot the clouds.
				
				lda camera_x + 1 
				lsr
				lsr
				lsr
				lsr
				
				clc
	
				sta csrc0 + 1
				adc #64
				sta csrc1 + 1
				
				ldx #39
		csrc0:	lda cloudpattern,x
				sta $0400 + 40,x
		csrc1:	lda cloudpattern + 64,x
				sta $0400 + 80,x
				dex
				bpl csrc0
					
				//plot radar mountains
				ldx bgsrc0 + 1 //this is mod40, as computed by the first part of this function.
							  //now we must divide by 5
				lda div5,x
				sta p0tmp
				asl
				anc #%00000110
				eor #%00000110
				adc #<[radar_mountains-charset] / 8
				tax
				tay
				iny
				
				lda #%00000100
				bit p0tmp
				beq !noswap+
				
				tya
				stx p0tmp
				tax
				ldy p0tmp
				
			!noswap:	
			
				.for (var i = 0 ; i < 8; i++)
					stx $0400 + 21 * 40 + 12 + i * 2
				.for (var i = 0 ; i < 8; i++)
					sty $0400 + 21 * 40 + 13 + i * 2
			
					
				rts 
}			

								
clear_irq:
{
				lda #$7f                    //CIA interrupt off
				sta $dc0d
				sta $dd0d
				lda $dc0d
				lda $dd0d
				
				lda #$01                    //Raster interrupt on
				sta $d01a
				lsr $d019
				rts
}			


//it takes a lot of code to make a game
.import source "misc.asm"
.import source "sfx.asm"
.import source "controls.asm"
.import source "hero.asm"
.import source "camera.asm"
.import source "weapons.asm"
.import source "enemies.asm"
.import source "hud.asm"
.import source "radar.asm"
.import source "splash.asm"


mod40:
.fill 256, mod(i,40)

div5:
.fill 320, i/5

//maps char y to screen coordinates. we only need 20 chars of it
screen40l:
.fill 20, <[$0400 + i * 40]
screen40h:
.fill 20, >[$0400 + i * 40]


.pc = $6000 "splash screen scr"
.import binary "..\assets\credits.scr"
.pc = $4000 "splash screen map"
.import binary "..\assets\credits.map"

//Saul Cross' Amazing tune
.pc = $7000 "sid"
.fill sid.size, sid.getData(i)

.print p0current //how much page zero did we use?

.pc = $7800 "bigsigns"

.label getreadymap = *
.for (var cx = 0; cx < 18; cx++)
{
	.fill 16,0
	.for (var cy = 0; cy < 16; cy++)
		.byte grgo.getSinglecolorByte(cx, cy) 
}

.label gameovermap = *
.for (var cx = 0; cx < 18; cx++)
{
	.fill 16,0
	.for (var cy = 0; cy < 16; cy++)
		.byte grgo.getSinglecolorByte(cx, cy + 16) 
}