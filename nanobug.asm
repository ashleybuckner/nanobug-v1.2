;
;				lwasm -9 -f srec -o nanobug.s19 -lnanobug.lst nanobug.asm
;

		org		0x0000
swi3 	rmb			2
swi2 	rmb			2
firq 	rmb			2
irq		rmb			2
swi		rmb			2
nmi		rmb			2

inpchrv	rmb			2
getchrv	rmb			2
prtchrv	rmb			2
putchrv	rmb			2
getstrv	rmb			2
prtstrv	rmb			2
tstchrv	rmb			2
ucasev	rmb			2
lcasev	rmb			2
getnumv	rmb			2
gethexv	rmb			2
cvthexv	rmb			2
prtdecv	rmb			2
prthex4v rmb		2
prthex2v rmb		2
spacev	rmb			2
escchrv	rmb			2
newlinev rmb		2
hashv	rmb			2
prtdatev rmb		2

ccreg	rmb			1
areg	rmb			1
breg	rmb			1
dreg	equ		areg
dpreg	rmb			1
xreg	rmb			2
yreg	rmb			2
ureg	rmb			2
pcreg	rmb			2
sreg	rmb			2

aciatmp			rmb		1
chksum			rmb		1
bytectr			rmb		1
linectr			rmb		1
inpbfr			rmb		80

		org		0xe000

softrst	jmp		reentry
		
hardrst	ldx		#0
		bra		start

;	 seconds
tstlp	clra										;	2
		sta		,x								;	4+0
		tst		,x								;	6+0
		bne		ramerr							;	3
		coma										;	2
		sta		,x								;	4+0
		cmpa	,x+								;	4+2
		beq		tstskip							;	3
ramerr	cwai	#0xff
tstskip	cmpx	#0x8000							;	4
		bne		tstlp							;	3		= 38 cycles

start	lds		#ramtop+1
		jsr		initacia
		sta		<aciatmp
		
		ldb		#14
		ldx		#ccreg
clrrglp	clr		,x+
		decb
		bne		clrrglp

;		clr		<dpreg
;		lda		#0x55
;		sta		<ccreg
;		ldd		#0x1234
;		std		<dreg
;		ldd		#0x1000
;		std		<xreg
;		ldd		#0x2000
;		std		<yreg
;		ldd		#0x3000
;		std		<ureg
;		ldd		#0x0200
;		std		<pcreg
		
;	Move the subroutine vector table into RAM
		ldx		#vectab
		ldy		#swi3					; .inpchr
veclp	ldd		,x++
		cmpd	#0
		beq		hello
		std		,y++
		bra		veclp

hello	ldx		#message
		jsr		prtstr

mainlp	ldx		#prompt
		jsr		prtstr

		ldx		#inpbfr
		lda		#72
		jsr		getstr
		
proccmd	jsr		skipsp
		
		lda		,x+
		tsta
		beq		mainlp
		jsr		skipsp
		anda	#0x7f
		jsr		ucase
		
mainlp1	cmpa	#'M'											; Modify memory?
		lbeq	modify
		
		cmpa	#'D'											; Hex dump?
		lbeq	listmem
		
		cmpa	#'G'											; Go to user code?
		lbeq	runprog
		
		cmpa	#'L'											; Load record from S-record data
		lbeq	ldprog
		
		cmpa	#'R'											; Registers
		beq	regstrs

		ldx		#invcmd
		jsr		prtstr
		jsr		prtchr
		jsr		newline
		jsr		newline
		bra		mainlp

regstrs	ldx		#ccflags
		ldb		<ccreg
ccloop	aslb
		bcs		ccskip1
		lda		#'.'
		bra		ccskip2
ccskip1	lda		,x
ccskip2	jsr		prtchr
		leax	1,x
		cmpx	#ccfltop
		bne		ccloop
		
		lda		#' '
		jsr		prtchr

		ldx		#areg
		ldb		#3
ccloop2	lda		,x+
		jsr		prthex2
		
		lda		#' '
		jsr		prtchr
		decb
		bne		ccloop2

		ldx		#xreg
