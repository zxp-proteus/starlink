      SUBROUTINE KPG1_PLPUT( CI1, CI2, LBND, UBND, ARRAY, STATUS )
*+
*  Name:
*     KPG1_PLPUT

*  Purpose:
*     Put a section of the current colour palette into the supplied array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_PLPUT( CI1, CI2, LBND, UBND, ARRAY, STATUS )

*  Description:
*     This routine puts a specified section of the colour palette for the 
*     currently opened graphics device into the supplied array. Other
*     elements of the array are left unchanged.
*
*  Arguments:
*     CI1 = INTEGER (Given)
*        The lowest colour index to change in the array.
*     CI2 = INTEGER (Given)
*        The highest colour index to change in the array.
*     LBND = INTEGER (Given)
*        The lower bound of the second axis of ARRAY.
*     UBND = INTEGER (Given)
*        The upper bound of the second axis of ARRAY.
*     ARRAY( 3, LBND : UBND ) = REAL (Given and Returned)
*        The array to recieved the palette.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  A graphics device must previously have been opened using PGPLOT.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     30-OCT-1998 (DSB):
*        Original version.
*     1-OCT-1999 (DSB):
*        Converted to PGPLOT.
*     3-OCT-2001 (DSB):
*        Added arguments LBND and UBND.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CTM_PAR'          ! Colout Table Management constants

*  Arguments Given:
      INTEGER CI1
      INTEGER CI2
      INTEGER LBND
      INTEGER UBND

*  Arguments Given and Returned:
      REAL ARRAY( 3, LBND:UBND )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop count
  
*.

*  Check the inherited status. 
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Inquire the palette colour indices, and store in the array.
      DO  I = MAX( LBND, CI1 ), MIN( UBND, CI2 )
         CALL PGQCR( I, ARRAY( 1, I ), ARRAY( 2, I ), ARRAY( 3, I ) )
      END DO

      END
