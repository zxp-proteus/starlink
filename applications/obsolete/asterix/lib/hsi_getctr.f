      SUBROUTINE HSI_GETCTR( FID, HCID, STATUS )
*+
*  Name:
*     HSI_GETCTR

*  Purpose:
*     Retrieves history control information from dataset

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL HSI_GETCTR( FID, HCID, STATUS )

*  Description:
*     Retrieves history control information from a dataset. This contains
*     the original file creation date, the creator's name and the number
*     of history records in the dataset.

*  Arguments:
*     FID = INTEGER (given)
*        ADI identifier of the dataset
*     HCID = INTEGER (returned)
*        ADI identifier of the history control data
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
*     HSI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/hsi.html

*  Keywords:
*     package:hsi, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     16 Mar 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PKG'

*  Arguments Given:
      INTEGER			FID

*  Arguments Returned:
      INTEGER			HCID

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      LOGICAL			AST_QPKGI
        EXTERNAL		AST_QPKGI

*  Local Variables:
      INTEGER			FILID			! File identifier
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check initialised
      IF ( .NOT. AST_QPKGI( HSI__PKG ) ) CALL HSI0_INIT( STATUS )

*  Get base file
      CALL ADI_GETFILE( FID, FILID, STATUS )

*  Simply invoke the method
      CALL ADI_EXEC( 'GetHistoryCtrl', 1, FILID, HCID, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'HSI_GETCTR', STATUS )

      END
