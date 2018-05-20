{$R-,S-}
UNIT Graf256;
(**) INTERFACE (**)
CONST
  pRep = $00;
  pXor = $18;
  pAnd = $08;
  pOr  = $10;
TYPE
  Line256   = ARRAY[0..319] OF Byte;
  Screen256 = ARRAY[0..199] OF Line256;
  color     = ARRAY[0..2] OF Byte;
  AllColors = ARRAY[0..255] OF Color;
VAR
  VGA256 : Screen256 ABSOLUTE $A000:0000;

  Procedure SetVGA256Mode;
  Procedure SetTextMode;
  Procedure ClearGraphics;{fills screen with color zero}
  Procedure Horizline(x1,y1,dist:word;clr:byte);
  Procedure FilledBox(x1,y1,x2,y2:word;clr:byte);
  PROCEDURE PutPixel256(X, Y, C : Word; upmode : Byte);
  FUNCTION GetPixel256(X, Y : Word) : Byte;
  PROCEDURE SetRGB256(PalNum, R, G, B : Byte);
  PROCEDURE GetRGB256(PalNum : Byte; VAR R, G, B : Byte);
  PROCEDURE Set256Colors(VAR Pal : AllColors);

VAR           {NOT USING PRE DEF PALLETES SAVES CODE SPACE}
  EvenPalette : AllColors;
  GrayPalette : AllColors;
