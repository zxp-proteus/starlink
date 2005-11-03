#!/bin/csh -x
#+

#  Name:
#     velmap.csh

#  Purpose:
#     Builds a velocity map of an emission line from a three-dimensional IFU
#     NDF.

#  Type of Module:
#     C-shell script.

#  Usage:
#     velmap [-c number] [-f] [-i filename] [-o filename] [-p] [-r number] 
#            [-s system] [-v] [-z/+z]

#  Description:
#     This shell script sits onto of a collection of A-tasks from the KAPPA
#     and FIGARO packages.  It reads a three-dimensional IFU NDF as input
#     and presents you with a white-light image of the cube.  You can
#     then select and X-Y position using the cursor.  The script will extract
#     and display this spectrum.  You will then be prompted to specify various
#     fitting parameters, such as the peak position, using the cursor.  The
#     script will then attempt to fit the emission line.  The fit will be
#     displayed and you are consulted regarding the goodness of fit.  If
#     you consider the fit good enough, the script will attempt to perform
#     similar fits to all spectra within the cube, building a two-dimensional
#     NDF image of the velocity of the line.

#     If you do not force the fit to be considered "good" by using the -f
#     command-line option, the script will offer the opportunity to manually
#     refit the spectral feature for individual pixels, such as those that
#     were not fitted by the automatic procedure.

#  Parameters:
#     -c number
#       Number of contours in the white-light image.  [15]
#     -f
#       Force the script to accept the first attempt to fit a Gaussian to
#       the line. This is a dangerous option, if the fit is poor, or
#       unobtainable the script may terminate abruptly if it is forced to
#       accept the fit.  Additionally this will suppress manual re-fitting 
#       of bad pixels at the end of the run of the script. [FALSE] 
#     -i filename
#       The script will use this as its input file, the specified file should
#       be a three-dimensional NDF.  By default the script will prompt for the
#       input file.
#     -o filename
#       The filename for the output NDF of the velocity map.
#     -p
#       The script will plot the final image map to the current display 
#       as well as saving it to an NDF file.  Additionally it will over-
#       plot the white-light image as a contour map for comparison.  [FALSE]
#     -r number
#       Rest-frame spectral unit of the line being fitted.
#     -s system
#       The co-ordinate system for velocities.  Allowed values are:
#          "VRAD" -- radio velocity;
#          "VOPT" -- optical velocity;
#          "ZOPT" -- redshift; and
#          "VELO" -- relativistic velocity.
#       If you supply any other value, the default is used.  ["VOPT"]
#     -v
#       The script will generate a variance array from the line fits and
#       attach it to the velocity-map NDF.  [FALSE]
#     -z 
#       The script will automatically prompt to select a region to zoom
#       before prompting for the region of interest.  [TRUE]
#     +z 
#       The program will not prompt for a zoom before requesting the region
#       of interest.  [FALSE]

#  Authors:
#     AALLAN: Alasdair Allan (Starlink, Keele University)
#     MJC: Malcolm J. Currie (Starlink, RAL)
#     {enter_new_authors_here}

#  History:
#     04-SEP-2000 (AALLAN):
#       Original version.
#     06-SEP-2000 (AALLAN):
#       Heavy modifications.
#     13-SEP-2000 (AALLAN):
#       Rewritten on the train.
#     18-SEP-2000 (AALLAN):
#       Major rewrite to make full use of parameter system.
#     19-SEP-2000 (AALLAN):
#       Moved from using bc to using KAPPA calc for some calculations.
#     31-OCT-2000 (AALLAN):
#       Fixed some bugs.
#     05-NOV-2000 (AALLAN):
#       Added variance arrays.
#     09-NOV-2000 (AALLAN):
#       Changed input method of inputing the continuum measurement.
#     10-NOV-2000 (AALLAN):
#       Added bad fit check, modified plot colour for contour lines.
#     12-NOV-2000 (AALLAN):
#       Modified to work under Solaris 5.8, problems with bc and csh.
#     20-NOV-2000 (AALLAN):
#       Incorporated changes made to source at ADASS.
#     23-NOV-2000 (AALLAN):
#       Added lots of command line options.
#       Added interrupt handling.
#     13-DEC-2000 (AALLAN):
#       Added manual refitting of bad data values
#     31-DEC-2000 (AALLAN):
#       Allowed 1 character responses to yes/no prompts
#     08-JAN-2001 (AALLAN):
#       Variance calculation made more robust
#       Fixed bug in magic value propogation
#       Major bug in manual refitting routine fixed
#     18-OCT-2001 (AALLAN):
#       Modified temporary files to use ${tmpdir}/${user}
#     2005 September 1 (MJC):
#       Replaced COPYAXIS with KAPPA:SETAXIS.
#     2005 September 2 (MJC):
#       Replaced PUTAXIS with KAPPA:SETAXIS in WCS mode.  Some tidying:
#       remove tabs, spelling corrections.  Added section headings in the
#       code.  Replace explicit wavelength in prompts with the current WCS
#       Frame's label for the spectral axis, and also used the corresponding
#       units in the output commentary.  Avoid :r.
#     2005 September 7 (MJC):
#       Convert the current WCS System into velocities.
#     2005 October 11 (MJC):
#       Added PARGET calls to access velocities and sent wcstran output to 
#       dev/null. Added -c option for contour levels.  Fixed bugs converting
#       the cursor position into negative pixel indices.  Ensured that the
#       plots of spectra use the axis co-ordinate system.  Called KAPPA:CALC
#       for floating-point arithmetic using appropriate precision, and ensure
#       a digit before a decimal point, unlike bc.  Plot spectra in histogram
#       mode for clarity.  Added defaults to parameter descriptions.
#       Appended data unit to reported peak values.  Inserted blank lines to
#       structure the commentary better.  Correct some output and comments: 
#       e.g. "spectra" singular to "spectrum".
#     2005 October 21 (MJC):
#       Test for existence of RestFreq, and use it where available instead
#       of prompting the user.  Remove second prompt for Rest-frame 
#       co-ordinate.  Ensure that the output velocities are in km/s.  
#       Added -s option.  Align some commentary.  WCSTRAN calls for fixing
#       individual pixels now uses the correct NDF.  Bug deriving the 
#       velocity of refitted point corrected, by resetting the WCS Frame,
#       System and Unit before transforming.
#     2005 November 1 (MJC):
#       Allow for UK data-cube format by creating a SPECTRUM Frame
#       with a Wavelength system and Angstrom units in the extracted
#       spectra; reset unclear labels to Wavelength.  For other cubes, search
#       for the SPECTRUM-domain Frame and select it in the extracted spectra,
#       if SPECTRUM is not already the current WCS Frame.  Assign Angstrom to
#       the spectral unit, if this is is not specified.  The prompt for the
#       rest-frame co-ordinate now includes the unit.
#     {enter_further_changes_here}

#  Copyright:
#     Copyright (C) 2000-2005 Central Laboratory of the Research Councils

#-

# Preliminaries
# =============

# On interrupt tidy up.
onintr cleanup

