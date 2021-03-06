      SUBROUTINE USI_CLONE( INP, OUT, CLASS, ID, STATUS )
*+
*  Name:
*     USI_CLONE

*  Purpose:
*     Create a cloned copy of input, getting name from environment

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL USI_CLONE( INP, OUT, CLASS, ID, STATUS )

*  Description:
*     {routine_description}

*  Arguments:
*     INP = CHARACTER*(*) (given)
*        Name of environment parameter specifying clone
*     OUT = CHARACTER*(*) (given)
*        Name of environment parameter specifying new file
*     CLASS = CHARACTER*(*) (given)
*        Class of object to associate. If the string '*' is supplied then
*        the same class as the object associated with INP is used.
*     ID = INTEGER (returned)
*        ADI identifier of opened object
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     {routine_references}...

*  Keywords:
*     {routine_keywords}...

*  Copyright:
*     {routine_copyright}

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     RB: Richard Beard (ROSAT, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     12 Jan 1995 (DJA):
*        Original version.
*     19 Dec 1995 (DJA):
*        Added special treatment of CLASS = '*'
*     14 May 1997 (RB):
*        Clone in now copy, close, open for update.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER*(*)		INP, OUT, CLASS

*  Arguments Returned:
      INTEGER			ID

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			CHR_LEN
        INTEGER			CHR_LEN

*  Local Variables:
      CHARACTER*200		FNAME, LFILE		! Input object
      CHARACTER*50		LCLASS			! Local copy of CLASS

      INTEGER			EP, PPOS		! Character pointers
      INTEGER			IFID			! INP's ADI identifier
      INTEGER			LCLL			! Length of LCLASS
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Does output parameter name include a representation code?
      PPOS = INDEX( OUT, '%' )
      IF ( PPOS .EQ. 0 ) THEN
        EP = LEN(OUT)
      ELSE
        EP = MAX(1,PPOS - 1)
      END IF

*  Get ADI identifier of already associated object
      CALL USI0_FNDADI( INP, IFID, STATUS )

*  Has user specified the special value '*' for CLASS?
      IF ( CLASS .EQ. '*' ) THEN
        CALL ADI_TYPE( IFID, LCLASS, STATUS )
        LCLL = CHR_LEN( LCLASS )
      ELSE
        LCLASS = CLASS
        LCLL = LEN(CLASS)
      END IF

*  Get output file name
      CALL USI_GET0C( OUT(:EP), FNAME, STATUS )
      IF ( STATUS .EQ. SAI__OK ) THEN

*      If caller specified a representation on the parameter, glue it
*      on to the file name
        IF ( PPOS .EQ. 0 ) THEN
          CALL ADI_FCLONE( IFID, FNAME, LCLASS, ID, STATUS )
        ELSE
          LFILE = FNAME(:MAX(1,CHR_LEN(FNAME)))//OUT(PPOS:)
          CALL ADI_FCLONE( IFID, LFILE, LCLASS, ID, STATUS )
        END IF

*  Now close and re-open for update!
      CALL ADI_FCLOSE( ID, STATUS )
      CALL ADI_FOPEN( FNAME, LCLASS, 'UPDATE', ID, stATUS )

*    Store in common
        CALL USI0_STOREI( OUT(:EP), ID, 'O', .FALSE., STATUS )

      END IF

      END
