all:
	sh testAll.sh

clean:
	@rm -f */TESTRESULTS* */*/TESTRESULTS* */tcplog_err 

showtimes:
	grep "^Test took" */TESTRESULTS* */*/TESTRESULTS*

showerrors:
	grep "^There were errors" */TESTRESULTS* */*/TESTRESULTS*

benchmark:
	cd benchmark && ./benchmark.sh -w 1 *.imn

benchmark_all:
	benchmark/benchmark.sh */*.imn
