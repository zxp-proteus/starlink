      SUBROUTINE SCULIB_SET_DATA_UB (USE_THIS, N_BOLS, N_POS, 
     :     N_BEAM, MASK, BVALUE, IN_DATA, STATUS)
*+
*  Name:
*     SCULIB_SET_QUAL

*  Purpose:
*     set data to a byte value given a byte mask 

*  Language:
*     Starlink Fortran 77
*  

*  Invocation:
*     CALL SCULIB_SET_DATA_UB(USE_THIS, N_BOLS, N_POS, N_BEAM, 
*    :  MASK, VALUE, IN_DATA, STATUS)


*  Description:
*       This routine uses a byte mask (N_BOLS * N_POS) to set a data
*       value in the output. A mask value of 1 indicates that a value
*       should be changed. This routine does not distinguish 'beams'

*  Arguments:
*     USE_THIS   = LOGICAL (Given)
*           Describes whether the mask should be set to the value (TRUE)
*           or whether the rest of the data should be set (FALSE)
*     N_BOLS                  = INTEGER (Given)
*           number of bolometers measured
*     N_POS                   = INTEGER (Given)
*           number of positions measured
*     N_BEAM                  = INTEGER (Given)
*           number of beams used
*     MASK( N_BOLS, N_POS)    = BYTE (Given)
*     BVALUE                  = BYTE (Given)
*           The value of the masked/unmasked data
*     IN_DATA (N_BOLS, N_POS, N_BEAM)
*                             = BYTE (Given and returned)
*           the data to be masked

*     STATUS                  = INTEGER (Given and returned)
*           global status

*  Method:
*  Deficiencies:
*  Bugs:

*  Authors:
*       Tim Jenness (JACH)

*  Copyright:
*     Copyright (C) 1995,1996,1997,1998,1999 Particle Physics and Astronomy
*     Research Council. All Rights Reserved.

*  History:
*     $Log$
*     Revision 1.3  1999/08/03 19:35:28  timj
*     Add copyright message to header.
*     Convert old header style to new.
*

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'PRM_PAR'

*  Arguments Given:
      INTEGER N_BOLS
      INTEGER N_POS
      INTEGER N_BEAM
      BYTE    MASK(N_BOLS, N_POS)
      LOGICAL USE_THIS
      BYTE    BVALUE

*  Arguments Given & Returned:
      BYTE    IN_DATA (N_BOLS, N_POS, N_BEAM)

*  Arguments Returned:

*  Status:
      INTEGER STATUS

*  External references:
*  Global variables:
*  Local Constants:

*  Local variables:
      INTEGER BEAM                      ! beam index in DO loop
      INTEGER BOL                       ! bolometer index in DO loop
      INTEGER POS                       ! measured position index in DO loop

*  Internal References:
*  Local data:

*.

      IF (STATUS .NE. SAI__OK) RETURN

*     Do this if we are changing the section
      IF (USE_THIS) THEN

         DO BOL = 1, N_BOLS

            DO POS = 1, N_POS

               IF (MASK(BOL,POS) .NE. 0) THEN

                  DO BEAM = 1, N_BEAM
*       Dont set BAD pixels                        
                     IF (IN_DATA(BOL, POS, BEAM) .NE. VAL__BADR) THEN
                        IN_DATA(BOL, POS, BEAM) = BVALUE
                     END IF
                  END DO
               END IF
            END DO
         END DO

*     Set unmasked data to value
      ELSE

         DO BOL = 1, N_BOLS
            DO POS = 1, N_POS

               IF (MASK(BOL, POS) .EQ. 0) THEN

                  DO BEAM = 1, N_BEAM
*     Dont set BAD pixels                        
                     IF (IN_DATA(BOL, POS, BEAM) .NE. VAL__BADR) THEN
                        IN_DATA(BOL, POS, BEAM) = BVALUE
                     END IF
                  END DO
               END IF
            END DO
         END DO

      END IF

      END