ccloop3	ldd		,x++
		jsr		prthex4
		cmpx	#sreg
		beq		regskip3

		lda		#' '
		jsr		prtchr
		bra		ccloop3

regskip3
		jsr		newline
		lbra	mainlp

ccflags	fcc		'EFHINZVC'
ccfltop

;
;	Modify memory
;	M <aaaa>
;	If address not specified, use current saved PC
;	U holds current memory location
;		
modify	jsr		gethex
		tsta
		bne		modskp1
		ldy		<pcreg
modskp1	tfr		y,u
modlp	tfr		u,d												; print current memory address
		jsr		prthex4
		lda		#' '
		jsr		prtchr
		
		lda		,u												; print contents
		jsr		prthex2
		lda		#' '
		jsr		prtchr
		
		ldx		#inpbfr											; get a new line
		lda		#72
		jsr		getstr
		
		jsr		skipsp
		lda		,x
		tsta
		beq		modnext
		
		cmpa	#'.'											; get out of jail?
		lbeq	mainlp
		
		cmpa	#'+'
		beq		modnext
		
		cmpa	#'-'
		beq		modprev
		
		cmpa	#'@'
		beq		modaddr
		
		jsr		gethex											; Get new value in y
		tsta
		beq		modnext
		tfr		y,d
		stb		,u
		
modnext	leau	1,u
		bra		modlp

modprev	leau	-1,u
		bra		modlp

modaddr	jsr		gethex
		tsta
		beq		modlp
		tfr		y,u
		bra		modlp

;
;		Hex dump
;
listmem	jsr		gethex
		tsta
		bne		lskip1
		ldx		<pcreg
		bra		listlp2

lskip1	tfr		y,x

listlp2	clr		<bytectr										; Clear character counter
		clr		<linectr

listlp	tst		<bytectr										; do we need to print new line & address?
		bne		listlp1

		lbsr	newline
		
		inc		<linectr
		lda		<linectr
		cmpa	#20
		blo		prtaddr
		
		jsr		inpchr
		cmpa	#'q'
		beq		exlist
		clr		<linectr
		
prtaddr	tfr		x,d												; print address
		lbsr	prthex4
		ldb		#16
		stb		<bytectr
		
listlp1	lbsr	space
		lda		,x+
		lbsr	prthex2
		
		dec		<bytectr
		bra		listlp

exlist	lbsr	newline
		lbra	mainlp

runprog	jsr		gethex
		tsta
		bne		rp1
		ldy		<pcreg
rp1		sty		<pcreg
		ldx		#reentry
		pshs	x
		jmp		,y
		
;rp1		ldx		#reentry								;	Save the return address in the stack
;		pshs	x
;		ldx		#sreg								;	ccreg
;		ldb		#12
;rploop	lda		,-x
;		pshs	a
;		decb
;		bne		rploop
;		orcc	#%10000000								; I want the full monty!
;rp2		
;		rti

reentry	pshs	cc
		std		<areg
		puls	a
		sta		<ccreg
		tfr		dp,a
		sta		<dpreg
		stx		<xreg
		sty		<yreg
		stu		<ureg
		
		lbra	mainlp

ldprog	jsr		inpchr
		
		cmpa	#'S'
		bne		ldprog
		
		jsr		inpchr
		cmpa	#'0'
		beq		srec0
		
		cmpa	#'5'
		beq		srec5
		
		cmpa	#'1'
		beq		srec1
		
		cmpa	#'9'
		bne 	ldprog								; ignore all other record types...

;		End-of-file record
srec9	lbsr	gethex2	
		sta		<chksum
		lbsr	gethex4								; Get address in D
		std		<pcreg								; Save in stored PC
		
;		jsr		prthex4
;		jsr		newline
		
		lbsr	gethex2
		jsr		newline
		
		lbra	mainlp

;		Record count record
srec5	lbsr	gethex2	
		sta		<chksum
		lbsr	gethex4
		
;		jsr		prthex4
;		jsr		newline

		lbra	srchksm

;		Header record - ignore (convert hex byte pairs to ASCII and print?)
srec0	lbsr	gethex2	
		sta		<chksum
		lbsr	gethex4								; Get address in D
		
		ldb		<chksum
		subb	#3
