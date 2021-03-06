      SUBROUTINE SPD_WFTC( NELM, FITPAR, XVAL, WGHT,
     :   CENTRE, PEAK, FWHM, UNITY, HESSE, COVAR, FITTED, STATUS )
*+
*  Name:
*     SPD_WFTC

*  Purpose:
*     Calculate covariance for multi triangle fit.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SPD_WFTC( NELM, FITPAR, XVAL, WGHT, CENTRE, PEAK, FWHM,
*        UNITY, HESSE, COVAR, FITTED, STATUS )

*  Description:
*     This routine calculates the Hesse matrix of second derivatives of
*     chi-squared for a multi-triangle function with partly fixed
*     parameters, and inverts the Hessian to work out the covariance
*     matrix.
*     The approximation is used that the (i,j)-th element of the Hessian
*     is the product of the derivatives of the fitting function w.r.t.
*     i-th and w.r.t. j-th parameter. (Bevington 1969, Press et al.
*     1986).
*
*         d^2 chi^2        [  1  df(x_l) df(x_l) ]
*        ----------- ~ sum [ --- ------- ------- ]
*         da_i da_j     l  [ V_l  da_i    da_j   ]

*  Arguments:
*     NELM = INTEGER (Given)
*        Number of data points fitted.
*     FITPAR = INTEGER (Given)
*        Number of free parameters.
*     XVAL( NELM ) = REAL (Given)
*        Abscissa values x_l.
*     WGHT( NELM ) = REAL (Given)
*        Weight values w_l. These should be 1/variance or
*        1/(covariance_row_sum)
*     CENTRE( 6 ) = REAL (Given)
*        Centre position for each component.
*     PEAK( 6 ) = REAL (Given)
*        Peak height for each component.
*     FWHM( 6 ) = REAL (Given)
*        Full width at half maximum for each component.
*     UNITY( FITPAR, FITPAR ) = DOUBLE PRECISION (Returned)
*        Unity matrix.
*     HESSE( FITPAR, FITPAR ) = DOUBLE PRECISION (Returned)
*        Hesse matrix.
*     COVAR( FITPAR, FITPAR ) = DOUBLE PRECISION (Returned)
*        If VARUSE is true, COVAR returns the covariance matrix.
*        If VARUSE is false, COVAR returns the covariance matrix divided
*        by the square of the rms.
*     FITTED = LOGICAL (Returned)
*        True if calculating the covariance matrix was successful.
*     STATUS = INTEGER (Given and Returned)
*        The global status. This may be set if inversion fails.

*  References:
*     Bevington, P.R., 1969, Data reduction and error analysis for
*     the physical sciences, McGraw-Hill, New York, San Francisco,
*     St. Louis, Toronto, London, Sydney
*
*     Press, W.H., Flannery, B.P., Teukolsky, S.A., Vetterlink, W.T.,
*     1986, Numerical recipes, The art of scientific computing,
*     Cambridge University Press, Cambridge, London, New York, New
*     Rochelle, Melbourne, Sydney

*  Authors:
*     ajlf: Amadeu Fernandes (UoE)
*     hme: Horst Meyerdierks (UoE, Starlink)
*     {enter_new_authors_here}

*  History:
*     31 Jan 1992 (ajlf):
*        Adapted from Specdre 0.6's SPFHSS.
*     23 Jul 1992 (hme):
*        Re-adapted from Specdre 0.7's SPFHSS.
*     12 Aug 1992 (hme):
*        Re-arrange COMMON block, N*8 byte groups first, NGAUSS last.
*     08 Jun 1993 (hme):
*        Change warning prefix from FITTRI to SPABG.
*     10 Jun 1993 (hme):
*        Replace the half-baked concept of warnings with proper error
*        reporting. The calling routine must then supress reports and
*        ignore status.
*     23 Jun 1993 (hme):
*        Escape to label 500 after error report.
*     19 Dec 1994 (hme):
*        Renamed from SPABG, common block in include file.
*     30 Jan 1995 (hme):
*        Use new funtion for derivative.
*     20 Nov 1995 (hme):
*        Use PDA instead of NAG
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Global Variables:
      INCLUDE 'SPD_WFCM'         ! Line fitting common block

*  Arguments Given:
      INTEGER NELM
      INTEGER FITPAR
      REAL XVAL( NELM )
      REAL WGHT( NELM )
      REAL CENTRE( MAXCMP )
      REAL PEAK(   MAXCMP )
      REAL FWHM(   MAXCMP )

