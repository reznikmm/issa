INSTALL = install -c
INSTALL_libs = $(INSTALL) -m 0555
INSTALL_data = $(INSTALL) -m 0444
SOEXT = .so

WEBXML = source/web.xml

all:
    #gprbuild -p -P gnat/servlets.gpr
	LIBRARY_TYPE=relocatable alr build

clean:
	rm -rf .objs .lib

deploy: all
	rm -rf install
	$(INSTALL) -d install
	$(INSTALL) -d install/WEB-INF
	$(INSTALL) -d install/WEB-INF/lib
	$(INSTALL) -d install/WEB-INF/lib/x86_64-linux
	$(INSTALL_libs) .lib/libissa$(SOEXT) \
	    install/WEB-INF/lib/x86_64-linux/
	$(INSTALL_data) $(WEBXML) install/WEB-INF/web.xml

run: deploy
	spikedog_awsd
