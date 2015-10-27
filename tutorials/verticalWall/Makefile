case.frd: case.inp all.msh
	../../application/ccx case
all.msh: send.fbd geom.fbd
	cgx -bg send.fbd || true
clean:
	rm -rf *.flm *.rad *.msh *.cvg *.dat *.frd *.sta *.out