*  Arguments Returned:
      DOUBLE PRECISION UNITY( FITPAR, FITPAR )
      DOUBLE PRECISION HESSE( FITPAR, FITPAR )
      DOUBLE PRECISION COVAR( FITPAR, FITPAR )
      LOGICAL FITTED

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER K1                 ! Free parameters' outer loop index
      INTEGER K2                 ! Free parameters' inner loop index
      INTEGER L1                 ! All parameters' index corresp. to K1
      INTEGER L2                 ! All parameters' index corresp. to K2
      INTEGER J1                 ! K1's component number
      INTEGER J2                 ! K2's component number
      INTEGER N1                 ! Number of comps tied to J1 wrt K1
      INTEGER N2                 ! Number of comps tied to J2 wrt K2
      INTEGER M                  ! Loop index to count and identify ties
      INTEGER I                  ! Loop index trough data
      INTEGER TIE1( MAXCMP )     ! List of comps tied to J1 wrt K1
      INTEGER TIE2( MAXCMP )     ! List of comps tied to J2 wrt K2
      INTEGER IPVT( 3*MAXCMP )   ! Pivot vector
      INTEGER IFAIL              ! Error code from PDA routine
      DOUBLE PRECISION DFDAK1    ! df/da_K1
      DOUBLE PRECISION DFDAK2    ! df/da_K2
      DOUBLE PRECISION WKSPCE( 3*MAXCMP ) ! Workspace for NAG routine
      DOUBLE PRECISION HESMIN    ! Minimum matrix element
      DOUBLE PRECISION HESMAX    ! Maximum matrix element
      DOUBLE PRECISION HESCAL    ! Matrix scaling factor

*  Internal declarations:
      REAL SPD_UAAUR             ! Fit function derivative value

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Double loop through elements of unity matrix.
      DO 2 K1 = 1, FITPAR
         DO 1 K2 = 1, FITPAR
            UNITY(K2,K1) = 0D0
            IF ( K1.EQ.K2 ) UNITY(K2,K1) = 1D0
 1       CONTINUE
 2    CONTINUE

*  Outer loop through elements of Hessian matrix.
      DO 19 K1 = 1, FITPAR

*     K1 is the first index of the matrix element and as such an index
*     in the array of free parameters. The corresponding index in the
*     array of all (free, fixed, tied, unused) parameters (all centres
*     followed by all peaks followed by all dispersions) is L1. It is
*     derived from K1 by inverting the permutation PARNO.
         L1 = 1
 3       CONTINUE                ! Start of 'DO WHILE' loop
         IF ( PARNO(L1) .NE. K1 ) THEN
            L1 = L1 + 1
            GO TO 3
         END IF

*     From comparing L1 with multiples of MAXCMP follows the component
*     number J1 to which the free parameter in question belongs.
*     With the component J1 known, we can scan the array of flags for
*     other parameters tied to this one. N1 tells how many there are and
*     TIE1 is the array telling which components these are. (Only
*     corresponding parameters are tied, e.g. centres with centres.)

*     K1-th free parameter is J1-th centre.
         IF ( L1 .LE. MAXCMP ) THEN
            J1 = L1
            N1 = 0
            DO 4 M = J1+1, NCOMP
               IF ( PARFLG(M) .EQ. J1 ) THEN
                  N1 = N1 + 1
                  TIE1(N1) = M
               END IF
 4          CONTINUE

*     K1-th free parameter is J1-th peak.
         ELSE IF ( L1 .LE. 2*MAXCMP ) THEN
            J1 = L1 - MAXCMP
            N1 = 0
            DO 5 M = J1+1, NCOMP
               IF ( PARFLG(M+MAXCMP) .EQ. J1 ) THEN
                  N1 = N1 + 1
                  TIE1(N1) = M
               END IF
 5          CONTINUE

*     K1-th free parameter is J1-th dispersion.
         ELSE
            J1 = L1 - 2 * MAXCMP
            N1 = 0
            DO 6 M = J1+1, NCOMP
               IF ( PARFLG(M+2*MAXCMP) .EQ. J1 ) THEN
                  N1 = N1 + 1
                  TIE1(N1) = M
               END IF
 6          CONTINUE
         END IF

*     Inner loop through elements of Hessian matrix.
         DO 18 K2 = 1, FITPAR

*        If K2.GE.K1, we really need to calculate the element.
            IF ( K2 .GE. K1 ) THEN

*           If K2.NE.K1 we need bother about L2,J2,N2,TIE2,
*           else the derivative w.r.t. free parameter K2 would be equal
*           to that w.r.t. free parameter K1.
               IF ( K2 .NE. K1 ) THEN

