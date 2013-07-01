#!/usr/bin/env python

'''
*+
*  Name:
*     skyloop

*  Purpose:
*     Create a map using the "inside-out" algorithm.

*  Language:
*     python (2.7 or 3.*)

*  Description:
*     This script makes a map from specified raw time-series data using
*     the algorithm described at
*     http://pipelinesandarchives.blogspot.co.uk/2012/10/inside-out-map-making.html.
*     It runs SMURF:MAKEMAP multiple times, performing a single iteration of
*     the Dynamic Iterative Map-Maker algorithm on each invocation,
*     including data from all chunks. Each map created by MAKEMAP is used
*     as the initial sky estimate for the next invocation. MAKEMAP subtracts
*     this initial sky estimate from the time-series data before starting
*     the first (and only) iteration, and then adds the initial sky estimate
*     back on at the end prior to creating the output map.
*
*     The script produces several intermediate files: a set of cleaned
*     time-series files that may be 2 to 3 times the size of the entire
*     set of raw data files included in the map, and a 2D map for every
*     iteration. These files are placed in a newly created directory that
*     is normally deleted before the script exits. The files can be retained
*     for debugging purposes if required by running the script with
*     "retain=yes" on the command line.
*
*     The temporary files are placed in a directory name "NDG_xxxxx",
*     located within the directory specified by environment variable
*     STAR_TEMP. If STAR_TEMP is not defined, they are placed in the system's
*     temporary directory (e.g. "/tmp").
*
*     In addition, files holding the extinction correction factor for each
*     data sample are written to the current working directory. These are
*     deleted when the script ends.

*  Usage:
*     skyloop in out niter pixsize config [itermap] [ref] [mask2] [mask3]
*             [extra] [retain] [msg_filter] [ilevel] [glevel] [logfile]
*             [restart]

*  Parameters:
*     CONFIG = LITERAL (Read)
*        The MAKEMAP configuration parameter values to use. Additions
*        will be made as follows:
*
*        - First iteration:
*           numiter=1
*           noi.calcfirst=1
*           exportNDF=ext
*           noexportsetbad=1
*           exportclean=1
*           ast.zero_notlast = 0
*           flt.zero_notlast = 0
*           com.zero_notlast = 0
*           itermap=0
*           shortmap=0
*           bolomap=0
*           flagmap=<undef>
*           sampcube=0
*           diag.append=0
*
*        - Subsequent iterations:
*           numiter=1
*           noi.calcfirst=1
*           doclean=0
*           importsky=ref
*           ext.import=1
*           ast.zero_notlast = 0
*           flt.zero_notlast = 0
*           com.zero_notlast = 0
*           flt.notfirst = 0
*           pln.notfirst = 0
*           smo.notfirst = 0
*           itermap=0
*           shortmap=0
*           bolomap=0
*           flagmap=<undef>
*           sampcube=0
*           diag.append=1
*
*        - Last iteration:
*           numiter=1
*           noi.calcfirst=1
*           doclean=0
*           importsky=ref
*           ext.import=1
*           ast.zero_notlast = 1
*           flt.zero_notlast = 1
*           com.zero_notlast = 1
*           flt.notfirst = 0
*           pln.notfirst = 0
*           smo.notfirst = 0
*           itermap=0
*           shortmap=0
*           bolomap=0
*           flagmap=<undef>
*           sampcube=0
*           diag.append=1
*
*     GLEVEL = LITERAL (Read)
*        Controls the level of information to write to a text log file.
*        Allowed values are as for "ILEVEL". The log file to create is
*        specified via parameter "LOGFILE. ["ATASK"]
*     ILEVEL = LITERAL (Read)
*        Controls the level of information displayed on the screen by the
*        script. It can take any of the following values (note, these values
*        are purposefully different to the SUN/104 values to avoid confusion
*        in their effects):
*
*        - "NONE": No screen output is created
*
*        - "CRITICAL": Only critical messages are displayed such as warnings.
*
*        - "PROGRESS": Extra messages indicating script progress are also
*        displayed.
*
*        - "ATASK": Extra messages are also displayed describing each atask
*        invocation. Lines starting with ">>>" indicate the command name
*        and parameter values, and subsequent lines hold the screen output
*        generated by the command.
*
*        - "DEBUG": Extra messages are also displayed containing unspecified
*        debugging information.
*
*        ["PROGRESS"]
*     IN = NDF (Read)
*        The group of time series NDFs to include in the output map.
*     ITERMAP = NDF (Write)
*        A 3D NDF to create holding the maps from all iterations. [!]
*     LOGFILE = LITERAL (Read)
*        The name of the log file to create if GLEVEL is not NONE. The
*        default is "<command>.log", where <command> is the name of the
*        executing script (minus any trailing ".py" suffix), and will be
*        created in the current directory. Any file with the same name is
*        over-written. []
*     NITER = _INTEGER (Read)
*        The number of iterations to perform. A positive value specifies
*        a fixed number of iterations to perform. A negative value
*        indicates that iterations should continue until the normalized
*        change in the map between iterations is less than the value of
*        the "maptol" parameter in the configuration supplied by
*        parameter CONFIG (a maptol value of 0.05 is used if CONFIG does
*        not specify maptol). If a value of zero is supplied for NITER,
*        the value used will be read from the "numiter" parameter in the
*        configuration. [0]
*     MASK2 = NDF (Read)
*        An existing NDF that can be used to specify a second external mask
*        for use with either the AST, FLT or COM model. See configuration
*        parameters AST.ZERO_MASK, FLT.ZERO_MASK and COM.ZERO_MASK. Note,
*        it is assumed that this image is aligned in pixel coordinate with
*        the output map. [!]
*     MASK3 = NDF (Read)
*        An existing NDF that can be used to specify a third external mask
*        for use with either the AST, FLT or COM model. See configuration
*        parameters AST.ZERO_MASK, FLT.ZERO_MASK and COM.ZERO_MASK. Note,
*        it is assumed that this image is aligned in pixel coordinate with
*        the output map. [!]
*     EXTRA = LITERAL (Read)
*        A string holding any extra command line options to be passed to
*        MAKEMAP (all invocations). [!]
*     MSG_FILTER = LITERAL (Read)
*        Controls the default level of information reported by Starlink
*        atasks invoked within the executing script. The accepted values
*        are the list defined in SUN/104 ("None", "Quiet", "Normal",
*        "Verbose", etc). ["Normal"]
*     OUT = NDF (Write)
*        The NDF holding the output map.
*     PIXSIZE = _REAL (Read)
*        Pixel dimensions in the output image, in arcsec. The same value
*        will be used for both axes. The default depends on the wavelength
*        of the input data. []
*     REF = NDF (Read)
*        An existing NDF that is to be used to define the output grid.
*        If supplied, the output grid will be aligned with the supplied
*        reference NDF. The reference can be either 2D or 3D and the spatial
*        frame will be extracted. If a null (!) value is supplied then the
*        output grid is determined by parameters REFLON, REFLAT, etc.
*        In addition, this NDF can be used to mask the AST, FLT or COM
*        model. See configuration parameters AST.ZERO_MASK, FLT.ZERO_MASK
*        and COM.ZERO_MASK.
*
*        On the second and subsequent invocations of MAKEMAP, any
*        supplied REF image is replaced by the map created by the previous
*        invocation of MAKEMAP. [!]
*     RESTART = LITERAL (Read)
*        If a value is assigned to this parameter, it should be the path
*        to a directory containing the intermediate files created by a
*        previous run of SKYLOOP. If supplied, execution of skyloop will
*        restart from the point where the previous run finished. This is
*        useful for continuing runs that have been interupted accidentally.
*        The path to the intermediate files can be found by examining the
*        log file created by the previous run. [!]
*     RETAIN = _LOGICAL (Read)
*        Should the temporary directory containing the intermediate files
*        created by this script be retained? If not, it will be deleted
*        before the script exits. If retained, a message will be
*        displayed at the end specifying the path to the directory. [FALSE]

*  Copyright:
*     Copyright (C) 2012 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     DSB: David S. Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     24-OCT-2012 (DSB):
*        Original version
*     16-JAN-2013 (DSB):
*        - Only include any supplied REF value in the makemap comamnd line
*        on the first iteration.
*        - Record quality info in the final map.
*     9-JAN-2013 (DSB):
*        Add support for diagnostics.
*     28-MAR-2013 (DSB):
*        Added parameter RESTART.
*     1-JUL-2013 (DSB):
*        Do not export cleaned data on the first iteration if the supplied 
*        data has already been cleaned. Instead, re-use the supplied data on
*        subsequent iterations.

*-
'''


