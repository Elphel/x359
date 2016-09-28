VERILOGDIR=   $(DESTDIR)/usr/local/verilog
#INSTALLDIR=   $(DESTDIR)/usr/local/bin
DOCUMENTROOT= $(DESTDIR)/www/pages
TESTSCRIPTS = $(DOCUMENTROOT)/359
 
OWN = -o root -g root

INSTMODE   = 0755
DOCMODE    = 0644

FPGA_BITFILES =   x359.bit
PHPSCRIPTS= test_scripts/10359_controls.html \
	    	test_scripts/10359_mem_test.php \
	    	test_scripts/10359_modes.php \
            test_scripts/phases_adjust.php \
            test_scripts/reg_read.php \
            test_scripts/reg_write.php \
            test_scripts/sensors_init.php \

all:
	@echo "make all in x359"
install:
	@echo "make install in x393sata"
	$(INSTALL) $(OWN) -d $(VERILOGDIR)
#	$(INSTALL) $(OWN) -d $(INSTALLDIR)
	$(INSTALL) $(OWN) -d $(DOCUMENTROOT)
	$(INSTALL) $(OWN) -d $(TESTSCRIPTS)

	$(INSTALL) $(OWN) -m $(INSTMODE) $(PHPSCRIPTS)    $(TESTSCRIPTS)
	$(INSTALL) $(OWN) -m $(DOCMODE)  $(FPGA_BITFILES) $(VERILOGDIR)
clean:
	@echo "make clean in x359"

