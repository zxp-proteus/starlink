void psx1_init_rtl( void )

/*
*+
*  Name:
*     psx1_init_rtl

*  Purpose:
*     Initialize the VAX C run time library.

*  Language:
*     ANSI C

*  Invocation:
*     psx1_init_rtl()

*  Description:
*     Initialize the VAX C run time library. This is needed on VMS for
*     PSX routines that get environment variables. On Unix (Sun and
*     DECstation), this routine has no effect.

*  Algorithm:
*     The status of the static variable init is checked to see if this
*     routine has already initialized the VAX C run time library. If it
*     has not, the routine tries to translate the environment variable
*     "USER".  If this is not possible, then the VAX C run time library
*     is initialized.

*  External Routines Used:
*     VAX C run time library:
*        vaxc$crtl_init

*  VMS-specific features used:
*     Although a VAX specific routine is called, that piece of code is
*     only included by the preprocessor on VMS systems, so the code is
*     portable.

*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council

*  Authors:
*     PMA: Peter Allan (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     16-APR-1991 (PMA):
*        Original version.
*     24-SEP-1992 (PMA):
*        Remove the extra check so see if vaxc$crtl_init() has already been
*        called. This was done by calling getenv("USER"), which failed to
*        work if a logical name of USER was defined. As of VMS 5.2, it is
*        safe to call vaxc$crtl_init() more than once.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
-----------------------------------------------------------------------------
*/

{

#if defined(vms)		 /* VMS specific code.			    */

/* Local Variables:							    */

   static int init = 0;          /* Is the run time library initialized?    */

/* External routines:							    */

   void vaxc$crtl_init( void );	 /* Function to initialize C run time
      				    library				    */

/* Has this routine initialized the library already?			    */

   if( init == 0 )

/* Initialize the VAX C run time library.				    */

   {
      vaxc$crtl_init();
      init = 1;
   }

#endif				 /* End of VMS specific code.		    */
}
