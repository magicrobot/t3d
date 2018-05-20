  unit trans_3d;
  (**)interface(**)

  {p3df- used by tiny_lib}
  type
  p3df=record
  x,y,z:real;
  end;

  Trans_Point3d=object
  public
  point3d:p3df;
  procedure Translate(p:p3df);
  procedure Scale(p:p3df);{get ratios sx,sy,sz.. in range 0..size-1 i.e translate by min later}
  procedure Rotate_x(Angle:real);
  procedure Rotate_y(Angle:real);
  procedure Rotate_z(Angle:real);
(*  procedure Rotate3d(p1,p2:p3df;angle:real);{rotate around 3d line} *)
  end;{object}

  (**)Implementation(**)
  procedure Trans_Point3d.Translate(p:p3df);
  begin
  point3d.x:=point3d.x+p.x;
  point3d.y:=point3d.y+p.y;
  point3d.z:=point3d.z+p.z;
  end;

  procedure Trans_Point3d.Scale(p:p3df);
  begin
  point3d.x:=point3d.x*p.x;
  point3d.y:=point3d.y*p.y;
  point3d.z:=point3d.z*p.z;
  end;

  procedure Trans_Point3d.Rotate_x(Angle:real);{rotate yz around x anti-clock}
  Var
  pt:p3df; c,s:real;
  begin
  pt:=point3d;
  c:=cos(Angle);s:=sin(Angle);
  {x doesn't change}
  point3d.y:=pt.y*c-pt.z*s;
  point3d.z:=pt.y*s+pt.z*c;
  end;

  procedure Trans_Point3d.Rotate_y(Angle:real);
  Var
  pt:p3df; c,s:real;
  begin
  pt:=point3d;
  c:=cos(Angle);s:=sin(Angle);
  point3d.z:=pt.z*c-pt.x*s;
  point3d.x:=pt.z*s+pt.x*c;
  end;

  procedure Trans_Point3d.Rotate_z(Angle:real);
  Var
  pt:p3df; c,s:real;
  begin
  pt:=point3d;
  c:=cos(Angle);s:=sin(Angle);
  point3d.x:=pt.x*c-pt.y*s;
  point3d.y:=pt.x*s+pt.y*c;
  end;

  (*  Incorrect...

  procedure Trans_Point3d.Rotate3d(p1,p2:p3df;angle:real);{To Do}
  var pt,pt2,pt3,rp,rp2,rp3,rp_res:p3df;
      d1,d2,s1,c1,s2,c2,s3,c3:real;

  begin{angle in radians}
  {translate p1-0, p2,point3d}
 s3:=sin(angle);c3:=cos(angle);{angle=-pi/2 to pi/2 radians or -2*pi..2*pi}
  {normalise angle..how?if >2*pi then divide angle by 2*pi & divide angle by result}
  pt.x:=p2.x-p1.x; {this could be done by declaring pt as transformable point}
  pt.y:=p2.x-p1.y; {would that cause recurse declaration error}
  pt.z:=p2.x-p1.z; {then use parameter passable simple procs}
  rp.x:=point3d.x-p1.x; {if some proc recurses only then variables produced in recursion}
  rp.y:=point3d.y-p1.y; {hence until recursion in proc using t.point is o.k}
  rp.z:=point3d.z-p1.z;{point to rotate}
  {later auto send inverse transforms to inverse transformations stack}
  {i.e each transform proc has unique id code or use its pointer,match param(for validity check) & send}

  {check if line already aligned to z axis.. then skip it}
  {i.e if pt has y=0(xz plane) or z=0(xy plane)}
  pt2:=pt;pt3:=pt;rp2:=rp;rp3:=rp;{if pt.y=0 then this may be handy}
  if ({(pt.x<>0)and}(pt.y<>0)) then{if in yz or xy plane }
     begin{align to z now}
     {align to plane(zx or yz), then rotate to z axis(around y or x)}
     d1:=sqrt(sqr(pt.y)+sqr(pt.z));
     {any value should be less than half or one third of sqrt of max val to avoid overflow from this formula}
     {length projected on yz plane-pythogras formula-rectangle by 4 same right triangles}
     s1:=pt.y/d1;{sine};c1:=pt.z/d1;{cosine} {line angle from yz plane on zx plane}
     {rotate around x- to get to zx plane}
     pt2.x:=pt.x;{already done}
     pt2.y:={pt.y*c1-pt.z*s1}0.0;{0.0- to speed up a little}
     pt2.z:={pt.y*s1+pt.z*c1}d1;
     rp2.x:=rp.x
     rp2.y:=rp.y*c1-rp.z*s1;
     rp2.z:=rp.y*s1+rp.z*c1;
     {rotate around y to align to z axis- now in zx plane}
     d2:=sqrt(sqr(d1)+sqr(pt2.x));{we know pt2.y=0(approx)}
     s2:=pt2.x/d2;c2:=pt2.z/d2;{could've only used pt.x,d1 instead of pt2.x,pt2.z}
     {c2=d1/d2,s2=pt.x/d2}
     pt3.y:=pt2.y;         {pt3 not needed-maybe}
     pt3.x:={pt2.x*c2-pt2.z*s2}0.0;
     pt3.z:={pt2.z*c2+pt2.x*s2}d2; {line aligned to z}
     rp3.y:=rp2.y;
     rp3.x:=rp2.x*c2-rp2.z*s2;
     rp3.z:=rp2.z*c2+rp2.x*s2;

     {now line is aligned to z, hence rotate point...}
     rp_res.x:=rp3.x*c3-rp3.y*s3;
     rp_res.y:=rp3.x*s3+rp3.y*c3;
             rp_res.z:=rp3.z
             rp3:=rp_res;
     {} {could do arctan first, then sin & cos.. but this is better(no division problem) }
     {then transform back- except rotate around z part}
     rp2.y:=rp3.y;
     rp2.x:=rp3.x*c2-rp3.z*(-s2);{uses cos(-a)=cos(a)}
     rp2.z:=rp3.z*c2+rp3.x*(-s2);{sin(-a)=-sin(a); a=angle from 0 angle ref}
     rp.y:=rp2.y*c1-rp.z*(-s1);
     rp.z:=rp2.y*(-s1)+rp2.z*c1;
     rp.x:=rp2.x;

     {}
     end else
     if (pt.x<>0) then{if in xy or zx plane} {verify this once}
     Begin           {align to y axis}
     d1:=sqrt(sqr(pt.x)+sqr(pt.y));
     s1:=pt.x/d1;{sine};c1:=pt.y/d1;{cosine} {line angle from yz plane on zx plane}
     {rotate around z- to get to yz plane}
     pt2.z:=pt.z;{already done}
     pt2.x:={pt.x*c1-pt.y*s1}0.0;{0.0- to speed up a little}
     pt2.y:={pt.x*s1+pt.y*c1}d1;
     rp2.z:=rp.z
     rp2.x:=rp.x*c1-rp.y*s1;
     rp2.y:=rp.x*s1+rp.y*c1;
     {rotate around x to align to y axis- now in yz plane}
     d2:=sqrt(sqr(d1)+sqr(pt2.z));{we know pt2.x=0(approx)}
     s2:=pt2.z/d2;c2:=pt2.y/d2;{could've only used pt.x,d1 instead of pt2.x,pt2.z}
     {c2=d1/d2,s2=pt.x/d2}
     pt3.x:=pt2.x;         {pt3 not needed-maybe}
     pt3.z:={pt2.x*c2-pt2.z*s2}0.0;
     pt3.y:={pt2.z*c2+pt2.x*s2}d2; {line aligned to z}
     rp3.x:=rp2.x;{chk}
     rp3.z:=rp2.x*c2-rp2.z*s2;
     rp3.y:=rp2.z*c2+rp2.x*s2;

     {now line is aligned to z, hence rotate point...}
     rp_res.x:=rp3.x*c3-rp3.y*s3;
     rp_res.y:=rp3.x*s3+rp3.y*c3;
             rp_res.z:=rp3.z
             rp3:=rp_res;
     {} {could do arctan first, then sin & cos.. but this is better(no division problem) }
     {then transform back- except rotate around z part}
     rp2.y:=rp3.y;
     rp2.x:=rp3.x*c2-rp3.z*(-s2);{uses cos(-a)=cos(a)}
     rp2.z:=rp3.z*c2+rp3.x*(-s2);{sin(-a)=-sin(a); a=angle from 0 angle ref}
     rp.y:=rp2.y*c1-rp.z*(-s1);
     rp.z:=rp2.y*(-s1)+rp2.z*c1;
     rp.x:=rp2.x;

     {}
     end else
     Begin
     {now line is aligned to z, hence rotate point...}
     {rp_res}rp3.x:=rp3.x*c3-rp3.y*s3;
     {rp_res}rp3.y:=rp3.x*s3+rp3.y*c3;
     rp:=rp3;
             {rp3.z:=rp3.z}
     end;{if aligned to z}

     {Translate back}
  point3d.x:=rp.x+p1.x;
  point3d.y:=rp.y+p1.y;
  point3d.z:=rp.z+p1.z;

  end;
 *)
  end.