import glob
import os
import shutil
import starutil
from starutil import invoke
from starutil import NDG
from starutil import msg_out


#  Assume for the moment that we will not be retaining temporary files.
retain = 0

#  A list of the extinction correction NDFs created by this script. These
#  are created and used in the current working directory, and are deleted
#  when the script exist.
new_ext_ndfs = []

#  A function to clean up before exiting. Delete all temporary NDFs etc,
#  unless the script's RETAIN parameter indicates that they are to be
#  retained. Also delete the script's temporary ADAM directory.
def cleanup():
   global retain, new_ext_ndfs
   try:
      starutil.ParSys.cleanup()
      if retain:
         msg_out( "Retaining EXT models in {0} and temporary files in {1}".format(os.getcwd(),NDG.tempdir))
      else:
         NDG.cleanup()
         for ext in new_ext_ndfs:
            os.remove( ext )
   except:
      pass

#  Catch any exception so that we can always clean up, even if control-C
#  is pressed.
try:

#  Declare the script parameters. Their positions in this list define
#  their expected position on the script command line. They can also be
#  specified by keyword on the command line. If no value is supplied on
#  the command line, the  user is prompted for a value when the parameter
#  value is first accessed within this script. The parameters "MSG_FILTER",
#  "ILEVEL", "GLEVEL" and "LOGFILE" are added automatically by the ParSys
#  constructor.
   params = []

   params.append(starutil.ParNDG("IN", "The input time series NDFs",
                                  starutil.get_task_par("DATA_ARRAY",
                                                        "GLOBAL",
                                                    default=starutil.Parameter.UNSET)))

   params.append(starutil.ParNDG("OUT", "The output map", default=None,
                                  exists=False, minsize=0, maxsize=1 ))

   params.append(starutil.Par0I("NITER", "No. of iterations to perform",
                                0, noprompt=True))

   params.append(starutil.Par0F("PIXSIZE", "Pixel size (arcsec)", None,
                                 maxval=1000, minval=0.01))

   params.append(starutil.Par0S("CONFIG", "Map-maker tuning parameters",
                                "^$STARLINK_DIR/share/smurf/dimmconfig.lis"))

   params.append(starutil.ParNDG("ITERMAP", "Output cube holding itermaps",
                                 default=None, exists=False, minsize=0,
                                 maxsize=1, noprompt=True ))

   params.append(starutil.ParNDG("REF", "The reference NDF", default=None,
                                 minsize=0, maxsize=1, noprompt=True ))

   params.append(starutil.ParNDG("MASK2", "The second mask NDF", default=None,
                                 minsize=0, maxsize=1, noprompt=True ))

   params.append(starutil.ParNDG("MASK3", "The third mask NDF", default=None,
                                 minsize=0, maxsize=1, noprompt=True ))

   params.append(starutil.Par0S("EXTRA", "Extra command-line options for MAKEMAP",
                                default=None, noprompt=True ))

   params.append(starutil.Par0L("RETAIN", "Retain temporary files?", False,
                                 noprompt=True))

   params.append(starutil.Par0S("RESTART", "Directory holding data from an interrupted run of skyloop",
                                default=None, noprompt=True ))

