      SUBROUTINE KPG1_MANID( NDIMI, DIMI, IN, NDIMO, DIMO, AXES, 
     :                         COLOFF, EXPOFF, OUT, STATUS )
*+
*  Name:
*     KPG1_MANID

*  Purpose:
*     Copy a data array with axis permutation and expansion.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_MANID( NDIMI, DIMI, IN, NDIMO, DIMO, AXES, COLOFF,
*                        EXPOFF, OUT, STATUS )

*  Description:
*     An input array is copied to an output array under control of a
*     supplied AXES vector.  Axes of the output array may be in a 
*     different order to those of the input array, and it may be 
*     required to expand along a new dimension or collapse along
*     an existing combination (being replaced by the mean of all
*     non-bad values).

*  Arguments:
*     NDIMI = INTEGER (Given)
*        The dimensionality of the input array.
*     DIMI( NDIMI ) = INTEGER (Given)
*        The shape of the input array.
*     IN( * ) = DOUBLE PRECISION (Given)
*        The input data array, vectorised.  The number of elements is
*        given by the product of the elements of DIMI.
*     NDIMO = INTEGER (Given)
*        The dimensionality of the output array (the number of elements
*        in AXES).
*     DIMO( NDIMO ) = INTEGER (Given)
*        The dimensions of the output array.  Information about the
*        extent of the expanded dimesions, as well as information 
*        implicit in DIMI and AXES, is held here.
*     AXES( NDIMO ) = INTEGER (Given)
*        An array determining how the output array is copied from the
*        input array.  The I'th element determines the source of the
*        I'th dimension of the output array.  If it is zero, a new
*        dimension will grow there.  Otherwise, it gives the index of
*        a dimension of the input array to copy.
*     COLOFF( * ) = INTEGER (Returned)
*        Workspace.  This array must have at least as many elements
*        as the product of all the dimensions of the input array along
*        which it is to be collapsed; that is the product of each 
*        element of DIMI whose index does not appear in AXES.
*     EXPOFF( * ) = INTEGER (Returned)
*        Workspace.  This array must have at least as many elements
*        as the product of all the newly expanded dimensions in the
*        output array; that is the product of each element of DIMO
*        for which the corresponding element of AXES is zero.
*     OUT( * ) = DOUBLE PRECISION (Returned)
*        The output array, vectorised.  The number of elements written 
*        is given by the product of the elements of NDIMO.
*     STATUS = INTEGER (Given)
*        The global status

*  Notes:
*     - The assumption that NDF__MXDIM = 7 is hard coded into this 
*     routine.
*     - A few arithmetic operations could be saved, at the expense of
*     the code's clarity,  by calculating the various array offsets 
*     at the same time as the next position vectors at various places 
*     in this routine.  Since this routine is unlikely to be a 
*     computational bottleneck I have favoured clarity over optimal 
*     performance.

*  Authors:
*     MBT: Mark Taylor (STARLINK)
*     {enter_new_authors_here}

*  History:
*     13-NOV-2001 (MBT):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF system constants
      INCLUDE 'PRM_PAR'          ! VAL__BADx constants

*  Arguments Given:
      INTEGER NDIMI
      INTEGER DIMI( NDIMI )
      DOUBLE PRECISION IN( * )
      INTEGER NDIMO
      INTEGER DIMO( NDIMO )
      INTEGER AXES( NDIMO )

*  Arguments Returned:
      INTEGER COLOFF( * )
      INTEGER EXPOFF( * )
      DOUBLE PRECISION OUT( * )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop index
      INTEGER J                  ! Loop index
      INTEGER IB                 ! Loop index over base pixels
      INTEGER IC                 ! Position in collapse offset array
      INTEGER IE                 ! Position in expand offset array
      INTEGER IXI                ! Position in vectorised input array
      INTEGER IXO                ! Position in vectorised output array
      INTEGER NBASO              ! Number of base (unique) output pixels
      INTEGER NCOLL              ! Num input pixels collapsed per base pixel
      INTEGER NEXP               ! Num output pixels expanded per base pixel
      INTEGER NVAL               ! Number of non-bad pixels used for sum
      INTEGER POSI( NDF__MXDIM ) ! Coordinates of current position in input
      INTEGER POSO( NDF__MXDIM ) ! Coordinates of current position in output
      INTEGER STRIDI( NDF__MXDIM ) ! Strides through input array dimensions
      INTEGER STRIDO( NDF__MXDIM ) ! Strides through output array dimensions
      LOGICAL USED( NDF__MXDIM ) ! Which axes of input array appear in output?
      DOUBLE PRECISION SUM       ! Sum of collapsed pixels for averaging
      DOUBLE PRECISION PIXI                ! Value of the current inupt pixel
      DOUBLE PRECISION PIXO                ! Value of the new output pixel

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ conversion routines
      INCLUDE 'NUM_DEF_CVT'

