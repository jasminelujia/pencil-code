; $Id: rzaver.pro,v 1.3 2002-10-02 20:11:14 dobler Exp $
;
;  reads the zaver.dat file
;
t=0.
bmxy=fltarr(nx,ny*nprocy,nnamexy)
;
close,1
openr,1,datatopdir+'/zaverages.dat'
;
fo='(8e10.3)'
default,w,.1
while not eof(1) do begin
  readf,1,t
  readf,1,bmxy,fo=fo
  ;oplot,bymxy,li=1
  print,t,max(bmxy)
  wait,w
end
close,1
;
END
