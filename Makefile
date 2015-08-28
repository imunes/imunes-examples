all:
	sh testAll.sh

clean:
	@rm -f */TESTRESULTS* */*/TESTRESULTS* */tcplog_err benchmark/start*log benchmark/term*log

showtimes:
	grep "^Test took" */TESTRESULTS* */*/TESTRESULTS*

showerrors:
	grep "^There were errors" */TESTRESULTS* */*/TESTRESULTS*

bench:
	cd benchmark && ./benchmark.sh -w 1 *.imn

bench_all:
	cd benchmark && ./benchmark.sh ../*/*.imn
