## Process this file with automake to produce Makefile.in

SUBDIRS = xmotif xathena xtk ptk

# To change driver list edit configure.ac
BUILT_DRIVER_ROUTINES = @BUILT_DRIVERS@
STAR_BUILT_DRIVER_ROUTINES = @STAR_BUILT_DRIVERS@

noinst_LTLIBRARIES = libpgplot_drivers.la libpgplot_star_drivers.la
libpgplot_drivers_la_SOURCES = grexec.f
libpgplot_star_drivers_la_SOURCES = star_grexec.f

EXTRA_libpgplot_drivers_la_SOURCES = $(DRIVER_ROUTINES)
libpgplot_drivers_la_LIBADD = $(BUILT_DRIVER_ROUTINES)
libpgplot_drivers_la_DEPENDENCIES = $(BUILT_DRIVER_ROUTINES)

EXTRA_libpgplot_star_drivers_la_SOURCES = $(STAR_DRIVER_ROUTINES)
libpgplot_star_drivers_la_LIBADD = $(STAR_BUILT_DRIVER_ROUTINES)
libpgplot_star_drivers_la_DEPENDENCIES = $(STAR_BUILT_DRIVER_ROUTINES)

bin_PROGRAMS = pgxwin_server
pgxwin_server_SOURCES = pgxwin_server.c
pgxwin_server_LDADD = $(X_LIBS) $(X_EXTRA_LIBS) $(X_PRE_LIBS) -lX11

dist_noinst_HEADERS = commands.h defines.h  pgxwin.h
dist_noinst_SCRIPTS = makegrexec.pl

grexec.f: $(BUILT_DRIVER_ROUTINES) makegrexec.pl
	./makegrexec.pl $(BUILT_DRIVER_ROUTINES)

star_grexec.f: $(STAR_BUILT_DRIVER_ROUTINES) makegrexec.pl
	./makegrexec.pl -o star_grexec.f $(STAR_BUILT_DRIVER_ROUTINES)

# These are all the driver routines, even if they do not build

DRIVER_ROUTINES = exdriv.f pgdriv.f cadriv.f hgdriv.f lxdriv.f	     \
ppdriv.F vtdriv.f gidriv.F hidriv.f psdriv.f ttdriv.f cwdriv.f	     \
gldriv.f nedriv.f wddriv.F hpdriv.f lsdriv.f nudriv.f qmdriv.f	     \
vadriv.f cgdriv.c nexsup.c rvdriv.c x2driv.c xmdriv.c figdisp_comm.c \
pgxwin.c pndriv.c tkdriv.c xadriv.c xwdriv.c bcdriv.f gvdriv.f	     \
ladriv.f lvdriv.f tfdriv.f xedriv.f gcdriv.f todriv.f zedriv.f	     \
ccdriv.f ljdriv.f lhdriv.f mfdriv.f hjdriv.f lndriv.f pxdriv.f	     \
txdriv.f epdriv.f godriv.f wsdriv.f vbdriv.f pkdriv.c

STAR_DRIVER_ROUTINES = exdriv.f pgdriv.f cadriv.f hgdriv.f lxdriv.f  \
ppdriv.F vtdriv.f gidriv.F hidriv.f psdriv.f ttdriv.f cwdriv.f	     \
gldriv.f nedriv.f wddriv.F hpdriv.f lsdriv.f nudriv.f qmdriv.f	     \
vadriv.f cgdriv.c nexsup.c rvdriv.c x2driv.c xmdriv.c figdisp_comm.c \
pgxwin.c pndriv.c tkdriv.c xadriv.c star_xwdriv.c bcdriv.f gvdriv.f   \
ladriv.f lvdriv.f tfdriv.f xedriv.f gcdriv.f todriv.f zedriv.f	     \
ccdriv.f ljdriv.f lhdriv.f mfdriv.f hjdriv.f lndriv.f pxdriv.f	     \
txdriv.f epdriv.f godriv.f wsdriv.f vbdriv.f gwmdriv.c pkdriv.c

AM_CFLAGS = -DPG_PPU

CLEANFILES = star_grexec.f grexec.f

