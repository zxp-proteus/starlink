      SUBROUTINE COF_WSTR( FUNIT, EXTNAM, EXTTYP, EXTLEV, WRITTN,
     :                     STATUS )
*+
*  Name:
*     COF_WSTR

*  Purpose:
*     Writes a dummy object into a FITS binary table.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL COF_WSTR( FUNIT, EXTNAM, EXTTYP, EXTLEV, WRITTN, STATUS )

*  Description:
*     The routine creates a FITS binary table of one row to store the
*     a dummy object called DUMMY_FOR_STRUC.  This is used to preserve
*     extension structures containing only NDFs whose paths may need
*     to be recreatedby FITS2NDF.

*  Arguments:
*     FUNIT = INTEGER (Given)
*        The logical unit number of the output FITS file.
*     EXTNAM = CHARACTER * ( * ) (Given)
*        The name of the structure.
*     EXTTYP = CHARACTER * ( * ) (Given)
*        The data type of the structure.
*     EXTLEV = INTEGER (Given)
*        The extension level.  Must be a positive integer.  If not it
*        is not written to the FITS header.
*     WRITTN = LOGICAL (Returned)
*        If .TRUE. the binary table has been written successfully.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Prior requirements:
*     -  A primary HDU unit exists in the FITS file, and the FITS file
*     is open.