#  Initialise the parameters to hold any values supplied on the command
#  line. This automatically adds definitions for the additional parameters
#  "MSG_FILTER", "ILEVEL", "GLEVEL" and "LOGFILE".
   parsys = starutil.ParSys( params )

#  It's a good idea to get parameter values early if possible, in case
#  the user goes off for a coffee whilst the script is running and does not
#  see a later parameter prompt or error.
   restart = parsys["RESTART"].value
   if restart == None:
      retain = parsys["RETAIN"].value
   else:
      retain = True
      NDG.tempdir = restart
      NDG.overwrite = True
      msg_out( "Re-starting using data in {0}".format(restart) )

   indata = parsys["IN"].value
   outdata = parsys["OUT"].value
   niter = parsys["NITER"].value
   pixsize = parsys["PIXSIZE"].value
   config = parsys["CONFIG"].value
   ref = parsys["REF"].value
   mask2 = parsys["MASK2"].value
   mask3 = parsys["MASK3"].value
   extra = parsys["EXTRA"].value
   itermap = parsys["ITERMAP"].value

#  See if we are using pre-cleaned data, in which case there is no need
#  to export the cleaned data on the first iteration.
   if invoke( "$KAPPA_DIR/configecho name=doclean config={0} "
              "defaults=$SMURF_DIR/smurf_makemap.def "
              "select=\"\'450=0,850=1\'\" defval=1".format(config)) == 1:
      precleaned = False
   else:
      precleaned = True

