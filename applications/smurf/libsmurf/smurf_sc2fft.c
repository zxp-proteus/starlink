/*
*+
*  Name:
*     SC2FFT

*  Purpose:
*     Top-level SCUBA-2 data ffting routine

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_sc2fft( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine performs for the forward or inverse FFT of SCUBA-2 data.
*     The FFT of the data are stored in a 4-dimensional array with dimensions
*     frequency, xbolo, ybolo, component (where component is a dimension
*     of length 2 holding the real and imaginary parts). The inverse flag
*     is used to transform back to the time domain from the frequency domain.
*     If the data are already in the requested domain, the ouput file is
*     simply a copy of the input file.

*  Notes:
*     Transforming data loses the VARIANCE and QUALITY components.

*  ADAM Parameters:
*     IN = NDF (Read)
*          Input files to be transformed
*     INVERSE = _INTEGER (Read)
*          If set perform inverse transform
*     OUT = NDF (Write)
*          Output files

*  Authors:
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2008-07-22 (EC):
*        Initial version - based on sc2clean task

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
*     University of British Columbia.
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

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <stdio.h>

#include "star/ndg.h"
#include "star/grp.h"
#include "ndf.h"
#include "mers.h"
#include "par.h"
#include "prm_par.h"
#include "sae_par.h"
#include "msg_par.h"

#include "smurf_par.h"
#include "libsmf/smf.h"
#include "smurflib.h"
#include "libsmf/smf_err.h"
#include "sc2da/sc2store.h"

#define FUNC_NAME "smurf_sc2fft"
#define TASK_NAME "SC2FFT"

void smurf_sc2fft( int *status ) {

  int flag;                 /* Flag for how group is terminated */
  size_t i=0;               /* Counter, index */
  smfData *idata=NULL;      /* Pointer to input smfData */
  Grp *igrp = NULL;         /* Input group of files */
  int inverse=0;            /* If set perform inverse transform */
  char fname[GRP__SZNAM+1]; /* Name of container file without suffix */
  smfData *odata=NULL;      /* Pointer to output smfData to be exported */
  Grp *ogrp = NULL;         /* Output group of files */
  size_t outsize;           /* Total number of NDF names in the output group */
  char *pname=NULL;         /* Poiner to fname */
  size_t size;              /* Number of files in input group */

  /* Main routine */
  ndfBegin();

  /* Get input file(s) */
  ndgAssoc( "IN", 1, &igrp, &size, &flag, status );

  /* Get output file(s) */
  ndgCreat( "OUT", igrp, &ogrp, &outsize, &flag, status );

  /* Are we doing an inverse transform? */
  parGet0i( "INVERSE", &inverse, status );

  /* Loop over input files */
  for( i=1; (*status==SAI__OK)&&(i<=size); i++ ) {

    /* Open the file */
    smf_open_file( igrp, i, "READ", SMF__NOCREATE_VARIANCE | 
                   SMF__NOCREATE_QUALITY, &idata, status );

    /* Tranform the data */
    odata = smf_fft_data( idata, inverse, status );

    /* If output is time-domain, ensure that it is ICD bolo-ordered */
    if( inverse ) {
      smf_dataOrder( odata, 1, status );
    }

    /* Export the data to a new file */
    pname = fname;
    grpGet( ogrp, i, 1, &pname, GRP__SZNAM, status );
    smf_NDFexport( odata, NULL, NULL, NULL, fname, status );

    /* Free resources */
    smf_close_file( &idata, status );
    smf_close_file( &odata, status );
  }

  /* Tidy up after ourselves: release the resources used by the grp routines */
  grpDelet( &igrp, status);
  grpDelet( &ogrp, status);

  ndfEnd( status );
}
