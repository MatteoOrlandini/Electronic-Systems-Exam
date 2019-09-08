

;Matteo Orlandini
;Ingegneria elettronica
;matricola 1079505
;
;Gestione eventi: microcontrollore in modalità sleep (dove possibile) 
;in assenza di eventi da processare
		
;il PIC non puo' uscire dallo sleep tramite invio di un carattere
;in quanto la seriale non funziona in sleep. Viene controllato in polling
;il bit RCIF Tche è settato quando c'è un carattere non letto nella FIFO
;indipendentemente dallo stato del bit di enable dell'interrupt.
		
;Descrizione della tesina
;Si realizzi un firmware che riceve dal computer (tramite porta seriale)
;una parola, come sequenza di codici ascii dei singoli caratteri. 
;La parola è terminata da un punto ed è di lunghezza massima fissata a priori. 
;Dopo aver ricevuto la parola, il programma deve reinviarla sulla porta 
;seriale scritta al contrario.
;
;
; Descrizione hardware:
; - scheda Cedar "Pic Board - Studio" (vedere schematico).
; - MCU: PIC16F887 (clock interno 8 MHz)
; - convertitore USB-seriale FT230X che gestisce in maniera trasparente
;   la comunicazione USB, permettendo al PC ed al PIC di vedere a tutti
;   gli effetti una porta seriale
;


		#include "p16f887.inc"
		;#include "macro.inc"  ; definizione di macro utili

		; configuration bits
		;_INTRC_OSC_NOCLKOUT : oscillatore interno senza uscita di clock
		;_WDT_OFF : disabilita il Watchdog Timer
		;_LVP_OFF : disabilita la programmazione a bassa tensione permettendo l
		;uso della PORTB dopo la programmazione
		__CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _WDT_OFF & _LVP_OFF
		;_BOR21V : Brown-out Reset settato a 2.1V
		__CONFIG _CONFIG2, _BOR21V

		; variabili in RAM (shared RAM)
		udata_shr
puntatoreChar	res     .1
numeroChar	res	.1 
rxData		res	.1

	
		; reset vector
rst_vector		code	0x0000
		pagesel start
		goto start


		; programma principale
		code
start
		movlw .0
		movwf numeroChar
		;inizializzo il puntatore al vettore che contiene i caratteri
		;per contenere l'indirizzo 0x20, cioè il primo general purpose
		;file register
		movlw 0x20
		movwf FSR
		pagesel initHw
		;initHw contiene le inizializzazioni hardware
		call initHw      
mainLoop	
		;abilitazione seriale e ricezione continua
		banksel RCSTA
		bsf RCSTA, SPEN
		bsf RCSTA, CREN
		banksel PIR1
		;se RCIF è a 1 allora è stato ricevuto un byte da seriale
		btfss PIR1, RCIF
		goto $-1
		;lettura del bit di Framing Error, se è ad uno si può resettare
		;portando a zero il bit SPEN di RCSTA che resetta la EUSART
		banksel RCSTA
		btfsc RCSTA, FERR
		bcf RCSTA, SPEN
		;lettura del contenuto di RCREG
		;per resettare l'interrupt RCIF
		banksel RCREG
		movf RCREG,w
		movwf rxData
		;metto il contenuto di RCREG nel vettore che contiene i caratteri
		movwf INDF
		;incremento il puntatore
		incf FSR, f
		;incremento la variabile che conta i caratteri
		incf numeroChar, f
		;se si è verificato un over run, cioè il bit OERR di RCSTA è 
		;a uno, si resetta il flag portando a zero il bit CREN di RCSTA
		banksel RCSTA
		btfsc RCSTA, OERR
		bcf RCSTA, CREN
		;se il byte ricevuto è un punto la parola è terminata
		movlw '.'
		;confronta il dato ricevuto con '.'
		subwf rxData, w
		btfsc STATUS,Z  
		;se il carattere ricevuto è '.', chiama TXEUSART
		call TXEUSART 
		goto mainLoop

TXEUSART	
		;resetto il bit SYNC di TXSTA (trasmissione asincrona)
		;banksel TXSTA
		;bcf TXSTA, 4
		banksel RCSTA
		bsf RCSTA, CREN
		;abilitazione della trasmissione seriale
		banksel TXSTA
		bsf TXSTA, TXEN			
invioDati	;decremento il puntatore
		decf FSR, f
		;metto il contenuto di ogni elemento del vettore in w
		movf INDF, w
		;TXIF è a 1 quando il buffer di trasmissione EUSART è vuoto
		banksel PIR1
		btfss PIR1, TXIF
		goto $-1
		;scrivo w (numeroChar) in TXREG
		banksel TXREG
		movwf TXREG
		;se TRMT (Transmit Shift Register) è vuoto allora vai al main loop
		;banksel TXSTA
		;btfsc TXSTA, TRMT
		;goto $-1
		decfsz numeroChar
		goto invioDati
		return


