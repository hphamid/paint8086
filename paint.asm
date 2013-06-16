Data segment
  widths db 2
  xs dw ?
  ys dw ?
  xf dw ?
  yf dw ?
  colorList  db 00111111b, 1, 2, 3, 4, 5, 14, 7
  colorCount equ $-colorList
  dcolor db 00111111b
  color db 00111111b  ; save current color
  state db 0 ; 0 = Draw, 1 = erase
  temp dw 0
  maxY    equ 420
  maxX    equ 640
  colorboxstarty equ maxY + 20
  colorboxstartx equ 20
  colorboxwidth equ 20
  modboxstartx equ colorboxstartx+ colorCount*colorboxwidth+200
  modboxstarty equ colorboxstarty
  modboxwidth equ 20
  modcount equ 3
  erasew equ 10
  draww equ 5
  airw equ 3
Data ends


stack_s segment PARA STACK 'STACK'
    DW          4000     DUP(0)
    Top_Stack   Label   Word
stack_s ends


init macro
  mov AX, Data
  mov DS, AX
  mov ES, AX

  mov AX, stack_s
  mov SS, AX

  mov ax, 0
  int 33h

  mov ax, 1
  int 33h
endm


mouseEventInit macro
  mov ax, seg eventf
  mov es, ax
  mov dx, offset eventf
  mov ax, 0ch
  mov cx, 00000011b
  int 33h
endm


pushall macro
  push ax
  push bx
  push cx
  push dx
  push bp
  push si
  push di
endm


popall macro
  pop di
  pop si
  pop bp
  pop dx
  pop cx
  pop bx
  pop ax
endm


putchar macro p1
    pushf
    push ax
    push dx
    mov dl, p1
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    popf
endm


drawline macro x1, y1, x2, y2
  pushall
  mov ax, x1
  mov xs, ax
  mov ax, y1
  mov ys, ax
  mov ax, x2
  mov xf, ax
  mov ax, y2
  mov yf, ax
  call ddraw
  popall
endm


drawemptyline macro x1, y1, x2, y2
  pushall
  mov ax, x1
  mov xs, ax
  mov ax, y1
  mov ys, ax
  mov ax, x2
  mov xf, ax
  mov ax, y2
  mov yf, ax
  call ddraw
  mov ax, x1
  inc ax
  inc ax
  mov xs, ax
  mov ax, y1
  inc ax
  inc ax
  mov ys, ax
  mov ax, x2
  dec ax
  dec ax
  mov xf, ax
  mov ax, y2
  dec ax
  dec ax
  mov yf, ax
  mov al, 0
  mov dcolor, al
  call ddraw
  popall
endm


drawcolors macro
  xor si, si
  mov bp, colorboxstartx
  mov di, colorboxstarty
  colorLoop:
  mov al, colorList[si]
  mov dcolor, al
  inc si
  mov cx, bp
  add cx, colorboxwidth
  mov dx, di
  add dx, colorboxwidth
  drawline bp,di,cx,dx
  mov bp, cx
  cmp si, colorCount
  jb colorLoop
  mov al, colorList
  mov dcolor, al
  mov color, al
endm


drawmods macro
  xor si, si
  mov bp, modboxstartx
  mov di, modboxstarty
  modLoop:
  mov al, colorList[si+2]
  mov dcolor, al
  inc si
  mov cx, bp
  add cx, modboxwidth
  mov dx, di
  add dx, modboxwidth
  drawemptyline bp,di,cx,dx
  mov bp, cx
  cmp si, modCount
  jb modLoop
  mov al, colorList
  mov dcolor, al
  mov color, al
endm


delay macro n
    push cx
    mov cx, n
    wt: loop wt
    pop cx
endm

findrand macro
  call random
  mov ax, temp
  and al, 1Fh
  xor ah, ah
  cbw
  sub ax, 8
endm

