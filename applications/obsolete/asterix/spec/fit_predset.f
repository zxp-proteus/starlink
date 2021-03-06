*+  FIT_PREDSET - Sets up components of <PREDICTION> structure
	SUBROUTINE FIT_PREDSET( DID, NDS, WORKSPACE, IDAT, IPRED,
     :                          STATUS )
*    Description :
*     All components of the FORTRAN structure PREDDAT (of type <PREDICTION>),
*     apart from PREDDAT.CONVOLVE which must already be defined, are set up.
*     The model space dimension and bin boundary values are extracted either
*     from the instrument response structure (if PREDDAT.CONVOLVE is TRUE)
*     or from the axis values of the dataset (if it is FALSE).
*     The logical WORKSPACE determines whether the workspace required for
*     chi-squared gradient calculations is set up, this is only required if
*     fitting is to be performed, not for generation of predicted data or
*     evaluation of chi-squared.
*    Method :
*     Note that if instrument convolution is to be performed then the only
*     components needed from OBDAT are OBDAT.NDAT and OBDAT.SETINDEX (which is
*     zero unless the dataset is a spectral set). Otherwise the dimension
*     information is also required.
*    Deficiencies :
*     The only type of instrument response catered for at present is energy
*     response.
*    Bugs :
*    Authors :
*     Trevor Ponman (BHVAD::TJP)
*    History :
*
*     14 Apr 88 : FIT_MSPACE adapted from FIT_DATGET (TJP)
*      8 Jul 88 : Dimensioning bug fixed (TJP)
*     21 Oct 88 : Renamed to FIT_PREDSET (TJP)
*     22 Feb 89 : ASTERIX88 version (TJP)
*     27 Sep 89 : Mod. to handle scalar axis WIDTH (TJP)
*     15 Mar 94 : Don't allocated DFDPPTR. If NMDAT is large then NPAMAX*NMDAT
*                 can get enormous! (DJA)
*      4 Mar 1996 (DJA):
*        Create grouped predicted data array too
*
*    Type Definitions :
*
	IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'PRM_PAR'
      INCLUDE 'FIT_PAR'
*    Structure definitions :
      INCLUDE 'FIT_STRUC'
*    Import :
        INTEGER			DID			! Dataset identifier
	INTEGER NDS			! Current dataset number
	LOGICAL WORKSPACE		! Set up chisq gradient workspace?
c	RECORD /DATASET/ OBDAT		! Observed datasets
*    Import-Export :
c	RECORD /PREDICTION/ PREDDAT	! Data predicted by model
        INTEGER IDAT, IPRED
*    Export :
*    Status :
	INTEGER STATUS
*    Local constants :
*    Local variables :
	INTEGER MBNDPTR			! Pointer to bounds in response object
	INTEGER I			! Index
      INTEGER			RMFID, ARFID
      INTEGER			IDIMM(FIT__MXDIM)
*-

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Instrument folding case (model space bins taken from response structure)
      IF ( PREDICTION_CONVOLVE(IPRED) ) THEN

*    Locate response
        CALL ERI_GETIDS( DID, DATASET_SETINDEX(IDAT), RMFID, ARFID,
     :                   STATUS )

*    Size of model space energy axis
        CALL ADI_CGET0I( RMFID, 'NENERGY', PREDICTION_NMDAT(IPRED),
     :                   STATUS )

*    This is 1-D specific
	PREDICTION_NMDIM(IPRED) = 1
	PREDICTION_IDIMM(1,IPRED) = PREDICTION_NMDAT(IPRED)
	PREDICTION_NMBOUND(IPRED) = PREDICTION_NMDAT(IPRED)

*    Set up model space bounds
	CALL DYN_MAPR( 1, PREDICTION_NMBOUND(IPRED),
     :                 PREDICTION_MLBNDPTR(IPRED), STATUS )
	CALL DYN_MAPR( 1, PREDICTION_NMBOUND(IPRED),
     :                 PREDICTION_MUBNDPTR(IPRED), STATUS )
	IF(STATUS.NE.SAI__OK) GOTO 99

*    Map energy bounds, decompose into lower and upper arrays
        CALL ADI_CMAPR( RMFID, 'Energy', 'READ', MBNDPTR, STATUS )
	CALL FIT_PREDSET_LUBND( PREDICTION_NMBOUND(IPRED),
     :                          %VAL(MBNDPTR),
     :                          %VAL(PREDICTION_MLBNDPTR(IPRED)),
     :                          %VAL(PREDICTION_MUBNDPTR(IPRED)))
        CALL ADI_CUNMAP( RMFID, 'Energy', MBNDPTR, STATUS )

*    Storage for predicted model array
	CALL DYN_MAPR( 1, PREDICTION_NMDAT(IPRED),
     :                 PREDICTION_MPTR(IPRED), STATUS )

