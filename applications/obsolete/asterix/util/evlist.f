      SUBROUTINE EVLIST( STATUS )
*+
*  Name:
*     EVLIST

*  Purpose:
*     Displays data values in an event dataset

*  Language:
*     Starlink Fortran

*  Type of Module:
*     ASTERIX task

*  Invocation:
*     CALL EVLIST( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     Displays the values of all the lists in an event dataset to the
*     ascii device of the users choice. The user may select the events
*     to display.

*  Usage:
*     evlist {parameter_usage}

*  Environment Parameters:
*     INP = CHAR (read)
*        Input dataset
*     SUBSET = CHAR (read)
*        Subset of items to be printed
*     DEV = CHAR (read)
*        Output ascii device

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

*  Implementation Status:
*     {routine_implementation_status}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     {task_references}...

*  Keywords:
*     evlist, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     JCMP: Jim Peden (University of Birmingham)
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     21 Sep 1983 (JCMP):
*        Original version.
*     10 Aug 1984 (JCMP):
*        Accumulation of non-scalar items, and tidied up
*     18 Jan 1985 (JCMP):
*        Version announcement. New output format
*      4 Feb 1985 (JCMP):
*        Revisions to output format
*     17 Dec 1985 (JCMP):
*        Mods to SUBSET parameter
*     27 Jan 1986 V0.4-1 (JCMP):
*        ADAM version
*     12 Feb 1986 V0.4-2 (JCMP):
*        Bug fix - fail if string truncation
*     28 Sep 1988 V1.0-1 (ADM):
*        ASTERIX88 version
*     30 Nov 1988 V1.5-0 (PLA):
*        More ASTERIX88 conversion
*      9 Nov 1993 V1.5-1 (DJA):
*        Increased length of UNITS
*      5 May 1994 V1.7-0 (DJA):
*        Use AIO for i/o
*     24 Nov 1994 V1.8-0 (DJA):
*        Now use USI for user interface
*     15 Aug 1995 V2.0-0 (DJA):
*        Full ADI port.
*      6 Oct 1997 V2.0-1 : Linux port (RJV)
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Status:
      INTEGER			STATUS             	! Global status

*  Local Constants:
      INTEGER			MAXCOLS			! Max # lists to
        PARAMETER		( MAXCOLS = 7 )		! display on page

      CHARACTER*30		VERSION
        PARAMETER		( VERSION = 'EVLIST Version 2.1-1' )

*  Local Variables:
      CHARACTER*14		C(MAXCOLS)      	! Formatted list values
      CHARACTER*20 		LNAMES(MAXCOLS) 	! Names of lists
      CHARACTER*20 	        MTYPE(MAXCOLS)   	! Mapping types of lists
      CHARACTER*132		OBUF			! Output text buffer
      CHARACTER*20 	        TYPE(MAXCOLS)   	! Types of lists
      CHARACTER*80           	LUNIT(MAXCOLS)  	! Data units

      DOUBLE PRECISION		DVAL			! List value

      INTEGER			FSTAT			! Fortran i/o status
      INTEGER                	I, J, K,L      	      	! Loop counters
      INTEGER			IDXPTR			! Display index
      INTEGER			IE1, IE2		! List range values
      INTEGER			IFID			! Input file identifier
      INTEGER			IP			! Photon number
      INTEGER			IVAL		      	! List value
      INTEGER                	INC          	      	! Number of lists to display at once
      INTEGER			IRNG			! Number of list ranges
      INTEGER			LID			! List identifier
      INTEGER                	LLEN      	      	! List length
      INTEGER			NRNG			! # separate ranges
      INTEGER                	OCH          	      	! Output channel
      INTEGER                	NDISP        	      	! Number of lists to be displayed
      INTEGER                	NEDISP        	      	! # events to display
      INTEGER                	NLDISP        	      	! # lists to display
      INTEGER                	NLIST        	      	! actual number of lists
      INTEGER                	OUTWID     	      	! Width of output device
      INTEGER			PTRS(MAXCOLS)		! Mapped list data
      INTEGER			RNGPTR			! List range index
      INTEGER                	START        	      	! List to display first

      LOGICAL                	CONTINUE     	      	! Used to control loops
      LOGICAL                	DUOK         	      	! data units present
      LOGICAL			LVAL		      	! List value
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Version id
      CALL MSG_PRNT( VERSION )

*  Initialize
      CALL AST_INIT()

*  Obtain data object
      CALL USI_ASSOC( 'INP', 'EventDS', 'READ', IFID, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Find all lists in the object
      CALL EDI_GETNS( IFID, LLEN, NLIST, STATUS )

*  Tell user if there aren't any
      IF ( NLIST .EQ. 0 ) THEN
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'FATAL ERROR: There are no lists to print',
     :                STATUS )
      END IF
      IF (STATUS .NE. SAI__OK) GOTO 99

*  Set up output channel
      CALL AIO_ASSOCO( 'DEV', 'LIST', OCH, OUTWID, STATUS )

*  Tell the user how many items there are
      CALL MSG_SETI( 'LEN', LLEN )
      CALL MSG_PRNT( 'There are ^LEN events per list' )

*  Map workspace to hold indices
      CALL DYN_MAPI( 1, LLEN, IDXPTR, STATUS )

*  Get the record numbers to display
      CALL PRS_GETLIST( 'SUBSET', LLEN, %VAL(IDXPTR), NEDISP,
     :                  STATUS )
      IF (STATUS .NE. SAI__OK) GOTO 99

*  Convert list to range pairs
      CALL DYN_MAPI( 1, NEDISP*2, RNGPTR, STATUS )
      CALL EVLIST_L2R( NEDISP, %VAL(IDXPTR), NRNG, %VAL(RNGPTR),
     :                 STATUS )

*  Print version and introductory information
      IF ( OUTWID .EQ. 132 ) THEN
        CALL AIO_BLNK( OCH, STATUS )
        CALL AIO_WRITE( OCH, VERSION, STATUS )
        CALL AIO_BLNK( OCH, STATUS )
        INC = 7
      ELSE
        INC = 4
      END IF

*  Set up for display loop
      START = 1 - INC
      NDISP = 0
      CONTINUE = .TRUE.

*  While more lists to display
      DO WHILE ( CONTINUE )

*    Advance window over lists
        START = START + INC
        NDISP = NDISP + INC
        IF ( NDISP .GE. NLIST ) THEN
          NDISP    = NLIST
          CONTINUE = .FALSE.
        END IF
        NLDISP = NDISP - START + 1

*    Get details of lists on this page
        J = 1
        DO I = START, NDISP

*      Index the list
          CALL EDI_IDX( IFID, I, LID, STATUS )

*      Get the list name & type
          CALL ADI_NAME( LID, LNAMES(J), STATUS )
          CALL ADI_CGET0C( LID, 'TYPE', TYPE(J), STATUS )

*      Units ok?
          CALL ADI_THERE( LID, 'Units', DUOK, STATUS )
          IF ( DUOK ) THEN
            CALL ADI_CGET0C( LID, 'Units', LUNIT(J), STATUS )
          ELSE
            LUNIT(J) = 'Units undefined'
          END IF
          IF ( STATUS .NE. SAI__OK ) GOTO 99

*      Free the list
          CALL ADI_ERASE( LID, STATUS )

*      Increment list counter
          J = J + 1

*    Next list on the page
        END DO

*    Page header
        CALL AIO_BLNK( OCH, STATUS )
        WRITE( OBUF, '(10(''-''),<NLDISP>(17(''-'')))')
        CALL AIO_WRITE( OCH, OBUF(:OUTWID-1), STATUS )
        WRITE( OBUF, '(A1,2X,A7,7A17)') '|', 'Item  |',
     :                     (' '//LNAMES(I)(1:15)//'|', I = 1, NLDISP)
        CALL AIO_WRITE( OCH, OBUF(:OUTWID-1), STATUS )
        WRITE( OBUF, '(A1,8X,A1,7A17)') '|', '|',
     :                       (' '//TYPE(I)(1:15)//'|', I = 1, NLDISP)
        CALL AIO_WRITE( OCH, OBUF(:OUTWID-1), STATUS )
        WRITE( OBUF, '(A1,8X,A1,7A17)') '|', '|',
     :                      (' '//LUNIT(I)(1:15)//'|', I = 1, NLDISP)
        CALL AIO_WRITE( OCH, OBUF(:OUTWID-1), STATUS )
        OBUF='|--------|'
        L=11
        DO I=1,NLDISP
          OBUF(L:)=' ---------------|'
          L=L+17
        ENDDO
        CALL AIO_WRITE( OCH, OBUF(:OUTWID-1), STATUS )

*    Loop over the ranges to display
        DO IRNG = 1, NRNG

*      Extract first and last event numbers in this range
          CALL ARR_ELEM1I( RNGPTR, 2*NRNG, (IRNG-1)*2+1, IE1, STATUS )
          CALL ARR_ELEM1I( RNGPTR, 2*NRNG, (IRNG-1)*2+2, IE2, STATUS )

*      Map this section for each list
          J = 1
          DO I = START, NDISP

*        Index the list
            CALL EDI_IDX( IFID, I, LID, STATUS )

*        Map data
            CALL EDI_MTYPE( LID, MTYPE(J), STATUS )
            IF ( STATUS .EQ. SAI__OK ) THEN
              CALL EDI_MAP( IFID, LNAMES(J), MTYPE(J), 'READ', IE1,
     :    		    IE2, PTRS(J), STATUS )
            ELSE
              CALL ERR_ANNUL( STATUS )
              PTRS(J) = 0
            END IF

*        Free the list
            CALL ADI_ERASE( LID, STATUS )

*        Increment list counter
            J = J + 1

*      Next list to map
          END DO

*      Print the list values
          DO I = IE1, IE2

*        Index into the mapped list sections
            IP = I - IE1 + 1

*        Extract and format data
            DO J = 1, NLDISP

*          Floating point list
              IF ( MTYPE(J) .EQ. 'DOUBLE' ) THEN
                CALL ARR_ELEM1D( PTRS(J), LLEN, IP, DVAL, STATUS )
                WRITE( C(J), '(1PG14.7)', IOSTAT=FSTAT ) DVAL

*          Integer list
              ELSE IF ( MTYPE(J) .EQ. 'INTEGER' ) THEN
                CALL ARR_ELEM1I( PTRS(J), LLEN, IP, IVAL, STATUS )
                WRITE( C(J), '(1X,I12)', IOSTAT=FSTAT ) IVAL

*          Logical list
              ELSE IF ( MTYPE(J) .EQ. 'LOGICAL' ) THEN
                CALL ARR_ELEM1L( PTRS(J), LLEN, IP, LVAL, STATUS )
                IF ( LVAL ) THEN
                   C(J) = '    True'
                ELSE
                   C(J) = '    False'
                END IF
              END IF

            END DO

*        Write data to buffer
 80         FORMAT( '|', I7, 1X, '|', 7(' ', A15,'|') )
            WRITE( OBUF, 80 ) I, (C(K), K = 1, NLDISP )

*        Write buffer to device
            CALL AIO_WRITE( OCH, OBUF(:OUTWID-1), STATUS )

*      Next event
          END DO

*      Unmap the lists on this page
          DO I = 1, NLDISP
            IF ( PTRS(I) .NE. 0 ) THEN
              CALL EDI_UNMAP( IFID, LNAMES(I), STATUS )
            END IF
          END DO

*    Next list range
        END DO

*    Page footer
        WRITE( OBUF, '(10(''-''),<NLDISP>(17(''-'')))')
        CALL AIO_WRITE( OCH, OBUF(:OUTWID-1), STATUS )

      END DO

*  Free index workspace
      CALL DYN_UNMAP( RNGPTR, STATUS )
      CALL DYN_UNMAP( IDXPTR, STATUS )

*  Close output channel
      CALL AIO_CANCL( 'DEV', STATUS )

*  Exit
 99   CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END


      SUBROUTINE EVLIST_L2R( NL, L, NR, R, STATUS )
*+
*  Name:
*     EVLIST_L2R

*  Purpose:
*     Convert a list of numbers into a list of consecutive ranges

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL EVLIST_L2R( NL, L, NR, R, STATUS )

*  Description:
*     {routine_description}

*  Arguments:
*     NL = INTEGER (given)
*        Number of values in list L
*     L[NR] = INTEGER (given)
*        Ordered list of values
*     NR = INTEGER (returned)
*        Number of ranges
*     R[2,*] = INTEGER (returned)
*        Start and stop indexes of ranges
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
*     {task_references}...

*  Keywords:
*     evlist, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     25 Sep 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER			NL, L(*)

*  Arguments Returned:
      INTEGER			NR, R(2,*)

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      INTEGER			J			! Loop over input

      LOGICAL			FOUND			! Found end of range
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise
      NR = 0
      J = 1

*  While more input values
      DO WHILE ( J .LE. NL )

*    Start of new range
        NR = NR + 1
        R(1,NR) = L(J)

*    Find end of range
        FOUND = .FALSE.
        DO WHILE ( (J.LE.NL) .AND. .NOT. FOUND )
          J = J + 1
          IF ( J .LE. NL ) THEN
            FOUND = ( L(J) .NE. (L(J-1)+1) )
          ELSE
            FOUND = .TRUE.
          END IF
        END DO

*    Set end of range
        IF ( FOUND ) THEN
          R(2,NR) = L(J-1)
        ELSE
          R(2,NR) = L(J)
        END IF

      END DO

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'EVLIST_L2R', STATUS )

      END
