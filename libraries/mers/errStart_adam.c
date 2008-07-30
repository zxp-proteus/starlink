/*
*+
*  Name:
*     errStart

*  Purpose:
*     Initialise the Error Reporting System.

*  Language:
*     Starlink ANSI C

*  Invocation:
*     errStart();

*  Description:
*     Initialises the global variables used by the Error Reporting System. 

*  Implementation Notes:
*     This subroutine is for use only with the ADAM implementation of
*     the Error Reporting System.

*  Algorithm:
*     - Call emsBegin
*     - Call emsLevel and call emsTune with that level

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     Copyright (C) 1983, 1989-1991 Science & Engineering Research Council.
*     Copyright (C) 2001 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     SLW: Sid Wright (UCL)
*     RFWS: R.F. Warren-Smith (STARLINK)
*     PCTR: P.C.T. Rees (STARLINK)
*     AJC: A.J.Chipperfield (STARLINK,RAL)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     23-FEB-1983 (SLW):
*        Original version.
*     7-AUG-1989 (RFWS):
*        Converted to new prologue layout and added comments.
*     11-SEP-1989 (PCTR):
*        Completed code tidy-up.
*     12-JAN-1990 (PCTR):
*        Converted to use EMS_ calls.
*     4-JUN-1991 (PCTR):
*        Added call to EMS1_MSTRT.
*     16-FEB-2001 (AJC):
*        Avoid use of EMS internals
*     29-JUL-2008 (TIMJ):
*        Rewrite in C.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

#include "sae_par.h"
#include "ems.h"
#include "merswrap.h"

void errStart( void ) {
  int status;   /* Internal status */
  int level;    /* The default level (prevents EMS output) */

  /*  Start a new error context */
  status = SAI__OK;
  emsBegin( &status );

  /*  Get the new level as the 'default' level */
  emsLevel( &level );

  /* Set the default level for EMS. That is a level below which EMS will not */
  emsTune( "MSGDEF", level, status );
}
