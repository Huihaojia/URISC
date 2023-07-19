all: clean com sim verdi
all_netlist: clean dclean dc netlist_com netlist_verdi

netlist_com:
	vcs \
	-f netlist.f \
	+libext+.v \
	-y /login_home/huihaojia/Codes/URISC_final/lib/*.v \
	-full64 -R +vc +v2k -sverilog -debug_access_all\
	-timescale=1ns/1ps \
	-negdelay +neg_tchk \
	+sdfverbose +no_notifier
	-l run.log \
	-o testbench.simv \
	+fsdb+force \
	| tee vcs.log

com:
	vcs \
	-f filelist.f \
	-full64 -R +vc +v2k -sverilog -debug_acc\
	-timescale=1ns/10ps \
	-l com.log \
	-o testbench.simv \
	+fsdb+force \
	| tee vcs.log

sim:
	./testbench.simv -l sim.log

clean:
	rm -rf *.log simv *.daidir csrc *.key DVEfiles *.vpd *.fsdb *.simv novas.* verdiLog *.tlist *.xlist

verdi:
	verdi \
	-nologo \
	-f filelist.f \
	-ssf *.fsdb &

netlist_verdi:
	verdi \
	-nologo \
	-f netlist.f \
	-ssf *.fsdb &

dc:
	dc_shell-xg-t -f run.tcl | tee -i log

dclean:
	rm -rf ./report/* ./output/* log *.rpt *.svf *.ddc *.mr *.syn