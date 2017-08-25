 module particle_injection

 public

 contains

 subroutine inject_particles ( plume, geo, advection, mass_trans, reaction, source, dt )
	   use reaction_class
	   use mass_trans_class
	   use plume_class
       use geometry_class
	   use source_vect_class
	   use advection_class
	   use timefunction_class
       use global_variables, only: DtStep,MinNumPart	   
       implicit none
       
	   type(plume_cl),        intent(inout) :: plume
       type(geometry_cl),     intent(in)    :: geo
	   type(advection_cl),    intent(in)    :: advection
       type(reaction_cl),     intent(in)    :: reaction
       type(mass_trans_cl),   intent(in)    :: mass_trans
       type(source_vect_cl),  intent(inout) :: source
       real*8,                intent(in)    :: dt
       integer                              :: isource,n,nt,i,np
       real*8                               :: time,Jm,ti,tf,freq,Jmt,Jmold,Mass,t1,t2
       real*8,  save, pointer               :: tinjold(:)
       integer, save, pointer               :: it(:),counter(:)
       real*8                               :: tinj
       real*8, save, pointer                :: MassNotInj(:)
       
!...initialize

         n = source%nsource

!...loop over injections
      
 source_loop: do isource=1,n	  
                               
          !....Dirac input (instantaneous injection)
          
          if (trim(adjustl(source%num(isource)%TypeInj)) == 'DIRAC') then
  
                 if (plume%time == source%num(isource)%TimeStartInj) then
                    call inject_particles_one_source ( plume, geo, advection, mass_trans, reaction, source, isource )
                 end if                       
                 cycle source_loop 
  
          end if              
          
          !...General input (time-varying injection)
          
          if (trim(adjustl(source%num(isource)%TypeInj)) == 'GENERAL') then              
  
                 if (plume%time < source%num(isource)%TimeStartInj .and. plume%time > source%num(isource)%TimeStopInj) cycle source_loop
                 call find_loc_TimeFunction_ (source%num(isource),plume%time)
                 Jm = evaluate_timefunction_upwind_ (source%num(isource)%timefunct,source%num(isource)%loc)
                 Mass = Jm * dt                               !total mass injected                      
                      if (Mass > 0.d0) then
                           np = max(1,int(Mass/source%num(isource)%pmassINI+0.5d0))         !calculate the number of particles to inject
                           source%num(isource)%np = np                                      !inject at least one particle           
                           source%num(isource)%pmass = Mass/dfloat(source%num(isource)%np)  !correct mass to match mass flux                      
                           call inject_particles_one_source ( plume, geo, advection, mass_trans, reaction, source, isource )
                      end if
                      !write(10004,'(F9.4, 2F9.2, 3F9.4, I9)') plume%time, Jm, Mass, source%num(isource)%pmass,source%num(isource)%TimeStartInj,source%num(isource)%TimeStopInj,it(isource)
                 cycle source_loop                
  
          end if
                 
       end do source_loop

 end subroutine


!***********************************************************************************
!      inject particles given one source type
!***********************************************************************************
  !subroutine inject_particles_one_source ( plume, geo, advection, reaction, source, kinj )
  subroutine inject_particles_one_source ( plume, geo, advection, mass_trans,reaction, source, kinj )
  	   use array_class
  	   use mass_trans_class
	   use reaction_class
	   use plume_class
       use geometry_class
	   use source_vect_class
	   use advection_class
	   use particle_class
	   use list_class
	   use gslib,            only: upper_case,open_fname_normal,inquire_number_lines,open_fname,locate
	   use constants,        only: pi
	   use global_variables, only: fdbg,npInj

	   implicit none   
	   
	   type(plume_cl),        intent(inout) :: plume
	   type(source_vect_cl),  intent(inout) :: source
       type(geometry_cl),     intent(in)    :: geo
	   type(advection_cl),    intent(in)    :: advection
       type(reaction_cl),     intent(in)    :: reaction
       type(mass_trans_cl),   intent(in)    :: mass_trans
	   type(particle_cl)                    :: particle
	   integer,               intent(in)    :: kinj

	   character(len=len(trim(adjustl(source%num(kinj)%name)))) :: fsour

	   integer                            :: cell(3)
	   integer                            :: i,j,k,npy,npz,jpz,jpy,jp,np,unit
       integer                            :: i2,i3,j2,j3,k2,k3,idwn,jdwn,kdwn,iup,jup,kup,zone,specie
	   real*8                             :: mp,rp,poro,kd,bd
	   real*8                             :: xp(3)
       real*8                             :: xinj,yinj,zinj,zbot,ztop,rcyr,rcp,xdist,width,height
	   real*8                             :: xinj_1,yinj_1,zinj_1,xinj_2,yinj_2,zinj_2
	   real*8                             :: xx0,yy0,zz0,rr0,zzk,rrk,tetak,ax,ay,az,dpy,dpz
	   real*8                             :: dline_x,dline_y,dline_z,d1_x,d1_y,d1_z
	   real*8                             :: xx1,yy1,zz1
   	   real*8                             :: dx,dy,dz
	   integer                            :: np11x,np11y,np11z,jp11x,jp11y,jp11z,npblock
       real                               :: ran
	   real*8, allocatable                :: lbdamin(:),qmod(:)
	   real*8                             :: totflux,xhalf(3),xint(3),x11(3),x22(3),cosdir(3),dd,lbda,lambda(6)
	   real*8                             :: x1,y1,z1,x2,y2,z2
	   integer                            :: iline,nline,ip1,jp1,kp1,ip2,jp2,kp2,imin,imax,jmin,jmax,kmin,kmax
	   integer                            :: nlinemax,icell,jcell,kcell,npsum,npline,jpline
	   real*8                             :: sumq,qx,qy,qz
	   real*8, allocatable                :: qm(:)
	   logical                            :: Intersection
	   integer                            :: nx,ny,nz,kk,jj
	   integer                            :: npi,npf,jpart
	   integer                            :: izone,ispecie
	   real*8                             :: rpt,Vol
	   integer                            :: id
	   real*8, pointer                    :: conc(:) => null()
       integer, allocatable               :: ix(:), iy(:), iz(:)