# Get the user name.
set user = `whoami`
set tmpdir = "/tmp"

# Clean up from previous runs.
rm -f ${tmpdir}/${user}/vmap* >& /dev/null
rm -f ${tmpdir}/${user}/?_?.sdf >& /dev/null

# Do the variable initialisation.
mkdir ${tmpdir}/${user} >& /dev/null
set curfile = "${tmpdir}/${user}/vmap_cursor.tmp"
set fitfile = "${tmpdir}/${user}/vmap_fitgauss.tmp"
set colfile = "${tmpdir}/${user}/vmap_col"
set ripfile = "${tmpdir}/${user}/vmap_rip"
set mapfile = "${tmpdir}/${user}/vmap_map.dat"
set varfile = "${tmpdir}/${user}/vmap_var.dat"

touch ${curfile}

# Set options access flags.
set plotspec = "FALSE"
set dovar = "FALSE"
set gotinfile = "FALSE"
set gotoutfile = "FALSE"
set gotzoom = "ASK"
set gotrest = "FALSE"
set forcefit = "FALSE"

# The SPECDRE extension is used to store the Gaussian fit.
set component = 1

# Specify the number of contours used to display the white-light image.
set numcont = 15

# Other defaults.
set plotdev = "xwin"
set fitgood = "yes"
set velsys = "VOPT"
set vunits = "km/s"

# Invoke the package setup.
alias echo 'echo > /dev/null'
source ${DATACUBE_DIR}/datacube.csh
unalias echo

