;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Name	adcCheck.asm
;	Author:	DTsebrii
;	Date:	02/28/2021
;	Description:	Program to set up a 10-bit ADC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;  Pin 1 VDD (+5V)		+5V
;  Pin 2 RA5		LED_1 (Active high output)
;  Pin 3 RA4		Pot
;  Pin 4 RA3		MCLR 
;  Pin 5 RA2		N/O
;  Pin 6 RA1/ICSPCLK
;  Pin 7 RA0/ICSPDAT/AN0
;  Pin 8 VSS (Ground)		Ground
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	list	p=12f1822,r=hex,w=0	; list directive to define processor
	
	nolist
	include	p12f1822.inc	; processor specific variable definitions
	list
;;;; CONFIGURATION WORDS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	__CONFIG _CONFIG1,_FOSC_INTOSC & _WDTE_OFF & _MCLRE_ON & _IESO_OFF
;	Internal oscillator, wdt is off, Pin4 is MCLR 
	__CONFIG _CONFIG2, _WRT_OFF & _PLLEN_OFF & _LVP_OFF
;	Constants
freqVal		EQU	b'01110000'	; 8MHz
initPort	EQU	b'00000000'	; PORTA all Voltage are low
TRISconf	EQU	b'11011111'	; All inputs except RA5 
allDigit	EQU	b'00000000'	; RA3 is analog
chan3		EQU	b'00001100'	; AN3 is ADC channel
adc1Conf	EQU	b'10010000'	; Right Just, Fosc/8 Vref = VDD
#define LED	LATA, 5			; LED pin
#define	ADC_ON	ADCON0, 0	; TEnable ADC bit
#define AN3_AN	ANSELA, 4	; RA4 in analog 

	ORG	0x00
; Main body
MainRoutine
	CALL sysInit	; Function to initialize the system
loop1
	CALL sampleADC
	GOTO	loop1


;;;; sysConfig ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Author:	DTsebrii
;Date:		02/27/2021
;Description:	Calling all subroutines required to 
;				configure the system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sysInit 
	
	CALL oscConfig
	CALL portConfig
	CALL adcConfig
	
	RETURN

;;;; oscConfig ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Author:	DTsebrii
;Date:		02/27/2021
;Description:	Seting the oscillator frequency level and
;				waiting until OSC is stable 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
oscConfig
	BANKSEL	OSCCON
	MOVLW	freqVal
	MOVWF	OSCCON
;	Wait until OSC is stable
oscStable
	BANKSEL	OSCSTAT
	BTFSS	OSCSTAT, HFIOFS	; Check either HFIOFS is 1
	GOTO	oscStable
	
	RETURN

;;;; portConfig ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Author:	DTsebrii
;Date:		02/27/2021
;Description:	Setting up the GPIO ports 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
portConfig
	BANKSEL ANSELA
	MOVLW	allDigit
	MOVWF	ANSELA		; All pins are digital
	BSF	AN3_AN

	BANKSEL LATA
	MOVLW	initPort
	MOVWF	LATA		; Output voltage is low 
	
	BANKSEL TRISA
	MOVLW	TRISconf
	MOVWF	TRISA		; RA5 is output 
	
	RETURN

;;;; adcConfig ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Author:	DTsebrii
;Date:		02/28/2021
;Description:	Setting up the ADC 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
adcConfig
	BANKSEL ADCON1
	MOVLW	adc1Conf
	MOVWF	ADCON1
	
	BANKSEL	ADCON0
	MOVLW	chan3
	IORWF	ADCON0	; Channel 3, GO is 0, ADC is OFF
	BSF	ADC_ON	; Turning on ADC 
	
	RETURN

;;;; sampleADC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Author:	DTsebrii
;Date:		02/28/2021
;Description:	Reading the ADC input and change the 
;				state of LED according to the ADC value
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
sampleADC
	CALL	delay50uS
	BANKSEL ADCON0
	BSF		ADCON0, GO	; Start sampling
busyADC	
	BTFSC	ADCON0, GO	; Wait till sampling is done 
	GOTO	busyADC		
	;512 = b'1000000000', so first 8 bit = 0
	BANKSEL	ADRESH
	LSRF	ADRESH	; if (ADRES < 512)
	BANKSEL	LATA
	SKPNZ
	BCF		LED
	SKPZ
	BSF		LED 
	RETURN
	

;;;; delay50us ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Author:	DTsebrii
;Date:		02/21/2021
;Description:	Taking a ucontroller under the loop 
;				for a 50uS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay50uS
;	DECFSZ takes 1 cy in non-zero case, 2 cy otherwise
;	GOTO takes 2 cy anyway
;	loop will take 3 cy per time. If Fosc = 8MHz,
;	Fcy = 2MHz => Tcy = .5us. To get 50us delay, 
;	100 cy must be done. It will take 33 iterations
;	Thus, cnt is equal to 32 
	MOVLW	.32
waitLoop
	DECFSZ	WREG
	GOTO	waitLoop
	
	RETURN
	
	END
	
	
	
