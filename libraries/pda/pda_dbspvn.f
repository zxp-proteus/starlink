*DECK PDA_DBSPVN
      SUBROUTINE PDA_DBSPVN (T, JHIGH, K, INDEX, X, ILEFT, VNIKX, WORK,
     +   IWORK, STATUS)
C***BEGIN PROLOGUE  PDA_DBSPVN
C***PURPOSE  Calculate the value of all (possibly) nonzero basis
C            functions at X.
C***LIBRARY   SLATEC
C***CATEGORY  E3, K6
C***TYPE      DOUBLE PRECISION (BSPVN-S, PDA_DBSPVN-D)
C***KEYWORDS  EVALUATION OF B-SPLINE
C***AUTHOR  Amos, D. E., (SNLA)
C***DESCRIPTION
C
C     Written by Carl de Boor and modified by D. E. Amos
C
C     Abstract    **** a double precision routine ****
C         PDA_DBSPVN is the BSPLVN routine of the reference.
C
C         PDA_DBSPVN calculates the value of all (possibly) nonzero basis
C         functions at X of order MAX(JHIGH,(J+1)*(INDEX-1)), where T(K)
C         .LE. X .LE. T(N+1) and J=IWORK is set inside the routine on
C         the first call when INDEX=1.  ILEFT is such that T(ILEFT) .LE.
C         X .LT. T(ILEFT+1).  A call to PDA_DINTRV(T,N+1,X,ILO,ILEFT,MFLAG)
C         produces the proper ILEFT.  PDA_DBSPVN calculates using the basic
C         algorithm needed in DBSPVD.  If only basis functions are
C         desired, setting JHIGH=K and INDEX=1 can be faster than
C         calling DBSPVD, but extra coding is required for derivatives
C         (INDEX=2) and DBSPVD is set up for this purpose.
C
C         Left limiting values are set up as described in DBSPVD.
C
C     Description of Arguments
C
C         Input      T,X are double precision
C          T       - knot vector of length N+K, where
C                    N = number of B-spline basis functions
C                    N = sum of knot multiplicities-K
C          JHIGH   - order of B-spline, 1 .LE. JHIGH .LE. K
C          K       - highest possible order
C          INDEX   - INDEX = 1 gives basis functions of order JHIGH
C                          = 2 denotes previous entry with work, IWORK
C                              values saved for subsequent calls to
C                              PDA_DBSPVN.
C          X       - argument of basis functions,
C                    T(K) .LE. X .LE. T(N+1)
C          ILEFT   - largest integer such that
C                    T(ILEFT) .LE. X .LT.  T(ILEFT+1)
C
C         Output     VNIKX, WORK are double precision
C          VNIKX   - vector of length K for spline values.
C          WORK    - a work vector of length 2*K
C          IWORK   - a work parameter.  Both WORK and IWORK contain
C                    information necessary to continue for INDEX = 2.
C                    When INDEX = 1 exclusively, these are scratch
C                    variables and can be used for other purposes.
C          STATUS  - Returned error status.
C                    The status must be zero on entry. This
C                    routine does not check the status on entry.
C
C     Error Conditions
C         Improper input is a fatal error.
C
C***REFERENCES  Carl de Boor, Package for calculating with B-splines,
C                 SIAM Journal on Numerical Analysis 14, 3 (June 1977),
C                 pp. 441-472.
C***ROUTINES CALLED  PDA_XERMSG
C***REVISION HISTORY  (YYMMDD)
C   800901  DATE WRITTEN
C   890831  Modified array declarations.  (WRB)
C   890831  REVISION DATE from Version 3.2
C   891214  Prologue converted to Version 4.0 format.  (BAB)
C   900315  CALLs to XERROR changed to CALLs to PDA_XERMSG.  (THJ)
C   920501  Reformatted the REFERENCES section.  (WRB)
C   950403  Implement status.  (HME)
C***END PROLOGUE  PDA_DBSPVN
C
      INTEGER STATUS
      INTEGER ILEFT, IMJP1, INDEX, IPJ, IWORK, JHIGH, JP1, JP1ML, K, L
      DOUBLE PRECISION T, VM, VMPREV, VNIKX, WORK, X
C     DIMENSION T(ILEFT+JHIGH)
      DIMENSION T(*), VNIKX(*), WORK(*)
C     CONTENT OF J, DELTAM, DELTAP IS EXPECTED UNCHANGED BETWEEN CALLS.
C     WORK(I) = DELTAP(I), WORK(K+I) = DELTAM(I), I = 1,K
C***FIRST EXECUTABLE STATEMENT  PDA_DBSPVN
      IF(K.LT.1) GO TO 90
      IF(JHIGH.GT.K .OR. JHIGH.LT.1) GO TO 100
      IF(INDEX.LT.1 .OR. INDEX.GT.2) GO TO 105
      IF(X.LT.T(ILEFT) .OR. X.GT.T(ILEFT+1)) GO TO 110
      GO TO (10, 20), INDEX
   10 IWORK = 1
      VNIKX(1) = 1.0D0
      IF (IWORK.GE.JHIGH) GO TO 40
C
   20 IPJ = ILEFT + IWORK
      WORK(IWORK) = T(IPJ) - X
      IMJP1 = ILEFT - IWORK + 1
      WORK(K+IWORK) = X - T(IMJP1)
      VMPREV = 0.0D0
      JP1 = IWORK + 1
      DO 30 L=1,IWORK
        JP1ML = JP1 - L
        VM = VNIKX(L)/(WORK(L)+WORK(K+JP1ML))
        VNIKX(L) = VM*WORK(L) + VMPREV
        VMPREV = VM*WORK(K+JP1ML)
   30 CONTINUE
      VNIKX(JP1) = VMPREV
      IWORK = JP1
      IF (IWORK.LT.JHIGH) GO TO 20
C
   40 RETURN
C
C
   90 CONTINUE
      CALL PDA_XERMSG ('SLATEC', 'PDA_DBSPVN',
     +   'K DOES NOT SATISFY K.GE.1', 2, 1, STATUS)
      RETURN
  100 CONTINUE
      CALL PDA_XERMSG ('SLATEC', 'PDA_DBSPVN',
     +   'JHIGH DOES NOT SATISFY 1.LE.JHIGH.LE.K', 2, 1, STATUS)
      RETURN
  105 CONTINUE
      CALL PDA_XERMSG ('SLATEC', 'PDA_DBSPVN',
     +   'INDEX IS NOT 1 OR 2', 2, 1, STATUS)
      RETURN
  110 CONTINUE
      CALL PDA_XERMSG ('SLATEC', 'PDA_DBSPVN',
     +   'X DOES NOT SATISFY T(ILEFT).LE.X.LE.T(ILEFT+1)', 2, 1, STATUS)
      RETURN
      END
