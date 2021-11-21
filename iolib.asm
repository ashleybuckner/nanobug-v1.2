ack		equ		0x06
bell	equ		0x07
bs		equ		0x08
cr		equ		0x0d
lf		equ		0x0a
nak		equ		0x16
esc		equ		0x1b
del		equ		0x7f

ctrlA	equ		0x01
ctrlB	equ		0x02
ctrlC	equ		0x03
ctrlD	equ		0x04
ctrlE	equ		0x05
ctrlF	equ		0x06
ctrlG	equ		0x07
ctrlH	equ		0x08
ctrlI	equ		0x09
ctrlJ	equ		0x0a
ctrlK	equ		0x0b
ctrlL	equ		0x0c
ctrlM	equ		0x0d
ctrlN	equ		0x0e
ctrlO	equ		0x0f
ctrlP	equ		0x10
ctrlQ	equ		0x11
ctrlR	equ		0x12
ctrlS	equ		0x13
ctrlT	equ		0x14
ctrlU	equ		0x15
ctrlV	equ		0x16
ctrlW	equ		0x17
ctrlX	equ		0x18
ctrlY	equ		0x19
ctrlZ	equ		0x1a

;		Variables in scratchpad RAM:
;aciatmp	equ		0x0000

acia	equ		0xbf80					; 63b50 ACIA
parport equ		0xbfa0					; VIA

ramtop	equ		0x7fff

initacia
;		pshs	a
		lda		#%00000011				; reset
		sta		acia			
		lda		#%10010101				; = 0x95: Enable IRQ if RX buffer full, divide by 16, 8N1 (I hope), RTS low, Tx interrupt disabled.
		sta		acia
		rts
;		sta		<aciatmp
;		sta		,x
;		puls	a,pc

;		Input a string into memory from the keyboard. On entry, X points to the input buffer:
;		x		pointer to buffer
;		a		length of buffer
;		On return
;		a		exit character
;		b		...

bufftmp	equ		0						; saved x
bufflen	equ		bufftmp+2				; buffer length
charctr	equ		bufflen+1				; position of current character
nchars	equ		charctr+1				; nchars in string
isflags	equ		nchars+1				; flags (insert/overwite mode)
tmpchr	equ		isflags+1
tmplen	equ		tmpchr+1

getstr	pshs	x,y,u
		leas	-tmplen,s				; reserve temporay variable space on system stack
		tfr		s,u						; u is now local variable pointer.
		stx		bufftmp,u				; ????
		sta		bufflen,u
		clr		charctr,u
		lda		#1
		sta		nchars,u
		clr		,x						; null eol terminator
		clr		tmplen,u				; insert mode
		
islp	lbsr	inpchr
		cmpa	#bs
		lbeq	backsp
		
		cmpa	#del
		
		cmpa	#cr
		bne		isnotcr
		lbsr	prtchr					; print the cr and then add an lf
		lda		#lf
		lbsr	prtchr
		lbra	isexit
		
isnotcr	cmpa	#esc					; don't print the escape char, it'll only lead to trouble and seat-wetting...
		lbeq	isexit
		
		cmpa	#ctrlA					; Left arrow
		beq		isstartln
		cmpa	#ctrlE
		beq		isendln
		cmpa	#ctrlB
		beq		isleft
		cmpa	#ctrlF
		beq		isright
		
		cmpa	#ctrlD
		beq		isdlte

		cmpa	#' '					; non-printable character?
		blo		iserr
		tsta
		bmi		iserr

;		Deal with a normal, printable character.
normchr	lbsr	prtchr					; print out character
		
		ldb		nchars,u				; is there room for it?
		cmpb	bufflen,u
		bhs		iserr

		ldb		charctr,u
		sta		b,x
		incb
		clr		b,x
		stb		charctr,u
		inc		nchars,u
		
		bra		islp

;		Move cursor to satrt of line. Stupidly.
isstartln
		bra		isstartln

;		Move cursor to end of line. Stupidly.
isendln	ldb		nchars,u
		bra		islp

isleft	bra		islp

isright	lbra		islp

backsp	tst		charctr,u				; at start of line?
		beq		iserr
		lbsr	prtchr
		dec		charctr,u				; decrement character counter
		ldb		charctr,u
		clr		b,x
		bra		islp

;		Delete character at cursor position
isdlte	lbra	islp

;		Arrive here of there's been an error of some sort. Send a bell character?
iserr	lda		#0x09
		lbsr	prtchr
		lbra	islp

isex1	lbsr	prtchr					; print out character

isexit	leas	tmplen,s
		puls	x,y,u,pc