CONST
  NicePalette : AllColors = (
($00,$00,$00),($00,$00,$2A),($00,$2A,$00),($00,$2A,$2A),
($2A,$00,$00),($2A,$00,$2A),($2A,$15,$00),($2A,$2A,$2A),
($21,$21,$21),($21,$21,$3F),($21,$3F,$21),($21,$3F,$3F),
($3F,$21,$21),($3F,$21,$3F),($3F,$3F,$21),($3F,$3F,$3F),
($01,$01,$01),($03,$03,$03),($05,$05,$05),($07,$07,$07),
($09,$09,$09),($0B,$0B,$0B),($0D,$0D,$0D),($0F,$0F,$0F),
($11,$11,$11),($13,$13,$13),($15,$15,$15),($17,$17,$17),
($19,$19,$19),($1B,$1B,$1B),($1D,$1D,$1D),($1F,$1F,$1F),
($00,$00,$12),($00,$00,$15),($00,$00,$18),($00,$00,$1B),
($00,$00,$1E),($00,$00,$21),($00,$00,$24),($00,$00,$27),
($00,$00,$2A),($00,$00,$2D),($00,$00,$30),($00,$00,$33),
($00,$00,$36),($00,$00,$39),($00,$00,$3C),($00,$00,$3F),
($00,$12,$00),($00,$15,$00),($00,$18,$00),($00,$1B,$00),
($00,$1E,$00),($00,$21,$00),($00,$24,$00),($00,$27,$00),
($00,$2A,$00),($00,$2D,$00),($00,$30,$00),($00,$33,$00),
($00,$36,$00),($00,$39,$00),($00,$3C,$00),($00,$3F,$00),
($00,$12,$12),($00,$15,$15),($00,$18,$18),($00,$1B,$1B),
($00,$1E,$1E),($00,$21,$21),($00,$24,$24),($00,$27,$27),
($00,$2A,$2A),($00,$2D,$2D),($00,$30,$30),($00,$33,$33),
($00,$36,$36),($00,$39,$39),($00,$3C,$3C),($00,$3F,$3F),
($12,$00,$00),($15,$00,$00),($18,$00,$00),($1B,$00,$00),
($1E,$00,$00),($21,$00,$00),($24,$00,$00),($27,$00,$00),
($2A,$00,$00),($2D,$00,$00),($30,$00,$00),($33,$00,$00),
($36,$00,$00),($39,$00,$00),($3C,$00,$00),($3F,$00,$00),
($12,$00,$12),($15,$00,$15),($18,$00,$18),($1B,$00,$1B),
($1E,$00,$1E),($21,$00,$21),($24,$00,$24),($27,$00,$27),
($2A,$00,$2A),($2D,$00,$2D),($30,$00,$30),($33,$00,$33),
($36,$00,$36),($39,$00,$39),($3C,$00,$3C),($3F,$00,$3F),
($12,$12,$00),($15,$15,$00),($18,$18,$00),($1B,$1B,$00),
($1E,$1E,$00),($21,$21,$00),($24,$24,$00),($27,$27,$00),
($2A,$2A,$00),($2D,$2D,$00),($30,$30,$00),($33,$33,$00),
($36,$36,$00),($39,$39,$00),($3C,$3C,$00),($3F,$3F,$00),
($21,$21,$21),($23,$23,$23),($25,$25,$25),($27,$27,$27),
($29,$29,$29),($2B,$2B,$2B),($2D,$2D,$2D),($2F,$2F,$2F),
($31,$31,$31),($33,$33,$33),($35,$35,$35),($37,$37,$37),
($39,$39,$39),($3B,$3B,$3B),($3D,$3D,$3D),($3F,$3F,$3F),
($12,$0D,$00),($15,$0F,$00),($18,$11,$00),($1B,$13,$00),
($1E,$15,$00),($21,$17,$00),($24,$19,$00),($27,$1B,$00),
($2A,$1D,$00),($2D,$20,$00),($30,$22,$00),($33,$24,$00),
($36,$26,$00),($39,$28,$00),($3C,$2A,$00),($3F,$2C,$00),
($0D,$12,$00),($0F,$15,$00),($11,$18,$00),($13,$1B,$00),
($15,$1E,$00),($17,$21,$00),($19,$24,$00),($1B,$27,$00),
($1D,$2A,$00),($20,$2D,$00),($22,$30,$00),($24,$33,$00),
($26,$36,$00),($28,$39,$00),($2A,$3C,$00),($2C,$3F,$00),
($0D,$00,$12),($0F,$00,$15),($11,$00,$18),($13,$00,$1B),
($15,$00,$1E),($17,$00,$21),($19,$00,$24),($1B,$00,$27),
($1D,$00,$2A),($20,$00,$2D),($22,$00,$30),($24,$00,$33),
($26,$00,$36),($28,$00,$39),($2A,$00,$3C),($2C,$00,$3F),
($12,$00,$0D),($15,$00,$0F),($18,$00,$11),($1B,$00,$13),
($1E,$00,$15),($21,$00,$17),($24,$00,$19),($27,$00,$1B),
($2A,$00,$1D),($2D,$00,$20),($30,$00,$22),($33,$00,$24),
($36,$00,$26),($39,$00,$28),($3C,$00,$2A),($3F,$00,$2C),
($00,$0D,$12),($00,$0F,$15),($00,$11,$18),($00,$13,$1B),
($00,$15,$1E),($00,$17,$21),($00,$19,$24),($00,$1B,$27),
($00,$1D,$2A),($00,$20,$2D),($00,$22,$30),($00,$24,$33),
($00,$26,$36),($00,$28,$39),($00,$2A,$3C),($00,$2C,$3F),
($00,$12,$0D),($00,$15,$0F),($00,$18,$11),($00,$1B,$13),
($00,$1E,$15),($00,$21,$17),($00,$24,$19),($00,$27,$1B),
($00,$2A,$1D),($00,$2D,$20),($00,$30,$22),($00,$33,$24),
($00,$36,$26),($00,$39,$28),($00,$3C,$2A),($00,$3F,$2C),
($32,$32,$3F),($32,$3F,$32),($32,$3F,$3F),($3F,$32,$32),
($3F,$32,$3F),($3F,$3F,$32),($3F,$2C,$19),($2C,$3F,$19),
($2C,$19,$3F),($3F,$19,$2C),($19,$2C,$3F),($19,$3F,$2C),
($39,$39,$3F),($39,$3F,$39),($3F,$39,$39),($3F,$3F,$3F));

