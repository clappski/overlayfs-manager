PREFIX ?= /usr/local/

bin/odb: src/odb.sh
	mkdir -p bin/
	cp src/odb.sh bin/odb

clean:
	rm bin/odb

install: bin/odb
	mkdir -p $(PREFIX)/bin
	cp -f bin/odb $(PREFIX)/bin
	chmod 755 $(PREFIX)/bin/odb

uninstall: $(PREFIX)/bin/odb
	rm $(PREFIX)/bin/odb