*              Derive L2 from K2 by inverting PARNO.
                  L2 = 1
 7                CONTINUE       ! Start of 'DO WHILE' loop
                  IF ( PARNO(L2) .NE. K2 ) THEN
                     L2 = L2 + 1
                     GO TO 7
                  END IF

*              Derive J2 from L2 by comparing with multiples of MAXCMP.
*              Derive N2 and TIE2 by scanning through flags.
                  CONTINUE

*              K2-th free parameter is J2-th centre.
                  IF ( L2 .LE. MAXCMP ) THEN
                     J2 = L2
                     N2 = 0
                     DO 8 M = J2+1, NCOMP
                        IF ( PARFLG(M) .EQ. J2 ) THEN
                           N2 = N2 + 1
                           TIE2(N2) = M
                        END IF
 8                   CONTINUE

*              K2-th free parameter is J2-th peak.
                  ELSE IF ( L2 .LE. 2*MAXCMP ) THEN
                     J2 = L2 - MAXCMP
                     N2 = 0
                     DO 9 M = J2+1, NCOMP
                        IF ( PARFLG(M+MAXCMP) .EQ. J2 ) THEN
                           N2 = N2 + 1
                           TIE2(N2) = M
                        END IF
 9                   CONTINUE

*              K2-th free parameter is J2-th dispersion.
                  ELSE
                     J2 = L2 - 2 * MAXCMP
                     N2 = 0
                     DO 10 M = J2+1, NCOMP
                        IF ( PARFLG(M+2*MAXCMP) .EQ. J2 ) THEN
                           N2 = N2 + 1
                           TIE2(N2) = M
                        END IF
 10                  CONTINUE
                  END IF
               END IF

*           Initialise the matrix element to 0 before adding it up while
*           looping through the data.
               HESSE(K2,K1) = 0D0

*           Loop through data (index I).
               DO 17 I = 1, NELM

*              Work out df(xI)/daK1.

*              If K1 is a centre.
                  IF ( L1 .LE. MAXCMP ) THEN

*                 Derivative of J1th Gauss function wrt CENTRE(J1).
                     DFDAK1 = DBLE( SPD_UAAUR( 1, CENTRE(J1), PEAK(J1),
     :                  FWHM(J1), XVAL(I) ) )

*                 Derivative of TIE1(M)-th component wrt CENTRE(J1).
                     DO 11 M = 1, N1
                        DFDAK1 = DFDAK1
     :                     + DBLE( SPD_UAAUR( 1, CENTRE(TIE1(M)),
     :                     PEAK(TIE1(M)), FWHM(TIE1(M)), XVAL(I) ) )
 11                  CONTINUE

*              Else if K1 is a peak.
                  ELSE IF ( L1 .LE. 2*MAXCMP ) THEN

*                 Derivative of J1th Gauss function wrt PEAK(J1).
                     DFDAK1 = DBLE( SPD_UAAUR( 2, CENTRE(J1), PEAK(J1),
     :                  FWHM(J1), XVAL(I) ) )

*                 Derivative of TIE1(M)-th component wrt PEAK(J1).
                     DO 12 M = 1, N1
                        DFDAK1 = DFDAK1
     :                     + DBLE( SPD_UAAUR( 2, CENTRE(TIE1(M)),
     :                     PEAK(TIE1(M)), FWHM(TIE1(M)), XVAL(I) ) )
 12                  CONTINUE

*              Else (K1 is a dispersion).
                  ELSE

*                 Derivative of J1th Gauss function wrt FWHM(J1).
                     DFDAK1 = DBLE( SPD_UAAUR( 3, CENTRE(J1), PEAK(J1),
     :                  FWHM(J1), XVAL(I) ) )

*                 Derivative of TIE1(M)-th component wrt FWHM(J1).
                     DO 13 M = 1, N1
                        DFDAK1 = DFDAK1
     :                     + DBLE( SPD_UAAUR( 3, CENTRE(TIE1(M)),
     :                     PEAK(TIE1(M)), FWHM(TIE1(M)), XVAL(I) ) )
 13                  CONTINUE
                  END IF

*              If K2.NE.K1. we need bother about different df(xI)/daK2.
                  IF ( K2 .NE. K1 ) THEN

*                 Work out df(xI)/daK2.

*                 If K2 is a centre.
                     IF ( L2 .LE. MAXCMP ) THEN

*                    Derivative of J2th Gauss function wrt CENTRE(J2).
                        DFDAK2 = DBLE( SPD_UAAUR( 1, CENTRE(J2),
     :                     PEAK(J2), FWHM(J2), XVAL(I) ) )