*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Calculate the array strides along each dimension for the input array.
      CALL KPG1_FILLI( 0, NDF__MXDIM, STRIDI, STATUS )
      STRIDI( 1 ) = 1
      DO I = 2, NDIMI
         STRIDI( I ) = STRIDI( I - 1 ) * DIMI( I - 1 )
      END DO

*  Calculate the array strides along each dimension for the output array.
      CALL KPG1_FILLI( 0, NDF__MXDIM, STRIDO, STATUS )
      STRIDO( 1 ) = 1
      DO I = 2, NDIMO
         STRIDO( I ) = STRIDO( I - 1 ) * DIMO( I - 1 )
      END DO

*  Find out which dimensions of the input array appear in the output
*  array.
      DO I = 1, NDIMI
         USED( I ) = .FALSE.
      END DO
      DO I = 1, NDIMO
         IF ( AXES( I ) .GT. 0 ) THEN
            USED( AXES( I ) ) = .TRUE.
         END IF
      END DO

*  Calculate the number of pixels in the input array which have to
*  be scanned for each base pixel in the output array.  This will only
*  be greater than one if we are collapsing along one or more 
*  dimensions.
      NCOLL = 1
      DO I = 1, NDIMI
         IF ( .NOT. USED( I ) ) THEN
            NCOLL = NCOLL * DIMI( I )
         END IF
      END DO

*  Calculate the list of offsets from the base position in the input
*  array which must be averaged over to get each result pixel.
      CALL KPG1_FILLI( 1, NDF__MXDIM, POSI, STATUS )
      DO IC = 1, NCOLL

*  Store the offset corresponding to the current relative position in 
*  the input array.
         COLOFF( IC ) =  ( POSI( 1 ) - 1 ) * STRIDI( 1 )
     :                 + ( POSI( 2 ) - 1 ) * STRIDI( 2 )
     :                 + ( POSI( 3 ) - 1 ) * STRIDI( 3 )
     :                 + ( POSI( 4 ) - 1 ) * STRIDI( 4 )
     :                 + ( POSI( 5 ) - 1 ) * STRIDI( 5 )
     :                 + ( POSI( 6 ) - 1 ) * STRIDI( 6 )
     :                 + ( POSI( 7 ) - 1 ) * STRIDI( 7 )

*  Get the next input array position along a collapsed dimension.
         J = 1
 2       CONTINUE
         IF ( USED( J ) ) THEN 
            IF ( J .LT. NDIMI ) THEN
               J = J + 1
               GO TO 2
            END IF
         ELSE
            IF ( POSI( J ) .LT. DIMI( J ) ) THEN
               POSI( J ) = POSI( J ) + 1
            ELSE
               POSI( J ) = 1
               J = J + 1
               GO TO 2
            END IF
         END IF
      END DO

*  Calculate the number of base (unique) pixels in the output array, 
*  and the number of copies of each.  If there is no expansion going
*  on, there will be only one copy of each.
      NEXP = 1
      NBASO = 1
      DO I = 1, NDIMO
         IF ( AXES( I ) .EQ. 0 ) THEN
            NEXP = NEXP * DIMO( I )
         ELSE
            NBASO = NBASO * DIMO( I )
         END IF
      END DO

*  Calculate the list of offsets from the base position in the output
*  array into which each pixel or collapsed set of pixels must be
*  copied into.
      CALL KPG1_FILLI( 1, NDF__MXDIM, POSO, STATUS )
      DO IE = 1, NEXP
         EXPOFF( IE ) = ( POSO( 1 ) - 1 ) * STRIDO( 1 )
     :                + ( POSO( 2 ) - 1 ) * STRIDO( 2 )
     :                + ( POSO( 3 ) - 1 ) * STRIDO( 3 )
     :                + ( POSO( 4 ) - 1 ) * STRIDO( 4 )
     :                + ( POSO( 5 ) - 1 ) * STRIDO( 5 )
     :                + ( POSO( 6 ) - 1 ) * STRIDO( 6 )
     :                + ( POSO( 7 ) - 1 ) * STRIDO( 7 )

