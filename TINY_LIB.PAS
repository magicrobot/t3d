  Unit Tiny_Lib;{Tiny3d}

  (* ***********************Interface************************************ *)
  Interface

  Uses Graf256,trans_3d;

  const tiny_min=-99{80};tiny_max=99{80};
  area=(tiny_max-tiny_min+1)*(tiny_max-tiny_min+1){*{2{};{*2 -ints}

  Type

  p3d=record
  x,y,z:integer;{for out of range.. min max -- clip}
  end;
  {
  p3df=record
  x,y,z:real;
  end;
  }
  z_array_ptr=^z_array;
  z_array=array[tiny_min..tiny_max,tiny_min..tiny_max] of {integer}shortint;

  (* Object Z_Draw *)
  z_draw = object

  private

  z_buff:z_array_ptr;
  distfactor:byte;
  scr_rel_X,scr_rel_Y:Word;

  min_r{range min val},max_r{range max val},ratios{rats}:p3df;
  {}
  num_shades_to_use:byte; min_shade_dist,max_shade_dist:integer;{so sqrt not used }
  shades_per_dist:real{integer}; {use longint for dist calc}
  {}
  public

  draw_color:word;
  shade_light_ref:p3d;{posision ref for shading with distance }
  PerspectiveView,texturing,shading,OverWriting:Boolean;
  {}
  {pallete, modulo 256 access}
  eyedist:integer;{0..256}
  {alignement variables}
  DrawCubeAngles:P3df;
  LogiCubeAngles:p3df;
  PTranslate:p3df;{after draw rotations..translate in logiccube, apply view}
  {}

  {physical 3d screen plot procs}

  constructor init;{currently assume 0,0}
  destructor  done;
  procedure set_relative(rel_x,rel_y:Word);
  procedure fillbuffer(c:byte{integer});
  procedure clear_depth_buffer;
  procedure pers_point(pin:p3d;var pout:p3d);{perspective view}
  function shade_num(xx,yy,zz:integer):byte;{+to use in z_point only}
  procedure z_point(x,y,z:integer{shortint});
  procedure z_line_fast(p1,p2:p3d);{for screen fixed 3d box}
  procedure filled_z_tri(p1,p2,p3:p3d);
  procedure SetPerspective(eye_d:integer);
  procedure Set_Dist_Factor(b:byte);
  function NumShadesToUse:byte;{light ref pos is public}
  procedure SetNumShadesToUse(n:byte);{light ref pos is public}
  procedure SetShadedistRange(m1,m2:integer);{use longint if range error occurs}
  {}
  procedure SetRange(minr,maxr:p3df);{later adjust min,max too}

  procedure Scaled_Point(pin:p3df;var pout:p3d);{plot min max= min/sqrt(2),max/sqrt(2)}
  procedure scaled_z_point(p:p3df);
  procedure scaled_z_line(p1,p2:p3df);
  procedure scaled_z_tri(p1,p2,p3:p3df);

  {aligned 3d screen draw procs}
  procedure al_point(pin:p3df;var pout:p3df);
  procedure aligned_z_point(p:p3df);
  procedure aligned_z_line(p1,p2:p3df);
  procedure aligned_z_tri(p1,p2,p3:p3df);

  end;{z-buffer object}

  (* ************************************************************** *)

  (* *****************Implementation******************************* *)
  Implementation

  constructor z_draw.init;
  begin
  getmem(z_buff,area);{runtime error if not enough free mem in heap}
  draw_color:=0;
  scr_rel_x:=0;scr_rel_y:=0;
  OverWriting:=false;
  Shading:=false;
  PerspectiveView:=false;
  distfactor:=10;{more= less attenuation with distance}
  {}   {scalings}
  min_r.x:=tiny_min;min_r.y:=tiny_min;min_r.z:=tiny_min;
  max_r.x:=tiny_max;max_r.y:=tiny_max;max_r.z:=tiny_max;
  ratios.x:=1.0{(max-min)/(max_r.x-min_r.x)};
  ratios.y:=1.0{(max-min)/(max_r.y-min_r.y)};
  ratios.z:=1.0{(max-min)/(max_r.z-min_r.z)};

  {}  {alignment}
  DrawCubeAngles.x:=0;
  DrawCubeAngles.y:=0;
  DrawCubeAngles.z:=0;

  LogiCubeAngles.x:=0;
  LogiCubeAngles.y:=0;
  LogiCubeAngles.z:=0;

  PTranslate.x:=0;
  PTranslate.y:=0;
  PTranslate.z:=0;
  {}
  eyedist:=1;
  {}     {shading}
  num_shades_to_use:=240;{>0,<=240.. first 16 reserved}
  min_shade_dist:=0;{>=0}
  max_shade_dist:=tiny_max-tiny_min;{>0}
  shades_per_dist:=(num_shades_to_use/(max_shade_dist-min_shade_dist));
  {}
  end;           {memalloc= nil return & no run time error for same}

  destructor  z_draw.done;
  begin
  freemem(z_buff,area);
  end;

  procedure z_draw.set_relative(rel_x,rel_y:Word);
  begin
  if (rel_x>(319-(tiny_max-tiny_min+1))) then rel_x:=0;
  if (rel_y>(199-(tiny_max-tiny_min+1))) then rel_y:=0;
  scr_rel_x:=rel_x;scr_rel_y:=rel_y;
  end;

  procedure z_draw.FillBuffer(c:byte{integer});
  var i,l:integer;
  begin
  fillchar(z_buff^[tiny_min,tiny_min],area,c)
  {
  for i:=min to max do
  for l:=min to max do
  z_buff^[i,l]:=c;
  }
  end;

  procedure z_draw.clear_depth_buffer;
  begin
  fillbuffer($80{-32768});{-128..$80,$8000-int }
  end;
  (*
  procedure zdraw.pers_point(pin:p3d;var pout:p3d);
  begin {do calc with reals if accuracy prob}
  {clip, don't store out of range points}
  if (pin.z>max)then begin pout:=pin;exit;{could cause div by zero err}end;
  pout.x:=round(int((eyedist*pin.x))/int((eyedist+(max-pin.z))));
  pout.y:=round(int((eyedist*pin.y))/int((eyedist+(max-pin.z))));
  pout.z:=pin.z;{should be 0 as by matrice view- but not in shading}
  end;
  *)
  procedure z_draw.pers_point(pin:p3d;var pout:p3d);
  begin {do calc with reals if accuracy prob}
  {clip, don't store out of range points}
  if (pin.z>tiny_max)then begin pout:=pin;exit;{could cause div by zero err}end;
  pout.x:=round((eyedist*pin.x)/(eyedist+(tiny_max-pin.z)/ distfactor));
  pout.y:=round((eyedist*pin.y)/(eyedist+(tiny_max-pin.z)/ distfactor));
  pout.z:=pin.z;{should be 0 as by matrice view- but not in shading}
  end;

  function z_draw.shade_num(xx,yy,zz:integer):byte;{+to use in z_point only}
  var dist:longint;
  begin
  shade_num:=0;
  with shade_light_ref do
  begin
  dist:=round(sqrt(sqr(x-xx)+sqr(y-yy)+sqr(z-zz)));
  end;{with}
  if ((dist<min_shade_dist)or(dist>max_shade_dist)) then exit;
  shade_num:=(round(shades_per_dist*(dist-min_shade_dist))mod 256);
  end;

  procedure z_draw.z_point(x,y,z:integer{shortint});
  var pp1,pp2:p3d;
  begin{will grow with perspective etc switches}
  if (PerspectiveView) then
     begin
     pp1.x:=x;pp1.y:=y;pp1.z:=z;
     pers_point(pp1,pp2);
     x:=pp2.x;y:=pp2.y;
     end;
  if ((x<tiny_min)or(x>tiny_max)or(y<tiny_min)or(y>tiny_max)or(z<tiny_min)or(z>tiny_max))then exit;
  {z should not exceed short range}
  if ((OverWriting=false)and(z<=z_buff^[x,y]))then exit;{else not needed since true=exit}
  if ((OverWriting=true)and(z<z_buff^[x,y]))then exit;
  if (shading) then
  vga256[scr_rel_y+tiny_max-y{y-min}][scr_rel_x+x-tiny_min]:=draw_color+shade_num(x,y,z)
  else
  vga256[scr_rel_y+tiny_max-y{y-min}][scr_rel_x+x-tiny_min]:=draw_color;{y dir change}
  z_buff^[x,y]:=z;
  end;{here relative co-ordinates can only be 0,0.. due to resolution}

  procedure z_draw.z_line_fast(p1,p2:p3d);{for screen fixed 3d box}
  {use current color to draw?palette color-shades set,.. then reserve a color}
  var
  y_unit, x_unit, z_unit,
  zx_ratio, zx_err, xy_err,
  zmx,i,
  xdiff, ydiff, zdiff :integer{shortint};
  P_status:Boolean;
  pp:p3d;
  begin
  {Bresenham method from book+mine mixed}

  {} {Perspective}
  p_status:=perspectiveView;
  if (P_status=true) then
  begin
  perspectiveView:=false;{so point etc don't use perspective}
  pp:=p1; pers_point(pp,p1);
  pp:=p2; pers_point(pp,p2);
  end;
  {}

  {}  {sort- valid for fast line only}
  xdiff:=p2.x-p1.x;
  ydiff:=p2.y-p1.y;
  {zdiff:=p2.z-p1.z;}

  if (abs(xdiff)>abs(ydiff)) then
     begin
     if (xdiff<0) then
        begin
        pp:=p1;p1:=p2;p2:=pp;{swap}
        end;
     end else
     begin
     if (ydiff<0) then
        begin
        pp:=p1;p1:=p2;p2:=pp;{swap}
        end;
     end;
  {}

  xdiff:=p2.x-p1.x;
  ydiff:=p2.y-p1.y;
  zdiff:=p2.z-p1.z;

  x_unit:=1;y_unit:=1;z_unit:=1;
  if (xdiff<0) then begin xdiff:=-xdiff; x_unit:=-1 end;
  if (ydiff<0) then begin ydiff:=-ydiff; y_unit:=-1 end;
  if (zdiff<0) then begin zdiff:=-zdiff; z_unit:=-1 end;
  {check for point or z-axis.. draw & exit}
  if ((xdiff=0)and(ydiff=0)) then
  begin
  {chk point or z axis & draw}
  {if (zdiff=0) then z_point() else}
  {since only closer z matters in points above each other}
  if (p2.z>p1.z) then z_point(p2.x,p2.y,p2.z) else z_point(p1.x,p1.y,p1.z);
  exit;{exit proc}
  end;{if point or z axis}
  {}
  xy_err:=0;
  zx_err:=0;

  if (xdiff>ydiff) then
     begin
     zx_ratio:=zdiff div xdiff;
     zmx:=zdiff mod xdiff;
     {}
     for i:=0 to xdiff do{1 to len1 do}
         begin
         z_point(p1.x,p1.y,p1.z);
         p1.x:=p1.x+x_unit;
         p1.z:=p1.z+z_unit*(zx_ratio);

         xy_err:=xy_err+ydiff;
         if (xy_err>=xdiff) then
            begin  {used to be >}
            xy_err:=xy_err-xdiff;
            p1.y:=p1.y+y_unit;
            end;

         zx_err:=zx_err+zmx;
         if (zx_err>=xdiff) then
            begin
            zx_err:=zx_err-xdiff;
            p1.z:=p1.z+z_unit;
            end;


         end;{for}
     end
     else{ydiff>xdiff}
     begin
     zx_ratio:=zdiff div ydiff;
     zmx:=zdiff mod ydiff;
     for i:=0 to ydiff do
         begin
         z_point(p1.x,p1.y,p1.z);
         p1.y:=p1.y+y_unit;
         p1.z:=p1.z+z_unit*(zx_ratio);

         xy_err:=xy_err+xdiff;
         if (xy_err>=ydiff) then
            begin
            xy_err:=xy_err-ydiff;
            p1.x:=p1.x+x_unit;
            end;
         {now we don't have to deal with seperate z-x line algo}
         zx_err:=zx_err+zmx;
         if (zx_err>=ydiff) then
            begin
            zx_err:=zx_err-ydiff;
            p1.z:=p1.z+z_unit;
            end;

            {works on assumption of opaque points only.. }

         end;{for}
     end;
     {}
     {last step- restore perspective} PerspectiveView:=p_status;
     {}

  {before calling z_point...for speedup use pre calc of relative shift for
  screen
  & perspective(if on) for x,y ends.. then turn (save pre state)these off ,
   plot,restore state(if say perspective was on) }
  end;{proc z_line}


  procedure z_draw.filled_z_tri(p1,p2,p3:p3d);{check valid tri or line or point}
{uses z_line_fast.. which is not fast in otherwise that if long z used then neglects it}
   procedure fillbw(orig,vv1,vv2:p3d;di:shortint;{}var neo,vr1,vr2:p3d{});
   var
   currp1,currp2, p1diff,p2diff,p1u,p2u:p3d;
   maxdiff1,maxdiff2,
   errx1,erry1,errz1,
   errx2,erry2,errz2,
   c1,c2,
   i,done1,done2:{shortint}integer;
   begin
   currp1:=orig;
   currp2:=orig;
   p1u.x:=1;p1u.y:=1;p1u.z:=1;   p2u.x:=1;p2u.y:=1;p2u.z:=1;
   p1diff.x:=vv1.x-orig.x;p1diff.y:=vv1.y-orig.y;p1diff.z:=vv1.z-orig.z;
   p2diff.x:=vv2.x-orig.x;p2diff.y:=vv2.y-orig.y;p2diff.z:=vv2.z-orig.z;
   if (p1diff.x<0)then begin p1diff.x:=-p1diff.x;p1u.x:=-1;end;
   if (p1diff.y<0)then begin p1diff.y:=-p1diff.y;p1u.y:=-1;end;
   if (p1diff.z<0)then begin p1diff.z:=-p1diff.z;p1u.z:=-1;end;
   if (p2diff.x<0)then begin p2diff.x:=-p2diff.x;p2u.x:=-1;end;
   if (p2diff.y<0)then begin p2diff.y:=-p2diff.y;p2u.y:=-1;end;
   if (p2diff.z<0)then begin p2diff.z:=-p2diff.z;p2u.z:=-1;end;
   errx1:=0;errx2:=0;erry1:=0;erry2:=0;errz1:=0;errz2:=0;

   maxdiff1:=p1diff.x;
   if (maxdiff1<p1diff.y) then maxdiff1:=p1diff.y;
   if (maxdiff1<p1diff.z) then maxdiff1:=p1diff.z;
   maxdiff2:=p2diff.x;
   if (maxdiff2<p2diff.y) then maxdiff2:=p2diff.y;
   if (maxdiff2<p2diff.z) then maxdiff2:=p2diff.z;
   done1:=1;done2:=1;c1:=0;c2:=0;

   repeat  {while with extra z_line at end}

   {z_line(currp1,currp2);
   -produces more jagged lines but are better approximates
   than using z_line in done1,done2=1 check... use this if trouble approx}

   {will slow a little but all overdraws happen-won't miss approximations}
   if((done1=1)and(done2=1)) then
   begin z_line_fast(currp1,currp2);{x-no}done1:=0;done2:=0;end;
                     {z_line fast couldn't handle triangle draw??why???}
   if (done1=0)then
   begin

   errx1:=errx1+p1diff.x; erry1:=erry1+p1diff.y; errz1:=errz1+p1diff.z;

   c1:=c1+1;{counter 1}

   if (errx1>=maxdiff1)then
   begin
   errx1:=errx1-maxdiff1;
   currp1.x:=currp1.x+p1u.x;
   if (di=0) then done1:=1;
   end;

   if (erry1>=maxdiff1)then
   begin
   erry1:=erry1-maxdiff1;
   currp1.y:=currp1.y+p1u.y;
   if (di=1) then done1:=1;
   end;

   if (errz1>=maxdiff1)then
   begin
   errz1:=errz1-maxdiff1;
   currp1.z:=currp1.z+p1u.z;
   end;

   end;{if done1=0}

   if (done2=0)then
   begin
   c2:=c2+1;
   errx2:=errx2+p2diff.x; erry2:=erry2+p2diff.y; errz2:=errz2+p2diff.z;
   if (errx2>=maxdiff2)then
   begin
   errx2:=errx2-maxdiff2;
   currp2.x:=currp2.x+p2u.x;
   if (di=0) then done2:=1;
   end;

   if (erry2>=maxdiff2)then
   begin
   erry2:=erry2-maxdiff2;
   currp2.y:=currp2.y+p2u.y;
   if (di=1) then done2:=1;
   end;

   if (errz2>=maxdiff2)then
   begin
   errz2:=errz2-maxdiff2;
   currp2.z:=currp2.z+p2u.z;
   end;

   end;{if done2=0}

   until((c1=maxdiff1+1)or(c2=maxdiff2+1));
   {some vertex reached}{counter=maxdiff1+1 or maxdiff2+1,1..}
   if ((c1=maxdiff1+1)and(c2<>maxdiff2+1)) then
      begin
      neo:=vv2; {hope this is ok}
      vr1:=vv1;{currp1;-was causing distortion}
      vr2:={currp2;-caused distortion}orig;
      end else
      begin
      neo:=vv1;
      vr1:={currp1;}vv2;
      vr2:={currp2;}orig;
      end;

   end;{proc fillbw}

  var
  xdiff12,xdiff23,xdiff31,
  ydiff12,ydiff23,ydiff31,
  {zdiff12,zdiff23,zdiff31,}
  dim_t,
  i : {shortint}integer;

  pmax,pmin,
  no,nv1,nv2,
  origin,v1,v2:p3d;
  P_status:Boolean;
  pp:p3d;
  begin {tri- sum of 2 sides> size of 3rd size}

  {if point condition tested then if valid tri or
  line check by sum of sides can be done,.. though haven't done it yet}
  {roots need not be taken for length checks- use long int...}

  {} {Perspective}
  p_status:=perspectiveView;
  if (P_status=true) then
  begin
  perspectiveView:=false;{so point etc don't use perspective}
  pp:=p1; pers_point(pp,p1);
  pp:=p2; pers_point(pp,p2);
  pp:=p3; pers_point(pp,p3);
  end;
  {}


  xdiff12:=p2.x-p1.x;
  ydiff12:=p2.y-p1.y;
  {zdiff12:=p2.z-p1.z;}

  xdiff23:=p3.x-p2.x;
  ydiff23:=p3.y-p2.y;
  {zdiff23:=p3.z-p2.z;}
                     {zdiffs needed?}
  xdiff31:=p1.x-p3.x;
  ydiff31:=p1.y-p3.y;
  {zdiff31:=p1.z-p3.z;}
  {horiz line is faster than vertical as by screen array & banking}
  if ((xdiff12=0)and(xdiff23=0)) then
     begin
     if
       ((ydiff12=0)and(ydiff23=0)) then{point or z_axis_line}
       begin {fin max z and put it}
       {}
       pmax.z:=p1.z;{if z diffs zero too then true point}
       if (pmax.z<p2.z) then pmax:=p2;
       if (pmax.z<p3.z) then pmax:=p3;
       z_point(pmax.x,pmax.y,pmax.z);
       {point & zline look alike-except when shadow ing }
       {} {here for speed & compactness i avoid full z line plot}
       exit;
       end else{ydiffs these are non zero dims to plot for}
       begin
       dim_t:=1;{common draw algo}
       if (ydiff12<>0) then
         begin
          if (ydiff31<>0)then
          begin
          origin:=p1;v1:=p2;v2:=p3;
          end else
          begin
          origin:=p2;v1:=p1;v2:=p3;
          end;
         end else
          begin
          origin:=p3;v1:=p2;v2:=p1;
          end;
          {ydiff draw}

       end;{if ydiffs =0//else}
     end else{xdiffs- atleast one non zero...one}
     begin   {could test ydiffs here too for speedup by least span check}
     dim_t:=0;{- if common draw used}
       if (xdiff12<>0) then
         begin
          if (xdiff31<>0)then
          begin
          origin:=p1;v1:=p2;v2:=p3;
          end else
          begin
          origin:=p2;v1:=p1;v2:=p3;
          end;
         end else
          begin
          origin:=p3;v1:=p2;v2:=p1;
          end;
          {xdiff draw here}
     end;

     {if common draw-here}
     fillbw(origin,v1,v2,dim_t,no,nv1,nv2);

     if (dim_t=0)then
     begin
     if(v1.x<>v2.x) then fillbw(no,nv1,nv2,dim_t,origin,v1,v2);
     end else
     if(v1.y<>v2.y){((v1.y-v2.y)<>0)} then fillbw(no,nv1,nv2,dim_t,origin,v1,v2);

     {}perspectiveview:=p_status;{}
  end;{proc filled z tri}

  procedure z_draw.SetPerspective(eye_d:integer);{later centrex & center view y}
  begin
  if (eye_d>0)then eyedist:=eye_d;
  end;

  procedure z_draw.Set_Dist_Factor(b:byte);
  begin
  if(b>0)then distfactor:=b;
  end;

  function z_draw.NumShadesToUse:byte;{light ref pos is public}
  begin
  NumShadesToUse:=num_shades_to_use;
  end;

  procedure z_draw.SetNumShadesToUse(n:byte);{light ref pos is public}
  begin
  if ((n>0)and(n<241))then
     begin
     num_shades_to_use:=n;
     shades_per_dist:=num_shades_to_use/(max_shade_dist-min_shade_dist);
     end;{if}
  end;

  procedure z_draw.SetShadeDistRange(m1,m2:integer);{use longint if range error occurs}
  var m:integer;
  begin
  if (m1=m2) then exit;
  if (m2<m1)then begin m:=m1;m1:=m2;m2:=m;end;
  if ((m1>=0)and(m1<256)) then
     begin
     min_shade_dist:=m1;
     max_shade_dist:=m2;
     shades_per_dist:=num_shades_to_use/(max_shade_dist-min_shade_dist);
     end;
  end;

  procedure z_draw.SetRange(minr,maxr:p3df);{later adjust min,max too}
  Begin
  if ((minr.x=maxr.x)or(minr.y=maxr.y)or(minr.z=maxr.z))then exit;
  min_r:=minr;  max_r:=maxr;
  ratios.x:=(tiny_max-tiny_min)/(max_r.x-min_r.x);
  ratios.y:=(tiny_max-tiny_min)/(max_r.y-min_r.y);
  ratios.z:=(tiny_max-tiny_min)/(max_r.z-min_r.z);
  end;


  procedure z_draw.Scaled_Point(pin:p3df;var pout:p3d);{plot min max= min/sqrt(2),max/sqrt(2)}
  var l1,l2,l3:longint;
  function sgn(l:longint):integer;
  begin
  {l<>0}
  sgn:=0;
  if (l>0) then sgn:=1;
  if (l<0) then sgn:=-1;
  {sgn:=round(l/abs(l));}
  end;

  begin
  l1:=round((pin.x-min_r.x)*ratios.x)+tiny_min;{trunc,round}
  if (abs(l1)>32767) then l1:=sgn(l1)*1000{32767};
  l2:=round((pin.y-min_r.y)*ratios.y)+tiny_min;
  if (abs(l2)>32767) then l2:=sgn(l1)*1000{32767};
  l3:=round((pin.z-min_r.z)*ratios.z)+tiny_min;
  if (abs(l3)>32767) then l3:=sgn(l1)*1000{32767};
  pout.x:=l1 {mod 32768};
  pout.y:=l2 {mod 32768};
  pout.z:=l3 {mod 32768};
  end;

  procedure z_draw.scaled_z_point(p:p3df);
  var pp:p3d;
  begin
  scaled_point(p,pp);
  z_point(pp.x,pp.y,pp.z);
  end;

  procedure z_draw.scaled_z_line(p1,p2:p3df);
  Var pp1,pp2:p3d;
  begin
  scaled_point(p1,pp1);
  scaled_point(p2,pp2);
  z_line_fast(pp1,pp2);
  end;

  procedure z_draw.scaled_z_tri(p1,p2,p3:p3df);
  Var pp1,pp2,pp3:p3d;
  begin
  scaled_point(p1,pp1);
  scaled_point(p2,pp2);
  scaled_point(p3,pp3);
  filled_z_tri(pp1,pp2,pp3);
  end;

  procedure z_draw.al_point(pin:p3df;Var pout:p3df);
  var t:trans_point3d;
  begin
  t.point3d:=pin;
  {draw cube- rotate relative to logic Cube}
  t.rotate_x(DrawCubeAngles.x);
  t.rotate_y(DrawCubeAngles.y);
  t.rotate_z(DrawCubeAngles.z);
  {translate in logic cube}
  t.translate(PTranslate);
  {rotate logic cube relative to physical}
  t.rotate_x(LogiCubeAngles.x);
  t.rotate_y(LogiCubeAngles.y);
  t.rotate_z(LogiCubeAngles.z);
  pout:=t.point3d;
  end;

  procedure z_draw.aligned_z_point(p:p3df);
  var pp:p3df;
  Begin
  al_point(p,pp);
  scaled_z_point(pp);
  end;

  procedure z_draw.aligned_z_line(p1,p2:p3df);
  var pp1,pp2:p3df;
  Begin
  al_point(p1,pp1);
  al_point(p2,pp2);
  scaled_z_line(pp1,pp2);
  end;

  procedure z_draw.aligned_z_tri(p1,p2,p3:p3df);
  var pp1,pp2,pp3:p3df;
  Begin
  al_point(p1,pp1);
  al_point(p2,pp2);
  al_point(p3,pp3);
  scaled_z_tri(pp1,pp2,pp3);
  end;

  end.{perspective draw, shading left}