!       call random_seed(put=seed)      

       fsour = trim(adjustl(source % num (kinj) % name))

	   fsour = upper_case (fsour)

	   !call allocate_particle_ (particle,reaction,0,0)
	   call allocate_particle_ (particle,mass_trans,0,0)
!
!       =======================================
!       punctual source at the injection point
!       =======================================

      if ( trim(adjustl(fsour)) == 'POINT' ) then

        mp     = source % num (kinj) % pmass         
        np     = source % num (kinj) % np
		zone   = source % num (kinj) % zone
		specie = source % num (kinj) % specie 

		do jp=1,np       
             	     
		     xp(1) = source % num (kinj) % par % xinj
		     xp(2) = source % num (kinj) % par % yinj
		     xp(3) = source % num (kinj) % par % zinj

           if (reaction%action) then

             call assign_to_particle_               ( particle , xp , mp, zone, specie )  !assign position and mass to particle
             call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	         call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
             rpt = particle%prop%rp
             call generate_plumeparticle_ID_ (id)
             call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
           else
             call generate_plumeparticle_ID_ (id)
             call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
		   end if


		 end do
		 
!       ====================   ===========================
!       vertical line source : random uniform distribution
!       ====================   ===========================

      else if (trim(adjustl(fsour)) == 'LINE' ) then

	   zz0 = source % num (kinj) % par % zbot
	   zz1 = source % num (kinj) % par % ztop
        
       mp     = source % num (kinj) % pmass         
	   np     = source % num (kinj) % np
	   zone   = source % num (kinj) % zone
	   specie = source % num (kinj) % specie 


	   do jp=1,np

	         xp(1) = source % num (kinj) % par % xinj
	         xp(2) = source % num (kinj) % par % yinj
	         call random_number(ran); xp(3) = zz0 + (zz1-zz0) * ran

           if (reaction%action) then
             call assign_to_particle_               ( particle , xp , mp, zone, specie )  !assign position and mass to particle
             call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	         call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
             rpt = particle%prop%rp
             call generate_plumeparticle_ID_ (id)
             call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
           else
             call generate_plumeparticle_ID_ (id)
             call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
		   end if

	   end do

!       ============================================
!       circle source : random uniform distribution
!       ============================================

      else if (trim(adjustl(fsour)) == 'CIRCLE' ) then

	   xx0 = source % num (kinj) % par % xinj
	   yy0 = source % num (kinj) % par % yinj
	   zz0 = source % num (kinj) % par % zbot
	   zz1 = source % num (kinj) % par % ztop
	   rr0 = source % num (kinj) % par % rcyr
     
	   mp     = source % num (kinj) % pmass         
       np     = source % num (kinj) % np
	   zone   = source % num (kinj) % zone
	   specie = source % num (kinj) % specie 

	   do jp=1,np
	         
	      call random_number(ran); zzk   = ran * (zz1-zz0)
	      call random_number(ran); rrk   = ran * (rr0)
	      call random_number(ran); tetak = ran * (2.d0*pi)

	      xp(1) = xx0 + rrk * dcos(tetak)
	      xp(2) = yy0 + rrk * dsin(tetak)
	      xp(3) = zz0 + zzk

          if (reaction%action) then
             call assign_to_particle_               ( particle , xp , mp, zone, specie )  !assign position and mass to particle
             call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	         call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
             rpt = particle%prop%rp
             call generate_plumeparticle_ID_ (id)
             call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
          else
             call generate_plumeparticle_ID_ (id)
             call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
		  end if

	   end do

!       =======================================================================
!       radially distributed centered at the well : random uniform distribution
!       =======================================================================

      else if ( trim(adjustl(fsour)) == 'RADIAL' ) then

	   xx0 = source % num (kinj) % par % xinj
	   yy0 = source % num (kinj) % par % yinj
       zz0 = source % num (kinj) % par % zbot
	   zz1 = source % num (kinj) % par % ztop
	   rr0 = source % num (kinj) % par % rcp

       mp     = source % num (kinj) % pmass         
       np     = source % num (kinj) % np
	   zone   = source % num (kinj) % zone
	   specie = source % num (kinj) % specie  

	     do jp=1,np
	     	        
	        call random_number(ran); zzk   = ran * (zz1-zz0)
	        call random_number(ran); tetak = ran * (2.d0*pi)

	        xp(1) = xx0 + rr0 * dcos(tetak)
	        xp(2) = yy0 + rr0 * dsin(tetak)
	        xp(3) = zz0 + zzk
             
			 if (reaction%action) then
               call assign_to_particle_               ( particle , xp , mp, zone, specie )  !assign position and mass to particle
               call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	           call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
               rpt = particle%prop%rp
               call generate_plumeparticle_ID_ (id)
               call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
             else
               call generate_plumeparticle_ID_ (id)
               call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			 end if

         end do

