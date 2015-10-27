ccx: ARPACK/libarpack_INTEL.a SPOOLES.2.2/spooles.a
	cd CalculiX/ccx_2.8p2/src;make
	cd ../../..
	cp CalculiX/ccx_2.8p2/src/ccx_2.8p2 ccx
ARPACK/libarpack_INTEL.a:
	cd ARPACK;sh ./fixhome.sh;make lib
	cd ..
SPOOLES.2.2/spooles.a:
	cd SPOOLES.2.2;make lib
	cd ..
clean:
	cd ARPACK;make clean
	cd ..
	cd SPOOLES.2.2;make clean
	cd ..
	cd CalculiX/ccx_2.8p2/src;make clean
	cd ../../..
	rm ccx
