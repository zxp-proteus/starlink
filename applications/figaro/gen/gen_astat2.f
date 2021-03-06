C+
      SUBROUTINE GEN_ASTAT2 (ARRAY,NX,NY,IXST,IXEN,IYST,IYEN,TOTAL,
     :                 AMAX,AMIN,MEAN,XMAX,XMIN,YMAX,YMIN,SIGMA,SIZE)
C
C     G E N _ A S T A T 2
C
C     Examines a subset of a 2-dimensional array and returns a number
C     of statistics about the data in it.  This routine is similar to
C     GEN_ASTAT, but it calculates the SIGMA value using 2 passes through
C     the data, and so is slower that GEN_ASTAT but gives a more accurate
C     value for SIGMA.
C
C     Parameters -  (">" input, "<" output)
C
C     (>) ARRAY   (Real array ARRAY(NX,NY)) The input array.
C     (>) NX      (Integer) The first (x) dimension of ARRAY.
C     (>) NY      (Integer) The second (y) dimension of ARRAY.
C     (>) IXST    (Integer) The first x-value of the subset.
C     (>) IXEN    (Integer) The last    "     "   "    "
C     (>) IYST    (Integer) The first y-value "   "    "
C     (>) IYEN    (Integer) The last    "     "   "    "
C     (<) TOTAL   (Real) The total data in the subset.
C     (<) AMAX    (Real) The maximum value in the subset.
C     (<) AMIN    (Real) The minimum   "   "   "   "
C     (<) MEAN    (Real) The mean      "   "   "   "
C     (<) XMAX    (Real) ) These four quantities return the positions
C     (<) XMIN    (Real) ) in x and y (ie the values of the array indices)
C     (<) YMAX    (Real) ) at which the maximum and minimum data values
C     (<) YMIN    (Real) ) were found.
C     (<) SIGMA   (Real) The standard deviation of the data in the subset
C     (<) SIZE    (Real) The number of pixels in the subset (this is
C                 not necessarily that implied by IXST,IYST etc, if these
C                 parameters would take the subset outside the array
C                 bounds.  SIZE is the number of pixels actually examined.
C
C                                               KS / AA0 19th March 1987
C     Modified:
C
C     30th Jun 1993.  KS/AAO. Unused variable removed.
C+
      IMPLICIT NONE
C
C     Parameters
C
      INTEGER NX,NY,IXST,IXEN,IYST,IYEN
      REAL TOTAL,AMAX,AMIN,MEAN,XMAX,XMIN,YMAX,YMIN
      REAL SIGMA,SIZE
      REAL ARRAY(NX*NY)
C          (Slightly more efficient than (NX,NY) in terms of code
C           generated by the compiler.)
C
C     Local variables
C
      INTEGER NXST,NYST,NXEN,NYEN,IX,IY,IPTR,IPBASE
      REAL    VALUE
      DOUBLE PRECISION SIGMADP,TOTALDP
C
C     Check array limits
C
      NXST=MAX(1,IXST)
      NYST=MAX(1,IYST)
      NXEN=MIN(NX,IXEN)
      NYEN=MIN(NY,IYEN)
      SIZE=FLOAT(NXEN-NXST+1)*FLOAT(NYEN-NYST+1)
C
C     Initial values
C
      IPBASE=(NYST-1)*NX+NXST
      AMAX=ARRAY(IPBASE)
      AMIN=AMAX
      TOTALDP=0.
      XMIN=NXST
      XMAX=NXST
      YMIN=NYST
      YMAX=NYST
C
C     Pass through data to get all values except sigma
C
      DO IY=NYST,NYEN
         IPTR=IPBASE
         DO IX=NXST,NXEN
            VALUE=ARRAY(IPTR)
            IPTR=IPTR+1
            IF (VALUE.LT.AMIN) THEN
               AMIN=VALUE
               XMIN=IX
               YMIN=IY
            END IF
            IF (VALUE.GT.AMAX) THEN
               AMAX=VALUE
               XMAX=IX
               YMAX=IY
            END IF
            TOTALDP=TOTALDP+VALUE
         END DO
         IPBASE=IPBASE+NX
      END DO
C
      MEAN=TOTALDP/SIZE
      TOTAL=TOTALDP
C
C     Now a second pass through to get Sigma.
C
      SIGMADP=0.
      IPBASE=(NYST-1)*NX+NXST
      DO IY=NYST,NYEN
         IPTR=IPBASE
         DO IX=NXST,NXEN
            VALUE=ARRAY(IPTR)
            IPTR=IPTR+1
            SIGMADP=SIGMADP+((VALUE-MEAN)*(VALUE-MEAN)/(SIZE-1.0))
         END DO
         IPBASE=IPBASE+NX
      END DO
C
      SIGMA=SQRT(SIGMADP)
C
      END