!       ======================================
!       block source :    uniform distribution
!       ======================================
            
      else if ( trim(adjustl(fsour)) == 'BLOCK' ) then

	   i2 = source % num (kinj) % par % idwn
	   j2 = source % num (kinj) % par % jdwn
	   k2 = source % num (kinj) % par % kdwn
	   i3 = source % num (kinj) % par % iup
	   j3 = source % num (kinj) % par % jup
	   k3 = source % num (kinj) % par % kup

	   ax = get_xmesh_(geo,i3+1) - get_xmesh_(geo,i2)
	   ay = get_ymesh_(geo,j3+1) - get_ymesh_(geo,j2)
	   az = get_zmesh_(geo,k3+1) - get_zmesh_(geo,k2)

	   xx0 = get_xmesh_(geo,i2)
	   yy0 = get_ymesh_(geo,j2)
	   zz0 = get_zmesh_(geo,k2)

        mp     = source % num (kinj) % pmass         
        np     = source % num (kinj) % np
		zone   = source % num (kinj) % zone
		specie = source % num (kinj) % specie  
            
            do jp=1,np
                                    
              call random_number(ran); xp(1) = xx0 + ran * ax
              call random_number(ran); xp(2) = yy0 + ran * ay
              call random_number(ran); xp(3) = zz0 + ran * az

              if (reaction%action) then
                call assign_to_particle_             ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                call update_cell_location_particle_  ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	            call update_properties_particle_     ( particle, geo, advection, reaction   ) !update retardation
                rpt = particle%prop%rp
                call generate_plumeparticle_ID_ (id)
                call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
              else
                call generate_plumeparticle_ID_ (id)
                call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			  end if
			       
		  end do

!       ============================================
!       vertical plane : random uniform distribution
!       ============================================

	  else if ( trim(adjustl(fsour)) == 'PLANE_RANDOM' ) then

	     xx0 = source % num (kinj) % par % xdist
	     yy0 = 0.5d0*(get_ymesh_(geo,geo%ny+1) - source % num (kinj) % par % width)
	     zz0 = 0.5d0*(get_zmesh_(geo,geo%nz+1) - source % num (kinj) % par % height)
	     ay  = source % num (kinj) % par % width
	     az  = source % num (kinj) % par % height

        mp     = source % num (kinj) % pmass         
        np     = source % num (kinj) % np
		zone   = source % num (kinj) % zone
		specie = source % num (kinj) % specie 
		  
		    do jp=1,np
              xp(1) = xx0
              call random_number(ran); xp(2) = yy0 + ran * ay
              call random_number(ran); xp(3) = zz0 + ran * az
              
			  if (reaction%action) then
                call assign_to_particle_             ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                call update_cell_location_particle_  ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	            call update_properties_particle_     ( particle, geo, advection, reaction   ) !update retardation
                rpt = particle%prop%rp
                call generate_plumeparticle_ID_ (id)
                call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
              else
                call generate_plumeparticle_ID_ (id)
                call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			  end if
			  			    
	        end do


!       ===========================================
!       line source : uniform distribution (random)
!       ===========================================

      else if ( trim(adjustl(fsour)) == 'LINE_BY_POINTS_RANDOM' ) then
        
        
            mp     = source % num (kinj) % pmass         
            np     = source % num (kinj) % np
		    zone   = source % num (kinj) % zone
		    specie = source % num (kinj) % specie 

	        dline_x = dsqrt( (source % num (kinj) % par % xinj_1-source % num (kinj) % par % xinj_2)**2 ) 
			dline_y = dsqrt( (source % num (kinj) % par % yinj_1-source % num (kinj) % par % yinj_2)**2 )
			dline_z = dsqrt( (source % num (kinj) % par % zinj_1-source % num (kinj) % par % zinj_2)**2 )

		    do jp=1,np
		    
              call random_number(ran); xp(1) = source % num (kinj) % par % xinj_1 + ran * dline_x
              call random_number(ran); xp(2) = source % num (kinj) % par % yinj_1 + ran * dline_y
              call random_number(ran); xp(3) = source % num (kinj) % par % zinj_1 + ran * dline_z
             
             if (reaction%action) then
                call assign_to_particle_               ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	            call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
                rpt = particle%prop%rp
                call generate_plumeparticle_ID_ (id)
                call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
             else
                call generate_plumeparticle_ID_ (id)
                call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			 end if

	        end do

!       ===============================================================
!       vertical plane : equidistant uniform distribution (not random)
!       ===============================================================

      else if ( trim(adjustl(fsour)) == 'PLANE' ) then

         mp     = source % num (kinj) % pmass         
         np     = source % num (kinj) % np
		 zone   = source % num (kinj) % zone
		 specie = source % num (kinj) % specie 

	     xx0 = source % num (kinj) % par % xdist
		 
	     yy0 = 0.5d0*(get_ymesh_(geo,geo%ny+1) - source % num (kinj) % par % width)
	     zz0 = 0.5d0*(get_zmesh_(geo,geo%nz+1) - source % num (kinj) % par % height)
	     ay  = source % num (kinj) % par % width
	     az  = source % num (kinj) % par % height
		 
		 npy=int(sqrt(float(np)))
		 npz=npy

		 dpy=ay/dfloat(npy+1)
		 dpz=az/dfloat(npz+1)
		    
            jp=0

			loop_vert_plane: do jpz=1,npz
			                 do jpy=1,npy

                              xp(1) = xx0
                              xp(2) = yy0 + dfloat(jpy) * dpy 
                              xp(3) = zz0 + dfloat(jpz) * dpz
                          
						  if (reaction%action) then
                              call assign_to_particle_               ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                              call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	                          call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
                              rpt = particle%prop%rp
                              call generate_plumeparticle_ID_ (id)
                              call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
                          else
                              call generate_plumeparticle_ID_ (id)
                              call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			              end if

                              if ( jp >= np ) exit loop_vert_plane

	                          end do
                              end do loop_vert_plane