*  Get the next output array position along an expanded dimension.
         J = 1
 3       CONTINUE
         IF ( AXES( J ) .GT. 0 ) THEN
            IF ( J .LT. NDIMO ) THEN
               J = J + 1
               GO TO 3
            END IF

         ELSE IF ( J .LE. NDIMO ) THEN

            IF ( POSO( J ) .LT. DIMO( J ) ) THEN
               POSO( J ) = POSO( J ) + 1
            ELSE IF ( J .LT. NDIMO ) THEN
               POSO( J ) = 1
               J = J + 1
               GO TO 3
            END IF
         END IF
      END DO

*  Loop over each base pixel in the output array, filling it and its
*  copies as appropriate from the input array.
      CALL KPG1_FILLI( 1, NDF__MXDIM, POSO, STATUS )
      DO IB = 1, NBASO

*  Get the offset into the array of the base output pixel from its
*  corodinates.
         IXO = POSO( 1 )
     :       + ( POSO( 2 ) - 1 ) * STRIDO( 2 )
     :       + ( POSO( 3 ) - 1 ) * STRIDO( 3 )
     :       + ( POSO( 4 ) - 1 ) * STRIDO( 4 )
     :       + ( POSO( 5 ) - 1 ) * STRIDO( 5 ) 
     :       + ( POSO( 6 ) - 1 ) * STRIDO( 6 )
     :       + ( POSO( 7 ) - 1 ) * STRIDO( 7 )

*  Get the coordinates of the base input pixel corresponding to this 
*  output pixel.
         DO I = 1, NDIMO
            IF ( AXES( I ) .GT. 0 ) THEN
               POSI( AXES( I ) ) = POSO( I )
            END IF
         END DO

*  Get the offset into the array of the base input pixel from its 
*  coordinates.
         IXI = POSI( 1 )
     :       + ( POSI( 2 ) - 1 ) * STRIDI( 2 ) 
     :       + ( POSI( 3 ) - 1 ) * STRIDI( 3 ) 
     :       + ( POSI( 4 ) - 1 ) * STRIDI( 4 )
     :       + ( POSI( 5 ) - 1 ) * STRIDI( 5 ) 
     :       + ( POSI( 6 ) - 1 ) * STRIDI( 6 )
     :       + ( POSI( 7 ) - 1 ) * STRIDI( 7 )

*  If we are not collapsing, just copy the value from the input to the
*  output array.
         IF ( NCOLL .EQ. 1 ) THEN
            PIXO = IN( IXI )

*  If we are collapsing, then average over the input pixels in the 
*  collapsed dimensions to form the output pixel.
         ELSE
            SUM = 0D0
            NVAL = 0
            DO IC = 1, NCOLL
               PIXI = IN( IXI + COLOFF( IC ) )
               IF ( PIXI .NE. VAL__BADD ) THEN
                  SUM = SUM + NUM_DTOD( PIXI )
                  NVAL = NVAL + 1
               END IF
            END DO
            IF ( NVAL .GT. 0 ) THEN
               PIXO = NUM_DTOD( SUM / DBLE( NVAL ) )
            ELSE
               PIXO = VAL__BADD
            END IF
         END IF

*  Copy the new pixel into its base position and any corresponding 
*  positions in newly expanded dimensions.
         DO IE = 1, NEXP
            OUT( IXO + EXPOFF( IE ) ) = PIXO
         END DO

*  Move to the next base output pixel.
         J = 1
 1       CONTINUE
         IF ( AXES( J ) .EQ. 0 ) THEN
            IF ( J .LT. NDIMO ) THEN
               J = J + 1
               GO TO 1
            END IF
         ELSE
            IF ( POSO( J ) .LT. DIMO( J ) ) THEN
               POSO( J ) = POSO( J ) + 1
            ELSE
               POSO( J ) = 1
               J = J + 1
               GO TO 1
            END IF
         END IF

      END DO

      END
