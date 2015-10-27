!
!     CalculiX - A 3-dimensional finite element program
!              Copyright (C) 1998-2015 Guido Dhondt
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation(version 2);
!
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of 
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
!     GNU General Public License for more details.
!
!     You should have received a copy of the GNU General Public License
!     along with this program; if not, write to the Free Software
!     Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
!
      subroutine film(h,sink,temp,kstep,kinc,time,noel,npt,
     &  coords,jltyp,field,nfield,loadtype,node,area,vold,mi)
!
!     user subroutine film
!
!
!     INPUT:
!
!     sink               most recent sink temperature
!     temp               current temperature value
!     kstep              step number
!     kinc               increment number
!     time(1)            current step time
!     time(2)            current total time
!     noel               element number
!     npt                integration point number
!     coords(1..3)       global coordinates of the integration point
!     jltyp              loading face kode:
!                        11 = face 1 
!                        12 = face 2 
!                        13 = face 3 
!                        14 = face 4 
!                        15 = face 5 
!                        16 = face 6
!     field              currently not used
!     nfield             currently not used (value = 1)
!     loadtype           load type label
!     node               network node (only for forced convection)
!     area               area covered by the integration point
!     vold(0..4,1..nk)   solution field in all nodes
!                        0: temperature
!                        1: displacement in global x-direction
!                        2: displacement in global y-direction
!                        3: displacement in global z-direction
!                        4: static pressure
!     mi(1)              max # of integration points per element (max
!                        over all elements)
!     mi(2)              max degree of freedomm per node (max over all
!                        nodes) in fields like v(0:mi(2))...
!
!     OUTPUT:
!
!     h(1)               magnitude of the film coefficient
!     h(2)               not used; please do NOT assign any value
!     sink               (updated) sink temperature (need not be
!                        defined for forced convection)
!
      implicit none
!
      character*20 loadtype
      integer kstep,kinc,noel,npt,jltyp,nfield,node,mi(*),pos1,pos2,pos3
      real*8 h(2),sink,time(2),coords(3),temp,field(nfield),area,
     &  vold(0:mi(2),*), t, ta, deltat, cp, mu, rho, beta, g, k, ny, l,
     &  Ra, Nu, b, lambda, il, Gr, Pr, f

      pos1 = index(loadtype, ";")
      read(loadtype(6:pos1-1), *) ta

      deltat = temp - ta
      if( abs(deltat) < .01d0 ) deltat = .01d0

      t = (temp + ta)/2.d0
      if( t.lt.-50 ) t = -50.d0
      if( t.gt.200 ) t = 200.d0

      g = 9.81d0
      cp = ( 8.287d-12*t**3 +4.050d-7*t**2 +1.538d-5*t +1.00588)*1.d3
      mu = ( 3.396d-8 *t**3 -3.661d-5*t**2 +5.012d-2*t +17.2172)*1.d-6
      beta=(-8.569d-8 *t**3 +4.676d-5*t**2 -1.379d-2*t +3.67965)*1.d-3
      rho =(-2.908d-8 *t**3 +1.597d-5*t**2 -4.756d-3*t +1.27778)
      k =  ( 3.946d-8 *t**3 -4.341d-5*t**2 +7.656d-2*t +24.3589)*1.d-3
      ny = (-4.834d-7 *t**3 +1.130d-4*t**2 +0.887883*t +134.993)*1.d-7
      Pr = (-4.298d-10*t**3 +5.408d-7*t**2 -1.555d-4*t +0.71099)

      if ( loadtype(5:5).eq."C" ) then

          pos2 = index(loadtype(pos1+1:), ";") + pos1

          read(loadtype(pos1+1:pos2-1), *) l
          read(loadtype(pos2+1:), *) b

          Ra = (rho**2.d0*g*beta*cp*b**4.d0*deltat)/(mu*k*l)
          Nu = Ra/24.d0* (1.d0 - exp(-35.d0/Ra))**.75d0

      else if ( loadtype(5:5).eq."W" ) then

          read(loadtype(pos1+1:), *) l

          Gr = (g*l**3.d0 *beta*deltat)/ny**2.d0
          Ra = Gr*Pr
          f = (1.d0 + (0.492d0/Pr)**(9.d0/16.d0) )**(-16.d0/9.d0)
          Nu = (0.825d0 + 0.387d0*(Ra*f)**(1.d0/6.d0) )**2.d0

      else if ( loadtype(5:5).eq."T" ) then

          read(loadtype(pos1+1:), *) l

          Gr = (g*l**3.d0 *beta*deltat)/ny**2.d0
          Ra = Gr*Pr
          f = (1.d0 + (0.332d0/Pr)**(11.d0/20.d0) )**(-20.d0/11.d0)

          if ( Ra*f > 7.d4 ) then
              Nu = .15d0*(Ra*f)**(1.d0/3.d0)
          else
              Nu = .766d0*(Ra*f)**(1.d0/5.d0)
          end if

      else if ( loadtype(5:5).eq."B" ) then

          read(loadtype(pos1+1:), *) l

          Gr = (g*l**3.d0 *beta*deltat)/ny**2.d0
          Ra = Gr*Pr
          f = (1.d0 + (0.332d0/Pr)**(11.d0/20.d0) )**(-20.d0/11.d0)

          Nu = .6d0*(Ra*f)**(1.d0/5.d0)

      end if

      lambda = Nu * k / l
      h(1)=lambda
      sink=ta
!
      return
      end

