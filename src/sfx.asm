.macro sfx(wavetable,channel)
{
			lda #<wavetable
			ldy #>wavetable
			ldx #channel * 7
			jsr sid.init + 6
}


sfx_fire:

		.byte $00,$F8,$08,$A4,$21,$AC,$81,$AB,$41,$AC,$80,$AA,$A9,$A8,$A7,$A6
		.byte $A5,$A4,$A3,$A2,$00

sfx_bexplosion:

		.byte $00,$FA,$08,$A8,$41,$AC,$81,$AB,$80,$AA,$A9,$A8,$A7,$A6,$A5,$A4
        .byte $A3,$A2,$A2,$A2,$A2,$A2,$A2,$A2,$A2,$A2
        .fill 32,$a2
        .byte $00
        
sfx_explosion:

        .byte $00,$FA,$08,$A0,$41,$97,$A2,$81,$A2,$A2,$A2,$80,$A2,$A2,$A1,$A0
        .byte $9F,$9E,$9D,$9D,$9D,$9D,$9D,$9D,$9D,$9C,$9C,$9C,$9C,$9C,$9C,$9C
        .byte $9C,$9C,$9C,$9B,$9B,$9B,$9B,$9B,$9A,$9A,$9A,$9A,$9A,$9A
        .byte $99,$99,$99,$99,$99,$99,$99,$00
        
sfx_rotor:
         
		.byte $90,$F8,$00,$DF,$81,$D7,$80,$D0,$C7,$C7,$C0,$C0,$C0,$BF,$BE,$BD
        .byte $00
         
         
sfx_bonus:

        .byte $00,$F6,$01,$DF,$81,$8C,$41,$8C,$8C,$8D,$8D,$8D,$8E,$8E,$8E,$8F
        .byte $8F,$8F,$90,$90,$90,$92,$92,$92,$93,$93,$93,$94,$94,$94,$96,$96
        .byte $96,$98,$98,$98,$9B,$9B,$9B,$A1,$A1,$A1,$A8,$A8,$A8,$AD,$AD,$AD
        .byte $B9,$B9,$B9,$40,$00