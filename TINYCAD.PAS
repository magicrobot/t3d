  Program TinyCAD;{Tiny 3d Draw CAD}
  {$M 60000,100000,100000}
  Uses Graf256,{KeyBoard,{Tiny_Lib,Trans_3d,PostEval}interprt;

  const

  kbEsc       = $011B;  kbNoKey     = 0;
  kbGrayUp    = $48E0;  kbGrayDown  = $50E0;
  kbGrayleft  = $4BE0;  kbGrayRight = $4DE0;
  kbGrayMinus = $4A2D;  kbGrayPlus  = $4E2B;

  {angmul=5;{5 degrees}

  type
  pbase=^interpreter;
  Var
  angmul:byte;
  DraWin:pbase;{Draw Buffer Object}
  ch, er:word; line_counter:longint;
  Ifilename,errfilename,command_line:string;
  Ifile,errfile:text;
                  {file,assign,reset,rewrite}
  FUNCTION ReadKeyEnh : Word; Assembler;
  ASM
    MOV AH, 10h
    INT 16h
  END;
  {
  Function ReadKey:char;
  Begin
  READKEY:=CHR(ReadKeyEnh AND $00FF);
  End;
  }
  Begin
  SetTextMode;

  {ask params}
  writeln;
  writeln('Enter Program File Path and Name:');
  readln(IfileName);
  if (ifilename='')then exit;
  writeln;
  writeln('Enter Error File Path and Name:');
  readln(errfileName);
  if (errfilename='')then exit;

  assign(ifile,ifilename);
  assign(errfile,errfilename);

  {
  writeln;
  writeln('Enter Output Bitmap file Path and Name(enter=none):');
  readln(OfileName);
  }
  {line from text file is command line}

  {$i-}
  reset(ifile);
  {$i+}
  er:=ioresult;
  if ((er<>0){or (filesize(ifile)<1)})then begin writeln('can''t open program file');exit;end;
  {$i-}
  rewrite(errfile);
  {$i+}
  er:=ioresult;

  if ((er<>0){or (filesize(errfile)<1})then begin writeln('can''t write error file');exit;end;

  drawin:=new(pbase,init);
  if drawin=nil then
  begin
  writeln('Cannot initialise...');
  close(ifile);close(errfile);
  exit;
  end;

  SetVGA256Mode;{Graphics}
  { experiment success}
  (*
  drawin^.draw_color:=8;
  drawin^.interpret('line -50,-50,-50,50,50,50');
  drawin^.interpret('set_draw_color 10');
  {drawin^.interpret('filled_tri -10,10,-10,100,10,60,1,1,0');}
  er:=drawin^.interpret('set_plot_eqn "x*y"');{eqn not working}
  drawin^.interpret('set_plot_range -1,1,-10,10,4,4');
  drawin^.interpret('set_axis_range -20,20,-20,20,-300,300');
  drawin^.interpret('set_draw_cube_angles -1.0,1.0,0');
  drawin^.interpret('plot');
  *)
  writeln(errfile,'Error list for ',ifilename);
  ch:=kbnokey;
  angmul:=10;
  while(ch<>kbesc)do
  Begin
  drawin^.clear_depth_buffer;
  cleargraphics;{fills 0 color}
  line_counter:=0;

  while not(eof(ifile)) do
  begin
  readln(ifile,command_line);
  line_counter:=line_counter+1;
  er:=0;
  if (command_line<>'')then
  er:=drawin^.interpret(command_line);
  if ((er<>0) and (ch=kbnokey))then writeln(errfile,'Error=',er,' line=',line_counter);
  end;{while}
  {}
  ch:=readkeyenh;{let person see the display}
  if (ch=kbGrayright) then
     begin
     drawin^.logicubeAngles.y:=drawin^.logicubeAngles.y+0.01746*angmul;{(22/(180*7));}
     if (drawin^.logicubeAngles.y>3.142)then drawin^.logicubeAngles.y:=-3.142;
     end else
  if (ch=kbGrayleft) then
     begin
     drawin^.logicubeAngles.y:=drawin^.logicubeAngles.y-0.01746*angmul;{(22/(180*7));}
     if (drawin^.logicubeAngles.y<-3.142)then drawin^.logicubeAngles.y:=3.142;
     end else
  if (ch=kbGrayUp) then
     begin
     drawin^.logicubeAngles.x:=drawin^.logicubeAngles.x-0.01746*angmul;{(22/(180*7));}
     if (drawin^.logicubeAngles.x<-3.142)then drawin^.logicubeAngles.x:=3.142;
     end else
  if (ch=kbGrayDown) then
     begin
     drawin^.logicubeAngles.x:=drawin^.logicubeAngles.x+0.01746*angmul;{(22/(180*7));}
     if (drawin^.logicubeAngles.x>3.142)then drawin^.logicubeAngles.x:=-3.142;
     end else
  if (ch=kbGrayplus) then
     begin
     angmul:=angmul+1;
     if angmul>30 then angmul:=30;
     end else
  if (ch=kbGrayminus) then
     begin
     angmul:=angmul-1;
     if angmul<1 then angmul:=1;
     end else
     ch:=kbesc;


  {$i-}
  reset(ifile);
  {$i+}
  er:=ioresult;
  if ((er<>0){or (filesize(ifile)<1)})then begin writeln('can''t open program file');close(errfile);exit;end;
  end;{while not esc}
  close(ifile);
  close(errfile);
  dispose(drawin,done);
  SetTextMode;{Text}
  {if (er<>0) then write('problem in eqn');}
  writeln('Program by Mandeep Singh Bhatia');
  writeln('B.E(Electronics & communication) - final year');
  writeln('Roll Number - 97 el 256');
  writeln('ITM GURGAON');
  writeln;
  End.
