      SUBROUTINE NDF2ASCII( STATUS )
*+
*  Name:
*     NDF2ASCII

*  Purpose:
*     Converts an NDF to an ASCII file.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL NDF2ASCII( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application converts an NDF to an ASCII file.  Only one of
*     the array components may be copied to the output file.  Preceding
*     the data there is an optional header consisting of either the
*     FITS extension with the values of certain keywords replaced by
*     information derived from the NDF, or a minimal FITS header also
*     derived from the NDF.  The output file uses LIST carriagecontrol.

*  Usage:
*     NDF2ASCII IN OUT [COMP] [RECLEN] NOPEREC=?

*  ADAM Parameters:
*     COMP = LITERAL (Read)
*        The NDF component to be copied.  It may be "Data", "Quality"
*        or "Variance". ["Data"]
*     FITS = _LOGICAL (Read)
*        If true, any FITS extension is written to start of the output
*        file, unless there is no extension whereupon a minimal FITS
*        header is written to the ASCII file. [FALSE]
*     FIXED = _LOGICAL (Read)
*        If true, the output file allocates a fixed number of
*        characters per data value.  The number of characters chosen is
*        the minimum that prevents any loss of precision, and hence is
*        dependent on the data type of the NDF array.  When FIXED is
*        FALSE, data values are packed as efficiently as possible within
*        each record. [FALSE]
*     IN = NDF (Read)
*        Input NDF data structure. The suggested default is the current
*        NDF if one exists, otherwise it is the current value.
*     NOPEREC = _INTEGER (Read)
*        The number of data values per record of the output file, when
*        FIXED is TRUE.  It should be in the range 1 to 16383.
*        The suggested default is the current value, or 8 when there
*        is not one.
*     OUT = FILENAME (Write)
*        Name of the output formatted Fortran file.  The file will
*        normally have variable-length records when there is a header,
*        but always fixed-length records when there is no header.  It
*        has a default file extension of ".DAT".
*     RECLEN = _INTEGER (Read)
*        The maximum record length in bytes of the output file.  This
*        must be between 32 and 32766.  The lower limit is further
*        increased to 80 when there is a FITS header to be copied.  It
*        is only used when FIXED is FALSE and will default to the
*        current value, or 512 if there is no current value.  When
*        FIXED is TRUE the application creates data records whose
*        length is the product of the number of bytes per value plus
*        one (for the space), times the number of values per record. []

*  Examples:
*     NDF2ASCII CLUSTER CLUSTER.DAT
*        This copies the data array of the NDF called CLUSTER to an
*        ASCII file called CLUSTER.DAT.  The maximum recordlength of
*        CLUSTER.DAT is 512 bytes, and the data values are packed into
*        these records as efficiently as possible.
*     NDF2ASCII CLUSTER CLUSTER.DAT V
*        This copies the variance of the NDF called CLUSTER to an
*        ASCII file called CLUSTER.DAT.  The maximum recordlength of
*        CLUSTER.DAT is 512 bytes, and the variance values are packed
*        into these records as efficiently as possible.
*     NDF2ASCII CLUSTER CLUSTER.DAT FIXED NOPEREC=12
*        This copies the data array of the NDF called CLUSTER to an
*        ASCII file called CLUSTER.DAT.  There are twelve data values
*        per record in CLUSTER.DAT. 
*     NDF2ASCII OUT=NDF234.DAT FITS RECLEN=128 IN=@234
*        This copies the data array of the NDF called 234 to an
*        ASCII file called NDF234.DAT.  The maximum recordlength of
*        CLUSTER.DAT is 128 bytes, and the data values are packed into
*        these records as efficiently as possible.  If there is a FITS
*        extension, it is copied to NDF234.DAT with substitution of
*        certain keywords, otherwise a minimal FITS header is produced.

*  Notes:
*     The details of the conversion are as follows:
*        -  the NDF array as selected by COMP is written to the ASCII
*        file in records following an optional header.  When FIXED is
*        FALSE all records are padded out to the recordlength.
*        -  HISTORY is not propagated.
*        -  ORIGIN information is lost.
*
*     When a header is to be made, it is composed of FITS-like card
*     images as follows:
*        -  The number of dimensions of the data array is written 
*        to the keyword NAXIS, and the actual dimensions to NAXIS1,
*        NAXIS2 etc. as appropriate.
*        -  If the NDF contains any linear axis structures the 
*        information necessary to generate these structures is 
*        written to the FITS-like headers. For example, if a linear 
*        AXIS(1) structure exists in the input NDF the value of the 
*        first data point is stored with the keyword CRVAL1,
*        and the incremental value between successive axis data is 
*        stored in keyword CDELT1. If there is an axis label it is
*        written to keyword CRTYPE1, and axis unit is written to CTYPE1.
*        (Similarly for AXIS(2) structures etc.) FITS does not have a
*        standard method of storing axis widths and variances, so these
*        NDF components will not be propagated to the header.
*        Non-linear axis data arrays cannot be represented by CRVALn
*        and CDELTn, and must be ignored.
*        -  If the input NDF contains TITLE, LABEL or UNITS components
*        these are stored with the keywords TITLE, LABEL or BUNITS
*        respectively.
*        -  If the input NDF contains a FITS extension, the FITS items 
*        may be written to the FITS-like header, with the following 
*        exceptions:
*           o  BITPIX is derived from the type of the NDF data array,
*           and so it is not copied from the NDF FITS extension.
*           o  NAXIS, and NAXISn are derived from the dimensions of the
*           NDF data array as described above, so these items are not
*           copied from the NDF FITS extension.
*           o  The TITLE, LABEL, and BUNITS descriptors are only copied
*           if no TITLE, LABEL, and UNITS NDF components respectively
*           have already been copied into these headers.
*           o  The CDELTn, CRVALn, CTYPEn, and CRTYPEn descriptors in
*           the FITS extension are only copied if the input NDF
*           contained no linear axis structures.
*           o  The standard order of the FITS keywords is preserved,
*           thus BITPIX, NAXIS and NAXISn appear immediately after the
*           first card image, which should be SIMPLE.
*           o  BSCALE and BZERO in a FITS extension are copied when
*           BITPIX is positive, i.e. the array is not floating-point.
*        -  An extra header record with keyword UNSIGNED and logical
*        value T is added when the array data type is one of the HDS
*        unsigned integer types.  This is done because standard FITS
*        does not support unsigned integers, and allows (in conjunction
*        with BITPIX) applications reading the ASCII file to determine
*        the data type of the array.
*        -  The last header record card will be the standard FITS END.
*        -  Other extensions are not propagated.

*  Related Applications:
*     CONVERT: ASCII2NDF; KAPPA: TRANDAT; SPECDRE: ASCIN and ASCOUT.

*  Implementation Status:
*     -  The value of bad pixels is not written to a FITS-like header
*     record with keyword BLANK.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1991 January 28 (MJC):
*        Original version.
*     1992 September 15 (MJC):
*        Added more control of the formatting of the output file.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      INTEGER   NFLAGS           ! Number of flags to indicate
                                 ! presence special NDF components
      PARAMETER( NFLAGS = 6 )
      INTEGER   SZDESC           ! Size of descriptor names
      PARAMETER( SZDESC = 8 )
      INTEGER   SZFITS           ! Size of FITS string
      PARAMETER( SZFITS = 80 )
      INTEGER   SZVAL            ! Size of descriptor values
      PARAMETER( SZVAL = 70 )

*  Local Variables:
      LOGICAL AXIFND             ! True if NDF contains a linear axis
                                 ! comps.
      LOGICAL AXLFND             ! True if NDF contains axis label
      LOGICAL AXUFND             ! True if NDF contains axis units
      LOGICAL BAD                ! Need to check for bad pixels?
      CHARACTER * ( DAT__SZLOC ) CLOC ! Locator to single FITS card
      LOGICAL CMPFND( NFLAGS )   ! True if certain special NDF
                                 ! components are present
      CHARACTER*( 25 ) COMLIS    ! List of the NDF components
      INTEGER COMLN              ! The used length of COMLIS
      CHARACTER*( 8 ) COMP       ! The component of NDF to plot
      LOGICAL CPFITS             ! True if there is a FITS extension to
                                 ! copy to the ASCII file's header
      CHARACTER DESCR * ( SZDESC ) ! Accommodates descriptor name
      CHARACTER * ( NDF__SZFTP ) DTYPE ! Processing type for
                                 ! integer array (not used)
      INTEGER EL                 ! Number of mapped elements
      LOGICAL END                ! True if there is no END card
                                 ! terminating the FITS extension
      INTEGER FD                 ! File descriptor
      CHARACTER * ( DAT__SZLOC ) FLOC ! Locator to FITS extension
      CHARACTER FITSTR *( SZFITS ) ! A FITS-header card
      LOGICAL FIXED              ! If true the output data are in fixed
                                 ! format
      LOGICAL HEADER             ! If true there will be FITS-like
                                 ! header
      INTEGER I                  ! Loop counter
      LOGICAL IDATA              ! True if NDF array is integer type
      CHARACTER * ( NDF__SZTYP ) ITYPE ! Implementation type for
                                 ! integer array
      LOGICAL LABFND             ! True if NDF LABEL found
      INTEGER NCARD              ! Number of cards in FITS extension
      INTEGER NCPVAL             ! Number of characters required to
                                 ! format a data value without loss of
                                 ! precision
      INTEGER NDF                ! Identifier for NDF
      INTEGER NUMPRE             ! Number of data values per record
      LOGICAL OPEN               ! Output file opened successfully
      INTEGER PNTR( 1 )          ! Pointer to NDF mapped array
      INTEGER RECL               ! Maximum recordlength of ASCII file
                                 ! in bytes
      INTEGER RECMIN             ! Minimum record length of the ASCII
                                 ! file
      LOGICAL THERE              ! FITS extension is present
      LOGICAL TITFND             ! True if NDF TITLE found
      CHARACTER * ( NDF__SZTYP ) TYPE ! Data type for processing
      LOGICAL UNTFND             ! True if NDF UNITS found
      CHARACTER VALUE * ( SZVAL ) ! Accommodates descriptor value

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain the input NDF.
*  =====================

*  Begin an NDF context.
      CALL NDF_BEGIN

*  Obtain an identifier for the input NDF.
      CALL NDF_ASSOC( 'IN', 'READ', NDF, STATUS )

*  Find out which component is to be processed.
*  ============================================

*  Form the component list of the input NDF. Data-array component must
*  exist for the file to be an NDF.
      COMLIS = 'Data'
      COMLN = 4
      
*  If the Quality component exists, append it to component list.
      CALL NDF_STATE( NDF, 'Quality', THERE, STATUS )
      IF ( THERE ) THEN
         CALL CHR_APPND( ','//'Quality', COMLIS, COMLN )
         COMLN = COMLN + 8
      END IF

*  If the Variance component exists, append it to component list.
      CALL NDF_STATE( NDF, 'Variance', THERE, STATUS )
      IF ( THERE ) THEN
         CALL CHR_APPND( ','//'Variance', COMLIS, COMLN )
         COMLN = COMLN + 9
      END IF

*  Find which component to copy. 
      CALL PAR_CHOIC( 'COMP', 'Data', COMLIS( :COMLN ), .FALSE., COMP,
     :                 STATUS )

*  Find the data type of the component.
      CALL NDF_TYPE( NDF, COMP, TYPE, STATUS )

*  Decide whether BSCALE and BZERO will need copying, i.e. is the type
*  floating point?
      IDATA = .NOT. ( TYPE .EQ. '_REAL' .OR. TYPE .EQ. '_DOUBLE' )

*  Process the FITS extension
*  ==========================

*  Is there a FITS extension?
      CALL NDF_XSTAT( NDF, 'FITS', THERE, STATUS )

*  Set the default minimum largest recordlength.
      RECMIN = 32

*  Ask if it there is to be a FITS-like header?
      CALL PAR_GET0L( 'FITS', HEADER, STATUS )

*  Is there a FITS extension to be copied?  If there is, set the minimum
*  recordlength to 80 for the ASCII FITS headers.
      CPFITS = HEADER .AND. THERE
      IF ( CPFITS ) RECMIN = 80

*  Find the formatting arrangement for the output file.
*  ====================================================

*  Determine whether there are a fixed number of values per output
*  record.
      CALL PAR_GET0L( 'FIXED', FIXED, STATUS )

*  Obtain the number of values per record.
      IF ( FIXED ) THEN
         CALL PAR_GDR0I( 'NOPEREC', 8, 1, 16383, .FALSE., NUMPRE,
     :                   STATUS )

*  Derive the number characters needed to store this without loss
*  of precision depending on the data type.
         IF ( TYPE .EQ. '_BYTE' ) THEN
            NCPVAL = VAL__SZB
         
         ELSE IF ( TYPE .EQ. '_DOUBLE' ) THEN
            NCPVAL = VAL__SZD

         ELSE IF ( TYPE .EQ. '_INTEGER' ) THEN
            NCPVAL = VAL__SZI

         ELSE IF ( TYPE .EQ. '_REAL' ) THEN
            NCPVAL = VAL__SZR

         ELSE IF ( TYPE .EQ. '_UBYTE' ) THEN
            NCPVAL = VAL__SZUB

         ELSE IF ( TYPE .EQ. '_UWORD' ) THEN
            NCPVAL = VAL__SZUW

         ELSE IF ( TYPE .EQ. '_WORD' ) THEN
            NCPVAL = VAL__SZW

         END IF

*  Derive the recordlength in bytes, allowing for a space between each 
*  value.
         RECL = ( NCPVAL + 1 ) * NUMPRE
      ELSE

*  Obtain the maximum recordlength in bytes of the output (free-format)
*  file.
         CALL PAR_GDR0I( 'RECLEN', 512, RECMIN, 32766, .FALSE., RECL,
     :                   STATUS )
      END IF

*  Open the ASCII file.
*  ====================

*  Open the FORTRAN file.
      CALL FIO_ASSOC( 'OUT', 'WRITE', 'LIST', RECL, FD, STATUS )

*  Process the FITS header.
*  ========================
      IF ( CPFITS ) THEN

*      Each item is copied to a header record except:
*         NAXIS, NAXISn - these are derived directly from the NDF data
*           array;
*         CRVALn, CDELTn, CRTYPEn, CTYPEn - derived from the NDF axis
*           structures if possible. If no linear NDF axis structures
*           are present, the values in the NDF FITS extension are
*           copied.  If any are non-linear all FITS axis information is
*           lost.
*         TITLE, LABEL, BUNITS - the values held in NDF TITLE, LABEL,
*           and UNITS are used if present, otherwise any values found in
*           the FITS extension are used.

*      Initialise flags to indicate that these components have not
*      been found.
         AXIFND = .FALSE.
         AXLFND = .FALSE.
         AXUFND = .FALSE.
         TITFND = .FALSE.
         LABFND = .FALSE.
         UNTFND = .FALSE.

*  Obtain a locator to the FITS extension.
         CALL NDF_XLOC( NDF, 'FITS', 'READ', FLOC, STATUS )

*  Get its shape, i.e. the number of FITS cards.
         CALL DAT_SIZE( FLOC, NCARD, STATUS )

*  Initialise flag to indicate whether or not an END card-image needs to
*  be added to the header.
         END = .FALSE.

*  Loop for each card.
         DO  I = 1, NCARD

*  Access the cell.
            CALL DAT_CELL( FLOC, 1, I, CLOC, STATUS )

*  Obtain its value.
            CALL DAT_GET0C( CLOC, FITSTR, STATUS )

*  Extract the FITS string.
            DESCR = FITSTR( 1:SZDESC )
            VALUE( 1:SZVAL ) = FITSTR( 11:SZFITS )

*  Update the end flag.
            END = I .EQ. NCARD .AND. DESCR( 1:3 ) .NE. 'END'

*  Leave out BITPIX, NAXIS, NAXISn, and possibly CDELTn, CRVALn,
*  CRTYPEn, CTYPEn, TITLE, LABEL, and BUNITS as described above.  Note
*  CROTAn are also excluded.
            IF ( ( INDEX( DESCR, 'NAXIS' ) .EQ. 0 ) .AND.
     :        ( INDEX( DESCR, 'BITPIX' ) .EQ. 0 ) .AND.
     :        ( INDEX( DESCR, 'BSCALE') .EQ. 0 .OR. IDATA ) .AND.
     :        ( INDEX( DESCR, 'BZERO' ) .EQ. 0 .OR. IDATA ) .AND.
     :        ( INDEX( DESCR, 'CDELT' ) .EQ. 0 .OR. .NOT. AXIFND ) .AND.
     :        ( INDEX( DESCR, 'CRVAL' ) .EQ. 0 .OR. .NOT. AXIFND ) .AND.
     :        ( INDEX( DESCR, 'CROTA' ) .EQ. 0 .OR. .NOT. AXIFND ) .AND.
     :        ( INDEX( DESCR, 'CRTYPE') .EQ. 0 .OR. .NOT. AXLFND ) .AND.
     :        ( INDEX( DESCR, 'CTYPE' ) .EQ. 0 .OR. .NOT. AXUFND ) .AND.
     :        ( INDEX( DESCR, 'LABEL' ) .EQ. 0 .OR. .NOT. LABFND ) .AND.
     :        ( INDEX( DESCR, 'BUNITS') .EQ. 0 .OR. .NOT. UNTFND ) .AND.
     :        ( INDEX( DESCR, 'TITLE') .EQ. 0 .OR. .NOT. TITFND ) ) THEN

*  Write the FITS card to the ASCII file.
               CALL FIO_WRITE( FD, FITSTR, STATUS )

*  This code assumes that the FITS header will begin with the mandatory
*  headers in the mandatory order.  It is not worth the great effort to
*  validate the FITS descriptors of a defunct format.  Thus keyword one
*  is SIMPLE.  Want to write after this.
               IF ( I .EQ. 1 ) THEN

*  Insert NAXIS, AXISn, and optional keywords to the header if the
*  appropriate special objects are present in the NDF.
                  CALL CON_SPHEA( NDF, FD, TYPE, 'FORMATTED', NFLAGS,
     :                            CMPFND, STATUS )

*  Use more obvious flags to indicate the certain items have been
*  written to the descriptors already.
                  AXIFND = CMPFND( 1 )
                  AXLFND = CMPFND( 2 )
                  AXUFND = CMPFND( 3 )
                  TITFND = CMPFND( 4 )
                  LABFND = CMPFND( 5 )
                  UNTFND = CMPFND( 6 )
               END IF
            END IF

*  Free the locator for the next card.
            CALL DAT_ANNUL( CLOC, STATUS )

*  Avoid unnecessary looping if something has gone wrong.
            IF ( STATUS .NE. SAI__OK ) GOTO 999
         END DO

*  Append the END card image if necessary.
         IF ( END ) THEN
            FITSTR = ' '
            FITSTR( 1:3 ) = 'END'

*  Write the FITS card to the ASCII file.
            CALL FIO_WRITE( FD, FITSTR, STATUS )

         END IF

*  Tidy the locator.
         CALL DAT_ANNUL( FLOC, STATUS )

*  Write a brief FITS header.
*  ==========================
      ELSE IF ( HEADER ) THEN

*  Create the SIMPLE card.
         FITSTR = ' '
         FITSTR( 1:9 ) = 'SIMPLE  ='
         FITSTR( 30: ) = 'T / File is simple'

*  Write the FITS card to the ASCII file.
         CALL FIO_WRITE( FD, FITSTR, STATUS )

*  Insert NAXIS, AXISn, and optional keywords to the header. 
         CALL CON_SPHEA( NDF, FD, TYPE, 'FORMATTED', NFLAGS, CMPFND,
     :                   STATUS )

*  Create the END card.
         FITSTR = ' '
         FITSTR( 1:3 ) = 'END'

*  Write the FITS card to the ASCII file.
         CALL FIO_WRITE( FD, FITSTR, STATUS )

      END IF

*  Process the input array.
*  ========================

*  Obtain the implementation type.
      CALL NDF_MTYPE( '_INTEGER,_REAL,_DOUBLE', NDF, NDF, COMP, ITYPE,
     :                DTYPE, STATUS )
      
*  Map the input data array using the implementation data type.
      CALL NDF_MAP( NDF, COMP, ITYPE, 'READ', PNTR, EL, STATUS )

*  Call a routine to write the data to the ASCII Fortran file.  The
*  selected routine depending on the data type of the array.  Note
*  that the implemented type for the integers is used, since the
*  subroutine called cannot process one- and two-byte integers
*  (due to a limitation of the CHR library).  So we convert to an
*  integer array and it gets converted back to the actual type when the
*  array is unmapped.
      IF ( ITYPE .EQ. '_INTEGER' ) THEN
         CALL CON_OAFFI( FD, EL, %VAL( PNTR( 1 ) ), FIXED, NCPVAL,
     :                   NUMPRE, RECL, STATUS )

      ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
         CALL CON_OAFFD( FD, EL, %VAL( PNTR( 1 ) ), FIXED, NCPVAL,
     :                   NUMPRE, RECL, STATUS )

      ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
         CALL CON_OAFFR( FD, EL, %VAL( PNTR( 1 ) ), FIXED, NCPVAL,
     :                   NUMPRE, RECL, STATUS )

      END IF

  999 CONTINUE

*  Close the output file.
      CALL FIO_CLOSE( FD, STATUS )

*  End the NDF context.
      CALL NDF_END( STATUS )

*  If an error occurred, then report context information.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'NDF2ASCII_ERR',
     :     'NDF2ASCII: Error converting an NDF to an ASCII file.',
     :     STATUS )
      END IF

      END