initHw
		;*********** inizio configurazioni hardware  *******************		
		
		;**********  inizio configurazione interrupt  ******************
		movlw B'00000000'
		banksel INTCON
		;INTCON:
		;bit 7 = 0 -> disabilitazione di tutti gli interrupt
		;bit 6 = 0 -> disabilitazione interrupt dalle periferiche
		;bit 5 = 0 -> disabilitazione interrupt timer 0
		;bit 4 = 0 -> disabilitazione interrupt esterno 
		;bit 3 = 0 -> disabilitazione interrupt porta B
		;bit 2 = 0 -> reset del flag interrupt timer 0 
		;bit 1 = 0 -> reset del flag interrupt esterno
		;bit 0 = 0 -> reset del flag interrupt porta B
		movwf INTCON

		movlw B'00000000'
		banksel PIE1
		;PIE1
		;bit 7 = 0 -> non implementato
		;bit 6 = 0 -> disabilitazione interrupt ADC
		;bit 5 = 0 -> disabilitazione interrupt EUSART in ricezione
		;bit 4 = 0 -> disabilitazione interrupt EUSART in trasmissione
		;bit 3 = 0 -> disabilitazione interrupt MSSP
		;bit 2 = 0 -> disabilitazione interrupt CCP1
		;bit 1 = 0 -> disabilitazione interrupt Timer 2 = PR2
		;bit 0 = 0 -> disabilitazione interrupt overflow Timer 1
		movwf PIE1
		;***********  fine configurazione interrupt  *******************
		
		;***********  inizio configurazione clock  *********************
		movlw B'01110001'
		banksel OSCCON
		;OSCCON:
		;bit 7 = non implementato
		;bit 6-4 = 111 -> oscillatore interno a 8 MHz
		;bit 3 = 0 -> il PIC lavore con l'oscillatore interno (solo lettura)
		;bit 2 = 0 -> HFINTOSC non stabile (solo lettura)
		;bit 1 = 0 -> LFINTOSC non stabile (solo lettura)
		;bit 0 = 1 -> oscillatore interno usato come clock di sistema
		movwf OSCCON

		movlw B'00000111'
		banksel OPTION_REG
		;OPTION_REG:
		;bit 7 = 0 -> pull up abilitato sulla porta b
		;bit 6 = 0 -> interrupt sul fronte di discesa 
		;bit 5 = 0 -> clock interno (Fosc/4)
		;bit 4 = 0 -> incremento del Timer 0 sulla transizione basso-alto
		;del pin T0CKI
		;bit 3 = 0 -> prescaler assegnato al Watch Dog Timer
		;bit 2-0 = 111 Prescaler 1:256
		; -> Ftick = (8 MHz / 4) / 256 = 7812.5 Hz, tick = 128us, periodo = 32.768 ms
		movwf OPTION_REG
		;************  fine configurazione clock  **********************
		
		;************  inizio configurazione porte  ********************
		;port A: non usata, input
		movlw B'11111111'
		banksel TRISA
		movwf TRISA

		;port B: non usata, input
		movlw B'11111111'
		banksel TRISB
		movwf TRISB
		
		;port C: RC6 e RC7 usate per la seriale
		movlw B'11111111'
		banksel TRISC
		movwf TRISC

		;port D: non usata, input
		movlw B'11111111'
		banksel TRISD
		movwf TRISD
		
		;port E: non usata, input
		movlw B'00001111'
		banksel TRISE
		movwf TRISE
		;**************  fine configurazione porte  ********************
		
		;**************  inizio configurazioni USART  ******************
		movlw B'00100100'
		banksel TXSTA
		;TXSTA:
		;bit 7 = 0 -> don't care perchè usart in modalità asincrona
		;bit 6 = 0 -> trasmissione a 8 bit
		;bit 5 (TXEN) = 1 -> trasmissione abilitata
		;bit 4 (SYNC) = 0 -> modalità asincrona
		;bit 3 = 0 -> Sync Break transmission completata
		;bit 2 = 1 -> Baud rate alta velocità
		;bit 1 = 0 -> Transmit Shift Register Status bit (solo lettura)
		;bit 0 = 0 -> contenuto del nono bit (non abilitato)
		movwf TXSTA
		
		movlw B'10010000'
		banksel RCSTA
		;RCSTA:
		;bit 7 (SPEN) = 1 -> porta seriale abilitata
		;bit 6 = 0 -> ricezione a 8 bit
		;bit 5 = 0 -> don't care perchè usart in modalità asincrona
		;bit 4 (CREN) = 1 -> ricezione continua abilitata
		;bit 3 = 0 -> don't care perchè ricezione a 8 bit
		;bit 2 = 0 -> Framing Error bit (solo lettura)
		;bit 1 = 0 -> Overrun Error bit (solo lettura)
		;bit 0 = 0 -> Nono bit ricevuto, non usato (solo lettura)
		movwf RCSTA
		
		movlw B'00000000'
		banksel BAUDCTL
		;BAUDCTL:
		;bit 7 = 0 -> overflow del baud timer (solo lettura)
		;bit 6 = 0 -> ricezione dello start bit (solo lettura)
		;bit 5 = 0 (non implementato)
		;bit 4 = 0 -> Transmissione dei dati non invertiti al pin RB7/TX/CK
		;bit 3 = 0 -> baud rate a 8 bit
		;bit 2 = 0 (non implementato)
		;bit 1 = 0 -> wake up enable bit disabilitato
		;bit 0 = 0 -> Auto-Baud Detect disabilitato
		movwf BAUDCTL
		
		;per avere un baud rate di 19200 occorre scrivere .25 nel 
		;registro SPBRG perché con Fosc = 8 MHz, SYNC = 0, BRGH = 1, 
		;BRG16 = 0 si ha BaudRate = Fosc/[16 * (n+1)] e con n = 25,
		;BaudRate = 19230 bps
		movlw .25
		banksel SPBRG
		movwf SPBRG
		;*************  fine configurazione USART  *********************
		return

		;************* fine configurazioni hardware  *******************

		end



