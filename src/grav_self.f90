! $Id: grav_self.f90,v 1.26 2005-06-27 00:14:18 mee Exp $

!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! MVAR CONTRIBUTION 3
! MAUX CONTRIBUTION 0
!
! PENCILS PROVIDED gg,g2,curlgg,curlcurlgg,divgg,divgg2,ug
!
!***************************************************************

module Gravity

!  self-gravity (solves Poisson equation)

  use Cparam

  implicit none

  private

  include 'gravity.h'

  interface potential
    module procedure potential_global
    module procedure potential_penc
    module procedure potential_point
  endinterface

  real, dimension(nx) :: gravx_pencil=0.,gravy_pencil=0.,gravz_pencil=0.
  real :: nu_epicycle=1.
  real :: lnrho_bot,lnrho_top,ss_bot,ss_top
  real :: grav_const=1.,gravdiff=0.
  real :: g0=0.,r0_pot=0.
  integer :: n_pot=10

!  NOTE: the following quantities are needed for compatibility
!  with usage of quantities from grav_z in density.f90

  real :: z1,z2,zref,gravz=-1.,zinfty,zgrav=impossible
  real :: gg_quench=0.
  character (len=labellen) :: grav_profile='const'

!  The gravity potential must always be negative. However, in an plane
!  atmosphere with constant gravity, the potential goes to zero at
!  some position which is referred to as "zinfty".

  namelist /grav_init_pars/ &
    grav_const

!  It would be rather unusual to change the profile during the
!  run, but "adjusting" the profile slighly may be quite useful.

  namelist /grav_run_pars/ &
    grav_const,gravdiff,gg_quench

  ! other variables (needs to be consistent with reset list below)
  integer :: idiag_curlggrms=0,idiag_curlggmax=0,idiag_divggrms=0
  integer :: idiag_divggmax=0,idiag_epot=0,idiag_depot=0

  contains

!***********************************************************************
    subroutine register_gravity()
!
!  initialise gravity flags
!
! 22-apr-03/axel: coded
!
      use Cdata
      use Mpicomm
      use Sub
!
      logical, save :: first=.true.
!
      if(.not. first) call stop_it('register_grav called twice')
      first = .false.
!
      lselfgravity = .true.
!
      igg = nvar+1             ! indices to access gg
      igx = igg
      igy = igg+1
      igz = igg+2
      nvar = nvar+3            ! added 3 variables
!
      if ((ip<=8) .and. lroot) then
        print*, 'register_gravity:  nvar = ', nvar
        print*, 'register_gravity: igx,igy,igz = ', igx,igy,igz
      endif
!
!  identify version number (generated automatically by CVS)
!
      if (lroot) call cvs_id( &
           "$Id: grav_self.f90,v 1.26 2005-06-27 00:14:18 mee Exp $")
!
      lgrav = .true.
      lgravz = .false.
      lgravr = .false.
!
!  Writing files for use with IDL
!
      if (lroot) then
        if (maux == 0) then
          if (nvar < mvar) write(4,*) ',gg $'
          if (nvar == mvar) write(4,*) ',gg'
        else
          write(4,*) ',gg $'
        endif
        write(15,*) 'gg = fltarr(mx,my,mz,3)*one'
      endif
!
    endsubroutine register_gravity
!***********************************************************************
    subroutine initialize_gravity()
!
!  Set up some variables for gravity; do nothing in grav_z
!  16-jul-02/wolf: coded
!  22-nov-02/tony: renamed from setup_grav
!
    endsubroutine initialize_gravity
!***********************************************************************
    subroutine read_gravity_init_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
                                                                                                   
      if (present(iostat)) then
        read(unit,NML=grav_init_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=grav_init_pars,ERR=99)
      endif
                                                                                                   
                                                                                                   
99    return
    endsubroutine read_gravity_init_pars
!***********************************************************************
    subroutine write_gravity_init_pars(unit)
      integer, intent(in) :: unit
                                                                                                   
      write(unit,NML=grav_init_pars)
                                                                                                   
    endsubroutine write_gravity_init_pars