# Handle any command-line arguements.
set args = ($argv[1-])
while ( $#args > 0 )
   switch ($args[1])
   case -c:    # Number of contours
      shift args
      set numcont = $args[1]
      if ( $numcont < 1 || $numcont > 100 ) then
         set numcont = 15
      endif
      shift args
      breaksw
   case -f:    # force fit?
      set forcefit = "TRUE"
      shift args
      breaksw                             
   case -i:    # input three-dimensional IFU NDF
      shift args
      set gotinfile = "TRUE"
      set infile = $args[1]
      shift args
      breaksw
   case -o:    # output velocity map
      shift args
      set gotoutfile = "TRUE"
      set outfile = $args[1]
      shift args
      breaksw
   case -p:    # plot output spectra
      set plotspec = "TRUE"
      set plotdev = "${plotdev}"
      shift args
      breaksw
   case -r:    # rest-frame spectral-unit of line
      shift args
      set gotrest = "TRUE"
      set rest_coord = $args[1]
      shift args
      breaksw
   case -s:    # velocity co-ordinate system
      shift args
      set velsys = `echo $args[1] | awk '{print toupper($0)}'`
      if ( $velsys != "VOPT" && $velsys != "VRAD" && \
           $velsys != "ZOPT" && $velsys != "VELO" ) set velsys = "VOPT"
      shift args
      breaksw
   case -v:    # generate variances?
      set dovar = "TRUE"
      shift args
     breaksw 
   case -z:    # zoom?
      set gotzoom = "TRUE"
      shift args
      breaksw 
   case +z:    # not zoom?
      set gotzoom = "FALSE"
      shift args
      breaksw 
   endsw  
end

# Obtain details of the input cube.
# =================================

# Get the input filename.
if ( ${gotinfile} == "FALSE" ) then
   echo -n "NDF input file: "
   set infile = $<
   set infile = ${infile:r}
endif

echo " "

echo "      Input NDF:"
echo "        File: ${infile}.sdf"

# Check that it exists.
if ( ! -e ${infile}.sdf ) then
   echo "VELMAP_ERR: ${infile}.sdf does not exist."
   rm -f ${curfile} >& /dev/null
   exit  
endif

# Find out the cube dimensions.
ndftrace ${infile} >& /dev/null
set ndim = `parget ndim ndftrace`
set dims = `parget dims ndftrace`
set lbnd = `parget lbound ndftrace`
set ubnd = `parget ubound ndftrace`
set unit = `parget units ndftrace`

if ( $ndim != 3 ) then
   echo "VELMAP_ERR: ${infile}.sdf is not a datacube."
   rm -f ${curfile} >& /dev/null
   exit  
endif

set bnd = "${lbnd[1]}:${ubnd[1]}, ${lbnd[2]}:${ubnd[2]}, ${lbnd[3]}:${ubnd[3]}"
@ pixnum = $dims[1] * $dims[2] * $dims[3]

# Report the statistics.
echo "      Shape:"
echo "        No. of dimensions: ${ndim}"
echo "        Dimension size(s): ${dims[1]} x ${dims[2]} x ${dims[3]}"
echo "        Pixel bounds     : ${bnd}"
echo "        Total pixels     : $pixnum"
echo " "

# Check to see if the NDF has VARIANCE.
set variance = `parget variance ndftrace`

# Show the white-light image.
# ===========================

# Collapse the white-light image.
echo "      Collapsing:"
echo "        White-light image: ${dims[1]} x ${dims[2]}"
collapse "in=${infile} out=${colfile} axis=3" >& /dev/null 

# Display the collapsed image.
gdclear device=${plotdev}
paldef device=${plotdev}
lutgrey device=${plotdev}
display "${colfile} device=${plotdev} mode=SIGMA sigmas=[-3,2]" >&/dev/null 

# Determine if we need to create or select a SPECTRUM-domain WCS Frame.
# =====================================================================

# Get the spectral label and units.
set slabel = `wcsattrib ndf=${infile} mode=get name="Label(3)"`
set sunits = `wcsattrib ndf=${infile} mode=get name="Unit(3)"`

# Check that the current frame is SPECTRUM or SKY-SPECTRUM.   We can re-use
# the last trace of the ripped spectrum.
set change_frame = "FALSE"
set curframe = `parget current ndftrace`
set domain = `parget fdomain"($curframe)" ndftrace`
if ( "$domain" != "SPECTRUM" && "$domain" != "SKY-SPECTRUM" ) then
   set change_frame = "TRUE"
endif

# Next question: is there a SPECTRUM frame to switch to in order to
# permit velocity calculations?  Loop through all the WCS Frames, looking
# for a SPECTRUM (or composite SKY-SPECTRUM).
set create_specframe = "FALSE"
if ( $change_frame == "TRUE" ) then
   set create_specframe = "TRUE"
   set nframe = `parget nframe ndftrace`
   set i = 1
   while ( $i <= $nframe && $create_specframe == "TRUE" )
      set domain = `parget fdomain"($i)" ndftrace`
      if ( "$domain" == "SPECTRUM" || "$domain" == "SKY-SPECTRUM" ) then
         set $create_specframe = "FALSE"
      endif
      @ i++
   end

# We need to create a WCS SPECTRUM domain, and hence not change frame.
   if ( "$create_specframe" == "TRUE" ) then
      set $change_frame = "FALSE"

# Check for the old-fashioned UK data-cube format that predates the
# SpecFrame.  Test for non-null units if there is no SpecFrame.  Set the
# label to something clearer than LAMBDA or Axis 3.
      if ( "${slabel}" == "LAMBDA" || "${slabel}" == "Axis 3" ) then
         set slabel = "Wavelength"
         if ( "$sunits" == "" ) then
            set sunits = "Angstrom"
         endif
      else
         echo " "
         echo "The input NDF does not have an SPECTRUM WCS Domain or it is not "
         echo "in the UK data-cube format.  Will convert the current frame to a "
         echo "SPECTRUM of type wavelength to calculate velocities."      
         echo " "

         if ( "$sunits" == "" ) then
            echo "Assuming that the undefined unit is Angstrom."
            set sunits = "Angstrom"
         endif
      endif
   endif
endif

# Obtain the spatial position of the spectrum graphically.
# ========================================================

# Grab the X-Y position.
echo " "
echo "  Left click on pixel to be extracted."
   
cursor showpixel=true style="Colour(marker)=2" plot=mark \
       maxpos=1 marker=2 device=${plotdev} frame="PIXEL" >> ${curfile}

# Wait for CURSOR output then get X-Y co-ordinates from 
# the temporary file created by KAPPA:CURSOR.
while ( ! -e ${curfile} ) 
   sleep 1
end

# We don't clean up the collapsed white-light image here as normal because
# it will be used later to clone both the AXIS and WCS co-ordinates for the
# new velocity map.

# Grab the spatial position.
set pos = `parget lastpos cursor | awk '{split($0,a," ");print a[1], a[2]}'`

# Get the pixel co-ordinates and convert to grid indices.  The
# exterior NINT replaces the bug/feature -0 result with the desired 0.
set xpix = `calc exp="nint(nint($pos[1]+0.5))" prec=_REAL`
set ypix = `calc exp="nint(nint($pos[2]+0.5))" prec=_REAL`

# Clean up the CURSOR temporary file.
rm -f ${curfile} >& /dev/null
touch ${curfile}

# Extract the spectrum.
# =====================

echo " "
echo "      Extracting:"
echo "        (X,Y) pixel: ${xpix},${ypix}"

# Extract the spectrum from the cube.
ndfcopy "in=${infile}($xpix,$ypix,) out=${ripfile} trim=true trimwcs=true"

# Check to see if the NDF has an AXIS structure.  If one does not exist,
# create an array of axis centres, derived from the current WCS Frame,
# along the axis.
set axis = `parget axis ndftrace`

if ( ${axis} == "FALSE" ) then
   setaxis "ndf=${ripfile} dim=1 mode=wcs comp=Centre" >& /dev/null
   echo "        Axes: Adding AXIS centres."
endif

# To compare like with like ensure, that plotting uses the AXIS frame.
wcsframe "ndf=${ripfile} frame=axis"

# Specify the units, in case these weren't know originally.
axunits "ndf=${ripfile} units=${sunits}" >& /dev/null

# Obtain the precision of the axis centres.
# Assuming this is only _REAL or _DOUBLE.
ndftrace ${ripfile} fullaxis >& /dev/null
set prec = `parget atype ndftrace`

if ( ${variance} == "FALSE" ) then
   echo "        Variances: present."
else
   echo "        Variances: absent."
endif

# Label for repeated fitting of the Gaussian.
refit:

# Obtain the spectral range interactively.
# ========================================

# Plot the ripped spectrum.
linplot "${ripfile} device=${plotdev}" mode=histogram \
        style="Colour(curves)=1" >& /dev/null

# Zoom if required.
if ( ${gotzoom} == "ASK") then
   echo " "
   echo -n "Zoom in (yes/no): "
   set zoomit = $<
else if ( ${gotzoom} == "TRUE") then
   set zoomit = "yes"
else
   set zoomit = "no"
endif

if ( ${zoomit} == "yes" || ${zoomit} == "y" ) then

# Get the lower limit.
# --------------------
   echo " "
   echo "  Left click on lower zoom boundary."
   
   cursor showpixel=true style="Colour(curves)=3" plot=vline \
          maxpos=1 device=${plotdev} >> ${curfile}
   while ( ! -e ${curfile} ) 
      sleep 1
   end
   set pos = `parget lastpos cursor`
   set low_z = $pos[1]

# Clean up the CURSOR temporary file.
   rm -f ${curfile} >& /dev/null
   touch ${curfile}

# Get the upper limit.
# --------------------
   echo "  Left click on upper zoom boundary."
   
   cursor showpixel=true style="Colour(curves)=3" plot=vline \
          maxpos=1 device=${plotdev} >> ${curfile}
   while ( ! -e ${curfile} ) 
      sleep 1
   end
   set pos = `parget lastpos cursor`
   set upp_z = $pos[1]

   echo " "
   echo "      Zooming:"
   echo "        Lower Boundary: ${low_z}"
   echo "        Upper Boundary: ${upp_z}"

# Clean up the CURSOR temporary file.
   rm -f ${curfile} >& /dev/null
   touch ${curfile}

# Label for repeated plotting of the spectrum.
rezoom:
 
# Replot the spectrum.
# --------------------
   linplot ${ripfile} xleft=${low_z} xright=${upp_z} \
           mode=histogram device=${plotdev} >& /dev/null
endif

# Grab the information needed by the FITGAUSS routine.
# ====================================================

# Get the lower mask boundary.
# ----------------------------

echo " "
echo "  Left click on the lower limit of the fitting region."
   
cursor showpixel=true style="Colour(curves)=2" plot=vline \
       maxpos=1 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
while ( ! -e ${curfile} ) 
   sleep 1
end

# Grab the position.
set pos = `parget lastpos cursor`
set low_mask = $pos[1]

# Clean up the CURSOR temporary file.
rm -f ${curfile} >& /dev/null
touch ${curfile}
 
# Get the upper mask boundary.
# ----------------------------

echo "  Left click on the upper limit of the fitting region."

cursor showpixel=true style="Colour(curves)=2" plot=vline \
       maxpos=1 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
while ( ! -e ${curfile} ) 
   sleep 1
end

# Grab the position.
set pos = `parget lastpos cursor`
set upp_mask = $pos[1]

echo " " 
echo "      Fit Mask:"
echo "        Lower Mask Boundary: ${low_mask}"
echo "        Upper Mask Boundary: ${upp_mask}"

# Clean up the CURSOR temporary file.
rm -f ${curfile} >& /dev/null
touch ${curfile}

# Get the continuum values.
# -------------------------

echo " "
echo "  Left click on your first estimate of the continuum."

cursor showpixel=true style="Colour(curves)=4" plot=hline \
       maxpos=1 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
while ( ! -e ${curfile} ) 
   sleep 1
end

# Grab the position.
set pos = `parget lastpos cursor`
set first_cont = $pos[2]

echo "  Left click on your second estimate of the continuum."

cursor showpixel=true style="Colour(curves)=4" plot=hline \
       maxpos=1 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
while ( ! -e ${curfile} ) 
   sleep 1
end

# Grab the position.
set pos = `parget lastpos cursor`
set second_cont = $pos[2]

echo " "
echo "      Continuum:"
echo "        First Estimate: ${first_cont}"
echo "        Second Estimate: ${second_cont}"

# Evaluate the average continuum.
set cont = `calc exp="0.5*((${first_cont})+(${second_cont}))" prec=${prec}`
#set cont = `echo "${first_cont}+${second_cont}" | bc`
#set scale = `echo "${cont}/2.0" | bc`
#set remainder = `echo "${cont}%2.0" | bc`
#set cont = `echo "${scale}+${remainder}" | bc`

echo "        Average Value: ${cont}"

# Get the line-peak position.
# ---------------------------

echo " " 
echo "  Left click on the line peak."

cursor showpixel=true style="Colour(marker)=3" plot=mark \
       maxpos=1 marker=2 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
while ( ! -e ${curfile} ) 
   sleep 1
end

# Grab the position.
set pos = `parget lastpos cursor`
set position = $pos[1]
set peak = $pos[2]

echo " "
echo "      Line Position:"
echo "        Peak Position: ${position} ${sunits}"
echo "        Peak Height: ${peak} ${unit}"

# Clean up the CURSOR temporary file.
rm -f ${curfile} >& /dev/null
touch ${curfile}

# Get the fwhm left side.
# -----------------------

echo " " 
echo "  Left click on the left-hand edge of the FWHM."

cursor showpixel=true style="Colour(marker)=3" plot=mark \
       maxpos=1 marker=2 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
while ( ! -e ${curfile} ) 
   sleep 1
end

# Grab the position.
set pos = `parget lastpos cursor`
set fwhm_low = $pos[1]

# Clean up the CURSOR temporary file.
rm -f ${curfile} >& /dev/null
touch ${curfile}

# Get the fwhm right side.
# ------------------------

echo "  Left click on the right-hand edge of the FWHM."
echo " "

cursor showpixel=true style="Colour(marker)=3" plot=mark \
       maxpos=1 marker=2 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
while ( ! -e ${curfile} ) 
   sleep 1
end

# Grab the position.
set pos = `parget lastpos cursor`
set fwhm_upp = $pos[1]

echo "      FWHM:"
echo "        Lower Bound: ${fwhm_low}"
echo "        Upper Bound: ${fwhm_upp}"

# Clean up the CURSOR temporary file.
rm -f ${curfile} >& /dev/null
touch ${curfile}

# Evaluate the fwhm.
# ------------------

set fwhm = `calc exp="(${fwhm_upp})-(${fwhm_low})" prec=${prec}`
echo "        FWHM: ${fwhm}"
echo " "

# Fit the line.
# =============

echo "      Fitting:"

fitgauss \
    "in=${ripfile} mask1=${low_mask} mask2=${upp_mask} cont=${cont} " \
    "peak=${peak} fwhm=${fwhm} reguess=no remask=no ncomp=1 cf=0 " \
    "pf=0 wf=0 comp=${component} fitgood=${fitgood} dialog=f " \
    "centre=${position} logfil=${fitfile} device=${plotdev}" >& /dev/null 

# Check to see whether or not fitting was successful.
if ( ! -e $fitfile ) then
   echo "        No fit available"
   echo ""
   echo -n "Refit (yes/no): "
   set fitgood = $<
   echo " "
   if ( ${fitgood} == "no" || ${fitgood} == "n" ) then
      rm -f ${fitfile} >& /dev/null
      goto cleanup 
   else
      if ( ${zoomit} == "yes" || ${zoomit} == "y" ) then
         goto rezoom
      else
         goto refit
      endif 
   endif
endif

# Read the fit from the temporary file.
set results = `cat ${fitfile} | head -n 23 | tail -1`
set array = \
   `echo $results | awk '{split($0,a," "); for(i=1; i<10; i++) print a[i]}'`

set centre_fit = $array[2]
set centre_err = $array[3]
set peak_height = $array[4]
set peak_err = $array[5]
set fwhm_fit = $array[6]
set fwhm_err = $array[7]
set integral = $array[8]
set integral_err = $array[9]

# Report the fit to the user.
echo "        Centre Position: ${centre_fit} +- ${centre_err} ${sunits}"
echo "        Peak Height: ${peak_height} +- ${peak_err} ${unit}"
echo "        FWHM: ${fwhm_fit} +- ${fwhm_err} ${sunits}"
echo "        Line integral: ${integral} +- ${integral_err} ${unit}"

# Fit ok?
echo " "

if ( ${forcefit} == "FALSE" ) then
   echo -n "Fit ok? (yes/no): "
   set fitgood = $<
   echo " "
else
   set fitgood = yes
endif

if ( ${fitgood} == "no" || ${fitgood} == "n" ) then
   rm -f ${fitfile} >& /dev/null
   if ( ${zoomit} == "yes" || ${zoomit} == "y" ) then
      goto rezoom
   else
      goto refit
   endif
else
   rm -f ${fitfile} >& /dev/null
endif

# Obtain the rest-frame co-ordinate.
# ==================================
set rest_known = "FALSE"
if ( ${gotrest} == "FALSE" ) then

# Get the rest-frame value.  There is at the time of writing no
# clean way to test whether or not this was successful.  So search the
# possible error message.
   set astat = `wcsattrib "ndf=${infile} mode=get name=RestFreq"`
   set found = `echo $astat | awk '{if (index( $0, "bad attribute")>0 ) print "Bad"}'`
   if ( $found == "Bad" ) then
      echo -n "Rest ${slabel} ($sunits): "
      set rest_coord = $<
      echo " "
   else

# Obtain the rest frequency in Ghz.  Note that the value is already
# stored in the WCS attributes.
      set rest_coord = `parget value wcsattrib`
      set slabel = "Frequency"
      set sunits = "GHz"
      set rest_known = "TRUE"
   endif

endif

echo "      Rest ${slabel}" ":"
echo "        ${slabel}" " : ${rest_coord} ${sunits}"
echo " "

# Loop through the entire datacube.
# =================================

# Create a couple of results files.
touch ${mapfile}
touch ${varfile}

# Start at the origin.
set x = 0
@ x = $x + $lbnd[1]
set y = 0
@ y = $y + $lbnd[2]

set line = ""
set vars = ""

# Setup output filename.
if ( ${gotoutfile} == "FALSE" ) then
   echo -n "NDF output file: "
   set outfile = $<
   echo " "
endif

date > ${tmpdir}/${user}/vmap_time.dat 

# Fit the cube in a similar fashion.
echo "      Fitting:"
while( $y <= ${ubnd[2]} )
   while ( $x <= ${ubnd[1]} )
      
# Extract the spectrum at the current spatial position.
      set specfile = "${tmpdir}/${user}/s${x}_${y}"
      ndfcopy "in=${infile}($x,$y,) out=${specfile}" \
              "trim=true trimwcs=true"

# Create a SpecFrame if one is not present, and make it the current
# frame.  At present the earlier test for a missing SpecFrame only
# occurs for a UK data-cube format with LAMBDA as the label, so the
# system is wavelength and units Angstrom.
      if ( $create_specframe == "TRUE" ) then
         wcsadd ndf=${specfile} frame=axis maptype=unit frmtype=spec \
                domain=SPECTRUM attrs="'System=wave,Unit=Angstrom'" >& /dev/null

# The spectrum has a SPECTRUM domain WCS Frame, so select it for
# velocity calculations.
      else if ( $change_frame == "TRUE" ) then
         wcsframe "ndf=${specfile} frame=SPECTRUM" >& /dev/null
      endif

# Specify the units, in case these weren't know originally.
      axunits "ndf=${ripfile} units=${sunits}" >& /dev/null

# Fit the Gaussian to the spectrum.
      fitgauss \
        "in=${specfile} mask1=${low_mask} mask2=${upp_mask} "\
        "cont=${cont} peak=${peak} fwhm=${fwhm} reguess=no remask=no "\
        "ncomp=1 cf=0 pf=0 wf=0 comp=${component} fitgood=${fitgood} "\
        "centre=${position} logfil=${fitfile} device=! "\
        "dialog=f" >& /dev/null

      if ( -e $fitfile ) then
         set results = `cat ${fitfile} | head -n 23 | tail -1`
         set array = \
      `echo $results | awk '{split($0,a," "); for(i=1; i<10; i++) print a[i]}'`

# Store the results.
         set centre_fit = $array[2]
         set centre_err = $array[3]
         set peak_height = $array[4]
         set peak_err = $array[5]
         set fwhm_fit = $array[6]
         set fwhm_err = $array[7] 
         set integral = $array[8]
         set integral_err = $array[9]

# Something has gone wrong.  Store a null value for this fit.
         set condition = `echo "if ($peak_height < 0) 1" | bc`
         if ( $condition == 1 ) then
            echo "        Spectrum at ($x,$y)"
            set line = "${line} -9999.99"  
            if ( ${dovar} == "TRUE" ) then
               set vars = "${vars} -9999.99"  
            endif  
         else
            echo "        Spectrum at ($x,$y): $centre_fit +- $centre_err ${sunits}" 

# Set the rest-frame value, if it's not already stored in the WCS
# attributes.  For this to work the current WCS Frame must be a
# SpecFrame.  At present there is no test.
            if ( ${rest_known} == "FALSE" ) then
               wcsattrib "ndf=${specfile} mode=set name=RestFreq "\
                         "newval='${rest_coord} ${sunits}'" >& /dev/null
            endif

# Reset the System of the current WCS Frame to velocities in the desired 
# system and units.
            wcsattrib "ndf=${specfile} mode=set name=System newval=${velsys}"
            wcsattrib "ndf=${specfile} mode=set name=Unit newval=${vunits}"

# Convert the line-centre position to optical velocity.
            wcstran "ndf=${specfile} posin=${centre_fit} framein=AXIS " \
                    "frameout=SPECTRUM" >& /dev/null
            set velocity = `parget posout wcstran`

            if ( ${dovar} == "TRUE" ) then
               echo -n "                           $velocity" 
            else
               echo "                           $velocity $vunits" 
            endif

            set line = "${line} ${velocity}"

# Calculate the error.
            if ( ${dovar} == "TRUE" ) then
               if ( ${centre_err} == "nan" || ${centre_err} == "INF" ) then

# Set variance to a null value.
                  echo " ${vunits}"
                  set vars = "${vars} -9999.99"
               else

# Convert the upper error bound position to optical velocity.
                  set upp_err = \
                    `calc exp="'${centre_fit} + ${centre_err}'" prec=_double`
                  wcstran "ndf=${specfile} posin=${upp_err} framein=AXIS " \
                          "frameout=SPECTRUM" >& /dev/null
                  set upp_vel = `parget posout wcstran`

                               
                  set low_err = \
                    `calc exp="'${centre_fit} - ${centre_err}'" prec=_double`
                  wcstran "ndf=${specfile} posin=${low_err} framein=AXIS " \
                          "frameout=SPECTRUM" >& /dev/null
                  set low_vel = `parget posout wcstran`

                  set vel_err = \
                    `calc exp="'(${upp_vel}-${low_vel})/2.0E+00'" prec=_double`  

                  if ( `echo "if ( $vel_err < 0.0 ) 1" | bc` ) then
                     set vel_err = `calc exp="'-($vel_err)'"`
                  endif
             
                  echo " +- ${vel_err} ${vunits}"
                  set vars = "${vars} ${vel_err}"
               endif
            endif  
         endif
      else

# No fit file.  Set dummy values.
         echo "        Spectrum at ($x,$y)" 
         set line = "${line} -9999.99" 
         if ( ${dovar} == "TRUE" ) then
            set vars = "${vars} -9999.99"
         endif     
      endif

# Remove temporary files for the current pixel.
      rm -f ${fitfile} >& /dev/null
      rm -f ${specfile}.sdf >& /dev/null

# Move to the next pixel.
      @ x = ${x} + 1
   end

# Store the results in a text file.
   echo "${line}" >> ${mapfile}
   set line = ""
   if ( ${dovar} == "TRUE" ) then
      echo "${vars}" >> ${varfile}
      set vars = ""
   endif

# Move to the next row.
   set x = 0
   @ x = $x + $lbnd[1]
   @ y = ${y} + 1
end

date >> ${tmpdir}/${user}/vmap_time.dat

# Convert the text file of the map to a two-dimensional NDF.
# ==========================================================

echo " "
echo "      Output NDF:"
echo "        Converting: Creating NDF from data." 

ascii2ndf "in=${mapfile} out=${outfile}_tmp shape=[${dims[1]},${dims[2]}] "\
          "maxlen=2048 type='_real'" >& /dev/null

# Set the null values to the bad value (VAL__BADR).
setmagic "in=${outfile}_tmp out=${outfile} repval=-9999.99" >& /dev/null
if ( -e ${outfile}.sdf ) then
   rm -f "${outfile}_tmp.sdf" >& /dev/null
else
   echo "WARNING: Setting MAGIC values failed."
   mv -f ${outfile}_tmp.sdf ${outfile}.sdf
endif

# Set the NDF origin.
echo "        Origin: Attaching origin (${lbnd[1]},${lbnd[2]})." 
setorigin "ndf=${colfile} origin=[${lbnd[1]},${lbnd[2]}]" >& /dev/null
setorigin "ndf=${outfile} origin=[${lbnd[1]},${lbnd[2]}]" >& /dev/null

# Attach the VARIANCE array.
if ( ${dovar} == "TRUE" ) then
   echo "        Converting: Attaching VARIANCE array." 
   ascii2ndf in=${varfile} comp="Variance" out=${outfile} \
             shape="[${dims[1]},${dims[2]}]" \
             maxlen=2048 type='_real'

# Replace its null values with the bad value.
   mv -f ${outfile}.sdf ${outfile}_tmp.sdf
   setmagic in=${outfile}_tmp out=${outfile} \
            comp="Variance" repval=-9999.99 >& /dev/null

   if ( -e ${outfile}.sdf ) then
      rm -f "${outfile}_tmp.sdf" >& /dev/null
   else
      echo "WARNING: Setting MAGIC variance values failed."
      mv -f ${outfile}_tmp.sdf ${outfile}.sdf
   endif     
endif

# Use the white-light image to clone the axis AXIS and WCS co-ordinates.
# The WCS information will be copied incorrectly if the AXIS structure does
# not exist before the WCS component is cloned.  If one an AXIS structure 
# does not exist, create an array of axis centres, derived from the current
# WCS Frame, along each axis.
if ( ${axis} == "FALSE" ) then
   echo "        Axes: Creating AXIS centres."
   setaxis "ndf=${colfile} dim=1 mode=wcs comp=Centre" >& /dev/null
   setaxis "ndf=${colfile} dim=2 mode=wcs comp=Centre" >& /dev/null
endif

echo "        Axes: Attaching AXIS structures." 
setaxis "ndf=${outfile} like=${colfile}" >& /dev/null

echo "        WCS: Attaching WCS information." 
wcscopy "ndf=${outfile} like=${colfile}" >& /dev/null

echo "        Title: Setting title." 
settitle "ndf=${outfile} title='Velocity Map'"
echo " "

# Plot the output velocity map.
# =============================

# Check to see if we need to plot the output velocity map.
if ( ${plotspec} == "TRUE" ) then
   lutcol device=${plotdev}
   echo "      Plotting:"
   echo "        Display: Velocity map using percentile scaling." 
   display "${outfile} device=${plotdev} mode=per percentiles=[15,98]"\
           "axes=yes margin=!" >& /dev/null
   echo "        Contour: White-light image with equally spaced contours." 
   contour "ndf=${colfile} device=${plotdev} clear=no mode=equi" \
           "axes=no ncont=${numcont} pens='colour=2' margin=!" >& /dev/null
   echo " "
endif

# Loop for manual fitting.
# ------------------------

set loop_var = 1
if ( ${forcefit} == "FALSE" ) then
   if ( ${plotspec} == "FALSE" ) then
      lutcol device=${plotdev}
      echo "      Plotting:"
      echo "        Display: Velocity map using percentile scaling." 
      display "${outfile} device=${plotdev} mode=per percentiles=[15,98]"\
              "axes=yes margin=!" >& /dev/null
      echo "        Contour: White-light image with equally spaced contours." 
      contour "ndf=${colfile} device=${plotdev} clear=no mode=equi"\
              "axes=no ncont=${numcont} pens='colour=2' margin=!" >& /dev/null 
   endif   
   while ( ${loop_var} == 1 )
      
      echo " "
      echo -n "Refit a point (yes/no): "
      set refit = $<
      echo " "

      if ( ${refit} == "yes" || ${refit} == "y" ) then

# Copy the current output file to a _tmp file.
         mv -f ${outfile}.sdf ${outfile}_tmp.sdf
      
# Grab the X-Y position.
         echo " "
         echo "  Left click on pixel to be extracted."
   
         cursor showpixel=true style="Colour(marker)=2" plot=mark \
             maxpos=1 marker=2 device=${plotdev} frame="PIXEL" >> ${curfile}

# Wait for CURSOR output then get X-Y co-ordinates from 
# the temporary file created by KAPPA:CURSOR.
         while ( ! -e ${curfile} ) 
            sleep 1
         end

# Grab the position.
         set pos = \
         `parget lastpos cursor | awk '{split($0,a," ");print a[1], a[2]}'`

# Get the pixel co-ordinates and convert to grid indices.  The
# exterior NINT replaces the bug/feature -0 result with the desired 0.
         set xpix = `calc exp="nint(nint($pos[1]+0.5))" prec=_REAL`
         set ypix = `calc exp="nint(nint($pos[2]+0.5))" prec=_REAL`

# Clean up the CURSOR temporary file.
         rm -f ${curfile}
         touch ${curfile}
      
# Extract the spectrum.
# =====================
         echo " "
         echo "      Extracting:"
         echo "        (X,Y) pixel: ${xpix},${ypix}"

# Extract the spectrum from the cube.
         ndfcopy in="${infile}($xpix,$ypix,)" out=${ripfile} \
                 trim=true trimwcs=true

# Check to see if the NDF has an AXIS component.  If one does not exist,
# create an array of axis centres, derived from the current WCS Frame.
         set axis = `parget axis ndftrace`

         if ( ${axis} == "FALSE" ) then
            setaxis "ndf=${ripfile} dim=1 mode=wcs comp=Centre" >& /dev/null
            echo "        Axes: Adding AXIS centres."
         endif

# To compare like with like ensure, that plotting uses the AXIS frame,
# but first record the index to the current Frame.
         ndftrace "ndf=${ripfile}" >& /dev/null
         set inframe = `parget current ndftrace`
         wcsframe "ndf=${ripfile} frame=axis"

# Check to see if the NDF has VARIANCE.
         if ( ${variance} == "FALSE" ) then
            echo "        Variances: present."
         else
            echo "        Variances: absent."
         endif

# Re-plot.
# ========

# Label for repeated fitting of the Gaussian.
manual_refit: 

# Specify the units, in case these weren't know originally.
         axunits "ndf=${ripfile} units=${sunits}" >& /dev/null

# Plot the ripped spectrum.
         linplot "${ripfile} mode=histogram device=${plotdev}" >& /dev/null

# Zoom if required.
         if ( ${gotzoom} == "ASK") then
            echo " "
            echo -n "Zoom in (yes/no): "
            set zoomit = $<
         else if ( ${gotzoom} == "TRUE") then
            set zoomit = "yes"
         else
            set zoomit = "no"
         endif

         if ( ${zoomit} == "yes" || ${zoomit} == "y" ) then

# Get the lower limit.
# --------------------
            echo " "
            echo "  Left click on lower zoom boundary."
   
            cursor showpixel=true style="Colour(curves)=3" plot=vline \
                   maxpos=1 device=${plotdev} >> ${curfile}
            while ( ! -e ${curfile} ) 
               sleep 1
            end
            set pos = `parget lastpos cursor`
            set low_z = $pos[1]

# Clean up the CURSOR temporary file.
            rm -f ${curfile}
            touch ${curfile}
   
# Get the upper limit.
# --------------------
            echo "  Left click on upper zoom boundary."

            cursor showpixel=true style="Colour(curves)=3" plot=vline \
                   maxpos=1 device=${plotdev} >> ${curfile}
            while ( ! -e ${curfile} ) 
               sleep 1
            end
            set pos = `parget lastpos cursor`
            set upp_z = $pos[1]

            echo " "
            echo "      Zooming:"
            echo "        Lower Boundary: ${low_z}"
            echo "        Upper Boundary: ${upp_z}"

# Clean up the CURSOR temporary file.
            rm -f ${curfile}
            touch ${curfile}

# Label for repeated fitting of the Gaussian.
manual_rezoom:   

# Replot the spectrum.
            linplot "${ripfile} xleft=${low_z} xright=${upp_z}"\
                    mode=histogram "device=${plotdev}" >& /dev/null
         endif

# Grab the information needed by the FITGAUSS routine.
# ====================================================

# Get the lower mask boundary.
# ----------------------------
         echo " "
         echo "  Left click on the lower limit of the fitting region."

         cursor showpixel=true style="Colour(curves)=2" plot=vline \
                maxpos=1 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
         while ( ! -e ${curfile} ) 
            sleep 1
         end

# Grab the position.
         set pos = `parget lastpos cursor`
         set low_mask = $pos[1]

# Clean up the CURSOR temporary file.
         rm -f ${curfile}
         touch ${curfile}
 
# Get the upper mask boundary.
# ----------------------------
         echo "  Left click on the upper limit of the fitting region."

         cursor showpixel=true style="Colour(curves)=2" plot=vline \
                maxpos=1 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
         while ( ! -e ${curfile} ) 
           sleep 1
         end

# Grab the position.
         set pos = `parget lastpos cursor`
         set upp_mask = $pos[1]

         echo " " 
         echo "      Fit Mask:"
         echo "        Lower Mask Boundary: ${low_mask}"
         echo "        Upper Mask Boundary: ${upp_mask}"

# Clean up the CURSOR temporary file.
         rm -f ${curfile}
         touch ${curfile}

# Get the continuum values.
# -------------------------
         echo " "
         echo "  Left click on your first estimate of the continuum."

         cursor showpixel=true style="Colour(curves)=4" plot=hline \
                maxpos=1 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
         while ( ! -e ${curfile} ) 
            sleep 1
         end

# Grab the position.
         set pos = `parget lastpos cursor`
         set first_cont = $pos[2]

         echo "  Left click on your second estimate of the continuum."

         cursor showpixel=true style="Colour(curves)=4" plot=hline \
                maxpos=1 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
         while ( ! -e ${curfile} ) 
            sleep 1
         end

# Grab the position.
         set pos = `parget lastpos cursor`
         set second_cont = $pos[2]

         echo " "
         echo "      Continuum:"
         echo "        First Estimate: ${first_cont}"
         echo "        Second Estimate: ${second_cont}"

# Derive the average continuum.
         set cont = `calc exp="0.5*((${first_cont})+(${second_cont}))" prec=${prec}`
#        set cont = `echo "${first_cont}+${second_cont}" | bc`
#        set scale = `echo "${cont}/2.0" | bc`
#        set remainder = `echo "${cont}%2.0" | bc`
#        set cont = `echo "${scale}+${remainder}" | bc`

         echo "        Average Value: ${cont}"

# Get the peak position.
# ----------------------
         echo " " 
         echo "  Left click on the line peak"

         cursor showpixel=true style="Colour(marker)=3" plot=mark \
                maxpos=1 marker=2 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
         while ( ! -e ${curfile} ) 
            sleep 1
         end

# Grab the position.
         set pos = `parget lastpos cursor`
         set position = $pos[1]
         set peak = $pos[2]

         echo " "
         echo "      Line Position:"
         echo "        Peak Position: ${position} ${sunits}"
         echo "        Peak Height: ${peak} ${unit}"

# Clean up the CURSOR temporary file.
         rm -f ${curfile}
         touch ${curfile}

# Get the fwhm left side.
# -----------------------
         echo " " 
         echo "  Left click on the left-hand edge of the FWHM."

         cursor showpixel=true style="Colour(marker)=3" plot=mark \
                maxpos=1 marker=2 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
         while ( ! -e ${curfile} ) 
            sleep 1
         end

# Grab position.
         set pos = `parget lastpos cursor`
         set fwhm_low = $pos[1]

# Clean up the CURSOR temporary file.
         rm -f ${curfile}
         touch ${curfile}

# Get the fwhm right side.
# ------------------------
         echo "  Left click on the right-hand edge of the FWHM."
         echo " "

         cursor showpixel=true style="Colour(marker)=3" plot=mark \
                maxpos=1 marker=2 device=${plotdev} >> ${curfile}

# Wait for CURSOR output then get spectral-unit,continuum measurement from 
# the temporary file created by KAPPA:CURSOR.
         while ( ! -e ${curfile} ) 
            sleep 1
         end

# Grab the position.
         set pos = `parget lastpos cursor`
         set fwhm_upp = $pos[1]

         echo "      FWHM:"
         echo "        Lower Bound: ${fwhm_low}"
         echo "        Upper Bound: ${fwhm_upp}"

# Clean up the CURSOR temporary file.
         rm -f ${curfile}
         touch ${curfile}

# Evaluate the fwhm.
# ------------------
         set fwhm = `calc exp="(${fwhm_upp})-(${fwhm_low})" prec=${prec}`
         echo "        FWHM: ${fwhm}"
         echo " "

# Fit the line.
# =============

# Reset the WCS Frame to its original value, now we've finished
# plotting and fitting.
         wcsframe "ndf=${ripfile} frame=${inframe}"

# Create a SpecFrame if one is not present, and make it the current
# frame.  At present the earlier test for a missing SpecFrame only
# occurs for a UK data-cube format with LAMBDA as the label, so the
# system is wavelength and units Angstrom.
         if ( $create_specframe == "TRUE" ) then
            wcsadd ndf=${ripfile} frame=axis maptype=unit frmtype=spec \
                  domain=SPECTRUM attrs="'System=wave,Unit=Angstrom'" >& /dev/null

# The spectrum has a SPECTRUM domain WCS Frame, so select it for
# velocity calculations.
         else if ( $change_frame == "TRUE" ) then
            wcsframe "ndf=${ripfile} frame=SPECTRUM" >& /dev/null
         endif

         echo "      Fitting:"

         fitgauss \
           "in=${ripfile} mask1=${low_mask} mask2=${upp_mask} cont=${cont} "\
           "peak=${peak} fwhm=${fwhm} reguess=no remask=no ncomp=1 "\
           "cf=0 pf=0 wf=0 comp=${component} fitgood=${fitgood} "\
           "centre=${position} logfil=${fitfile} device=${plotdev}"\
           "dialog=f" >& /dev/null 

# Check to see whether or not fitting was successful.
         if ( ! -e $fitfile ) then
            echo "        No fit available"
            echo ""
            echo -n "Refit (yes/no): "
            set fitgood = $<
            echo " "
            if ( ${fitgood} == "no" || ${fitgood} == "n" ) then
               rm -f ${fitfile}
               goto cleanup 
            else
               if ( ${zoomit} == "yes" || ${zoomit} == "y" ) then
                  goto manual_rezoom
               else
                  goto manual_refit
               endif 
            endif
         endif     
 
# Get the fit from the temporary file.
         set results = `cat ${fitfile} | head -n 23 | tail -1`
         set array = \
      `echo $results | awk '{split($0,a," "); for(i=1; i<10; i++) print a[i]}'`

         set centre_fit = $array[2]
         set centre_err = $array[3]
         set peak_height = $array[4]
         set peak_err = $array[5]
         set fwhm_fit = $array[6]
         set fwhm_err = $array[7]
         set integral = $array[8]
         set integral_err = $array[9]

# Show the user the fit.
         echo "        Centre Position: ${centre_fit} +- ${centre_err} ${sunits}"
         echo "        Peak Height: ${peak_height} +- ${peak_err} ${unit}"
         echo "        FWHM: ${fwhm_fit} +- ${fwhm_err} ${sunits}"
         echo "        Line integral: ${integral} +- ${integral_err} ${unit}"

# Fit ok?
         echo " "

         if ( ${forcefit} == "FALSE" ) then
            echo -n "Fit ok? (yes/no/quit): "
            set fitgood = $<
            echo " "
         else
            set fitgood = yes
         endif

         if ( ${fitgood} == "no" || ${fitgood} == "n" ) then
            rm -f ${fitfile} 
            if ( ${zoomit} == "yes" || ${zoomit} == "y" ) then
               goto manual_rezoom
            else
               goto manual_refit
            endif
         else if ( ${fitgood} == "quit" || ${fitgood} == "q" ) then
            rm -f ${fitfile}
            goto dropout 
         else    
            rm -f ${fitfile}
         endif

# Calculate the velocity.
# =======================

# Set the rest-frame value, if it's not already stored in the WCS
# attributes.  For this to work the current WCS Frame must be a
# SpecFrame.  At present there is no test.
         if ( ${rest_known} == "FALSE" ) then
            wcsattrib "ndf=${ripfile} mode=set name=RestFreq "\
                      "newval='${rest_coord} ${sunits}'" >& /dev/null
         endif

# Reset the System of the current WCS Frame to velocities in the desired 
# system and units.
         wcsattrib "ndf=${ripfile} mode=set name=System newval=${velsys}"
         wcsattrib "ndf=${ripfile} mode=set name=Unit newval=${vunits}"

# Convert the line-centre position to optical velocity.
         wcstran "ndf=${ripfile} posin=${centre_fit} framein=AXIS " \
                 "frameout=SPECTRUM" >& /dev/null
         set velocity = `parget posout wcstran`

         if ( ${dovar} == "TRUE" ) then
            echo "        (X,Y) Pixel: ${xpix}:${ypix}"
            echo -n "        Line Velocity: $velocity" 
         else
            echo "        (X,Y) Pixel: ${xpix},${ypix}"
            echo "        Line Velocity: $velocity ${vunits}" 
         endif

# Change the pixel value.
         set pixel = "${xpix}:${xpix},${ypix}:${ypix}"
         chpix in=${outfile}_tmp out=${outfile} comp="Data"\
               newval=${velocity} section=\'${pixel}\' 

         if ( -e ${outfile}.sdf ) then
            rm -f ${outfile}_tmp.sdf >& /dev/null
         else
            echo "WARNING: Inserting new pixel value failed"
            mv  -f ${outfile}_tmp.sdf ${outfile}.sdf
         endif

# Calculate the error.
         if ( ${dovar} == "TRUE" ) then
            if ( ${centre_err} == "nan" || ${centre_err} == "INF" ) then

# Set the variance to the null value.
               echo " ${vunits}"
               set vel_err = -9999.99     
            else

# Derive value's error bars.
               set upp_err = \
                 `calc exp="'${centre_fit} + ${centre_err}'" prec=_double`
               wcstran "ndf=${ripfile} posin=${upp_err} framein=AXIS" \
                       "frameout=SPECTRUM" >& /dev/null
               set upp_vel = `parget posout wcstran`
                               
               set low_err = \
                 `calc exp="'${centre_fit} - ${centre_err}'" prec=_double`
               wcstran "ndf=${ripfile} posin=${low_err} framein=AXIS " \
                       "frameout=SPECTRUM" >& /dev/null
               set low_vel = `parget posout wcstran`

               set vel_err = \
                 `calc exp="'(${upp_vel}-${low_vel})/2.0E+00'" prec=_double`  

               if ( `echo "if ( $vel_err < 0.0 ) 1" | bc` ) then
                  set vel_err = `calc exp="'-($vel_err)'"`
                endif

               echo " +- ${vel_err} ${vunits}"
            endif

# Move the output file to a temporary place holder.
            mv -f ${outfile}.sdf ${outfile}_tmp.sdf 

# Change the pixel value.
            set pixel = "${xpix}:${xpix},${ypix}:${ypix}"
            chpix in=${outfile}_tmp out=${outfile} comp="Variance" \
                  newval=${vel_err} section=\'${pixel}\'

            if ( -e ${outfile}.sdf ) then
               rm -f ${outfile}_tmp.sdf >& /dev/null
            else
               echo "WARNING: Inserting new variance value failed."
               mv -f ${outfile}_tmp.sdf ${outfile}.sdf
            endif
        
# Set the null values to the bad value (VAL__BADR).
            mv -f ${outfile}.sdf ${outfile}_tmp.sdf >& /dev/null
            setmagic in=${outfile}_tmp out=${outfile} \
                     comp="Variance" repval=-9999.99 >& /dev/null
            if ( -e ${outfile}.sdf ) then
               rm -f ${outfile}_tmp.sdf
            else
               echo "WARNING: Setting MAGIC values failed."
               mv -f ${outfile}_tmp.sdf ${outfile}
            endif
         endif

# Plot the new velocity map.
# ==========================
         lutcol device=${plotdev}
         echo " "
         echo "      Plotting:"
         echo "        Display: Velocity map using percentile scaling." 
         display "${outfile} device=${plotdev} mode=per percentiles=[15,98]"\
                 "axes=yes margin=!" >& /dev/null
         echo "        Contour: White-light image with equally spaced contours." 
         contour "ndf=${colfile} device=${plotdev} clear=no mode=equi"\
                 "axes=no ncont=${numcont} pens='colour=2' margin=!" >& /dev/null
         echo " "

# Clean up temporary velmap files, salvage ${outfile}_tmp in the case
# where there is no existing $outfile (i.e. CHPIX has not run).
         if ( -e ${outfile}_tmp.sdf ) then
            if ( -e ${outfile}.sdf ) then
               rm -f ${outfile}_tmp.sdf
            else
               mv -f ${outfile}_tmp.sdf ${outfile}.sdf
            endif
         endif

# End of manual-refitting loop.
      else

# Drop out of while loop     
         set loop_var = 0
      endif
   end
endif

# Dropout point for aborted fitting, try and salvage already existing
# velocity maps that may be lying around instead of throwing them away
dropout:     
if ( -e ${outfile}_tmp.sdf ) then
   if ( -e ${outfile}.sdf ) then
      rm -f ${outfile}_tmp.sdf
   else
      mv -f ${outfile}_tmp.sdf ${outfile}.sdf
   endif
endif

# Clean up
# ========
cleanup:

rm -f ${curfile} >& /dev/null
rm -f ${colfile}.sdf >& /dev/null
rm -f ${ripfile}.sdf >& /dev/null
rm -f ${fitfile} >& /dev/null
rm -f ${mapfile} >& /dev/null
rm -f ${varfile} >& /dev/null
rm ${tmpdir}/${user}/vmap_time.dat >& /dev/null
rmdir ${tmpdir}/${user} >& /dev/null