*  No convolution - model space is identical to data space. Set up only
*  those components of PREDDAT required (not MPTR), using data axis values.
      ELSE

	PREDICTION_MPTR(IPRED)=0			! Flag for `not set'
	PREDICTION_NMDIM(IPRED)=DATASET_NDIM(IDAT)
	PREDICTION_NMBOUND(IPRED)=0
	DO I=1,DATASET_NDIM(IDAT)
	  PREDICTION_IDIMM(I,IPRED) = DATASET_IDIM(I,IDAT)
	  PREDICTION_NMBOUND(IPRED) = PREDICTION_NMBOUND(IPRED)+
     :                                  PREDICTION_IDIMM(I,IPRED)
	END DO
	PREDICTION_NMDAT(IPRED) = DATASET_NDAT(IDAT)

*    Set up model bounds using axis values from observed data
	CALL DYN_MAPR(1,PREDICTION_NMBOUND(IPRED),
     :                                PREDICTION_MLBNDPTR(IPRED),STATUS)
	CALL DYN_MAPR(1,PREDICTION_NMBOUND(IPRED),
     :                                PREDICTION_MUBNDPTR(IPRED),STATUS)

*    Copy over local data then restore
        DO I = 1, PREDICTION_NMDIM(IPRED)
          IDIMM(I) =  PREDICTION_IDIMM(I,IPRED)
        END DO
	CALL FIT_PREDSET_AXBOUND( DID, NDS,PREDICTION_NMDIM(IPRED),
     :    IDIMM,PREDICTION_NMBOUND(IPRED),
     :    %VAL(PREDICTION_MLBNDPTR(IPRED)),
     :    %VAL(PREDICTION_MUBNDPTR(IPRED)),STATUS)
        DO I = 1, PREDICTION_NMDIM(IPRED)
           PREDICTION_IDIMM(I,IPRED) = IDIMM(I)
        END DO

      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

* Storage for predicted data and if necessary workspace for chisq gradient
      CALL DYN_MAPR(1,DATASET_NDAT(IDAT),PREDICTION_DPTR(IPRED),STATUS)
      IF ( WORKSPACE ) THEN
	CALL DYN_MAPR(1,PREDICTION_NMDAT(IPRED),
     :                               PREDICTION_PREDPTR(1,IPRED),STATUS)
        IF ( .NOT. DATASET_GFLAG(IDAT) ) THEN
	  CALL DYN_MAPR(1,PREDICTION_NMDAT(IPRED),
     :                               PREDICTION_PREDPTR(2,IPRED),STATUS)
        END IF
        PREDICTION_DFDPPTR(IPRED) = VAL__BADI

*  Set explicitly to zero as a flag for `workspace not mapped'
      ELSE
	PREDICTION_PREDPTR(1,IPRED) = 0
	PREDICTION_PREDPTR(2,IPRED) = 0
	PREDICTION_DFDPPTR(IPRED) = 0

      END IF

*  Grouping? Set up array for grouped predicted model data
      DO I = 1, 2
        IF ( DATASET_GFLAG(IDAT) ) THEN
          CALL DYN_MAPR( 1, DATASET_NGDAT(IDAT),
     :                   PREDICTION_PGDPTR(I,IPRED), STATUS )
        ELSE
          PREDICTION_PGDPTR(I,IPRED) = PREDICTION_PREDPTR(I,IPRED)
        END IF
      END DO
      IF ( DATASET_GFLAG(IDAT) ) THEN
        CALL DYN_MAPR( 1, DATASET_NGDAT(IDAT),
     :                 PREDICTION_GDPTR(IPRED), STATUS )
      ELSE
        PREDICTION_GDPTR(IPRED) = PREDICTION_DPTR(IPRED)
      END IF

*  Exit
 99   IF ( STATUS .NE. SAI__OK ) THEN
        CALL AST_REXIT( 'FIT_PREDSET', STATUS )
      END IF

      END


*+  FIT_PREDSET_AXBOUND - Generates bin boundaries from data axis values
      SUBROUTINE FIT_PREDSET_AXBOUND(DID,NDS,NMDIM,IDIMM,NBOUND,LBOUND,
     :UBOUND,STATUS)
*    Description :
*     Uses axis information to set up bin boundaries for data modelling.
*     For data of dimension >1 it is assumed that there are just NBIN(i)
*     lower and upper bounds for each dimension, and these are concatenated
*     into the LBOUND and UBOUND arrays.
*    History :
*     30 Mar 87: Original (TJP)
*     31 Mar 88: Lower and upper axis bounds, zero width if no axis_error (TJP)
*     15 Feb 89: ASTERIX88 version (TJP)
*    Type Definitions :
	IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Import :
        INTEGER			DID			! Dataset id
	INTEGER NDS			! Current dataset number
	INTEGER NMDIM			! Dimensionality of data
	INTEGER IDIMM(NMDIM)		! No of bounds
	INTEGER NBOUND			! No of bin bounds
*    Import-Export :
*    Export :
	REAL LBOUND(NBOUND)		! Data bin lower bounds
	REAL UBOUND(NBOUND)		! Data bin upper bounds
*    Status :
	INTEGER STATUS
*    Local variables :
	INTEGER AXPTR			! Pointer to axis data
	INTEGER AXNO			! Axis number
	INTEGER N			! Current bound number
*-

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Loop through data dimensions
      N = 1
      DO AXNO = 1, NMDIM

