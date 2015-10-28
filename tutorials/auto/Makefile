case.frd: case.inp send.fbd
	../../application/ccx case
send.fbd case.inp: geom.py
	python3 geom.py > geom.log
clean:
	rm -rf *.flm *.rad *.msh *.cvg *.dat *.frd *.sta *.out *.dfl *.log *.fbd *.inp
