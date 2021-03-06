      SUBROUTINE BDI1_ARYWB( BDID, HFID, PSID, STATUS )
*+
*  Name:
*     BDI1_ARYWB

*  Purpose:
*     Write back an array to an HDS file

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL BDI1_ARYWB( BDID, PSID, STATUS )

*  Description:
*     This routine is called before the association between a bit of memory
*     and an HDS object is destroyed. If the memory is a simple mapping then
*     the HDS object is simply unmapped. If the memory is dynamically
*     allocated because, for example, it is one of the more complicated
*     representations, then more work has to be done.

*  Arguments:
*     BDID = INTEGER (given)
*        ADI identifier to top level BDI object
*     HFID = INTEGER (given)
*        The ADI identifier of the HDS file object
*     PSID = INTEGER (given)
*        ADI identifier to private storage
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
*     This routine coerces to the simple array representations, but there
*     should be some mechanism for handling magic values and writing the
*     appropriate flags.

*  References:
*     BDI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/bdi.html

*  Keywords:
*     package:bdi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     9 Aug 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'

*  Arguments Given:
      INTEGER                   BDID,HFID,PSID

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*(DAT__SZLOC)	DLOC			! DATA locator
      CHARACTER*(DAT__SZLOC)	LOC			! Item locator
      CHARACTER*3		MSYS			! Mapping system
      CHARACTER*6		MODE			! Mapping mode
      CHARACTER*(DAT__SZTYP)	MTYPE			! Mapping type
      CHARACTER*(DAT__SZNAM)	NAME			! Object name
      CHARACTER*(DAT__SZLOC)	PLOC			! Object parent locator
      CHARACTER*(DAT__SZTYP)	TYPE			! BASE type
      CHARACTER*6		VARNT			! Array variant

      INTEGER			ANDIM, ADIMS(DAT__MXDIM)! Existing object dimensions
      INTEGER			FPTR			! Mapped file data
      INTEGER			I			! Loop over dimensions
      INTEGER			NDIM, DIMS(DAT__MXDIM)	! Object dimensions
      INTEGER			PTR			! Item data address

      LOGICAL			OK			! Locator is valid?
      LOGICAL			PRIM			! Object is primitive?
      LOGICAL			SAME			! Objects same shape?
      LOGICAL			THERE			! Object exists?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get mapping mode
      CALL ADI_CGET0C( PSID, 'MapSystem', MSYS, STATUS )

*  Get mode
      CALL ADI_CGET0C( PSID, 'Mode', MODE, STATUS )

*  Get pointers
      CALL ADI_CGET0I( PSID, 'FilePtr', FPTR, STATUS )
      CALL ADI_CGET0I( PSID, 'Ptr', PTR, STATUS )

*  Extract locator
      CALL ADI_CGET0C( PSID, 'Locator', LOC, STATUS )

*  Dynamic mapping which requires write back?
      IF ( (MSYS.NE.'loc') .AND. (MODE.NE.'READ') ) THEN

*    If the HDS object is a primitive and MSYS is not equal to 'loc'
*    it is because the HDS object dimensions are incorrect. We must fix
*    this when we write back the data
        CALL DAT_PRIM( LOC, PRIM, STATUS )
        IF ( PRIM ) THEN

*      Extract dimensions
          CALL ADI_THERE( PSID, 'SHAPE', THERE, STATUS )
          IF ( THERE ) THEN
            CALL ADI_CGET1I( PSID, 'SHAPE', DAT__MXDIM, DIMS, NDIM,
     :                       STATUS )
          ELSE
            NDIM = 0
            DIMS(1) = 0
          END IF

*      Get type used to map
          CALL ADI_CGET0C( PSID, 'Type', MTYPE, STATUS )

*      Get actual dimensions and compare with those of the dat we want to write
          CALL DAT_SHAPE( LOC, DAT__MXDIM, ADIMS, ANDIM, STATUS )
          SAME = (ANDIM.EQ.NDIM)
          I = 1
          DO WHILE ( (I.LE.NDIM) .AND. SAME )
            IF ( DIMS(I) .EQ. ADIMS(I) ) THEN
              I = I + 1
            ELSE
              SAME = .FALSE.
            END IF
          END DO

*      Recreate data if wrong shape
          IF ( .NOT. SAME ) THEN
            CALL DAT_PAREN( LOC, PLOC, STATUS )
            CALL DAT_NAME( LOC, NAME, STATUS )
            CALL DAT_ANNUL( LOC, STATUS )
            CALL DAT_ERASE( PLOC, NAME, STATUS )
            CALL DAT_NEW( PLOC, NAME, '_'//MTYPE, NDIM, DIMS, STATUS )
            CALL DAT_FIND( PLOC, NAME, LOC, STATUS )
            CALL DAT_ANNUL( PLOC, STATUS )
          END IF

*      Write the data
          CALL DAT_PUT( LOC, '_'//MTYPE, NDIM, DIMS, %VAL(PTR), STATUS )

        ELSE

*      Get existing array variant
          CALL CMP_GET0C( LOC, 'VARIANT', VARNT, STATUS )
          IF ( STATUS .NE. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'BDI1_ARYWB_1',
     :           'Error accessing array variant', STATUS )

          ELSE IF ( VARNT .EQ. 'SPACED' ) THEN

*        Get type used to map
            CALL ADI_CGET0C( PSID, 'Type', MTYPE, STATUS )

*        Get dimensions
            CALL DAT_THERE( LOC, 'DIMENSION', THERE, STATUS )
            IF ( THERE ) THEN
              CALL CMP_GET0I( LOC, 'DIMENSION', DIMS(1), STATUS )
              NDIM = 1
            ELSE
              CALL CMP_GET1I( LOC, 'DIMENSION', DAT__MXDIM, DIMS(1),
     :                        NDIM, STATUS )
            END IF

*        Convert to simple array variant
            CALL CMP_TYPE( LOC, 'BASE', TYPE, STATUS )
            CALL DAT_NEW( LOC, 'DATA', TYPE, NDIM, DIMS, STATUS )
            CALL DAT_FIND( LOC, 'DATA', DLOC, STATUS )
            CALL DAT_PUT( DLOC, '_'//MTYPE, NDIM, DIMS, %VAL(PTR),
     :                    STATUS )
            CALL DAT_ANNUL( DLOC, STATUS )
            CALL CMP_PUT0C( LOC, 'VARIANT', 'SIMPLE', STATUS )

*        Erase old spaced array components
            CALL DAT_ERASE( LOC, 'BASE', STATUS )
            CALL DAT_ERASE( LOC, 'SCALE', STATUS )
            IF ( THERE ) THEN
              CALL DAT_ERASE( LOC, 'DIMENSION', STATUS )
            ELSE
              CALL DAT_ERASE( LOC, 'DIMENSIONS', STATUS )
            END IF

          ELSE
            STATUS = SAI__ERROR
            CALL MSG_SETC( 'V', VARNT )
            CALL ERR_REP( 'BDI1_ARYWB_1', 'Unrecognised array '/
     :                    /'variant /^V/', STATUS )
          END IF

        END IF

*    Release dynamic memory
        CALL DYN_UNMAP( PTR, STATUS )

      END IF

*  Check it's valid
      CALL DAT_VALID( LOC, OK, STATUS )
      IF ( OK ) THEN
        IF ( FPTR .NE. 0 ) THEN
          CALL DAT_UNMAP( LOC, STATUS )
        END IF
        CALL DAT_ANNUL( LOC, STATUS )
      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL AST_REXIT( 'BDI1_ARYWB', STATUS )
      END IF

      END