!       ===========================================================
!       line source : equidistant uniform distribution (not random)
!       ===========================================================
            
      else if ( trim(adjustl(fsour)) == 'LINE_BY_POINTS' ) then

            mp     = source % num (kinj) % pmass         
            np     = source % num (kinj) % np
		    zone   = source % num (kinj) % zone
		    specie = source % num (kinj) % specie  

            do jp=1,np
      
	        dline_x = dsqrt( (source % num (kinj) % par % xinj_1-source % num (kinj) % par % xinj_2)**2 ) 
			dline_y = dsqrt( (source % num (kinj) % par % yinj_1-source % num (kinj) % par % yinj_2)**2 )
			dline_z = dsqrt( (source % num (kinj) % par % zinj_1-source % num (kinj) % par % zinj_2)**2 )

	        d1_x = dline_x / dfloat(np+1)
			d1_y = dline_y / dfloat(np+1)
			d1_z = dline_z / dfloat(np+1)
	  
	        xp(1) = source % num (kinj) % par % xinj_1 + d1_x * (jp )  
            xp(2) = source % num (kinj) % par % yinj_1 + d1_y * (jp )
			xp(3) = source % num (kinj) % par % zinj_1 + d1_z * (jp )

             if (reaction%action) then
                call assign_to_particle_               ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	            call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
                rpt = particle%prop%rp
                call generate_plumeparticle_ID_ (id)
                call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
             else
                call generate_plumeparticle_ID_ (id)
                call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
		     end if

	        end do