#  If requested, use numiter from the config file. Arbitrarily choose 850 um
#  values for the waveband-specific parameters, but these are not actually used.
   if niter == 0:
      niter = int( invoke( "$KAPPA_DIR/configecho name=numiter config={0} "
                           "defaults=$SMURF_DIR/smurf_makemap.def "
                           "select=\"\'450=0,850=1\'\" defval=5".format(config)))

#  If iterating to convergence, get the maximum allowed normalised map
#  change between iterations, and set the number of iterations positive.
   if niter < 0:
      niter = -niter
      maptol = float( invoke( "$KAPPA_DIR/configecho name=maptol config={0} "
                           "defaults=$SMURF_DIR/smurf_makemap.def "
                           "select=\"\'450=0,850=1\'\" defval=0.05".format(config)))
   else:
      maptol = 0

   converged = False

#  Determine the value of the (AST,COM,FLT).ZERO_NITER, ZERO_NOTLAST and
#  ZERO_FREEZE parameters in the supplied config. We need to ensure that
#  appropriate changes are made to the values of these on each invocation
#  of makemap.
   zero_niter = {}
   zero_notlast = {}
   zero_freeze = {}
   for model in ["ast", "com", "flt"]:
      zero_niter[model] = int( invoke( "$KAPPA_DIR/configecho name={0}.zero_niter config={1} "
                                       "defaults=$SMURF_DIR/smurf_makemap.def "
                                       "select=\"\'450=0,850=1\'\"".format(model,config)))
      zero_notlast[model] = int( invoke( "$KAPPA_DIR/configecho name={0}.zero_notlast config={1} "
                                       "defaults=$SMURF_DIR/smurf_makemap.def "
                                       "select=\"\'450=0,850=1\'\"".format(model,config)))
      zero_freeze[model] = int( invoke( "$KAPPA_DIR/configecho name={0}.zero_freeze config={1} "
                                       "defaults=$SMURF_DIR/smurf_makemap.def "
                                       "select=\"\'450=0,850=1\'\"".format(model,config)))

#  The first invocation of makemap will create NDFs holding cleaned
#  time-series data and EXT model values. The NDFs are created with
#  hard-wired names and put in the current working directory. For
#  tidyness, we will move the cleaned data files into the NDG temp
#  directory, where all the other temp files are stored. In order to
#  distinguish NDFs created by this script from any pre-existing NDFs
#  - which we do not want to move, we now record the paths and
#  last-accessed times of any relevant pre-existing NDFs. Note, if the
#  "ext.import" config parameter is set, makemap expects EXT model
#  values to be in the current working directory, so we do not move
#  those NDFs to the NDG temp directory. Use last-accessed times rather
#  than inode numbers since something very strange seems to be happening
#  with inode numbers for NDFs created by the starutil module (two
#  succesive NDFs with the same path can have the same inode number).
   orig_cln_ndfs = {}
   for path in glob.glob("s*_con_res_cln.sdf"):
      orig_cln_ndfs[path] = os.stat(path).st_atime

