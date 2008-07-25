/*
*+
*  Name:
*     smf_expand_tilegroup

*  Purpose:
*     Expand an output group by taking into account tiles and pol

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_expand_tilegroup( Grp * ogrp, size_t ntile, size_t npbin,
*                           size_t * outsize, int *status);

*  Arguments:
*     ogrp = Grp* (Given and Returned)
*        The initial output group. It will be modified to contain the
*        expanded filenames. Previous entries will be removed.
*     ntile = size_t (Given)
*        Number of tiles.
*     npbin = size_t (Given)
*        Number of polarimetry bins.
*     outside = size_t * (Returned)
*        Size of the newly modified output group.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     When tiling or polarimetry are enabled the number of output files
*     is multiplied. This function takes a group of output files and expands
*     it to add tiling and polarimeter suffices.

*  Authors:
*     David S. Berry (UCLan)
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-06-05 (TIMJ):
*        Initial version taken from smurf_makecube
*     2008-07-24 (TIMJ):
*        Use size_t
*     {enter_further_changes_here}

*  Notes:
*     To simplify the interface we reuse the supplied group rather
*     than returning a brand new group.

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"
#include "ast.h"
#include "star/grp.h"

#include "smf.h"

void
smf_expand_tilegroup ( Grp * ogrp, size_t ntile, int npbin, size_t * outsize,
                       int * status) {

  char basename[ GRP__SZNAM + 1 ]; /* Output base file name */
  int blen;                  /* Used length of the "basename" string */
  int ipbin;              /* Loop pol bin counter */
  size_t itile;              /* Loop tile counter */
  char *pname = NULL;        /* Name of currently opened data file */
  Grp *tgrp = NULL;     /* Temporary group */

  if (*status != SAI__OK) return;

/* Expand the group to hold an output NDF name for each tile. */
  if( ntile > 1 ) {
    pname = basename;
    /* Get the base file name from the group */
    grpGet( ogrp, 1, 1, &pname, GRP__SZNAM, status );

    /* Resize the group to 0 entries */
    grpSetsz( ogrp, 0, status );

    blen = astChrLen( basename );
    for( itile = 0; itile < ntile; itile++ ) {
      sprintf( basename + blen, "_%zd", itile + 1 );            
      grpPut1( ogrp, basename, 0, status );
    }
    *outsize = ntile;
  } else {
    *outsize = 1;
  }
         
/* Expand the group to hold an output NDF name for each polarisation bin
   and tile. */
  if( npbin > 1 ) {
    /* get a copy of the current output group */
    tgrp = grpCopy(ogrp, 0, 0, 0, status);
    
    /* and clear the output group in preparation for repopulating it */
    grpSetsz(ogrp, 0, status );

    /* loop over each tile and create names for each pol bin */
    for( itile = 1; itile <= *outsize; itile++ ) {
      pname = basename;
      grpGet( tgrp, itile, 1, &pname, GRP__SZNAM, status );
      blen = astChrLen( basename );

      for( ipbin = 0; ipbin < npbin; ipbin++ ){
        sprintf( basename + blen, ".p%d", ipbin + 1 );            
        grpPut1( ogrp, basename, 0, status );
      }
    }
    grpDelet( &tgrp, status);
  }

  /* finalize size of output group */
  *outsize = grpGrpsz( ogrp, status );

}
