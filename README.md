# imunes-examples
Examples for the IMUNES network emulator.

IMUNES is a lightweight network emulator that runs on top of the FreeBSD kernel
which is used to create a virtual network topology by using FreeBSD
[jails](https://www.freebsd.org/doc/handbook/jails.html) and
[netgraph](https://www.freebsd.org/cgi/man.cgi?netgraph%284%29).

To run the scenarios, after starting the virtual machine, just clone the git
repository into the machine and follow the instructions.

Additional instructions and explanations are available on our [wiki page](http://imunes.tel.fer.hr/trac/wiki/WikiImunesExamples).

The table below shows which tests work on Linux and FreeBSD operating systems.

|                  |    Linux    |   FreeBSD   |
|------------------|:-----------:|:-----------:|
| benchmark        |     YES     |     YES     |
| DHCP             |     YES     |     YES     |
| DNS+Mail+WEB     |     YES     |     YES     |
| functional_tests |      NO     |     YES     |
| gif              |      NO     |     YES     |
| OSPF             |     YES     |     YES*    |
| Ping             |     YES     |     YES     |
| RIP              |     YES     |     YES     |
| services         |     YES     |     YES     |
| Traceroute       |     YES     |     YES     |

*problems with quagga OSPFv2 routing daemon on FreeBSD-9.3