#  Note any pre-existing NDFs holding extinction values.
   orig_ext_ndfs = {}
   for path in glob.glob("s*_con_ext.sdf"):
      orig_ext_ndfs[path] = os.stat(path).st_atime

#  On the first invocation of makemap, we use the raw data files specified
#  by the IN parameter to create an initial estimate of the sky. We also
#  save the cleaned time series data, and the EXT model (if we are doing
#  more than one iteration), for use on subsequent iterations (this speeds
#  them up a bit). First create a text file holding a suitably modified
#  set of configuration parameters. This file is put in the NDG temp
#  directory (which is where we store all temp files).
   conf0 = os.path.join(NDG.tempdir,"conf0") # Full path to new config file
   fd = open(conf0,"w")       # Open the new config file.
   fd.write("{0}\n".format(config)) # Inherit the supplied config parameter values.
   fd.write("numiter=1\n")    # MAKEMAP should do only one iteration.
   fd.write("itermap=0\n")    # Itermaps don't make sense
   fd.write("bolomap=0\n")    # Bolomaps don't make sense
   fd.write("shortmap=0\n")   # Shortmaps don't make sense
   fd.write("flagmap=<undef>\n")# Flagmaps don't make sense
   fd.write("sampcube=0\n")   # Sampcubes don't make sense
   fd.write("noi.calcfirst=1\n")# The NOI model is usually calculated after the
                              # first ieration, which is no use to use as
                              # we are only doing one iteration. So instead
                              # pre-calculate NOI before the iteration starts.
   if niter > 1:
      fd.write("exportNDF=ext\n")# Save the EXT model values to avoid
                                 # re-calculation on each invocation of makemap.
      fd.write("noexportsetbad=1\n")# Export good EXT values for bad bolometers
      if not precleaned:
         fd.write("exportclean=1\n")  # Likewise save the cleaned time-series data.

   fd.write("ast.zero_notlast = 0\n") # Masking is normally not performed
   fd.write("flt.zero_notlast = 0\n") # on the last iteration. But the first
   fd.write("com.zero_notlast = 0\n") # iteration is also the last iteration
                              # in our case, so force any enabled
                              # masking to be performed on the last iteration.
   fd.write("diag.append = 0\n") # Ensure a new diagnostics file is started
   fd.close()                 # Close the config file.

#  Get the name of a temporary NDF that can be used to store the first
#  iteration map. This NDF is put in the NDG temp directory. If we are
#  only doing one iteration, used the supplied output NDF name.
   if niter == 1:
      newmap = outdata
   else:
      newmap = NDG(1)
   prevmap = None

#  Start a list of these maps in case we are creating an output itermap cube.
   maps = []
   maps.append(newmap)

#  If we are restarting, check if the NDF already exists and is readable.
#  If so, we do not re-create it.
   msg_out( "Iteration 1...")
   gotit = False
   if restart != None:
      try:
         invoke("$KAPPA_DIR/ndftrace ndf={0} quiet=yes".format(newmap))
         msg_out( "Re-using existing map {0}".format(newmap) )
         gotit = True
      except:
         pass

#  If required, construct the text of the makemap command and invoke it.
   if not gotit:
      cmd = "$SMURF_DIR/makemap in={0} out={1} method=iter config='^{2}'".format(indata,newmap,conf0)
      if pixsize:
         cmd += " pixsize={0}".format(pixsize)
      if ref:
         cmd += " ref={0}".format(ref)
      if mask2:
         cmd += " mask2={0}".format(mask2)
      if mask3:
         cmd += " mask3={0}".format(mask3)
      if extra:
         cmd += " "+extra
      invoke(cmd)

#  Unless the supplied data was pre-cleaned, the NDFs holding the cleaned
#  time-series data will have been created by makemap in the current working
#  directory. Move them to the NDG temporary directory. Avoid moving any
#  other files that have similar names by checking each file inode number and
#  last-accessed time against the lists of inode numbers and times that
#  existed before makemap was run.
      if niter > 1:
         if not precleaned:
            for ndf in glob.glob("s*_con_res_cln.sdf"):
               if not ndf in orig_cln_ndfs:
                  shutil.move( ndf, NDG.tempdir )
               elif os.stat(ndf).st_atime > orig_cln_ndfs[ndf]:
                  shutil.move( ndf, NDG.tempdir )