!       ========================================
!       line source : FLUX-WEIGHTED distribution 
!       ========================================
            
      else if ( trim(adjustl(fsour)) == 'LINE_FLUX_WEIGHTED' ) then

        xinj_1 = source %num(kinj) %par % xinj_1
        xinj_2 = source %num(kinj) %par % xinj_2
        yinj_1 = source %num(kinj) %par % yinj_1
        yinj_2 = source %num(kinj) %par % yinj_2
        zinj_1 = source %num(kinj) %par % zinj_1
        zinj_2 = source %num(kinj) %par % zinj_2       
       
        !*************************************************************    
        ! the injection line is horizontal and parallel to y-direction
        !*************************************************************

        if (xinj_1 == xinj_2 .and.  zinj_1 == zinj_2) then

             mp     = source % num (kinj) % pmass         
             np     = source % num (kinj) % np
		     zone   = source % num (kinj) % zone
		     specie = source % num (kinj) % specie 

            ! find the end-point cells defining the line

             nx = length_array_ (geo%dx)
			 ny = length_array_ (geo%dy)
			 nz = length_array_ (geo%dz)

			 if (nx == 1) then
                dx = value_array_ (geo%dx)
				i2  = dint(xinj_1/dx) + 1
			 else
				call locate(geo%xmesh%values,nx+1,1,nx+1,xinj_1,i2)
             end if

			 if (ny == 1) then
                dy = value_array_ (geo%dy)
				j2  = dint(yinj_1/dy) + 1
                j3  = dint(yinj_2/dy) + 1
			 else
				call locate(geo%ymesh%values,ny+1,1,ny+1,yinj_1,j2)
				call locate(geo%ymesh%values,ny+1,1,ny+1,yinj_2,j3)
             end if

			 if (nz == 1) then
                dz = value_array_ (geo%dz)
				k2  = dint(zinj_1/dz) + 1
			 else
				call locate(geo%zmesh%values,nz+1,1,nz+1,zinj_1,k2)
             end if     

	         if (j3 < j2) then
	   	              jj = j2
	   	              j2 = j3
	                  j3 = jj
	         end if
  
             ! get velocities
       
             allocate(qm(j2:j3))
       
             do j=j2,j3
   
                  qx = 0.5d0*(advection%qx%values(i2,j,k2)+advection%qx%values(i2+1,j,k2))
                  qz = 0.5d0*(advection%qz%values(i2,j,k2)+advection%qz%values(i2,j,k2+1))
                  if (ny /= 1) dy = value_array_ (geo%dy,1,j,1)
                  qm(j) = dsqrt(qx*qx+qz*qz)*dy
       
             end do
         
             ! distribute particles block by block 
       
             xp(1) = 0.5d0 * (get_xmesh_(geo,i2+1) + get_xmesh_(geo,i2))
             xp(3) = 0.5d0 * (get_zmesh_(geo,k2+1) + get_zmesh_(geo,k2))

             npsum = 0
       
             do j=j2,j3

                 npblock = 0
 
                 if (sum(qm(j:j3)) > 0.d0) npblock = dint( (np-npsum) * qm(j) / sum(qm(j:j3)) + 0.5d0 )    
	             
                 if (ny /= 1) dy = value_array_ (geo%dy,1,j,1)         
                 
                 yy0 = get_ymesh_(geo,j) 
          
                 do jp=1,npblock
                      
                     xp(2) = yy0 + jp * dy / dfloat(npblock+1)
              
                     if (reaction%action) then
                         call assign_to_particle_             ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                         call update_cell_location_particle_  ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	                     call update_properties_particle_     ( particle, geo, advection, reaction   ) !update retardation
                         rpt = particle%prop%rp
                         call generate_plumeparticle_ID_ (id)
                         call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
                     else
                         call generate_plumeparticle_ID_ (id)
                         call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			         end if
			       
		         end do
          
                 npsum = npsum + npblock
          
             end do

             if (npsum /= np) stop 'number of particles injected not correct'

             deallocate(qm)
            
            
        !***********************************************************    
        ! the injection line is vertical and parallel to z-direction
        !***********************************************************            

        elseif (xinj_1 == xinj_2 .and. yinj_1 == yinj_2) then
            
             mp     = source % num (kinj) % pmass         
             np     = source % num (kinj) % np
		     zone   = source % num (kinj) % zone
		     specie = source % num (kinj) % specie 

            ! find the end point cells defining the line

             nx = length_array_ (geo%dx)
			 ny = length_array_ (geo%dy)
			 nz = length_array_ (geo%dz)

			 if (nx == 1) then
                dx = value_array_ (geo%dx)
				i2  = dint(xinj_1/dx) + 1
			 else
				call locate(geo%xmesh%values,nx+1,1,nx+1,xinj_1,i2)
             end if

			 if (ny == 1) then
                dy = value_array_ (geo%dy)
				j2  = dint(yinj_1/dy) + 1
			 else
				call locate(geo%ymesh%values,ny+1,1,ny+1,yinj_1,j2)
             end if

			 if (nz == 1) then
                dz = value_array_ (geo%dz)
				k2  = dint(zinj_1/dz) + 1
                k3  = dint(zinj_2/dz) + 1
			 else
				call locate(geo%zmesh%values,nz+1,1,nz+1,zinj_1,k2)
			    call locate(geo%zmesh%values,nz+1,1,nz+1,zinj_2,k3)
             end if     

	         if (k3 < k2) then
	   	              kk = k2
	   	              k2 = k3
	                  k3 = kk
	         end if
  
             ! get velocities
       
             allocate (qm(k2:k3))
       
             do k=k2,k3
   
                  qx = 0.5d0*(advection%qx%values(i2,j2,k)+advection%qx%values(i2+1,j2,k))
                  qy = 0.5d0*(advection%qy%values(i2,j2,k)+advection%qy%values(i2,j2+1,k))
                  if (nz /= 1) dz = value_array_ (geo%dz,1,1,k)
                  qm(k) = dsqrt(qx*qx+qy*qy)*dz
       
             end do
               
             ! distribute particles block by block 
       
             xp(1) = 0.5d0 * (get_xmesh_(geo,i2+1) + get_xmesh_(geo,i2))
             xp(2) = 0.5d0 * (get_ymesh_(geo,j2+1) + get_ymesh_(geo,j2))

             npsum = 0
       
             do k=k2,k3
          
                 npblock = 0
 
                 if (sum(qm(k:k3)) > 0.d0) npblock = dint( (np-npsum) * qm(k) / sum(qm(k:k3)) + 0.5d0 )    

                 if (nz /= 1) dz = value_array_ (geo%dz,1,1,k)        

                 zz0 = get_zmesh_(geo,k) 
          
                 do jp=1,npblock
                      
                     xp(3) = zz0 + jp * dz / dfloat(npblock+1)
                     
                     if (reaction%action) then
                         call assign_to_particle_             ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                         call update_cell_location_particle_  ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	                     call update_properties_particle_     ( particle, geo, advection, reaction   ) !update retardation
                         rpt = particle%prop%rp
                         call generate_plumeparticle_ID_ (id)
                         call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
                     else
                         call generate_plumeparticle_ID_ (id)
                         call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			         end if
			       
		         end do
                 
                 npsum = npsum + npblock
          
             end do

             if (npsum /= np) stop 'number of particles injected not correct'


             deallocate(qm)


        !*****************************************************
        ! the injection line is generic (not parallel to axis)
        !*****************************************************
        ! CAREFUL: TOO SLOW ALGORITHM
        !*****************************************************

        else
        
        stop 'Injection algorithm not available for arbitrary lines'
        
        nline  = 0

        mp     = source % num (kinj) % pmass         
        np     = source % num (kinj) % np
		zone   = source % num (kinj) % zone
		specie = source % num (kinj) % specie 
        
            ! calculate cosine of the directional vectors

			  x11(1) = source%num(kinj)%par%xinj_1
			  x11(2) = source%num(kinj)%par%yinj_1
			  x11(3) = source%num(kinj)%par%zinj_1

              call assign_to_particle_            ( particle , x11 , mp, zone, specie )  !assign position and mass to particle
              call update_cell_location_particle_ ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	          
			     ip1 = particle % cell % num(1)
	             jp1 = particle % cell % num(2)
                 kp1 = particle % cell % num(3)
			  
			  x22(1) = source%num(kinj)%par%xinj_2
			  x22(2) = source%num(kinj)%par%yinj_2
			  x22(3) = source%num(kinj)%par%zinj_2

              call assign_to_particle_            ( particle , x22 , mp, zone, specie )  !assign position and mass to particle
              call update_cell_location_particle_ ( particle, geo )       !update cell location and local coordinates, save switchcell flag
     
	             ip2 = particle % cell % num(1)
	             jp2 = particle % cell % num(2)
                 kp2 = particle % cell % num(3)

              imin = min(ip1,ip2)
	          jmin = min(jp1,jp2)
	          kmin = min(kp1,kp2)

	          if (imin <= 0) imin = 1
	          if (jmin <= 0) jmin = 1
	          if (kmin <= 0) kmin = 1

              imax = max(ip1,ip2)
	          jmax = max(jp1,jp2)
	          kmax = max(kp1,kp2)    

	          if (imax > geo%nx) imax = geo%nx
	          if (jmax > geo%ny) jmax = geo%ny
	          if (kmax > geo%nz) kmax = geo%nz     

	          dd = dsqrt( ( x11(1) - x22(1) ) **2 +  &
	                      ( x11(2) - x22(2) ) **2 +  &
			              ( x11(3) - x22(3) ) **2 )
			   
	          cosdir(1) =  ( x22(1) - x11(1) ) / dd
	          cosdir(2) =  ( x22(2) - x11(2) ) / dd
	          cosdir(3) =  ( x22(3) - x11(3) ) / dd

              nlinemax = (kmax-kmin+1)*(jmax-jmin+1)*(imax-imin+1) 

              allocate (lbdamin(nlinemax),qmod(nlinemax))

			  lbdamin = 0.d0
			  qmod    = 0.d0
	
	    xint = x11
		
		do kcell = kmin, kmax
	    do jcell = jmin, jmax
	    do icell = imin, imax

	        ! Calculate lambda's

              x1 = get_xmesh_ ( geo, icell ) 
	          y1 = get_ymesh_ ( geo, jcell )
	          z1 = get_zmesh_ ( geo, kcell )
	          x2 = get_xmesh_ ( geo, icell + 1 )
	          y2 = get_ymesh_ ( geo, jcell + 1 )
	          z2 = get_zmesh_ ( geo, kcell + 1 )

	          if (cosdir(1) /= 0.d0) lambda(1) = ( x1 - xint(1) ) / cosdir(1)
	          if (cosdir(1) /= 0.d0) lambda(2) = ( x2 - xint(1) ) / cosdir(1)
	
	          if (cosdir(2) /= 0.d0) lambda(3) = ( y1 - xint(2) ) / cosdir(2)
	          if (cosdir(2) /= 0.d0) lambda(4) = ( y2 - xint(2) ) / cosdir(2) 

	          if (cosdir(3) /= 0.d0) lambda(5) = ( z1 - xint(3) ) / cosdir(3)
	          if (cosdir(3) /= 0.d0) lambda(6) = ( z2 - xint(3) ) / cosdir(3) 

            ! Find grid-cell intersection:
		     
              lbda = maxval(lambda)
			  Intersection = .FALSE.
			  
			  do i=1,6             

				 if ( dot_product(cosdir,cosdir)*lambda(i) <= 0.d0) cycle

				 xp = xint + cosdir * lambda(i)
                
				 if ( xp(1) >= x1 .and. xp(1) <= x2 .and. &
	                  xp(2) >= y1 .and. xp(2) <= y2 .and. &
		              xp(3) >= z1 .and. xp(3) <= z2 ) then
						  Intersection = .TRUE.
					      if (dabs(lambda(i)) < dabs(lbda) ) lbda = lambda(i)
	             end if

              end do
        
		      if (Intersection) then

			      xhalf = xint + cosdir * lbda * 0.5d0
                  xint  = xint + cosdir * lbda
				   
				  nline = nline + 1
				  lbdamin(nline) = lbda
				  
                ! Calculate velocity mid-point: 

                  call assign_to_particle_            ( particle , xhalf , mp, zone, specie )  !assign position and mass to particle
                  call update_cell_location_particle_ ( particle, geo )       !update cell location and local coordinates, save switchcell flag
                  call update_velocity_particle_      ( particle, geo, advection ) !update velocities qL,qT,qnode,qfaces        
              
			      qmod(nline) = calc_module_Darcy_velocity_particle_ (particle)
 
              end if

        end do
		end do
		end do   

       ! calculate total Darcy-flux weighted by line-length

        totflux = 0.d0
              
	    do iline = 1, nline
		       totflux = totflux + qmod(iline)*lbdamin(iline)
	    end do
			
       ! calculate position particles 

        npsum   = 0
        lbda    = 0.d0
		jp      = 0
            
		do iline=1,nline

			   npline = int(dble(np) * qmod(iline)*lbdamin(iline)/totflux+0.5d0)
			               
			   do jpline=1,npline

                 xp = x11 + lbda*cosdir + cosdir*lbdamin(iline)/dfloat(npline+1) * dfloat(jpline)
			    
                 if (reaction%action) then
                    call assign_to_particle_               ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                    call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	                call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
                    rpt = particle%prop%rp
                    call generate_plumeparticle_ID_ (id)
                    call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
                  else
                    call generate_plumeparticle_ID_ (id)
                    call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			      end if
 
	           end do
		
			   lbda = lbda + lbdamin(iline)		
	    
		end do



        deallocate(lbdamin,qmod)

        end if


