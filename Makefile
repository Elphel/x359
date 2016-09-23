include $(AXIS_TOP_DIR)/tools/build/Rules.axis
OWN = -o root -g root

DOCUMENTROOT = $(prefix)/usr/html
TESTSCRIPTS = $(DOCUMENTROOT)/359
INCLUDES =     $(prefix)/usr/html/includes
INSTDOCS =  0644

PHPSCRIPTS= test_scripts/10359_controls.html \
	    test_scripts/10359_mem_test.php \
	    test_scripts/10359_modes.php \
            test_scripts/phases_adjust.php \
            test_scripts/reg_read.php \
            test_scripts/reg_write.php \
            test_scripts/sensors_init.php \

all:
install:
	$(INSTALL) $(OWN) -d $(DOCUMENTROOT)
	$(INSTALL) $(OWN) -d $(TESTSCRIPTS)
#install files
	$(INSTALL) $(OWN) -m $(INSTDOCS) $(PHPSCRIPTS)  $(TESTSCRIPTS)