;		Convert ASCII character in A to lower case
lcase	cmpa	#'A'
		blo		exlcase
		cmpa	#'Z'
		bhi		exlcase
		suba	#'A'-'a'
exlcase	rts

;		Convert ASCII character in A to upper case
ucase	cmpa	#'a'
		blo		exucase
		cmpa	#'z'
		bhi		exucase
		suba	#'a'-'A'
exucase	rts

;		Read a character from ACIA - echo
getchr	bsr		inpchr
		jmp		prtchr

;		Read a character from ACIA - no echo		
inpchr	pshs	x
		ldx		#acia
;		ldb		<aciatmp
;		andb	#0b10111111				; clear bit 6 - RTS low
iploop	lda		0,x						; 4+0
		bita	#0x01					; 2
		beq		iploop					; 3 (when taken) 
		lda		1,x
;		orb		#0b01000000				; set bit 6 - RTS high
;		stb		0,x
		puls	x,pc

tstchr	pshs	x
		ldx		#acia
		lda		0,x
		bita	#0x01
		puls	x,pc

;		Convert a numerical string in memory to an unsigned binary value in D.
;		On entry:
;		A		radix
;		X		points to string
;		Local variables (pointed to by S):
;		0		Temporary store for result
;		2		saved radix
getnum	pshs	y
		leas	-3,s
		clr		,s						; set result to zero
		clr		1,s
		sta		2,s						; save radix
		
gnlp0	lda		,x+
		lbsr	cvthex					; convert to binary in A
		cmpa	2,s
		bge		gnexit					; invalid char? exit loop
		
		tfr		a,b
		lda		#0						; save current value as 16 bit value	
		tfr		d,y					
		
		ldb		2,s						; retrive radix and decide what to do...
		cmpb	#2
		beq		gnbin
		cmpb	#8
		beq		gnoct
		cmpb	#10
		beq		gndec
		cmpb	#16
		beq		gnhex
										; flag invlaid radix somehow?
		bra		gnexit

gnbin	ldd		,s						; get current result
		lslb
		rola
		bra		gnlp1

gnoct	ldd		,s
		lslb
		rola
		lslb
		rola
		lslb
		rola
		bra		gnlp1

gndec	ldd		,s
		lslb
		rola
		tfr		d,y
		lslb
		rola
		lslb
		rola
		lslb
		rola
		leay	d,y
		tfr		y,d
		bra		gnlp1

gnhex	ldd		,s
		lslb
		rola
		lslb
		rola
		lslb
		rola
		lslb
		rola
		
gnlp1	leay	d,y						; add current result (d) to saved converted digit (y)
		sty		,s						; and save
		bra		gnlp0

gnexit	ldd		,s
		leas	3,s
		leax	-1,x
		puls	y,pc

;		Convert a hex string in memory to an unsigned binary value in D.
;		TO DO
;		On input:
;		x		address of hexadecimal  string
;		On output:
;		a		number of characters entered
;		y		converted value
gethex	pshs	b						; save y
;		ldd		#0						; allocate two bytes on the stack for resuly, initialised to zero...
;		pshs	d
		leas	-3,s
		clr		,s
		clr		1,s
		clr		2,s
		tfr		s,y						; ... and get y to point to them
gxlp	lda		,x+						; get next character to A
		bsr		cvthex					; convert frtom hex to binary in A
		cmpa	#0x10
		bge		gthx0					; invalid hex char? exit loop

		tfr		a,b
		lda		#0						; save current value onto stack as 16 bit value						
		pshs	d
		ldd		,y						; get the current number
		lslb
		rola
		lslb
		rola
		lslb
		rola
		lslb
		rola
		addd	,s++					; add current digit on
		std		,y						; and save back into local variable.
		inc		2,y
		bra		gxlp
		
gthx0	leax	-1,x
		lda		2,y
		ldy		,y						; get converted value
		leas	3,s						; restore stack
		puls	b,pc

;		Concert ASCII char in A to hex digit. Case insensitive. Carry set if invlaid char. DAA trick?
cvthex	cmpa	#'a'					; If upper case convert to lower.
		blt		cvthx1
		suba	#0x20
		
cvthx1	suba	#'0'
		blt		cvthx3
		cmpa	#10
		blt		cvthx2
		suba	#0x07
		blt		cvthx3
;		cmpa	#0x10
;		bge		cvthx3
		
cvthx2	rts								; successul conversion

cvthx3	lda		#0x7f					; invalid hex char - carry set
		rts

prtstr	pshs	a
psloop	lda		,x+
		tsta
		beq		exitps
		lbsr	prtchr
		bra		psloop
