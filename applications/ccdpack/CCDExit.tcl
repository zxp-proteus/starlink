proc CCDExit {} {

#+
#  Name:
#     CCDExit

#  Type of Module:
#     Tcl/Tk procedure.

#  Purpose:
#     Exits the CCDPACK GUI.

#  Description:
#     This routine offers to close down the GUI and performs a clean
#     exit if requested.

#  Global parameters:
#     MAIN = array (read)
#       MAIN(window) = name of the main top-level window.
#       MAIN(name) = name of application.

#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     MBT: Mark Taylor (STARLINK)
#     {enter_new_authors_here}

#  History:
#     7-NOV-1995 (PDRAPER):
#        Original version.
#     13-MAY-1999 (PDRAPER):
#        Changed window control policy to just transient (explicit
#        raising causes problems with some WMs).
#     11-MAY-2000 (MBT):
#        Upgraded for Tcl8.
#     {enter_changes_here}

#-

#  Global parameters:
   global MAIN
#.

   set Main $MAIN(window)
   set main [CCDPathOf $Main]
   if { [winfo exists $main] } { 

#  Widget creation.
      CCDCcdWidget Top top Ccd_toplevel .exit -title "Exit from $MAIN(name)"
      CCDTkWidget Line1 line1 frame $top.f1 -height 3
      CCDTkWidget Message message \
         label $top.message \
                      -text "Are you sure you want to exit from $MAIN(name)" \
                      -borderwidth 3 -padx 10 -pady 10
      CCDTkWidget Bitmap bitmap label $top.bitmap -bitmap questhead
      CCDTkWidget Line2 line2 frame $top.f2 -height 3
      CCDCcdWidget Choice choice Ccd_choice $Top.button -standard 0
               
#  Configure widgets.
      $Choice addbutton Yes "$Top kill $Top;$Main kill $Main; destroy ."
      $Choice addbutton No  "$Top kill $Top"

#  Pack widgets.
      pack $choice -side bottom -fill x
      pack $line1 -side top -fill x
      pack $message -side left -fill both -expand true
      pack $bitmap -side right
      pack $line2 -side top -fill x
      
#  Make sure this window is on top and reasonable prominent 
#  (centre of screen of parent top-level).
      wm withdraw $top
      update idletasks
      set x [expr [winfo screenwidth $top]/2 - [winfo reqwidth $top]/2]
      set y [expr [winfo screenheight $top]/2 - [winfo reqheight $top]/2]
      wm geometry $top +$x+$y
      wm deiconify $top

#  Try to make sure this window stays on Top.
      wm transient $top [CCDPathOf .topwin]

#  Yes is default.
      $Choice focus Yes
      
#  Wait for the acknowledgement.
      CCDWindowWait $Top
   }
#  End of procedure.
}
# $Id$
