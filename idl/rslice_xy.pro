; $Id: rslice_xy.pro,v 1.3 2002-10-02 20:11:14 dobler Exp $
;
;  reads xy slices
;  this routine is not very general yet and needs to be adjusted
;  before it can be general purpose.
;
file_slice=datatopdir+'/proc0/uz.xy'
file_slice=datatopdir+'/proc0/bx.xy'
file_slice=datatopdir+'/proc0/divu.xy'
file_slice=datatopdir+'/proc0/lnrho.xy'
file_slice=datatopdir+'/proc0/ux.xy'
;
t=0.
xy_slice=fltarr(nx,ny)
;
close,1
openr,1,file_slice,/f77
while not eof(1) do begin
  readu,1,xy_slice,t
  print,t,min(xy_slice),max(xy_slice)
  ;plot,xy_slice(11,*),yr=[-1,1]*1e-3
  ;tvscl,xy_slice
  tvscl,congrid(xy_slice,2*nx,2*ny)
  wait,.1
end
;
close,1
END
