;*************************************************************** 
;* Feladat: 
;* R�vid le�r�s:
; 
;* Szerz�k: 
;* M�r�csoport: <merocsoport jele>
;
;***************************************************************
;* "AVR ExperimentBoard" port assignment information:
;***************************************************************
;*
;* LED0(P):PortC.0          LED4(P):PortC.4
;* LED1(P):PortC.1          LED5(P):PortC.5
;* LED2(S):PortC.2          LED6(S):PortC.6
;* LED3(Z):PortC.3          LED7(Z):PortC.7        INT:PortE.4
;*
;* SW0:PortG.0     SW1:PortG.1     SW2:PortG.4     SW3:PortG.3
;* 
;* BT0:PortE.5     BT1:PortE.6     BT2:PortE.7     BT3:PortB.7
;*
;***************************************************************
;*
;* AIN:PortF.0     NTK:PortF.1    OPTO:PortF.2     POT:PortF.3
;*
;***************************************************************
;*
;* LCD1(VSS) = GND         LCD9(DB2): -
;* LCD2(VDD) = VCC         LCD10(DB3): -
;* LCD3(VO ) = GND         LCD11(DB4): PortA.4
;* LCD4(RS ) = PortA.0     LCD12(DB5): PortA.5
;* LCD5(R/W) = GND         LCD13(DB6): PortA.6
;* LCD6(E  ) = PortA.1     LCD14(DB7): PortA.7
;* LCD7(DB0) = -           LCD15(BLA): VCC
;* LCD8(DB1) = -           LCD16(BLK): PortB.5 (1=Backlight ON)
;*
;***************************************************************

.include "m128def.inc" ; Definition file for ATmega128 
;* Program Constants 
.equ const =$00 ; Generic Constant Structure example  
;* Program Variables Definitions 
.def temp =r16 ; Temporary Register example 

;*************************************************************** 
;* Reset & Interrupt Vectors  
.cseg 
.org $0000 ; Define start of Code segment 
	jmp RESET ; Reset Handler, jmp is 2 word instruction 
	jmp DUMMY_IT	; Ext. INT0 Handler
	jmp DUMMY_IT	; Ext. INT1 Handler
	jmp DUMMY_IT	; Ext. INT2 Handler
	jmp DUMMY_IT	; Ext. INT3 Handler
	jmp DUMMY_IT	; Ext. INT4 Handler (INT gomb)
	jmp DUMMY_IT	; Ext. INT5 Handler
	jmp DUMMY_IT	; Ext. INT6 Handler
	jmp DUMMY_IT	; Ext. INT7 Handler
	jmp DUMMY_IT	; Timer2 Compare Match Handler 
	jmp DUMMY_IT	; Timer2 Overflow Handler 
	jmp DUMMY_IT	; Timer1 Capture Event Handler 
	jmp DUMMY_IT	; Timer1 Compare Match A Handler 
	jmp DUMMY_IT	; Timer1 Compare Match B Handler 
	jmp DUMMY_IT	; Timer1 Overflow Handler 
	jmp DUMMY_IT	; Timer0 Compare Match Handler 
	jmp DUMMY_IT	; Timer0 Overflow Handler 
	jmp DUMMY_IT	; SPI Transfer Complete Handler 
	jmp DUMMY_IT	; USART0 RX Complete Handler 
	jmp DUMMY_IT	; USART0 Data Register Empty Hanlder 
	jmp DUMMY_IT	; USART0 TX Complete Handler 
	jmp DUMMY_IT	; ADC Conversion Complete Handler 
	jmp DUMMY_IT	; EEPROM Ready Hanlder 
	jmp DUMMY_IT	; Analog Comparator Handler 
	jmp DUMMY_IT	; Timer1 Compare Match C Handler 
	jmp DUMMY_IT	; Timer3 Capture Event Handler 
	jmp DUMMY_IT	; Timer3 Compare Match A Handler 
	jmp DUMMY_IT	; Timer3 Compare Match B Handler 
	jmp DUMMY_IT	; Timer3 Compare Match C Handler 
	jmp DUMMY_IT	; Timer3 Overflow Handler 
	jmp DUMMY_IT	; USART1 RX Complete Handler 
	jmp DUMMY_IT	; USART1 Data Register Empty Hanlder 
	jmp DUMMY_IT	; USART1 TX Complete Handler 
	jmp DUMMY_IT	; Two-wire Serial Interface Handler 
	jmp DUMMY_IT	; Store Program Memory Ready Handler 

.org $0046

;****************************************************************
;* DUMMY_IT interrupt handler -- CPU hangup with LED pattern
;* (This way unhandled interrupts will be noticed)

;< t�bbi IT kezel� a f�jl v�g�re! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< t�bbi IT kezel� a f�jl v�g�re! >

;*************************************************************** 
;* MAIN program, Initialisation part
.org $004B;
RESET: 
;* Stack Pointer init, 
;  Set stack pointer to top of RAM 
	ldi temp, LOW(RAMEND) ; RAMEND = "max address in RAM"
	out SPL, temp 	      ; RAMEND value in "m128def.inc" 
	ldi temp, HIGH(RAMEND) 
	out SPH, temp 

M_INIT:
;< ki- �s bemenetek inicializ�l�sa stb > 
.def temp2 = r18;temp2 reg
ldi temp2, 0
.def lift = r17 ; regiszter a lift fut�f�ny�nek
ldi lift, 1 ;Bet�ltj�k az egyet, mert kezdetben a lift a f�ldszinten van
ldi temp, 0xFF
out DDRC, temp ; a C port ir�ny�t be�ll�tjuk kimenetk�nt
ldi temp, 0x00 ; bemeneti ir�nyt szeretn�k a switcheknek
sts DDRG, temp ; ir�ny be�ll�t�sa a switcheknek


ldi temp, 1
mov lift, temp


;*************************************************************** 
;* MAIN program, Endless loop part

;***************************************************************
;* A ledeken l�that� a 7 emeletes + f�ldszintes h�zban a lift aktu�lis helye.
;* A BT0 �s BT1 gombokkal h�vhatjuk a liftet �s miut�n a lift meg�rkezett 
;* a switch-ekkel tudjuk megmondani, hogy hanyadik emeletre szeretn�nk menni. 
;* Ezut�n a BT3 gomb megnyom�sa ut�n a lift elindul. 
;* Maga a lift egy gy�jt�lift, azaz �tk�zben meg tud �llni,
;* �s azonos ir�nyba k�zleked� utasokat fel tud venni.
;***************************************************************
 
M_LOOP: 

;< f�ciklus >
	lds temp, PING ; a PING-b�l a kapcsol�k temp-be
	cpse temp, temp2 ; compare skip if equal, �sszehasonl�tja, hogy minden switch 1-be van-e
	call SWITCH ;ha v�ltozott valamelyik switch megh�vja a switch szubrutint
	out PORTC, lift ; az els� ledet bekapcsoljuk. Azaz a lift a f�ldszinten v�r

	jmp M_LOOP ; Endless Loop  


;*************************************************************** 
;* Subroutines, Interrupt routines

SWITCH:
	cpse temp, lift
	inc lift
	ret
	