#  Get a list of the extinction correction files created by the first
#  invocation of makemap.
         for ndf in glob.glob("s*_con_ext.sdf"):
            if not ndf in orig_ext_ndfs:
               new_ext_ndfs.append(ndf)
            elif os.stat(ndf).st_atime > orig_ext_ndfs[ndf]:
               new_ext_ndfs.append(ndf)

#  Get the paths to the the moved cleaned files.
   if niter > 1:
      if not precleaned:
         cleaned = NDG( os.path.join( NDG.tempdir,"s*_con_res_cln.sdf"))
      else:
         cleaned = indata

#  Now do the second and subsequent iterations. These use the cleaned
#  time-series data created by the first iteration as their time-series
#  input, and use the output map from the previous iteration as their
#  initial guess at the sky. First create a map holding things to add
#  to the config for subsequent invocations.
      add = {}
      add["exportNDF"] = 0     # Prevent EXT model being exported.
      add["exportclean"] = 0   # Prevent cleaned time-series data being exported.
      add["doclean"] = 0       # Do not clean the supplied data (it has
      add["importsky"] = "ref" # Get the initial sky estimate from the REF parameter.
      add["ext.import"] = 1    # Import the EXT model created by the first iteration.
      add["flt.notfirst"] = 0  # Ensure we use FLT on 2nd and subsequent invocations
      add["pln.notfirst"] = 0  # Ensure we use PLN on 2nd and subsequent invocations
      add["smo.notfirst"] = 0  # Ensure we use SMO on 2nd and subsequent invocations
      add["diag.append"] = 1   # Ensure we append diagnostics to the file
                               # created on the first iteration.

#  Now create the config, inheriting the config from the first invocation.
      iconf = 1
      confname = os.path.join(NDG.tempdir,"conf1")
      fd = open(confname,"w")
      fd.write("^{0}\n".format(conf0))# Inherit the first iteration config.
      for key in add:
         fd.write("{0}={1}\n".format( key, add[key] ))
      fd.close()

#  Indicate we do not need to create a new config file yet.
      newcon = 0

#  Get the name of an NDF in which to store the normalized map change
#  after each iteration.
      mapchange = NDG(1)

#  Now do the second and subsequent iterations.
      iter = 2
      while iter <= niter:
         msg_out( "Iteration {0}...".format(iter))

#  On this iteration we will want to use the output map from the previous
#  iteration as the initial guess at the sky. So copy the new map name over
#  to the "prevmap" variable.
         prevmap = newmap

#  When "zero_niter" invocations have been performed, switch off zero
#  masking (so long as zero_niter > 0).  Do this for AST, COM and FLT
#  models.
         for model in ["ast", "com", "flt"]:
            if zero_niter[model] > 0 and iter > zero_niter[model]:
               zero_niter[model] = 0
               add[ model+".zero_niter" ] = -1
               newcon = 1

#  When "zero_freeze" invocations have been performed, switch freeze the
#  mask (so long as zero_freeze > 0).  Do this for AST, COM and FLT models.
         for model in ["ast", "com", "flt"]:
            if zero_freeze[model] > 0 and iter > zero_freeze[model] + 1:
               zero_freeze[model] = 0
               add[ model+".zero_freeze" ] = -1
               newcon = 1

#  If this is the last iteration, put the output map in the NDF specified
#  by the script's "OUT" parameter.
         if iter == niter:
            newmap = outdata

#  Also, if this is the last iteration, create a modified configuration file
#  that supresses masking (unless the xxx.zero_notlast value in the
#  supplied config indicates otjerwise).
            for model in ["ast", "com", "flt"]:
               if zero_notlast[model] != 0:
                  add["ast.zero_notlast"] = 1
                  newcon = 1

#  If this is not the last iteration, get the name of a temporary NDF that
#  can be used to store the current iteration's map. This NDF is put in
#  the NDG temp directory.
         else:
            newmap = NDG(1)