!***********************************************************************
    subroutine read_gravity_run_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
                                                                                                   
      if (present(iostat)) then
        read(unit,NML=grav_run_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=grav_run_pars,ERR=99)
      endif
                                                                                                   
                                                                                                   
99    return
    endsubroutine read_gravity_run_pars
!***********************************************************************
    subroutine write_gravity_run_pars(unit)
      integer, intent(in) :: unit
                                                                                                   
      write(unit,NML=grav_run_pars)
                                                                                                   
    endsubroutine write_gravity_run_pars
!
!***********************************************************************
    subroutine init_gg(f,xx,yy,zz)
!
!  initialise gravity; called from start.f90
!  9-jan-02/wolf: coded
!  24-nov-2002: renamed from init_grav to stay consistent
! 
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx,yy,zz
!
! Not doing anything (this might change if we decide to store gg)
!
      if(NO_WARN) print*,f,xx,yy,zz !(keep compiler quiet)
    endsubroutine init_gg
!***********************************************************************
    subroutine pencil_criteria_gravity()
! 
!  All pencils that the Gravity module depends on are specified here.
! 
!  21-11-04/anders: coded
!
      lpenc_requested(i_uu)=.true.
      lpenc_requested(i_rho)=.true.
      if (gravdiff/=0.) lpenc_requested(i_curlcurlgg)=.true.
      if (gg_quench/=0.) lpenc_requested(i_g2)=.true.
!
      if (idiag_curlggrms/=0 .or. idiag_curlggmax/=0) &
          lpenc_requested(i_curlgg2)=.true.
      if (idiag_divggrms/=0 .or. idiag_divggmax/=0) &
          lpenc_requested(i_divgg2)=.true.
      if (idiag_depot/=0) lpenc_requested(i_g2)=.true.
      if (idiag_depot/=0) lpenc_requested(i_ug)=.true.
!
    endsubroutine pencil_criteria_gravity
!***********************************************************************
    subroutine pencil_interdep_gravity(lpencil_in)
!
!  Interdependency among pencils from the Gravity module is specified here.
!
!  21-11-04/anders: coded
! 
      logical, dimension(npencils) :: lpencil_in
! 
      if (lpencil_in(i_g2)) lpencil_in(i_gg)=.true.
      if (lpencil_in(i_curlgg2)) lpencil_in(i_curlgg)=.true.
      if (lpencil_in(i_divgg2)) lpencil_in(i_divgg)=.true.
      if (lpencil_in(i_ug)) then
        lpencil_in(i_uu)=.true.
        lpencil_in(i_gg)=.true.
      endif
! 
    endsubroutine pencil_interdep_gravity
!***********************************************************************
    subroutine calc_pencils_gravity(f,p)
!   
!  Calculate Gravity pencils.
!  Most basic pencils should come first, as others may depend on them.
! 
!  21-11-04/anders: coded
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      type (pencil_case) :: p
!      
      intent(in) :: f
      intent(inout) :: p
! 
      if (lpencil(i_gg)) p%gg=f(l1:l2,m,n,igx:igz)
      if (lpencil(i_g2)) call dot2_mn(p%gg,p%g2)
      if (lpencil(i_curlgg)) call curl(f,igg,p%curlgg)
      if (lpencil(i_curlcurlgg)) call del2v_etc(f,igg,curlcurl=p%curlcurlgg)
      if (lpencil(i_curlgg2)) call dot2_mn(p%curlgg,p%curlgg2)
      if (lpencil(i_divgg)) call div(f,igg,p%divgg)
      if (lpencil(i_divgg2)) p%divgg2=p%divgg**2
      if (lpencil(i_ug)) call dot_mn(p%uu,p%gg,p%ug)
!
    endsubroutine calc_pencils_gravity
!***********************************************************************
    subroutine duu_dt_grav(f,df)
!
!  advance pseudo selfgravity and add to duu/dt
!
! 22-apr-03/axel: coded
!
      use Cdata
      use Sub
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
!      
      integer :: j
!
      intent(in) :: f
      intent(out) :: df
!
!  different gravity profiles
!
      if (headtt) print*,'duu_dt_grav: SOLVE'