code    segment
  Assume CS:code, DS:data, ES:code, SS:stack_s

  eventf proc far
    pushall
    and bx, 0001H
    jnz keydown
    jmp efin
    keydown:
      mov xf, cx
      mov yf, dx
      call chksetting
      mov ah, state
      cmp ah, 0
      jne ndrawNormal
      jmp drawNormal
      ndrawNormal:
      cmp ah, 1
      jne nerase
      jmp erase
      nerase:
        jmp efin
      erase:
      mov ah, erasew
      mov widths, ah
      mov ah, 0
      mov dcolor, ah
      jmp calldraw
      drawNormal:
      mov ah, draww
      mov widths, ah
      mov ah, color
      mov dcolor, ah
      jmp calldraw
      calldraw:
      call draw
      jmp efin
    efin:
      popall
      ret
  eventf endp

  random proc near
    pushall
    mov ax, 0
    int 1ah
    add dx, temp
    inc dx
    mov ax, 123
    mul dx
    mov temp, ax
    popall
    ret
  random endp

  Airbrush proc near
    pushall
    mov ax, 3
    int 33h
    and bx, 0001h
    cmp bx, 0001h
    je Airdo
    jmp Afin
    Airdo:
      findrand
      sub cx, ax
      findrand
      findrand
      sub dx, ax
      mov xf, cx
      mov yf, dx
      mov al, color
      mov dcolor, al
      mov ah, airw
      mov widths, ah
      call draw
      jmp Afin
    Afin:
      popall
      ret
  Airbrush endp

  chksetting proc near
    pushall
    mov cx, xf
    mov dx, yf
    cmp cx, colorboxstartx
    jae color2
    jmp fin
  color2:
    cmp cx, colorboxstartx + colorCount * colorboxwidth
    jb color3
    jmp chkmod
  color3:
    cmp dx, colorboxstarty
    jae color4
    jmp fin
  color4:
    cmp dx, colorboxstarty + colorboxwidth
    jbe decodeColor
    jmp fin
    decodeColor:
    mov ax, cx
    sub ax, colorboxstartx
    mov dl, colorboxwidth
    div dl
    xor ah, ah
    cbw
    mov si, ax
    mov al, colorList[si]
    mov color, al
    jmp fin
  chkmod:
    cmp cx, modboxstartx
    jae mod2
    jmp fin
  mod2:
    cmp cx, modboxstartx + modCount * modboxwidth
    jb mod3
    jmp fin
  mod3:
    cmp dx, modboxstarty
    jae mod4
    jmp fin
  mod4:
    cmp dx, modboxstarty + modboxwidth
    jbe decodemod
    jmp fin
    decodemod:
    mov ax, cx
    sub ax, modboxstartx
    mov dl, modboxwidth
    div dl
    mov state, al
    jmp fin
  fin:
    popall
    ret
  chksetting endp


  draw proc near
    pushall
    mov cx, xf
    mov dx, yf
    cmp cx, maxX
    jb xok
    jmp dfin
  xok:
    cmp dx, maxY
    jb dodraw
    jmp dfin
  dodraw:
    mov xf, cx
    mov yf, dx
    mov al, widths
    cbw
    cmp cx, ax
    ja subx
    mov cx, ax
    inc cx
    subx:
    sub cx, ax
    cmp dx, ax
    ja suby
    mov dx, ax
    inc dx
    suby:
    sub dx, ax
    mov xs, cx
    mov ys, dx
    call ddraw
    dfin:
    popall
    ret
  draw endp

  ddraw proc near
      pushall
      mov cx, xs                  ;For xs <= CX < xf
    XLOOP:

        mov dx, ys                  ;For ys <= CY < yf
    YLOOP:

        mov al, dcolor               ;Change color of a pixel
        mov ah, 0ch
        int 10h

        inc dx
        cmp dx, yf
        jb YLOOP

        inc CX
        cmp CX, xf
        jb XLOOP
        popall
        ret
  ddraw endp

start:
  MOV AH, 0                   ;Video mode 640x480, 256 colors
  MOV AL, 12H
  INT 10H
  init
  drawline 0,maxY, maxX,  maxY+1
  drawcolors
  drawmods
  xor al, al
  mov state, al
  mouseEventInit

  infinit:
  mov al,state
  cmp al, 2
  jne infinit
  call Airbrush
  delay 50000
  jmp infinit
code ends
end start
