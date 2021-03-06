/*+
 *  Name:
 *     IOR

 *  Purpose:
 *     Perform a logical OR of two given Fortran INTEGERs and returns 
 *     the result.

 *  Language:
 *     Starlink ANSI C

 *  Invocation:
 *     RESULT = IOR( I1, I2 )

 *  Description:
 *     This function is designed to be callable from Fortran. It performs
 *     a bitwise OR (logical OR on corresponding bits) of two INTEGERs
 *     and returns the resultant INTEGER.

 *  Arguments:
 *     I1 = INTEGER (Given)
 *        The first INTEGER
 *     I2 = INTEGER (Given)
 *        The second INTEGER

 *  Returned Value:
 *     IOR = INTEGER
 *        The result of the bitwise OR.

 *  Authors:
 *     BKM: B.K. McIlwrath (STARLINK)
 *     {enter_new_authors_here}

 *  History:
 *     19-JUN-1995 (BKM):
 *        Original version.
 *     {enter_further_changes_here}

 *  Bugs:
 *     {note_any_bugs_here}

 *- */

/* Include Statements: */
#include "ncar.h"

/* Function Definitons: */
INTEGER IOR( INTEGER *i1, INTEGER *i2 ){

/* Return the result. */
   return( (INTEGER) *i1 | *i2 );
}
