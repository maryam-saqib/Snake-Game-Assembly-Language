[org 0x100]

jmp start

tickcount: dw 0
score: dw 0
oldisr: dd 0

clrscr:	                     ;;;;;clear screen
mov ax,0xb800
mov es,ax
mov di,0
loop11: mov word[es:di],0x0720
add di,2
cmp di,4000
jne loop11
ret

printnum: 	                    ;;;;;print score

push bp 
mov bp, sp 
push es 
push ax 
push bx 
push cx 
push dx
push di

mov ax, 0xb800 
mov es, ax 
mov ax, [bp+4] 
mov bx, 10 
mov cx, 0
mov di,152

nextdigit: mov dx, 0 
div bx 
add dl, 0x30 
push dx 
inc cx 
cmp ax, 0 
jnz nextdigit 

nextpos: pop dx 
mov dh, 0x07 
mov [es:di], dx 
add di, 2 
loop nextpos

pop di
pop dx 
pop cx 
pop bx 
pop ax 
pop es 
pop bp 

ret 2

PrintAstr: 	                     ;;;;;print asterik
;push di
mov di,0
mov ah,0x07
mov al,'*'
mov[es:di],ax
;pop di
ret

printG:	                        ;;;;;print green
push di
mov di,0
loop12: mov word[es:di],0x2220
add di,2
cmp di,4000
jne loop12
pop di
ret

printR:	                          ;;;;;print red
push di

mov di,529                        ;;;;first red line
loop13: mov word[es:di],0x2044
add di,2
cmp di,589
jne loop13

mov di,960                        ;;;;second red line
loop15: mov word[es:di],0x4420
add di,2
cmp di,1020
jne loop15

mov di,1118                        ;;;;third red line
loop16: mov word[es:di],0x4420
sub di,2
cmp di,1058
jne loop16

mov di,1809                        ;;;;fourth red line
loop14: mov word[es:di],0x2044
add di,2
cmp di,1869
jne loop14

mov di,2240                        ;;;;fifth red line
loop17: mov word[es:di],0x4420
add di,2
cmp di,2300
jne loop17

mov di,2398                       ;;;;sixth red line
loop18: mov word[es:di],0x4420
sub di,2
cmp di,2338
jne loop18

pop di

ret

mvright:                              ;;;;move right
mov ax, 0xb800 
mov es, ax 
mov ah,0x07
mov al,'*'
mov word [es:di],0x0720
add di,2
cmp word [es:di],0x2220
jne cmp2
mov [es:di],ax
inc word [cs:score]
push word [cs:score]
call printnum
cmp2:
cmp word [es:di],0x4420
je endG
cmp word [es:di],0x2044
je endG
ret

mvleft:                              ;;;;move left
mov ah,0x07
mov al,'*'
mov word [es:di],0x0720
sub di,2
cmp word [es:di],0x2220
jne cmp4
mov [es:di],ax
inc word [cs:score]
push word [cs:score]
call printnum
cmp4:
cmp word [es:di],0x4420
je endG
cmp word [es:di],0x2044
je endG
ret

mvdown:                               ;;;;move down
mov ah,0x07
mov al,'*'
mov word [es:di],0x0720
add di,160
cmp word [es:di],0x2220
jne cmp3
mov [es:di],ax
inc word [cs:score]
push word [cs:score]
call printnum
cmp3:
cmp word [es:di],0x4420
je endG
cmp word [es:di],0x2044
je endG
ret

endG:
mov bp,0x5000
mov ax,0x4c00
int 21h
add si,0x100
add di,2
jmp nxtloop

mvup:                               ;;;;move up
mov ah,0x07
mov al,'*'
mov word [es:di],0x0720
sub di,160
cmp di,0
jge nxtloop
add di,4002

nxtloop:
cmp word [es:di],0x2220
jne cmp5
cmp bp,0x5000
jne nloop
cmp si,0x100
jne nloop
sub di,4
jmp cmp5
nloop:
mov [es:di],ax
inc word [cs:score]
push word [cs:score]
call printnum
cmp5:
mov si,0x200
cmp word [es:di],0x4420
je endG
cmp word [es:di],0x2044
je endG
ret

timer:                             ;;;;timer
push ax 
inc word [cs:tickcount]; increment tick count 
cmp word [cs:tickcount],18
jne end1

loopd:
cmp bp,0x1000
jne loopl
call mvdown
jmp skip

loopl:
cmp bp,0x2000
jne loopu
call mvleft
jmp skip

loopu:
cmp bp,0x3000
jne loopr
call mvup
jmp skip

loopr:
cmp bp,0x5000
je skip
call mvright
jmp skip

skip:
sub word [cs:tickcount],18

end1:
mov al, 0x20 
out 0x20, al ; end of interrupt 
pop ax 
iret ; return from interrupt

kbisr: 
push ax 
push es 
mov ax, 0xb800 
mov es, ax  
in al, 0x60 

cmp al,0x50
jne nextcmp
mov bp,0x1000
jmp exit

nextcmp: 
cmp al,0x4D
jne nextcmp2
mov bp,0x4000
jmp exit

nextcmp2: 
cmp al,0x4B
jne nextcmp3
mov bp,0x2000
jmp exit

nextcmp3: 
cmp al,0x48
jne nomatch
mov bp,0x3000
jmp exit

nomatch: 
pop es 
pop ax 
jmp far [cs:oldisr] ; call the original ISR 

exit: mov al, 0x20 
out 0x20, al ; send EOI to PIC 
pop es 
pop ax 
iret

start:
call clrscr
call printG
call printR
mov ax,0000
push word [cs:score]
call printnum
call PrintAstr

xor ax, ax 
mov es, ax ; point es to IVT base 
cli ; disable interrupts 
mov word [es:8*4], timer; store offset at n*4 
mov [es:8*4+2], cs ; store segment at n*4+2 
sti ; enable interrupts

xor ax, ax 
mov es, ax 
mov ax, [es:9*4] 
mov [oldisr], ax 
mov ax, [es:9*4+2] 
mov [oldisr+2], ax  
cli
mov word [es:9*4], kbisr
mov [es:9*4+2], cs
sti

mov ax,0x4c00
int 21h
