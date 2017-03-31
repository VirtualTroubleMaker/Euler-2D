module FVM                                           !finite volume method 
    use Control_para
    use Grid_info
    implicit none   
    real(8)::u_inf,v_inf,a_inf                        !incoming flow's velocities and sound velocity
    real(8),allocatable::U(:,:) ,&                    !the oringinal variables of every cell
                         W(:,:)   , &                 !the conservative variables of every cell
                         W0(:,:)  ,Wn(:,:),Wn1(:,:), &                 !the zeroth step conservative variables
                         Rsi(:,:) , &                 !residual 
                         Fc(:,:)  , &                 !convective flux of every cell
                         alf(:)   , &                 !spectral radius of every edge
                         Dissi(:,:)  , D_last(:,:),&  !artificial dissipation of every cell
                         dt(:), &                    !time step of every cell
                         U_av(:,:)
     real(8)::t_total = 0.0
     real(8),allocatable::Q(:,:) 
     
contains

include "Mean_edge.f90"
include "Con_flux.f90"
include "Art_dissipation.f90"
include "Runge_Kutta.f90"

include "Output.f90"
include "outputFreeFlow.f90"
subroutine Allocate_memory    

    !allocate memory 
    allocate( U(5,ncells) ) 
    
    allocate( W(5,ncells) )
    allocate( Wn(5,ncells) )
    allocate( Wn1(5,ncells) )
    allocate( W0(5,ncells) )
    allocate( Rsi(5,ncells) )
    allocate( Fc(5,ncells) )
    allocate( alf(nedges) )
    allocate( Dissi(5,ncells) )
    allocate( D_last(5,ncells) )
    allocate( dt(ncells) )
    
    allocate( U_av(6,nedges) )
    allocate( Q(5,ncells) )
    
end subroutine

subroutine Flow_init      !initialize the flow field
    implicit none
   
    a_inf=sqrt(p_inf*gamma/rou_inf)
    u_inf=Ma_inf*a_inf*cos(att/180.0*pi)        
    v_inf=Ma_inf*a_inf*sin(att/180.0*pi)
   
    U(1,:)=rou_inf
    U(2,:)=u_inf
    U(3,:)=v_inf
    U(5,:)=p_inf
    
    W(1,:)=rou_inf
    W(2,:)=rou_inf*u_inf
    W(3,:)=rou_inf*v_inf
    W(5,:)=p_inf/(gamma-1) + rou_inf*(u_inf**2 + v_inf**2)/2.0   
    
end subroutine

subroutine Solver          !the Solver
    implicit none
    integer::i,j
    integer::iter          !iterative variable
    integer::count
    integer::flag          !the variable to judge wheathe the mean density converges          
    character(len = 30)::filename
    write(*,*)  "Solver"
    
    call outputFreeFlow
    call Grid
    call Allocate_memory
    call Flow_init
    
    Wn1 = W
    Wn = W
    
    do i=1,phase
        do iter = 1,itermax
            
            Wn1 = Wn
            Wn = W
            do j = 1,5
                Q(j,:) = 2.0/dt_r*vol*Wn(j,:) -1.0/2.0/dt_r*vol*Wn1(j,:)
            end do
            
            t_total = t_total + dt_r
           
            do count= 1,iter_inner
                write(*,*) "t:",t_total,"dt:",dt_r
                write(*,*)  iter,i
                call Runge_Kutta
            
                call Converge(flag) 
           
                !if(flag == 1)  then
                !    write(*,*)  "Inner iteration converge..."
                !    exit 
                !else
                !    write(*,*)  iter,"...Misconverge..."
                !end if  
                !
                !end if
            end do
        end do
        
        write(filename,"(I2)") i
            
        filename = "flow-info-" // trim(filename)
        call Output(filename) 
        write(*,*) "Output"        
    end do
    
end subroutine 

!subroutine Converge(flag)          !verify wheather the flow converge
!    implicit none
!    integer::i,j
!    integer::flag                  !flag, 1:converge;0:disconverge
!   
!    real(8)::Rsi_old = 0.0,Rsi_new
!    !write(*,*)  "Converge"
!
!    
!    Rsi_new = sum ( Rsi(1,:) )/ncells
!    
!    flag = 0 
!    
!    if(abs(Rsi_new) .LE. eps ) flag = 1
!    
!    write(*,*) abs(Rsi_new) 
!           
!    Rsi_old = Rsi_new
!    
!end subroutine

subroutine Converge(flag)          !verify wheather the flow converge
    implicit none
    integer::i,j
    integer::flag                  !flag, 1:converge;0:disconverge
    real(8)::rou_ncell=0.0    !the mean density of n+1 layer
    real(8)::u_ncell=0.0    !the mean density of n+1 layer
    real(8)::v_ncell=0.0    !the mean density of n+1 layer
    real(8)::p_ncell=0.0    !the mean density of n+1 layer
      
    real(8),save::rou_mean = 1.225  !the mean density of n layer
    real(8),save::u_mean = 0.0  !the mean density of n layer
    real(8),save::v_mean = 0.0  !the mean density of n laye
    real(8),save::p_mean = 103150.0  !the mean density of n layer


    !write(*,*)  "Converge"

    rou_ncell = sum(U(1,:))/ncells
    u_ncell = sum(U(2,:))/ncells
    v_ncell = sum(U(3,:))/ncells
    p_ncell = sum(U(5,:))/ncells
    
    flag = 0
    
    if (abs(rou_ncell-rou_mean) .LE. eps)   flag = 1
    
    write(*,*)  U(1,1),U(2,1),U(3,1),U(5,1)
    write(*,*)  abs(rou_ncell-rou_mean),abs(p_ncell-p_mean)
    write(*,*)  abs(u_ncell-u_mean),abs(v_ncell-v_mean)
    write(*,*)
       
    rou_mean = rou_ncell
    u_mean = u_ncell
    v_mean = v_ncell
    p_mean = p_ncell
    
end subroutine


end module
    