#  If required, create a new config file.
         if newcon:
            newcon = 0
            iconf += 1
            confname = os.path.join(NDG.tempdir,"conf{0}".format(iconf))
            fd = open(confname,"w")
            fd.write("^{0}\n".format(conf0))# Inherit the first iteration config.
            for key in add:
               fd.write("{0}={1}\n".format( key, add[key] ))
            fd.close()

#  See if the output NDF already exists.
         gotit = False
         if restart != None:
            try:
               invoke("$KAPPA_DIR/ndftrace ndf={0} quiet=yes".format(newmap))
               msg_out( "Re-using existing map {0}".format(newmap) )
               gotit = True
            except:
               pass

#  If required, construct the text of the makemap command and invoke it. We
#  specify the map from the previous iteration as the REF image.
         if not gotit:
            cmd = "$SMURF_DIR/makemap in={0} out={1} method=iter config='^{2}' ref={3}"\
                  .format(cleaned,newmap,confname,prevmap)
            if pixsize:
               cmd += " pixsize={0}".format(pixsize)
            if mask2:
               cmd += " mask2={0}".format(mask2)
            if mask3:
               cmd += " mask3={0}".format(mask3)
            if extra:
               cmd += " "+extra
            invoke(cmd)

#  If required, get the mean normalised map change, and see if it has
#  dropped below maptol. If so, we must do one further iteration to
#  ensure that the masking is not visible in the final map.
         invoke("$KAPPA_DIR/maths exp=\"'abs(ia-ib)/sqrt(va)'\" ia={0} "
                "ib={1} out={2}".format(newmap,prevmap,mapchange))
         invoke("$KAPPA_DIR/stats ndf={0} clip=\\[3,3,3\\] quiet".format(mapchange))
         meanchange = starutil.get_task_par( "mean", "stats" )
         if maptol > 0.0 and converged == False:
            msg_out( "Normalised mean change in map = {0} (maptol="
                     "{1})".format(meanchange,maptol) )
            if meanchange <= maptol:
               msg_out( "Converged! But we need to do one more iteration..." )
               converged = True
               niter = iter + 1
         else:
            msg_out( "Normalised mean change in map = {0}".format(meanchange) )


#  Append the output map name to the list of maps to be included in any
#  itermap cube.
         maps.append(newmap)

#  Increment the iteration number
         iter += 1

#  Report convergence failure.
   if maptol > 0.0 and not converged:
        msg_out("Map did not converge.")

#  Now we have done all iterations, create the output itermap cube if
#  required.
   if itermap and niter > 1:
      msg_out( "Creating output itermap cube {0}...".format(itermap) )
      inputs = NDG( maps )
      invoke("$KAPPA_DIR/paste in={0} out={1} shift=\[0,0,1\]".format(inputs,itermap) )

#  Since no masking is done on the final iteration, the output map will
#  not currently contain a quality array. If the previous iteration has a
#  quality component copy it to the last iteration, and set bad bits to
#  zero. This is to provide a record of the final used mask.
   if prevmap != None:
      try:
         invoke("$HDSTOOLS_DIR/hcopy inp={0} out={1}".format(prevmap,newmap) )
      except starutil.StarUtilError as err:
         pass
   if niter > 1 : invoke("$KAPPA_DIR/setbb ndf={0} bb=0".format(newmap) )

#  Remove temporary files.
   cleanup()


#  If an StarUtilError of any kind occurred, display the message but hide the
#  python traceback. To see the trace back, uncomment "raise" instead.
except starutil.StarUtilError as err:
#  raise
   print( err )
   print( "\n\nskyloop ended prematurely so intermediate files are being retained in {0}.".format(NDG.tempdir) )
   print( "It may be possible to re-started skyloop using the RESTART parameter.\n" )

# This is to trap control-C etc, so that we can clean up temp files.
except:
   print( "\n\nskyloop ended prematurely so intermediate files are being retained in {0}.".format(NDG.tempdir) )
   print( "It may be possible to re-started skyloop using the RESTART parameter.\n" )
   raise