(**) IMPLEMENTATION (**)
  PROCEDURE SetVideoMode(M : Byte); Assembler;
  ASM
    MOV AH, 00   {function 0, "set video mode"}
    MOV AL, M
    INT 10h
  END;

  Procedure SetVGA256Mode;
  Begin
  SetVideoMode($13);
  End;

  Procedure SetTextMode;
  Begin
  SetVideoMode(3);
  end;

  Procedure ClearGraphics;Assembler;
  ASM {by me}
  mov ax,$a000
  mov es,ax
  xor di,di
  mov cx,32000
  cld
  xor ax,ax
  rep stosw
  end;

  Procedure Horizline(x1,y1,dist:word;clr:byte);assembler;
  asm{mine- if word mult is faster than 2 shr's & xchng}
  mov ax,$a000
  mov es,ax
  mov ax,y1
  mov di,320   {for start from 0,0.. xsize*y+x=offset;; 0..319}
  mul di
  add ax,x1
  mov di,ax {offset calc done}
  mov cx,dist
  mov al,clr {fill color}
  cld {inc dir addr.. in di}
  rep stosb
  end;

  Procedure FilledBox(x1,y1,x2,y2:word;clr:byte);
  var lp,d:integer;
  begin
  if (x1>x2)then begin lp:=x1;x1:=x2;x2:=lp;end;
  if (y1>y2)then begin lp:=y1;y1:=y2;y2:=lp;end;
  d:=x2-x1;
  for lp:=y1 to y2 do
  horizline(x1,lp,d,clr);
  end;

  PROCEDURE PutPixel256(X, Y, C : Word;
              upmode : Byte); Assembler;
  ASM
    MOV AX, Y
    MOV BX, X
    XCHG AH, AL    {AX is now 256 * Y}
    ADD BX, AX     {BX contains 256*Y + X}
    SHR AX, 1
    SHR AX, 1      {AX contains 64 * Y}
    ADD BX, AX     {BX contains (256+64)*Y + X...}
                   {... that's 320*Y + X}
    MOV AX, 0A000h
    MOV ES, AX     {ES:BX points to byte}
    MOV AX, C
    MOV AH, upmode
    CMP AH, pRep
    JNE @NotRep
    MOV ES:[BX], AL
    JMP @end
     @NotRep:
    CMP AH, pAnd
    JNE @NotAnd
    AND ES:[BX], AL
    JMP @End
     @NotAnd:
    CMP AH, pOr
    JNE @NotOr
    OR ES:[BX], AL
    JMP @End
     @NotOr:
    XOR ES:[BX], AL
    @End:
  END;

  FUNCTION GetPixel256(X, Y : Word) : Byte; Assembler;
  ASM  {ultimate optimised addr calc for reqd mode}
    MOV AX, Y
    MOV BX, X
    XCHG AH, AL     {AX is now 256 * Y}
    ADD BX, AX      {BX contains 256*Y + X}
    SHR AX, 1
    SHR AX, 1       {AX contains 64 * Y}
    ADD BX, AX      {BX contains (256+64)*Y + X}
                    {... that's 320*Y + X}
    MOV AX, 0A000h
    MOV ES, AX      {ES:BX points to byte}
    MOV AL, ES:[BX] {put it in AL - that's all!}
  END;

  PROCEDURE SetRGB256(PalNum, R, G, B : Byte); Assembler;
  ASM
    XOR BH, BH
    MOV BL, PalNum {BX contains color now}
    MOV AH, 10h    {func. 10h, subfunc. 10h}
    MOV AL, 10h    {"Set Color Register"}
    MOV DH, R
    MOV CH, G
    MOV CL, B
    INT 10h
  END;

  PROCEDURE GetRGB256(PalNum : Byte;
              VAR R, G, B : Byte); Assembler;
  ASM
    XOR BH, BH
    MOV BL, PalNum {BX contains color now}
    MOV AH, 10h    {func. 10h, subfunc. 10h}
    MOV AL, 15h    {"Get Color Register"}
    INT 10h
    LES DI, R
    MOV ES:[DI], DH
    LES DI, G
    MOV ES:[DI], CH
    LES DI, B
    MOV ES:[DI], CL
  END;

  PROCEDURE Set256Colors(VAR Pal : AllColors); Assembler;
  ASM
    MOV AH, 10h  {function 10h, subfunction 12h}
    MOV AL, 12h  {"set block of color registers"}
    MOV BX, 0    {first register is 0}
    MOV CX, 256  {number of registers is 256}
    LES DX, Pal  {ES:DX points to color table}
    INT 10h
  END;

  PROCEDURE SetUpPal;
  VAR
    BB : ARRAY[0..3] OF Byte;
    RG : ARRAY[0..7] OF Byte;
    N  : Byte;
  BEGIN
    BB[0] := $00; BB[1] := $55; BB[2] := $AA; BB[0] := $FF;
    RG[0] := $00; RG[1] := $24; RG[2] := $49; RG[3] := $6D;
    RG[4] := $92; RG[5] := $B6; RG[6] := $DB; RG[7] := $FF;
    FOR N := 0 to 255 DO
      BEGIN
        EvenPalette[N][0] := RG[N MOD 8];
        EvenPalette[N][1] := RG[(N DIV 8) MOD 8];
        EvenPalette[N][2] := BB[N DIV 64];
        GrayPalette[N][0] := N MOD 64;
        GrayPalette[N][1] := N MOD 64;
        GrayPalette[N][2] := N MOD 64;
      END;
  END;

BEGIN
  SetUpPal;
END.