!       ==================================================
!       VERTICAL line source : FLUX-WEIGHTED distribution 
!       ==================================================
            
      else if ( trim(adjustl(fsour)) == 'VERTICAL_LINE_FLUX_WEIGHTED' ) then
 
        mp     = source % num (kinj) % pmass         
        np     = source % num (kinj) % np
		zone   = source % num (kinj) % zone
		specie = source % num (kinj) % specie 

       ! get velocities

	   i2 = source % num (kinj) % par % idwn
	   j2 = source % num (kinj) % par % jdwn
	   k2 = source % num (kinj) % par % kdwn
	   k3 = source % num (kinj) % par % kup

             ! get velocities
  
             sumq = 0.d0
       
             allocate (qm(k2:k3))
       
             do k=k2,k3
   
                  qx = 0.5d0*(advection%qx%values(i2,j2,k)+advection%qx%values(i2+1,j2,k))
                  qy = 0.5d0*(advection%qy%values(i2,j2,k)+advection%qy%values(i2,j2+1,k))
                  if (nz /= 1) dz = value_array_ (geo%dz,1,1,k)
                  qm(k) = dsqrt(qx*qx+qy*qy)*dz
       
             end do
     
             ! distribute particles block by block 
       
             xp(1) = 0.5d0 * (get_xmesh_(geo,i2+1) + get_xmesh_(geo,i2))
             xp(2) = 0.5d0 * (get_ymesh_(geo,j2+1) + get_ymesh_(geo,j2))

             npsum = 0
       
             do k=k2,k3

                 npblock = 0
 
                 if (sum(qm(k:k3)) > 0.d0) npblock = dint( (np-npsum) * qm(k) / sum(qm(k:k3)) + 0.5d0 )    
                           
	             az  = get_zmesh_(geo,k+1) - get_zmesh_(geo,k)          
                 zz0 = get_zmesh_(geo,k) 
          
                 do jp=1,npblock
                      
                     xp(3) = zz0 + jp * az / dfloat(npblock+1)
                     
                     if (reaction%action) then
                         call assign_to_particle_             ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                         call update_cell_location_particle_  ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	                     call update_properties_particle_     ( particle, geo, advection, reaction   ) !update retardation
                         rpt = particle%prop%rp
                         call generate_plumeparticle_ID_ (id)
                         call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
                     else
                         call generate_plumeparticle_ID_ (id)
                         call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			         end if
			       
		         end do

                 npsum = npsum + npblock
          
             end do

             if (npsum /= np) stop 'number of particles injected not correct'

             deallocate(qm)