!
!  advance gravity, dg/dt = 4pi*G*rho*uu
!  Note that 4pi*G = "grav_const"
!
      do j=0,2
        df(l1:l2,m,n,igg+j)=df(l1:l2,m,n,igg+j)+grav_const*p%rho*p%uu(:,1+j)
      enddo
!
!  diffuse non-potential contribution to gravity to zero
!
      if (gravdiff/=0.) then
        df(l1:l2,m,n,igx:igz)=df(l1:l2,m,n,igx:igz)-gravdiff*p%curlcurlgg
      endif
!
!  quenching factor
!
      if (gg_quench/=0.) then
        quench(:,1)=1./(1.+p%g2/gg_quench)
        quench(:,2)=quench(:,1)
        quench(:,3)=quench(:,1)
      else
        quench=1.
      endif
!
!  add gravitational acceleration to momentum equation
!
      df(l1:l2,m,n,iux:iuz)=df(l1:l2,m,n,iux:iuz)+quench*f(l1:l2,m,n,igx:igz)
!
!  diagnostics
!
      if (ldiagnos) then
!
!  check the degree of non-potential contamination
!
        if (idiag_curlggrms/=0) &
            call sum_mn_name(p%curlgg2,idiag_curlggrms,lsqrt=.true.)
        if (idiag_curlggmax/=0) &
            call max_mn_name(p%curlgg2,idiag_curlggmax,lsqrt=.true.)
!
!  for comparison, we also need divgg
!
        if (idiag_divggrms/=0) &
              call sum_mn_name(p%divgg2,idiag_divggrms,lsqrt=.true.)
        if (idiag_divggmax/=0) &
              call max_mn_name(p%divgg2,idiag_divggmax,lsqrt=.true.)
!
!  gravitational energy
!
        if (idiag_depot/=0) call sum_mn_name(-.5*p%g2/grav_const,idiag_epot)
!
!  change in gravitational energy
!
        if (idiag_depot/=0) call sum_mn_name(p%rho*p%ug,idiag_depot)
!
      endif
!
   endsubroutine duu_dt_grav
!***********************************************************************
    subroutine potential_global(xx,yy,zz,pot,pot0)
!
!  gravity potential
!  16-jul-02/wolf: coded
!
      use Cdata, only: mx,my,mz
      use Mpicomm
!
      real, dimension (mx,my,mz) :: xx,yy,zz, pot
      real, optional :: pot0
!
      call stop_it("potential_globali: not implemented for grav_self")
!
      if(NO_WARN) print*,xx(1,1,1)+yy(1,1,1)+zz(1,1,1), &
           pot(1,1,1),pot0  !(keep compiler quiet)
!
    endsubroutine potential_global
!***********************************************************************
    subroutine potential_penc(xmn,ymn,zmn,pot,pot0,grav,rmn)
!
!  calculates gravity potential and gravitational acceleration
!  on a pencil.
!
!  21-jan-02/wolf: coded
!   8-jul-02/axel: activated and used for initial conditions
!
      use Cdata
      use Sub
!
      real, dimension (nx) :: pot
      real, optional :: ymn,zmn,pot0
      real, optional, dimension (nx) :: xmn,rmn
      real, optional, dimension (nx,3) :: grav
!
      intent(in) :: xmn,ymn,zmn,rmn
      intent(out) :: pot,grav
!
!  identifier
!
      if (headt) print*,'potential_penc: ENTER'
!
!  different profiles, calculate also gz=-dpot/dz
!  remember, gravz=-1 (at least negative) for z pointing upwards.
!
      pot=0.  !(not implemented)
      if (present(pot0)) pot0=0.  !(not implemented)
      if (present(grav)) then
        grav=0.  !(not implemented)
        !grav=f(l1:l2,m,n,igx:igz)
      endif
!
      if(NO_WARN) print*,xmn,ymn,zmn,rmn !(keep compiler quiet)
    endsubroutine potential_penc
!***********************************************************************
    subroutine potential_point(x,y,z,r, pot,pot0, grav)
!
!  Gravity potential in one point
!
!  20-dec-03/wolf: coded
!
      use Mpicomm, only: stop_it