exitps	puls	a,pc

prtdec	pshs	d,x,y,cc
;		leay	dectab,pc
		ldy		#dectab
		leas	-1,s
		
pdlp0	clr		,s
pdlp0a	cmpd	,y
		blo		pdlp1
		subd	,y
		inc		,s
		bra		pdlp0a

pdlp1	tfr		d,x
		lda		,s
		bsr		prthex
		ldd		,y++
		cmpd	#1
		tfr		x,d
		bne		pdlp0

pdlp2	leas	1,s
		puls	d,x,y,cc,pc

dectab	fdb		10000
		fdb		1000
		fdb		100
		fdb		10
		fdb		1
		
prthex4 pshs	a
		bsr		prthex2
		tfr		b,a
		bsr		prthex2
		puls	a,pc

prthex2 pshs	a
pth2	lsra
		lsra
		lsra
		lsra
		bsr		prthex
		puls	a

prthex	pshs	a
		anda	#0x0f
		cmpa	#9
		ble		noconv
		adda	#'A'-'0'-10
noconv	adda	#'0'
		bsr		prtchr
		puls	a,pc

space	pshs 	a
		lda		#' '
		lbsr	prtchr
		puls	a,pc
		
escchr	pshs	a
		lda		#0x1b
		bsr		prtchr
		puls	a
		bra		prtchr

newline	pshs 	a
		lda		#cr
		lbsr	prtchr
		lda		#lf
		lbsr	prtchr
		puls	a,pc

putchr	cmpa	#' '
		blo		nonprt
		cmpa	#0x7f
		bhs		nonprt
		bra	prtchr
nonprt	lda		#'.'

prtchr	pshs	b,x
		ldx		#acia
pcloop	ldb		,x
		bitb	#%00000010
		beq		pcloop
		sta		1,x
		puls	b,x,pc

;		Skip over space characters (space, tab) stopping at a NULL char.
skipsp	pshs	a
skplp	lda		,x
		
		cmpa	#' '
		beq		gotsp
		
		cmpa	#0x09
		beq		gotsp
		
;		tsta
;		bne		gotsp
		
		puls	a,pc
		
gotsp	leax	1,x
		bra		skplp

hash	pshs	dp,u,y
		ldy		#5381
;		ldy		#1

hashlp	lda		,x+
		cmpa	#' '
		ble		hashex
		cmpa	#0x7f
		bhs		hashex

;	Convert to lower case	- use lcase?	
		cmpa	#'a'
		ble		skip1
		cmpa	#'z'
		bge		skip1
		suba	#0x20
		tfr		a,dp
		
;	Multiply y by 33
skip1	tfr		y,d
		tfr		y,u

		lslb							; *2
		rola
		lslb							; *4
		rola
		lslb							; *8
		rola
		lslb							; *16
		rola
		lslb							; *32
		rola

		tfr		d,y
		tfr		u,d						; add original value back on.
		leay	d,y

*	Add character to y
		tfr		dp,a
		leay	a,y
		bra		hashlp

hashex	leax	-1,x
		tfr		y,d
		puls	u,y,dp,pc

;		Print date
prtdate	pshs	d
		tfr		a,b
		lsrb
		clra
		addd	#1980
		lbsr	prtdec
		lda		#'/'
		lbsr	prtchr
		
prtmnth	
		ldd		,s
		lsra
		rorb
		lsrb
		lsrb
		lsrb
		lsrb
;		clra
		tfr		b,a
		lbsr	prtdec2
		lda		#'/'
		lbsr	prtchr

prtday	clra
		lda		1,s
		anda	#0x1f
		lbsr	prtdec2

		puls	d,pc

;		Print time
prttime	pshs	d
;		tfr		a,b

hours	lsra
		rorb
		lsra
		rorb
		lsra
		rorb
		lbsr	prtdec2
		lda		#':'
		lbsr	prtchr

mnutes	;ldd		,s
;		lsra
;		rorb
;		lsra
;		rorb
;		lsra
;		rorb
		lsrb
		lsrb
		tfr		b,a
		lbsr	prtdec2
		lda		#':'
		lbsr	prtchr
		
scnds	lda		1,s
		anda	#0x1f
		asla
		lbsr	prtdec2

		puls	d,pc

prtdec2	pshs	d
		tfr		a,b
		clra
pdc2lp	cmpb	#10
		blo		pdc2
		inca
		subb	#10
		bra		pdc2lp
pdc2	lbsr	prthex
		tfr		b,a
		lbsr	prthex
		puls	d,pc
	