sr0lp	lbsr	gethex2
;		jsr		putchr
		decb
		bne		sr0lp

		lbra	srchksm

;		Data record
srec1	lbsr	gethex2								; Get byte count in A
		sta		<chksum									; Store computed checksum
		suba	#3									; Take off three (address bytes, checksum) to give number of datum bytes
		sta		<bytectr									; and save byte counter.
		
		lbsr	gethex4								; Get address in D
;		lbsr	prthex4
		tfr		d,y
		tfr		d,u
		adda	<chksum									; add high byte of address to checksum
		sta		<chksum
		addb	<chksum									; add low byte
		stb		<chksum
		
sr1lp	;lbsr	space
		lbsr	gethex2								; get byte
;		lbsr	prthex2
		sta		,y+									; store in buffer
		adda	<chksum									; add to checksum
		sta		<chksum
		dec		bytectr
		bne		sr1lp
		
srchksm	lbsr	gethex2								; get checksum in A...

exsrec	adda	<chksum									; ...an add to computed checksum
		inca
;		lbsr	prthex2

;		lbsr	newline
		lbra	ldprog

;		bra		ldprog

srecerr	ldx		#srecerrmsg
		lbsr	prtstr

		lbra	mainlp

;	TO DO - use inpchr instaed of getchr so that S-record conetnts are not echoed.
gethex2	jsr		inpchr
		lbsr	cvthex
		lsla
		lsla
		lsla
		lsla
		pshs	a
		jsr		inpchr
		lbsr	cvthex
		ora		,s+
		rts

gethex4	bsr		gethex2
		tfr		a,b
		bsr		gethex2
		exg		a,b
		rts

vectab	fdb		rtint
		fdb		rtint
		fdb		rtint
		fdb		rtint
		fdb		rtint
		fdb		rtint

		fdb		inpchr
		fdb		getchr
		fdb		prtchr
		fdb		putchr
		fdb		getstr
		fdb		prtstr
		fdb		tstchr
		fdb		ucase
		fdb		lcase
		fdb		getnum
		fdb		gethex
		fdb		cvthex
		fdb		prtdec
		fdb		prthex4
		fdb		prthex2
		fdb		space
		fdb		escchr
		fdb		newline
		fdb		hash
		fdb		prtdate
		fdb		0

swiint	jmp		[swi]
;		rti

swi2int	jmp		[swi2]
;		rti

swi3int	jmp		[swi3]
;		rti
	
firqint	jmp		[firq]
;		rti

nmiint	jmp		[nmi]
;		rti

irqint	jmp		[irq]
rtint:	rti

message
		fcb		esc,'E'
		fcc		'     \     /       '
		fcb		cr,lf
		fcc		'   /-----u------   '
		fcb		cr,lf
		fcc		'  /        .    \  '
		fcb		cr,lf
		fcc		' /   .  :   ,   |  '
		fcb		cr,lf
		fcc		' |    ,  ,      |  '
		fcb		cr,lf
		fcc		' |     , .      |  '
		fcb		cr,lf
		fcc		'  \        ,   /   '
		fcb		cr,lf
		fcc		'   \     ,    /    '
		fcb		cr,lf
		fcc		'    \        /     '
		fcb		cr,lf
		fcc		'     \______/      '
		fcb		cr,lf
		fcb		cr,lf
		fcc		"Nanobug 6809 monitor v1.2"
		fcb		cr,lf
		fcc		"A J F Buckner 2021"
		fcb		cr,lf
		fcb		cr,lf
		fcb		0

prompt	fcc		"* "
		fcb		0

invcmd	fcc		'Unrecognised command '
;		fcb		cr,lf
;		fcb		cr,lf
		fcb		0
		
srecerrmsg
		fcc		""
		fcb		0

		include iolib.asm
		
romtop

		org		0xfff0
rsrvd	fdb		0x0000
swi3vec fdb		swi3int
swi2vec fdb		swi2int
firqvec fdb		firqint
irqvec	fdb		irqint
swivec	fdb		swiint
nmivec	fdb		nmiint
rstvec	fdb		hardrst