*    Get axis values
        CALL BDI_AXMAPR( DID, AXNO, 'Bounds', 'READ', AXPTR, STATUS )

	IF(STATUS.NE.SAI__OK)THEN

*     No axis data available, assume spot values 0,1,2,3,4... (i.e. both
*     sets of bounds the same)
	    CALL ERR_ANNUL(STATUS)
	    CALL ARR_REG1R(0.0,1.0,IDIMM(AXNO),LBOUND(N),STATUS)
	    CALL ARR_REG1R(0.0,1.0,IDIMM(AXNO),UBOUND(N),STATUS)
	    CALL MSG_SETI('NDS',NDS)
	    CALL MSG_PRNT( 'No axis values found in dataset ^NDS - '//
     :                               'assuming spot values 0,1,2...' )
	  ELSE

*    Set up bounds
	    CALL FIT_PREDSET_AXBOUND_SET(IDIMM(AXNO),%VAL(AXPTR),
     :                                   LBOUND(N),UBOUND(N))
            CALL BDI_AXUNMAP( DID, AXNO, 'Bounds', AXPTR, STATUS )

	  ENDIF
	  N=N+IDIMM(AXNO)

      END DO

*  Exit
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL AST_REXIT( 'FIT_PREDSET_AXBOUND', STATUS )
      END IF

      END


*+  FIT_PREDSET_AXBOUND_SET - Sets up bin boundaries for one axis
      SUBROUTINE FIT_PREDSET_AXBOUND_SET(NBIN,BNDS,LBOUND,UBOUND)
*    Description :
*     Uses axis data and  width if available to set up bin boundaries.
*     If no bin width information is available then spot values
*     are assumed, and the lower and upper bounds are equal.
*    History :
*     31 Mar 87 : Original (TJP)
*     13 Apr 88 : Modified to return lower and upper bounds (TJP)
*     17 Feb 89 : ASTERIX88 version, axis width (rather than error/errorm) (TJP)
*    Type Definitions :
	IMPLICIT NONE
*    Global constants :
*    Import :
	INTEGER NBIN			! No of axis bins
        REAL	BNDS(2,NBIN)		! Bounds
*    Import-Export :
*    Export :
	REAL LBOUND(*)			! Lower bin bounds
	REAL UBOUND(*)			! Upper bin bounds
*    Status :
*    Local variables :
	INTEGER I
*-

*
      DO I = 1, NBIN
        LBOUND(I) = BNDS(1,I)
        UBOUND(I) = BNDS(2,I)
      END DO

      END

*+  FIT_PREDSET_LUBND - Extracts lower and upper bounds from single bound array
      SUBROUTINE FIT_PREDSET_LUBND(NBND,MBND,LBOUND,UBOUND)
*    Description :
*     Decomposes an array of model bin bounds (assuming contiguous bins) into
*     separate lower & upper bin bound arrays.
*    History :
*     21 Mar 88: Original (TJP)
*      8 Jul 88: Dimensioning bug fixed (TJP)
*    Type Definitions :
	IMPLICIT NONE
*    Import :
	INTEGER NBND			! No of output bounds
	REAL MBND(NBND+1)		! Input bounds
*    Import-Export :
*    Export :
	REAL LBOUND(NBND)		! Lower bin bounds
	REAL UBOUND(NBND)		! Upper bin bounds
*    Local constants :
*    Local variables :
	INTEGER I
*-

	DO I=1,NBND
	  LBOUND(I)=MBND(I)
	  UBOUND(I)=MBND(I+1)
	ENDDO
	END

*+  FIT_PREDSET_LUCEN - Sets up model bounds from bin centre values
      SUBROUTINE FIT_PREDSET_LUCEN(NBIN,BIN,LBOUND,UBOUND)
*    Description :
*     Sets up lower & upper model bin bound arrays from bin centre values,
*     assuming contiguous bins.
*     The ambiguity in defining N+1 bounds from N bin values is resolved by
*     assuming that the second bound lies mid-way between the first two bin
*     centres.
*    History :
*     30 Mar 87: Original (TJP)
*      8 Jul 87: Bounds correctly handled where no base value is defined (TJP)
*     21 Mar 88: Modified to give lower & upper bounds (TJP)
*     15 Feb 89: ASTERIX88 version, no base value passed in (TJP)
*    Type Definitions :
	IMPLICIT NONE
*    Import :
	INTEGER NBIN			! No of bins
	REAL BIN(NBIN)			! Bin centres
*    Import-Export :
*    Export :
	REAL LBOUND(NBIN)		! Lower bin bounds
	REAL UBOUND(NBIN)		! Upper bin bounds
*    Local constants :
*    Local variables :
	INTEGER I
	REAL BASE			! Base value
*-

* Base value
	BASE=(3*BIN(1)-BIN(2))/2.0	! Corresponds to definition in header
	LBOUND(1)=BASE

* Other bounds
	DO I=1,NBIN
	  UBOUND(I)=2*BIN(I)-LBOUND(I)		! i.e. BIN are bin centres
	  IF(I.LT.NBIN)THEN
	    LBOUND(I+1)=UBOUND(I)
	  ENDIF
	ENDDO
	END
