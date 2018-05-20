unit interprt;

interface
uses trans_3d,tiny_lib,PostEval,Graf256{,TextEdit};
const max_params=9;
type

interpreter=object(z_draw)
private
Vref:Var_Table;
Func_Postfix:Exp_Table; err_pos,err_code:word;
Fstring:string;
g_pos,temp_pt1,temp_pt2,temp_pt3:p3df;
   pr:array [1..max_params] of string;{string[100]or 250} {will need large stack-data}
   V :array [1..max_params] of real;
   {}
   start_x,start_y,step_x,step_y:real; numsteps_x,numsteps_y:byte;
   err_code_i,err_pos_i:word;
   {}
   curr_pos:word;slen:byte;reads:string;
public                 {read-text.. text files type}
{txt_edit:text_edit;{use addr}
MeshMode:Boolean;

constructor init;
destructor done;

Procedure setplotfunc(fnc:string);{return error in plot}
Procedure plot3d;
function set_plot_range(xv1,xv2,yv3,yv4:real;nxv5,nyv6:byte):boolean;
procedure init_reader(s:string);{curr_pos,}
function get_word_and_set_next:string;
function get_params(n:byte):boolean;
function get_values(n:byte):boolean;
procedure make_shades(maxb,minb:byte);
Function interpret(CommandLine:string):word;{full/stepped(skip,execute)}
end;

implementation

constructor interpreter.init{(fn:string)};
begin
if not inherited init then fail;
{z_draw.}{Inherited init;}
{txt_edit.init(fn);{check for fail too later.. or set & read status}
{use new with pointers to create objects}

MeshMode:=true;{optimise speed}
VREF.NUM_VARS_USED:=4;
VREF.VARS[1].NAME:='X';
VREF.VARS[2].NAME:='Y';
VREF.VARS[3].NAME:='PI';
VREF.VARS[4].NAME:='DR';{(rad/deg)*deg=rad... deg to rad}
VREF.VARS[1].VALUE:=0.0;
VREF.VARS[2].VALUE:=0.0;
VREF.VARS[3].VALUE:=PI;
VREF.VARS[4].VALUE:={180.0/}PI/180.0;
fstring:='0';{default 3d func}
infix_to_postfix(fstring,func_postfix,vref,err_code,err_pos);
{initialise func plot params too}
start_x:=0;start_y:=0;numsteps_x:=10;numsteps_y:=10;step_x:=5;step_y:=5;
err_code:=0;err_pos:=0;{}
end;

destructor interpreter.done;
begin
z_draw.done;
{txt_edit.done;}
end;

Procedure interpreter.setplotfunc(fnc:string);{return error in plot}
var pf:Exp_Table;i:Byte;  {use or don't}
begin

{string should be uppercase only}
for i := 1 to Length(fnc) do
  fnc[i] := UpCase(fnc[i]);
{fnc[0]=length ascii}
infix_to_postfix(fnc,pf,vref,err_code,err_pos);
if (err_code=0) then begin fstring:=fnc;func_postfix:=pf;end;
{err_code & err_pos good for checking expression faults for recent tried func}
end;

Procedure interpreter.plot3d;
var
    stx,sty:real; r1,r2,r3,r4:symbol_id; pok:boolean;
    p1,p2,p3,p4:p3df; cx,cy:byte;
{define & set start_x,start_y,numsteps_x,numsteps_y,step_x,step_y.. by a proc}
begin
stx:=start_x;
for cx:=1 to (numsteps_x-1) do {min val for numsteps=2}
    begin
    {}
    sty:=start_y;
        {Vref.vars[1].value:=stx;}
    {}
    for cy:=1 to (numsteps_y-1) do
        begin
      {}Vref.vars[1].value:=stx;{}
        Vref.vars[2].value:=sty;

        eval_postfix(func_postfix,vref,r1);

        Vref.vars[1].value:=stx+step_x;
        {Vref.vars[2].value:=sty;}
        eval_postfix(func_postfix,vref,r2);

        Vref.vars[1].value:=stx;
        Vref.vars[2].value:=sty+step_y;
        eval_postfix(func_postfix,vref,r3);

        Vref.vars[1].value:=stx+step_x;
        {Vref.vars[2].value:=sty+step_y;}
        eval_postfix(func_postfix,vref,r4);
        {now plot for r1,r2,r3 & r4,r3,r2}

        {surface 1}
        pok:= not(
                 (r1.inf or r1.indeter or r1.unreal)or
                 (r2.inf or r2.indeter or r2.unreal)or
                 (r3.inf or r3.indeter or r3.unreal)
                 );
        if pok then
        begin
        p1.x:=stx;p1.y:=sty;p1.z:=r1.value;
        p2.x:=stx+step_x;p2.y:=sty;p2.z:=r2.value;
        p3.x:=stx;p3.y:=sty+step_y;p3.z:=r3.value;
           if MeshMode then begin
                            aligned_z_line(p1,p2);
                            aligned_z_line(p1,p3);
                            {aligned_z_line(p2,p3);}
                            end else
                            aligned_z_tri(p1,p2,p3);
        end;
        {surface 2}
        pok:= not(
                 (r4.inf or r4.indeter or r4.unreal)or
                 (r2.inf or r2.indeter or r2.unreal)or
                 (r3.inf or r3.indeter or r3.unreal)
                 );
        if pok then
        begin
        p4.x:=stx+step_x;p4.y:=sty+step_y;p4.z:=r4.value;
        p2.x:=stx+step_x;p2.y:=sty;p2.z:=r2.value;{in case surface1 not done}
        p3.x:=stx;p3.y:=sty+step_y;p3.z:=r3.value;
           if MeshMode then begin
                            aligned_z_line(p4,p2);{due to approx error p4,p2 or p2,p4 can be different for depth calc}
                            aligned_z_line(p4,p3);
                            {aligned_z_line(p2,p3);}
                            end else
                            aligned_z_tri(p4,p2,p3);
        end;
        {}
        sty:=sty+step_y;
        end;{cy}
        stx:=stx+step_x;
    end;{cx}
end;

function interpreter.set_plot_range(xv1,xv2,yv3,yv4:real;nxv5,nyv6:byte):boolean;
begin{}
set_plot_range:=false;
if not((xv1<>xv2)and(yv3<>yv4)and(nxv5>1)and(nyv6>1)) then exit{ret error};
start_x:=xv1;start_y:=yv3;
numsteps_x:=nxv5; numsteps_y:=nyv6;
step_x:=(xv2-xv1)/numsteps_x;
step_y:=(yv4-yv3)/numsteps_y;
set_plot_range:=true;
end;

procedure interpreter.init_reader(s:string);{curr_pos,}
begin{}
curr_pos:=1; reads:=s; slen:=length(reads);
end;

function interpreter.get_word_and_set_next:string;
var st:string;
begin{}
st[0]:=#0;  slen:=length(reads){for safety};
get_word_and_set_next:=st;
if (curr_pos>slen) then exit;

while( ((reads[curr_pos]=' ')or(reads[curr_pos]=','))and(curr_pos<=slen)) do
curr_pos:=curr_pos+1;{trim spaces}
if (curr_pos>slen) then exit;

while ( (not((reads[curr_pos]=' ')or(reads[curr_pos]=',')))
           and(curr_pos<=slen) and (reads[curr_pos]<>'"')
         ) do
         begin
         st:=st+reads[curr_pos];
         curr_pos:=curr_pos+1;
         end;{while}
if ((reads[curr_pos]='"')and(st[0]=#0)) then
begin st:='"';curr_pos:=curr_pos+1;end;
{seperates " from within all words}
get_word_and_set_next:=st;

end;

function interpreter.get_params(n:byte):boolean;
var st:string;ch:char;lp:byte;
begin{}
get_params:=false;
{max_params=9} if ((n<1)or(n>max_params))then exit;
{seek for strings too}
for lp:=1 to n do
    begin
    pr[lp]:=get_word_and_set_next;
    if pr[lp]='"' then
       begin
       pr[lp][0]:=#0;
       ch:=#0;
       st[0]:=#0;{zero length string}
       while ((ch<>'"')) do
             begin
             st:=get_word_and_set_next;
             if (st='') then exit;
             ch:=st[1];
             {if (st<>'')then ch:=st[1] else exit{func failed}
             if (ch<>'"') then pr[lp]:=pr[lp]+st;
             end;{while}
       end;{if}
    if (pr[lp]='') then exit;{in sufficient params}
    end;{for}
get_params:=true;{all ok}
end;

function interpreter.get_values(n:byte):boolean;
var lp:byte;b:boolean;
begin{}
get_values:=false;
if ((n<1)or(n>max_params))then exit;
for lp:=1 to n do
    begin
    v[lp]:=str_val(pr[lp],b); {posteval}
    if b then exit;{exceeding number}
    end;
get_values:=true;
end;

procedure interpreter.make_shades(maxb,minb:byte);
var rr,gr,br,brr:real;
    r,g,b,lp:byte;
    av:word;
    {c:allcolor;}

begin{}
if (maxb=minb) then exit;{use set rgb instead}
if ((draw_color+numshadestouse)>256) then exit{exceeds pallete};
getrgb256(draw_color,r,g,b);
av:=r+g+b;
if (av<1) then exit{black only};
if (maxb<minb){sort} then begin lp:=maxb;maxb:=minb;minb:=lp;end;
brr:=(maxb-minb)/numshadestouse;
rr:=r/av;gr:=g/av;br:=b/av;{real expected}
for lp:=1 to numshadestouse  do
    begin
    r:=abs(round(rr*(brr*lp+minb)))mod 256;
    b:=abs(round(gr*(brr*lp+minb)))mod 256;
    g:=abs(round(br*(brr*lp+minb)))mod 256;
    setrgb256(draw_color+lp-1,r,g,b);
    end;
end;

Function interpreter.interpret(CommandLine:string):word;{full/stepped(skip,execute)}
VAR
   Command,param:string[30];
   (*
   pr:array [1..9] of string;{string[100]or 250} {will need large stack}
   V :array [1..9] of real;
   *)
   ll,lpp:byte;
   (*
   procedure capitalise(var ss:string);
   var ll,lpp:byte;
   begin
   ll:=length(ss);
   for lpp:=1 to ll do ss[lpp]:=upcase(ss[lpp]);
   end;
   *)
begin
interpret:=0;{no error}  {consider uppercase}
{errors- wrong no. of params or type, is number or name check}
{or wrong command}
            {UPCASE ENTIRE FILE}
if (length(commandline)<1)then begin interpret:=16{invalid line};exit;end;
{capitalise(commandline);}
   ll:=length(commandline);
   for lpp:=1 to ll do commandline[lpp]:=upcase(commandline[lpp]);
init_reader(CommandLine);
{command:=get_word_and_set_next;}
if (get_params(1)=false)then begin interpret:=1{command expected};exit;end;
command:=pr[1];
{case command of
     begin}
     if (command='MOVE_TO') then
               Begin
               if (get_params(3)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(3)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               g_pos.x:=v[1];
               g_pos.y:=v[2];
               g_pos.z:=v[3];
               end
               else
     if (command='LINE_TO')then
               Begin
               if (get_params(3)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(3)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               temp_pt1.x:=v[1];temp_pt1.y:=v[2];temp_pt1.z:=v[3];
               aligned_z_line(g_pos,temp_pt1);
               g_pos:=temp_pt1;
               end{}
                  else
     if (command='POINT')then
               Begin
               if (get_params(3)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(3)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;

               temp_pt1.x:=v[1];temp_pt1.y:=v[2];temp_pt1.z:=v[3];
               aligned_z_point(temp_pt1);
               {g_pos.x:=;}
               end{}
                else

     if (command='LINE') then
               Begin
               if (get_params(6)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(6)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               temp_pt1.x:=v[1];temp_pt1.y:=v[2];temp_pt1.z:=v[3];
               temp_pt2.x:=v[4];temp_pt2.y:=v[5];temp_pt2.z:=v[6];
               aligned_z_line(temp_pt1,temp_pt2);
               {g_pos:=temp_pt2;}

               end
                  else

     if (command='FILLED_TRI')then
               Begin
               if (get_params(9)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(9)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               temp_pt1.x:=v[1];temp_pt1.y:=v[2];temp_pt1.z:=v[3];
               temp_pt2.x:=v[4];temp_pt2.y:=v[5];temp_pt2.z:=v[6];
               temp_pt3.x:=v[7];temp_pt3.y:=v[8];temp_pt3.z:=v[9];
               aligned_z_tri(temp_pt1,temp_pt2,temp_pt3);
               end{now get out of case.. break?continue}
                  else

     if (command='PLOT')then begin plot3d; end{NO PARAMS}
                                   else
     if (command='MAKE_SHADES')then {max,min brightness level}
               Begin  {}
               if (get_params(2)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(2)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               make_shades(abs(trunc(v[1]))mod 256,abs(trunc(v[2]))mod 256);{}
               end{}
                  else
     if (command='SET_PLOT_EQN')then
               Begin  {}
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
                                 {" gfgfgfg  gfg "}
               setplotfunc(pr[1]);
               end
                  else
     (*
     'SET_PLOT_RES':
               Begin
               if (get_params(pr,2)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(pr,v,2)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;

               end;{x&y num_steps-2 to 255}  {numsteps..step}
     *)
     if (command='SET_PLOT_RANGE')then{start_x,y,stop_x,y,numsteps_x,y}
               Begin
               if (get_params(6)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(6)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               if (set_plot_range(v[1],v[2],v[3],v[4],abs(trunc(v[5]))mod 256,abs(trunc(v[6]))mod 256)=false)
               then begin interpret:=10;exit;end;{adjusts step size}

               end{x&y num_steps-2 to 255}  {numsteps..step}
                  else
     if (command='SET_DRAW_COLOR')then
               Begin
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(1)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               {if ((v[1]<256)and(v[1]>=0)then}
               draw_color:=abs(trunc(v[1]))mod 256;
               end
                  else
     if (command='SET_RGB')then
               Begin
               if (get_params(3)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(3)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               {graf256}
               setrgb256(draw_color,abs(trunc(v[1]))mod 256,abs(trunc(v[2]))mod 256,abs(trunc(v[3]))mod 256);
               end{maybe mod 64 or 32 should be used}
                  else
     if (command='SET_AXIS_RANGE')then
               Begin
               if (get_params(6)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(6)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               temp_pt1.x:=v[1];temp_pt2.x:=v[2];
               temp_pt1.y:=v[3];temp_pt2.y:=v[4];
               temp_pt1.z:=v[5];temp_pt2.z:=v[6];
               setrange(temp_pt1,temp_pt2);
               end{}
                   else
     if (command='SET_SHADE_REF_POS')then{align point & place light src-later}
               Begin
               if (get_params(3)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(3)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               if ((v[1]<23000{127})and(v[1]>-23000{-128}) and
                   (v[2]<23000{127})and(v[2]>-23000{-128}) and
                   (v[3]<23000{127})and(v[3]>-23000{-128}))then
                  begin
                  shade_light_ref.x:=trunc(v[1]);
                  shade_light_ref.y:=trunc(v[2]);
                  shade_light_ref.z:=trunc(v[3]);
                  end;

               end{}
                  else
     if (command='SET_SHADING_RANGE')then{DIST1,DIST2->LATER SCALE,.. NOW INTS}
               Begin
               if (get_params(2)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(2)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               if ((v[1]<23000{127})and(v[1]>-23000{-128}) and
                   (v[2]<23000{127})and(v[2]>-23000{-128})
                  )then
                   SetShadeDistRange(trunc(v[1]),trunc(v[2]));
               end{}
                  else
     if (command='SET_MAX_SHADES')then
               Begin
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(1)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               {set num shades to use}
               if (v[1]<1.0) then v[1]:=1.0;
               SetNumShadesToUse(trunc(v[1])mod 256);
               end{}
                  else
     if (command='SET_DRAW_CUBE_ANGLES')then
               Begin
               if (get_params(3)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(3)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               DrawCubeAngles.x:=v[1];
               DrawCubeAngles.y:=v[2];
               DrawCubeAngles.z:=v[3];
               end{}
                  else
     if (command='SET_DRAW_TRANSLATION')then
               Begin
               if (get_params(3)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(3)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               PTranslate.x:=v[1];PTranslate.y:=v[2];PTranslate.z:=v[3];
               end{}
                  else
     if (command='SET_VIEW_CUBE_ANGLES')then
               Begin
               if (get_params(3)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(3)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               LogiCubeAngles.x:=v[1];
               LogiCubeAngles.y:=v[2];
               LogiCubeAngles.z:=v[3];
               end{}
                  else
     if (command='SET_DIST_FACTOR')then
               Begin
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(1)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               set_dist_factor(abs(round(v[1]))mod 256);
               end{}
                  else
     if (command='SET_EYE_DISTANCE')then
               Begin
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               if (get_values(1)=false) then
                                             begin
                                             interpret:=3;
                                             {in range num expected}
                                             exit;
                                             end;
               setperspective(abs(round(v[1]))mod 23000);
               end{}
                  else
     if (command='SET_PERSPECTIVE_VIEW')then{ON/OFF}
               Begin
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               PerspectiveView:=pr[1]='ON'; {pr[1][0]..str len}
               end{}
                  else
     if (command='SET_MESHMODE')then
               Begin
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               MeshMode:=pr[1]='ON';
               end{}
                  else
     if (command='SET_OVERWRITING')then
               Begin
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               OverWriting:=pr[1]='ON';
               end{}
                  else
     if (command='SET_SHADING')then
               Begin
               if (get_params(1)=false) then
                                           begin
                                           interpret:=2;{less params}
                                           exit;
                                           end;
               Shading:=pr[1]='ON';
               end{}


     else
         interpret:=1;{wrong command}

     {end;{case}
end;

end.