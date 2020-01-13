PREFIX ?= /usr/local/

bin/odb:
	mkdir -p bin/
	mv src/odb.sh bin/odb

clean:
	rm bin/odb

install: bin/odb
	mkdir -p $(PREFIX)/bin
	cp -f bin/odb $(PREFIX)/bin
	chmod 755 $(PREFIX)/bin/odb
