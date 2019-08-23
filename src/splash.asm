showpic:
{
				jsr vsync
				lda #$0b
				sta $d011
				
				lda #$00
				sta $d020
				sta $d021
				
				lda #$01
				sta $dd00
				lda #%00001000
				sta $d018
				lda #$d8
				sta $d016
				
				ldx #0
			!:
				.for (var i = 0; i < 4; i++)
				{
					lda $8400 + $100 * i,x
					sta $d800 + $100 * i,x
				}
				inx
				bne !-
				
				jsr vsync
				lda #$3b
				sta $d011
				
			!:	jsr vsync
				
				lda  $dc00
				and #%00010000
				bne !-
				
				
				rts
}


splash:
{
				lda #0
				jsr sid.init
nosid:
				sei

				lda #0
				sta $d021
				sta $d015
				sta button
				
				lda #$0f
				sta $d418
				
				ldx #39
			!:  lda #0	
				sta $d800 + 16 * 40,x
				lda #$0f
				.for (var i = 0; i < 8; i++)
				sta $d800 + (17 + i) * 40,x
				dex
				bpl !- 			
				
				lda #$c8
				sta $d016
			
			loop:		
				jsr vsync
				jsr random_
				jsr sid.play
				
				lda #2
				sta $dd00
				lda #%10000000
				sta $d018
				lda #$3b
				sta $d011
				
				lda #180
			!:	cmp $d012
				bcs !-
				
				lda #3
				sta $dd00
				lda #$1b
				sta $d011
				lda #%11010110
				sta $d018
	//			inc $d020

				lda button
				cmp #2
				bcs !exit+
				cmp #0
				beq waitrelease
				cmp #1
				beq waitpush
				jmp loop				
				
				
			!exit:
				lda #1
				jsr sid.init
				rts
				
			waitpush:
				lda #%00010000
				bit $dc00
				bne !skp+
				inc button
			!skp:
				jmp loop
				
			waitrelease:
				lda #%00010000
				bit $dc00
				beq !skp+
				inc button
			!skp:
				jmp loop	
				
button:
.byte 0
}				