!       ==================================================
!       VERTICAL block source : FLUX-WEIGHTED distribution 
!       ==================================================

      else if ( trim(adjustl(fsour)) == 'VERTICAL_BLOCK_FLUX_WEIGHTED' ) then

        mp     = source % num (kinj) % pmass         
        np     = source % num (kinj) % np
		zone   = source % num (kinj) % zone
		specie = source % num (kinj) % specie 

       ! get velocities

	   i2 = source % num (kinj) % par % idwn
	   j2 = source % num (kinj) % par % jdwn
	   k2 = source % num (kinj) % par % kdwn
	   k3 = source % num (kinj) % par % kup

             ! get velocities

             sumq = 0.d0

             allocate (qm(k2:k3))

             do k=k2,k3

                  qx = 0.5d0*(advection%qx%values(i2,j2,k)+advection%qx%values(i2+1,j2,k))
                  qy = 0.5d0*(advection%qy%values(i2,j2,k)+advection%qy%values(i2,j2+1,k))
                  if (nz /= 1) dz = value_array_ (geo%dz,1,1,k)
                  qm(k) = dsqrt(qx*qx+qy*qy)*dz

             end do
     
             ! distribute particles block by block 
       
             xp(1) = 0.5d0 * (get_xmesh_(geo,i2+1) + get_xmesh_(geo,i2))
             xp(2) = 0.5d0 * (get_ymesh_(geo,j2+1) + get_ymesh_(geo,j2))

             npsum = 0
	         
	         ax = value_array_ (geo%dx,i2,1,1) 
	         ay = value_array_ (geo%dy,1,j2,1)        

	         xx0 = get_xmesh_(geo,i2) + ax/2             
	         yy0 = get_ymesh_(geo,j2) + ay/2
	         
	         do k=k2,k3
          
                 npblock = 0
 
                 if (sum(qm(k:k3)) > 0.d0) npblock = dint( (np-npsum) * qm(k) / sum(qm(k:k3)) + 0.5d0 )         
 	             
                 az = value_array_ (geo%dz,1,1,k)                
                 
                 zz0 = get_zmesh_(geo,k) 
          
                 do jp=1,npblock
                                    
                    call random_number(ran); xp(1) = xx0 + (ran-0.5) * ax
                    call random_number(ran); xp(2) = yy0 + (ran-0.5) * ay
                    call random_number(ran); xp(3) = zz0 + ran * az

                    if (reaction%action) then
                          call assign_to_particle_             ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                          call update_cell_location_particle_  ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	                      call update_properties_particle_     ( particle, geo, advection, reaction   ) !update retardation
                          rpt = particle%prop%rp
                          call generate_plumeparticle_ID_ (id)
                          call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
                     else
                          call generate_plumeparticle_ID_ (id)
                          call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			         end if			       
		         
		         end do

                 npsum = npsum + npblock

             end do

             if (npsum /= np) stop 'number of particles injected not correct'

             deallocate(qm)