*                    Derivative of TIE2(M)-th component wrt CENTRE(J2).
                        DO 14 M = 1, N2
                           DFDAK2 = DFDAK2
     :                        + DBLE( SPD_UAAUR( 1, CENTRE(TIE2(M)),
     :                        PEAK(TIE2(M)), FWHM(TIE2(M)), XVAL(I) ) )
 14                     CONTINUE

*                 Else if K2 is a peak.
                     ELSE IF ( L2 .LE. 2*MAXCMP ) THEN

*                    Derivative of J2th Gauss function wrt PEAK(J2).
                        DFDAK2 = DBLE( SPD_UAAUR( 2, CENTRE(J2),
     :                     PEAK(J2), FWHM(J2), XVAL(I) ) )

*                    Derivative of TIE2(M)-th component wrt PEAK(J2).
                        DO 15 M = 1, N2
                           DFDAK2 = DFDAK2
     :                        + DBLE( SPD_UAAUR( 2, CENTRE(TIE2(M)),
     :                        PEAK(TIE2(M)), FWHM(TIE2(M)), XVAL(I) ) )
 15                     CONTINUE

*                 Else (K2 is a dispersion).
                     ELSE

*                    Derivative of J2th Gauss function wrt FWHM(J2).
                        DFDAK2 = DBLE( SPD_UAAUR( 3, CENTRE(J2),
     :                     PEAK(J2), FWHM(J2), XVAL(I) ) )

*                    Derivative of TIE2(M)-th component wrt FWHM(J2).
                        DO 16 M = 1, N2
                           DFDAK2 = DFDAK2
     :                        + DBLE( SPD_UAAUR( 3, CENTRE(TIE2(M)),
     :                        PEAK(TIE2(M)), FWHM(TIE2(M)), XVAL(I) ) )
 16                     CONTINUE
                     END IF

*              Else df(xI)/daK2 = df(xI)/daK1.
                  ELSE
                     DFDAK2 = DFDAK1
                  END IF

*              Add this pixel's contribution to the matrix element.
                  HESSE(K2,K1) = HESSE(K2,K1)
     :               + DFDAK1 * DFDAK2 * WGHT(I)
 17            CONTINUE

*        Else we can copy the matrix element from the other half.
            ELSE
               HESSE(K2,K1) = HESSE(K1,K2)
            END IF
 18      CONTINUE
 19   CONTINUE

*  Get the extreme absolute values of diagonal elements.
*  The hope is that these include the most extreme values.
*  The motivation is that matrix elements should not be too great so
*  that F04AFF does not crash.
      HESMIN = ABS( HESSE(1,1) )
      HESMAX = HESMIN
      DO 20 K1 = 2, FITPAR
         HESMIN = MIN( HESMIN, ABS( HESSE(K1,K1) ) )
         HESMAX = MAX( HESMAX, ABS( HESSE(K1,K1) ) )
 20   CONTINUE

*  Scaling factor.
      HESCAL = SQRT(HESMIN) * SQRT(HESMAX)
      IF ( HESCAL .GT. 0D0 ) THEN
         HESCAL = 1D0 / HESCAL
      ELSE
         HESCAL = 1D0
      END IF

*  Preemptive scaling of the matrix.
      DO 22 K1 = 1, FITPAR
         DO 21 K2 = 1, FITPAR
            COVAR(K2,K1) = HESSE(K2,K1) * HESCAL
 21      CONTINUE
 22   CONTINUE

*  Inverting the Hessian results in the covariance.
      FITTED = .TRUE.
      CALL PDA_DGEFA( COVAR, FITPAR, FITPAR, IPVT, IFAIL )
      IF ( IFAIL .EQ. 0 ) THEN
         CALL PDA_DGEDI( COVAR, FITPAR, FITPAR, IPVT, 0D0, WKSPCE, 1 )
      END IF

*  Deal with error conditions. A failure of inversion is non-fatal.
*  In case of failure set covariance matrix to zero.
      IF ( IFAIL .NE. 0 ) THEN
         DO 24 K1 = 1, FITPAR
            DO 23 K2 = 1, FITPAR
               COVAR(K2,K1) = 0D0
 23         CONTINUE
 24      CONTINUE
         FITTED = .FALSE.
         STATUS = SAI__ERROR
         CALL ERR_REP( 'SPD_WFTC_NAGERR', 'SPD_WFTC: Error ' //
     :      'inverting Hesse matrix (calulating covariance).', STATUS )
         GO TO 500
      END IF

*  Post-inversion scaling of the matrix.
      DO 26 K1 = 1, FITPAR
         DO 25 K2 = 1, FITPAR
            COVAR(K2,K1) = COVAR(K2,K1) * HESCAL
 25      CONTINUE
 26   CONTINUE

*  Return.
 500  CONTINUE
      END
