      SUBROUTINE TCI_GETID( ID, TIMID, STATUS )
*+
*  Name:
*     TCI_GETID

*  Purpose:
*     Read the timing info from a dataset

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL TCI_GETID( ID, TIMID, STATUS )

*  Description:
*     Returns an object describing the timing info associated
*     with the specified dataset. This describes the observation
*     length, exposure time and detector on/off times.

*  Arguments:
*     ID = INTEGER (given)
*        ADI identifier of dataset
*     TIMID = INTEGER (returned)
*        ADI identifier of timing info
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
*     TCI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/tci.html

*  Keywords:
*     package:tci, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     6 Mar 1995 (DJA):
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
      INCLUDE 'AST_PKG'

*  Arguments Given:
      INTEGER                   ID

*  Arguments Returned:
      INTEGER                   TIMID

*  Status:
      INTEGER                   STATUS                  ! Global status

*  External References:
      EXTERNAL			AST_QPKGI
        LOGICAL			AST_QPKGI

*  Local Constants:
      CHARACTER*4		TCI_PROP
        PARAMETER		( TCI_PROP = '.TCS' )

*  Local Variables:
      INTEGER			FILID			! File identifier
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check initialised
      IF ( .NOT. AST_QPKGI( TCI__PKG ) ) CALL TCI0_INIT( STATUS )

*  Initialise return values
      TIMID = ADI__NULLID

*  Locate file object
      CALL ADI_GETFILE( ID, FILID, STATUS )

*  Invoke the read method
      CALL ADI_EXEC( 'ReadTiming', 1, FILID, TIMID, STATUS )

*  Store the returned object on the property list of the object
      CALL ADI_CPUTID( ID, TCI_PROP, TIMID, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'TCI_GETID', STATUS )

      END
