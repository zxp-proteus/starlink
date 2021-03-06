*+  SSO_INIT - Initialise SSO system
      SUBROUTINE SSO_INIT( )
*
*    Description :
*
*     Resets use flags to make SSO resources (datasets and mapped items)
*     available to system.
*
*    Authors :
*
*     David J. Allan (BHVAD::DJA)
*
*    History :
*
*      2 Jul 91 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'AST_PKG'
*
*    Global variables :
*
      INCLUDE 'SSO_CMN'
*
*    Local variables :
*
      INTEGER                    I                  ! Loop over SSO resources
*-

*   Reset use flags

*    for datasets
      DO I = 1, SSO__MXDS
        SSO_DS_USED(I) = .FALSE.
      END DO

*    for mapped items
      DO I = 1, SSO__MXMI
        SSO_MI_USED(I) = .FALSE.
      END DO

*  Mark initialised
      CALL AST_SPKGI( SSO__PKG )

      END