*  Notes:
*    -  The component path, less any prefix to omit, is stored in the
*    EXTNAME keyword.
*    -  EXTTYP is written to the EXTTYPE keyword.
*    -  EXTLEV is written to the EXTLEVEL keyword.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     2008 February 11 (MJC):
*        Original version.
*     {enter_changes_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! Data-system constants
      INCLUDE 'PRM_PAR'          ! Primitive-data constants

*  Arguments Given:
      INTEGER FUNIT
      CHARACTER * ( * ) EXTNAM
      CHARACTER * ( * ) EXTTYP
      INTEGER EXTLEV

*  Arguments Returned:
      LOGICAL WRITTN

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER FITSOK             ! Good status for FITSIO library
      PARAMETER( FITSOK = 0 )

      INTEGER MXOBJ              ! Maximum number of objects
      PARAMETER ( MXOBJ = 1 )

*  Local Variables:
      CHARACTER*80  CDUMMY       ! Dummy for reading TFORMn cards
      INTEGER CPOS               ! Character position
      INTEGER FSTAT              ! FITSIO status
      INTEGER IVALUE             ! Integer component value
      INTEGER NCEXT              ! Column from which the EXTNAME starts
      CHARACTER*6 ROUTIN         ! Name of the FITSIO routine used to
                                 ! copy data into the binary table
      CHARACTER*1 SHAPE          ! Shape of the structure
      INTEGER SIZE               ! Size of the dummy HDS object
      CHARACTER*( DAT__SZTYP ) TFORM( MXOBJ ) ! Components' types
      CHARACTER*( DAT__SZNAM ) TTYPE( MXOBJ ) ! Names of the
                                 ! binary-table columns
      CHARACTER*1 TUNIT( MXOBJ ) ! Binary-table component types
      CHARACTER*( DAT__SZTYP ) TYPE ! Type of the component

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the return value.
      WRITTN = .FALSE.

*  Initialise the FITSIO status.  It's not the same as the Starlink
*  status, which is reset by the fixed part.
      FSTAT = FITSOK

*  Assimilate the information to make the binary-table header.
*  ===========================================================

*  Assign its name and record that as the label for the column.  Note 
*  the FITS type is equivalent to HDS name just to confuse matters.
*  There is only one column for the primitive object.
      TTYPE( 1 ) = 'DUMMY_FOR_STRUC'

*  Assign component's data type and size.
      TYPE = '_INTEGER'
      SIZE = 1

*  Convert the type to the binary-table code.
      CALL COF_HT2BN( TYPE, SIZE, TFORM( 1 ), STATUS )

*  Assign a null units.
      TUNIT( 1 ) = ' '

*  Obtain the shape of the component.
      SHAPE = '0'
      
      NCEXT = 1

*  Don't create a new extension if there was something wrong with the
*  component.
      IF ( STATUS .NE. SAI__OK ) GOTO 999

*  Create the binary table.
*  ========================

*  Create new header and data section.
      CALL FTCRHD( FUNIT, FSTAT )

*  Create binary-table header.  There is only one row in the table.
*  The "variable-length data area" has length of 0 bytes.
      CALL FTPHBN( FUNIT, 1, 1, TTYPE, TFORM, TUNIT,
     :             EXTNAM( NCEXT: ), 0, FSTAT )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.
      IF ( FSTAT .GT. FITSOK ) THEN
         CALL COF_FIOER( FSTAT, 'COF_WSTR_ERR1',
     :      'FTPHBN', 'Error writing binary-table header.', STATUS )
         GOTO 999
      END IF

*  Write the TNULL1 card for an integer object (column).
*  =====================================================

*  FITSIO does not permit cards to be placed after a named card; 
*  it requires that we read that named card first.  So choose the
*  the TFORM1 card.  Note that by definition the table only has one
*  column.
      CALL FTGCRD( FUNIT, 'TFORM1', CDUMMY, FSTAT )

*  Insert the TNULL1 card whose value is the bad/null value the integer 
*  data type.
      CALL FTIKYJ( FUNIT, 'TNULL1', VAL__BADI,
     :             'Starlink bad value', FSTAT )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.  Specify from which routine the error arose.
      IF ( FSTAT .GT. FITSOK ) THEN
         CALL COF_FIOER( FSTAT, 'COF_WSTR_ERR7', 'FTIKYJ',
     :     'Error writing TNULL1 card for a binary table.',
     :     STATUS )
         GOTO 999
      END IF

*  Write additional header cards.
*  ==============================

*  These pertain to the structure rather than columns in the table.

*  Set the extension level.
      CALL FTPKYJ( FUNIT, 'EXTLEVEL', EXTLEV, 'Level in the '/
     :             /'hierarchical structure', FSTAT )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.
      IF ( FSTAT .GT. FITSOK ) THEN
         CALL COF_FIOER( FSTAT, 'COF_WSTR_ERR2', 'FTPKYJ',
     :     'Error writing extension level in header.', STATUS )
         GOTO 999
      END IF

*  Set the extension type.
      CALL FTPKYS( FUNIT, 'EXTTYPE', EXTTYP, 'HDS data '/
     :             /'type of the primitive object', FSTAT )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.
      IF ( FSTAT .GT. FITSOK ) THEN
         CALL COF_FIOER( FSTAT, 'COF_WSTR_ERR3', 'FTPKYS',
     :     'Error writing extension type in header.', STATUS )
         GOTO 999
      END IF

*  Set the extension shape.
      CALL FTPKYS( FUNIT, 'EXTSHAPE', SHAPE, 'Shape '/
     :             /'of the hierarchical structure', FSTAT )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.
      IF ( FSTAT .GT. FITSOK ) THEN
         CALL COF_FIOER( FSTAT, 'COF_WSTR_ERR8', 'FTPKYS',
     :     'Error writing extension shape in header.', STATUS )
         GOTO 999
      END IF

*  Define the structure of the binary table.
*  =========================================

*  Define the structure of a new binary table.  The "variable-length
*  data area" has length of 0 bytes.  The first 1 is because there is
*  only one column.
      CALL FTBDEF( FUNIT, 1, TFORM, 0, 1, FSTAT )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.
      IF ( FSTAT .GT. FITSOK ) THEN
         CALL COF_FIOER( FSTAT, 'COF_WSTR_ERR3', 'FTBDEF',
     :     'Error defining binary-table structure.', STATUS )
         GOTO 999
      END IF

*  Copy a scalar value to the table.
*  =================================

*  Obtain each value using the appropriate type and write it to the
*  binary table. 

*  Set the current null value for undefined values.
      CALL FTTNUL( FUNIT, 1, VAL__BADI, FSTAT )

*  Handle a bad status.  Negative values are reserved for non-fatal
*  warnings.  Specify from which routine the error arose.
      IF ( FSTAT .GT. FITSOK ) THEN
         CALL COF_FIOER( FSTAT, 'COF_WSTR_ERR6', 'FTTNUL',
     :     'Error setting null value for a binary-table '/
     :     /'column.', STATUS )
         GOTO 999
      END IF

*  Set duumy value.
      IVALUE = 1

*  Copy the integer value to the FITS binary table.
      CALL FTPCLI( FUNIT, 1, 1, 1, 1, IVALUE, FSTAT )
      ROUTIN = 'FTPCLI'
      
*  Record that the extension was written satisfactorily.
      WRITTN = .TRUE.

*  Exit point if something has gone wrong.
  999 CONTINUE

      END