!
      real :: pot,rad
      real, optional :: x,y,z,r
      real, optional :: pot0,grav
!
      call stop_it("grav_self: potential_point not implemented")
!
      if(NO_WARN) print*,x,y,z,r,pot,pot0,grav     !(to keep compiler quiet)
    endsubroutine potential_point
!!***********************************************************************
!    subroutine self_gravity(f)
!!
!!  calculates gravity potential and gravitational acceleration.
!!  Routine is called prior to explicit time-advance via Runge-Kutta .
!!
!!   1-jan-03/axel: coded
!!
!      use Cdata
!      use Sub
!!
!      real, dimension (mx,my,mz,mvar+maux) :: f
!      real, dimension (mx,my,mz) :: resid
!      real :: fac,diag,om_diag,om=0.9
!      integer :: iter
!!
!!  identifier
!!
!      if(lroot.and.headt) print*,'self_gravity'
!!
!      fac=1./dx**2
!      diag=-2.*fac
!      om_diag=om/diag
!!  
!!  SOR iterations
!!
!      do iter=1,iterations_selfgrav
!        !
!        !  x-direction
!        !
!        resid(2:mx-1,:,:)=fac*(phi(1:mx-2,:,:)-2*phi(2:mx-1,:,:)+phi(3:mx,:,:))
!        resid(1     ,:,:)=fac*(phi(  mx  ,:,:)-2*phi(1     ,:,:)+phi(2   ,:,:))
!        resid(  mx  ,:,:)=fac*(phi(  mx-1,:,:)-2*phi(  mx  ,:,:)+phi(1   ,:,:))
!        !
!        resid=resid-grav*(exp(f(:,:,:,ilnrho))-1.)
!        phi=phi-om_diag*resid
!        phi=phi-sum(phi(l1:l2,m1:m2,n1:n2))/nw
!        !
!        if(ldebug_selfgrav) then
!          print*,iter,phi(l1,m1,n1)
!        endif 
!      enddo
!!
!!  debug output
!!   
!      if(ldebug_selfgrav) write(99) iter,phi
!!
!    endsubroutine self_gravity
!***********************************************************************
    subroutine rprint_gravity(lreset,lwrite)
!
!  reads and registers print parameters relevant for gravity advance
!
!  26-apr-03/axel: coded
!
      use Cdata
      use Sub
!
      integer :: iname
      logical :: lreset,lwr
      logical, optional :: lwrite
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
!
!  reset everything in case of RELOAD
!  (this needs to be consistent with what is defined above!)
!
      if (lreset) then
        idiag_curlggrms=0; idiag_curlggmax=0; idiag_divggrms=0; idiag_divggmax=0
        idiag_epot=0; idiag_depot=0
      endif
!
!  check for those quantities that we want to evaluate online
!
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),&
            'curlggrms',idiag_curlggrms)
        call parse_name(iname,cname(iname),cform(iname),&
            'curlggmax',idiag_curlggmax)
        call parse_name(iname,cname(iname),cform(iname),&
            'divggrms',idiag_divggrms)
        call parse_name(iname,cname(iname),cform(iname),&
            'divggmax',idiag_divggmax)
        call parse_name(iname,cname(iname),cform(iname),'depot',idiag_depot)
        call parse_name(iname,cname(iname),cform(iname),'epot',idiag_epot)
      enddo
!
!  write column, idiag_XYZ, where our variable XYZ is stored
!
      if (lwr) then
        write(3,*) 'i_curlggrms=',idiag_curlggrms
        write(3,*) 'i_curlggmax=',idiag_curlggmax
        write(3,*) 'i_divggrms=',idiag_divggrms
        write(3,*) 'i_divggmax=',idiag_divggmax
        write(3,*) 'i_depot=',idiag_depot
        write(3,*) 'i_epot=',idiag_epot
        write(3,*) 'igg=',igg
        write(3,*) 'igx=',igx
        write(3,*) 'igy=',igy
        write(3,*) 'igz=',igz
      endif
!
    endsubroutine rprint_gravity
!***********************************************************************

endmodule Gravity
