      SUBROUTINE ADI2_FCOMIT( FID, STATUS )
*+
*  Name:
*     ADI2_FCOMIT

*  Purpose:
*     Commit buffer changes to a FITSfile object

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI2_FCOMIT( FID, STATUS )

*  Description:
*     Commit any changes to keywords or data to the FITS file on disk. The
*     file is not closed.

*  Arguments:
*     FID = INTEGER (given)
*        ADI identifier of the FITSfile object
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
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     2 Feb 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'

*  Arguments Given:
      INTEGER			FID			! FITSfile identifier

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      INTEGER			NHDU			! HDU count
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Extract logical unit
c      CALL ADI_CGET0I( FID, 'Nhdu', NHDU, STATUS )

*  Commit units and keywords
c      CALL ADI2_CHKPRV( FID, NHDU, .TRUE., STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'ADI2_FCOMIT', STATUS )

      END


      SUBROUTINE ADI2_FCOMIT_HDU( FID, HID, STATUS )
*+
*  Name:
*     ADI2_FCOMIT_HDU

*  Purpose:
*     Commit buffer changes to a FITSfile object

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI2_FCOMIT_HDU( FID, HID, STATUS )

*  Description:
*     Commit any changes to keywords or data to the FITS file on disk. The
*     file is not closed.

*  Arguments:
*     FID = INTEGER (given)
*        ADI identifier of the FITSfile object
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
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     2 Feb 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'

*  Arguments Given:
      INTEGER			FID			! FITSfile identifier
      INTEGER			HID			! HDU identifier

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*132		CMT			! Keyword comment
      CHARACTER*20		CLASS			! Keyword value class
      CHARACTER*132		CVALUE			! Keyword value
      CHARACTER*8		KEY			! Keyword name

      DOUBLE PRECISION		DVALUE			! Keyword value

      REAL			RVALUE			!

      INTEGER			FSTAT			! FITSIO status
      INTEGER			IKEY			! Loop over keys
      INTEGER			IVALUE			! Keyword value
      INTEGER			KCID			! Keyword container
      INTEGER			KID			! Keyword object
      INTEGER			LUN			! Logical unit number
      INTEGER			NKEY			! # of keywords

      LOGICAL			COMIT			! Value committed?
      LOGICAL			THERE			! Object exists?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Extract logical unit
      CALL ADI2_GETLUN( FID, LUN, STATUS )

*  Locate keyword container
      CALL ADI_FIND( HID, 'Keys', KCID, STATUS )

*  Get number of keywords
      CALL ADI_NCMP( KCID, NKEY, STATUS )
      DO IKEY = 1, NKEY
        CALL ADI_INDCMP( KCID, IKEY, KID, STATUS )
        CALL ADI_THERE( KID, '.COMMITTED', COMIT, STATUS )
        IF ( .NOT. COMIT ) THEN
          CALL ADI_NAME( KID, KEY, STATUS )
          CALL ADI_THERE( KID, '.COMMENT', THERE, STATUS )
          IF ( THERE ) THEN
            CALL ADI_CGET0C( KID, '.COMMENT', CMT, STATUS )
          ELSE
            CALL ADI2_STDCMT( KEY, CMT, STATUS )
          END IF
          CALL ADI_TYPE( KID, CLASS, STATUS )
          IF ( CLASS(1:1) .EQ. 'D' ) THEN
            CALL ADI_GET0D( KID, DVALUE, STATUS )
            CALL FTPKYG( LUN, KEY, DVALUE, 8, CMT, FSTAT )
          ELSE IF ( CLASS(1:1) .EQ. 'R' ) THEN
            CALL ADI_GET0R( KID, RVALUE, STATUS )
            CALL FTPKYE( LUN, KEY, RVALUE, 8, CMT, FSTAT )
          ELSE IF ( CLASS(1:1) .EQ. 'I' ) THEN
            CALL ADI_GET0I( KID, IVALUE, STATUS )
            CALL FTPKYJ( LUN, KEY, IVALUE, CMT, FSTAT )
          ELSE
            CALL ADI_GET0C( KID, CVALUE, STATUS )
            CALL FTPKYS( LUN, KEY, CVALUE, CMT, FSTAT )
          END IF
          IF ( FSTAT .NE. 0 ) THEN
            CALL MSG_SETC( 'KEY', KEY )
            CALL ADI2_FITERP( FSTAT, STATUS )
            CALL ERR_REP( ' ', 'Error comitting keyword ^KEY to disk',
     :                    STATUS )
            GOTO 99
          END IF
          CALL ADI_CPUT0L( KID, '.COMMITTED', .TRUE., STATUS )
        END IF
        CALL ADI_ERASE( KID, STATUS )
      END DO

*  Free keyword contrainer
      CALL ADI_ERASE( KCID, STATUS )

*  Report any errors
 99   IF ( STATUS .NE. SAI__OK ) THEN
        CALL AST_REXIT( 'ADI2_FCOMIT_HDU', STATUS )
      END IF

      END
