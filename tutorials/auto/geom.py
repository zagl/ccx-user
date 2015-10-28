#!/usr/bin/env python3

import pycgx
import re
import fileinput
import subprocess

def heatSinkTemp(length, width, height, n_fins, fin_width, base_width, conductivity, ta, emissivity, flux):
    # Geometry
#    length = 0.075
#    width = 0.0495
#    height = 0.050
#    n_fins = 6
#    fin_width = 2e-3
#    base_width = 7e-3
#
#
#
#    # Physical
#    conductivity = 200.
#    ta = 20.
#    emissivity = 0.90
#    flux = 15.

    fin_spacing = (width- fin_width) /(n_fins -1) - fin_width

    flux_density = flux / (length*width)

    c = pycgx.Cgx()

    heatsink = c.makeHeatsink(
        [0., 0., 0.],
        [length, width, height],
        n_fins, fin_width, base_width,
        [4,1,2],
        'heatsink'
    )

    top = c.makeSet("ht")
    top.add(heatsink.maxX)

    bottom = c.makeSet("hb")
    bottom.add(heatsink.minX)

    channel = c.makeSet("hc")
    channel.add(heatsink.inside)

    walls = c.makeSet("hw")
    walls.add(heatsink.minZ)
    walls.add(heatsink.maxZ)
    walls.add(heatsink.minY)
    walls.add(heatsink.maxY)

    rad = c.makeSet('rad')
    rad.add(heatsink.inside)
    rad.add(heatsink.minX)
    rad.add(heatsink.maxX)
    rad.add(heatsink.minY)
    rad.add(heatsink.maxY)
    rad.add(heatsink.maxZ)

    flux = c.makeSet("flux")
    flux.add(heatsink.minZ)

    c.meshLinear()
    c.sendMesh()
    top.sendFilm()
    bottom.sendFilm()
    channel.sendFilm()
    walls.sendFilm()
    rad.sendRadiate()
    flux.sendFlux()

    c.write('send.fbd')

    out = subprocess.getoutput('cgx -bg send.fbd')

    l_hor = fin_width*height/(2*(fin_width+height))

    with fileinput.FileInput('ht.flm', inplace=True) as fobj:
        for line in fobj:
            print(re.sub(r'(F[0-9]).*', r'\1NUT {0:d}; {1:0.3e}'.format(int(ta), l_hor), line), end='')

    with fileinput.FileInput('hb.flm', inplace=True) as fobj:
        for line in fobj:
            print(re.sub(r'(F[0-9]).*', r'\1NUB {0:d}; {1:0.3e}'.format(int(ta), l_hor), line), end='')

    with fileinput.FileInput('hw.flm', inplace=True) as fobj:
        for line in fobj:
            print(re.sub(r'(F[0-9]).*', r'\1NUW {0:d}; {1:0.3e}'.format(int(ta), length), line), end='')

    with fileinput.FileInput('hc.flm', inplace=True) as fobj:
        for line in fobj:
            print(re.sub(r'(F[0-9]).*', r'\1NUC {0:d}; {1:3d}; {2:d}'.format(int(ta), int(length*1000), int(fin_spacing*1e6)), line, ), end='')

    with fileinput.FileInput('rad.rad', inplace=True) as fobj:
        for line in fobj:
            print(re.sub(r'(R[0-9])', r'\1CR', line), end='')

    case_deck = '''\
    *INCLUDE, INPUT=all.msh
    *MATERIAL, Name=Aluminium
    *CONDUCTIVITY
      %f,0.
    *SOLID SECTION, Elset=Eall, Material=Aluminium
    *PHYSICAL CONSTANTS,ABSOLUTE ZERO=-273.15,STEFAN BOLTZMANN=5.669E-8
    *INITIAL CONDITIONS,TYPE=TEMPERATURE
      Nall, %f
    *AMPLITUDE, NAME=Aflux
      0., %f
    *AMPLITUDE, NAME=AinfTemp
      0., %f
    *AMPLITUDE, NAME=ARad
      0., %f
    *STEP
    *HEAT TRANSFER,STEADY STATE
    *DFLUX, AMPLITUDE=Aflux
    *INCLUDE, INPUT=flux.dfl
    *FILM
    *INCLUDE, INPUT=hb.flm
    *INCLUDE, INPUT=ht.flm
    *INCLUDE, INPUT=hw.flm
    *INCLUDE, INPUT=hc.flm
    *RADIATE, AMPLITUDE=AinfTemp, RADIATION AMPLITUDE=ARad
    *INCLUDE, INPUT=rad.rad
    *EL FILE
      HFL
    *NODE FILE
      NT,RFL
    *END STEP''' % (conductivity, ta, flux_density, ta, emissivity)

    with open('case.inp', 'w') as fobj:
        fobj.write(case_deck)

    out = subprocess.getoutput('../../application/ccx case')

    eval_fbd = '''\
    read case.frd
    ds 1 e 1'''

    with open('eval.fbd', 'w') as fobj:
        fobj.write(eval_fbd)

    out = subprocess.getoutput('cgx -bg eval.fbd | grep max')

    return float(out[5:17])


for n in range(2,20):
    t = heatSinkTemp(
        length = 0.075,
        width = 0.0495,
        height = 0.050,
        n_fins = n,
        fin_width = 2e-3,
        base_width = 7e-3,
        conductivity = 200.,
        ta = 20.,
        emissivity = 0.90,
        flux = 15.,
    )
    print(t)

