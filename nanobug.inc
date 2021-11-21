		pragma	nolist

vecbase	equ		0x0000
swi3 	equ		vecbase
swi2 	equ		swi3+2
firq 	equ		swi2+2
irq		equ		firq+2
swi		equ		irq+2
nmi		equ		swi+2

sbrbase	equ		nmi+2

inpchr	equ		0
getchr	equ		inpchr+1
prtchr	equ		getchr+1
putchr	equ		prtchr+1
getstr	equ		putchr+1
prtstr	equ		getstr+1
tstchr	equ		prtstr+1
ucase	equ		tstchr+1
lcase	equ		ucase+1
getnum	equ		lcase+1
gethex	equ		getnum+1
cvthex	equ		gethex+1
prtdec	equ		cvthex+1
prthex4 equ		prtdec+1
prthex2 equ		prthex4+1
space	equ		prthex2+1
escchr	equ		space+1
newline equ		escchr+1
hash	equ		newline+1
prtdate equ		hash+1
skipsp	equ		prtdate+1

eot		equ		0x04
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

via		equ		0xbfa0
via_ora	equ		via+1
via_orb	equ		via
via_ddra equ	via+3
via_ddrb equ	via+2
via_t1cl equ	via+4
via_t1ch equ	via+5
via_t1ll equ	via+6
via_t1lh equ	via+7
via_t2cl equ	via+8
via_t2ch equ	via+9
via_sr	equ		via+0x0a
via_acr	equ		via+0x0b
via_pcr	equ		via+0x0c
via_ifr	equ		via+0x0d
via_ier	equ		via+0x0e
via_ora2 equ	via+0x0f

oscall	macro
		jsr			[sbrbase+(\1)*2]
		endm

		pragma	list