!       ==================================================
!       VERTICAL block source : FLUX-WEIGHTED distribution 
!       ==================================================

      else if ( trim(adjustl(fsour)) == 'CELLS_FILE_FLUX_WEIGHTED' ) then

        mp     = source % num (kinj) % pmass         
        np     = source % num (kinj) % np
		zone   = source % num (kinj) % zone
		specie = source % num (kinj) % specie 

      ! get velocities
        allocate(ix(size(source % num (kinj) % par % ix)))
        allocate(iy(size(source % num (kinj) % par % iy)))
        allocate(iz(size(source % num (kinj) % par % iz)))
	    ix = source % num (kinj) % par % ix
	    iy = source % num (kinj) % par % iy
	    iz = source % num (kinj) % par % iz

             ! get velocities

             allocate (qm(size(ix)))

             do k=1,size(ix)
                  qx = advection%qx%values(ix(k)+1,iy(k),iz(k)) - advection%qx%values(ix(k),iy(k),iz(k))
                  qy = advection%qy%values(ix(k),iy(k)+1,iz(k)) - advection%qy%values(ix(k),iy(k),iz(k))
                  qz = advection%qz%values(ix(k),iy(k),iz(k)+1) - advection%qz%values(ix(k),iy(k),iz(k))
                  qm(k) = qx+qy+qz
                  !qm(k) = abs(qm(k))
             end do
             
             !write(10006,'(11A9)') 'Layer', 'npblock', 'qx', 'qy', 'qz', 'ix(k)', 'iy(k)', 'iz(k)', 'xx0', 'yy0', 'zz0'
             
             ! distribute particles block by block 
       
             !xp(1) = 0.5d0 * (get_xmesh_(geo,ix(1)+1) + get_xmesh_(geo,ix(1)))
             !xp(2) = 0.5d0 * (get_ymesh_(geo,j2+1) + get_ymesh_(geo,j2))

             npsum = 0

	         do k=1,size(ix)

                 !npblock = dint(np*qm(k)/sumq+0.5d0)
                 !npblock = dint(np*exp(qm(k))/sumq+0.5d0)

                 npblock = 0

                 if (sum(qm(k:size(ix))) > 0.d0) then
                     npblock = dint( (np-npsum) * qm(k) / sum(qm(k:size(ix))) + 0.5d0 )
                 else
                     write(*,*) 'Flux in the injection block is negative (pumping out)!'
                     npblock = dint( (np-npsum) / (size(ix)+1-k) + 0.5d0 )
                     !exit
                 end if

	             ax = value_array_ (geo%dx,ix(k),1,1) 
	             ay = value_array_ (geo%dy,1,iy(k),1)
	             az = value_array_ (geo%dz,1,1,iz(k))

	             xx0 = get_xmesh_(geo,ix(k)) + ax/2
	             yy0 = get_ymesh_(geo,iy(k)) + ay/2
                 zz0 = get_zmesh_(geo,iz(k)) 
                 
                 !write(10006,'(2I9, 3F9.4,3I9, 3F9.4)') k, npblock, qx, qy, qz, ix(k), iy(k), iz(k), xx0, yy0, zz0
          
                 do jp=1,npblock
                                    
                    call random_number(ran); xp(1) = xx0 + (ran-0.5) * ax
                    call random_number(ran); xp(2) = yy0 + (ran-0.5) * ay
                    call random_number(ran); xp(3) = zz0 + ran * az

                    if (reaction%action) then
                          call assign_to_particle_             ( particle , xp , mp, zone, specie )  !assign position and mass to particle
                          call update_cell_location_particle_  ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	                      call update_properties_particle_     ( particle, geo, advection, reaction   ) !update retardation
                          rpt = particle%prop%rp
                          call generate_plumeparticle_ID_ (id)
                          call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,zone,specie)
                     else
                          call generate_plumeparticle_ID_ (id)
                          call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,zone,specie)
			         end if			       
		         
		         end do

                 npsum = npsum + npblock

             end do

             if (npsum /= np) then
                 write(*,*) 'npsum injected: ', npsum, 'number calculated from mass/pmass: ', np
                 stop 'number of particles injected not correct'
             end if

             deallocate(qm)



!       ================================================
!       Read Position and Properties Particles from File
!       ================================================

	  else if ( trim(adjustl(fsour)) == 'READ_PARTICLE_FILE' ) then

	        call open_fname_normal ( source%num(kinj)%par%file, unit )
			
			read(unit,*)
			read(unit,*) np
 
            np = source%num(kinj)%np
 
			do  jp=1,np
			    read(unit,*) xp(1),xp(2),xp(3),mp,izone,ispecie
                if (reaction%action) then
				   call assign_to_particle_               ( particle , xp , mp, izone, ispecie )  !assign position and mass to particle
                   call update_cell_location_particle_    ( particle, geo )       !update cell location and local coordinates, save switchcell flag
	               call update_properties_particle_       ( particle, geo, advection, reaction   ) !update retardation
                   rpt = particle%prop%rp
                   call generate_plumeparticle_ID_ (id)
                   call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,izone,ispecie)
			    else 
                   call generate_plumeparticle_ID_ (id)
                   call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,izone,ispecie)
				end if
			end do

           close(unit)

!       ================================================
!       Read a File with initial concentrations
!       ================================================

	  else if ( trim(adjustl(fsour)) == 'READ_CONCENTRATION_FILE' ) then

	        call open_fname_normal ( source%num(kinj)%par%file, unit )
			
			read(unit,*)
 
            mp      = source % num (kinj) % pmass         
		    izone   = source % num (kinj) % zone  
		    ispecie = source % num (kinj) % specie  
 
            nx = geo%nx
            ny = geo%ny
            nz = geo%nz
 
            source%num(kinj)%np = 0
 
            if(.not.associated(conc)) allocate(conc(nx))
 
            do k=nz,1,-1
               do j=ny,1,-1
                   read(unit,*)  (conc(i),i=1,nx)
                   conc = conc * source % num (kinj) % par % const
                   do i=1,nx
                      if (conc(i)<=0.d0) cycle
                      dx   = value_array_ (geo%dx,i,1,1)
                      dy   = value_array_ (geo%dy,1,j,1)
                      dz   = value_array_ (geo%dz,1,1,k)
                      Vol  = dx*dy*dz 
                      poro = value_array_ (advection%poro,i,j,k)
                      np   = int(conc(i)*poro*Vol/mp+0.5d0)
 			          do  jp=1,np
	                      xx0 = get_xmesh_(geo,i)
	                      yy0 = get_ymesh_(geo,j)
	                      zz0 = get_zmesh_(geo,k)                                   
                          call random_number(ran); xp(1) = xx0 + ran * dx
                          call random_number(ran); xp(2) = yy0 + ran * dy
                          call random_number(ran); xp(3) = zz0 + ran * dz                    
                          if (reaction%action) then
                              rpt = 1.d0
                              call generate_plumeparticle_ID_ (id)
                              call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,rpt,izone,ispecie)
			              else 
                              call generate_plumeparticle_ID_ (id)
                              call add_particle_to_plume_ (plume,id,xp(1),xp(2),xp(3),mp,1.d0,izone,ispecie)
				          end if
			          end do
			          source%num(kinj)%np = source%num(kinj)%np + np
			       end do
			   end do
           end do
           
           deallocate(conc)
           
           close(unit)
           
	  end if
	  
!...add to number of injected particles 

      npInj = npInj + source%num(kinj)%np

!......delete dummy particle

      call delete_particle_ (particle)

  end subroutine

 end module