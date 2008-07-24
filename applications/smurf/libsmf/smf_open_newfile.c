/*
*+
*  Name:
*     smf_open_newfile

*  Purpose:
*     Low-level file creation function

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_open_newfile( const Grp * ingrp, int index, smf_dtype dtype,
*                       int ndims, 
*                       const dim_t dims[], int flags, smfData ** data, 
*                       int *status);

*  Arguments:
*     ingrp = const Grp * (Given)
*        NDG group identifier
*     index = int (Given)
*        Index corresponding to required file in group
*     dtype = smf_dtype (Given)
*        Data type of this smfData. Unsupported types result in an error.
*     ndims = int (Given)
*        Number of dimensions in dims[]. Maximum of NDF__MXDIM.
*     dims[] = const dim_t (Given)
*        Array of dimensions. Values will be copied from this array.
*     flags = int (Given)
*        Flags to denote whether to create flatfield, header, or file components
*        and create variance and quality arrays
*     data = smfData ** (Returned)
*        Pointer to pointer smfData struct to be filled with file info and data
*        Should be freed using smf_close_file.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main routine to create new data files. The user
*     supplies a Grp and index and the properties of the DATA array
*     they wish to create. The routine returns a populated smfData
*     with the DATA pointer mapped and ready to accept values.
*
*     The routine maps a DATA array by default. If VARIANCE and
*     QUALITY components are desired then their creation can be
*     controlled with the flags argument. Use SMF__MAP_VAR and
*     SMF__MAP_QUAL respectively to obtain the VARIANCE and QUALITY
*     arrays.
*
*     A simple NDF file is created with just a DATA array - the user
*     can use smf_get_xloc and smf_get_ndfid to add more components

*  Notes:
*     - Cloned from smf_open_file.c
*     - Limited to data with no more than 3 dimensions
*     - Additional components added to this file must be unmapped
*       separately

*  Authors:
*     Andy Gibb (UBC)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2006-07-20 (AGG):
*        Initial test version
*     2006-07-24 (AGG):
*        Change datatype to a char* and avoid strncpy()
*     2006-08-01 (AGG):
*        Now map VARIANCE and QUALITY if desired
*     2006-08-08 (TIMJ):
*        Use dim_t as much as possible.
*     2006-09-15 (AGG):
*        Add status checking
*     2006-10-11 (AGG):
*        Change API to take lbnd, ubnd from caller
*     2008-04-14 (EC):
*        Add named QUALITY extension
*     2008-05-30 (EC):
*        Initialize history component
*     2008-07-23 (EC):
*        Allow 4-dimensional data to store FFTs
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 University of British Columbia. All Rights
*     Reserved.

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

/* Standard includes */
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "ndf.h"
#include "mers.h"
#include "msg_par.h"
#include "prm_par.h"
#include "par.h"

/* SMURF includes */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_open_newfile"

void smf_open_newfile( const Grp * igrp, int index, smf_dtype dtype, const int ndims,
		       const int *lbnd, const int *ubnd, int flags, smfData ** data,
		       int *status) {

  /* Local variables */
  const char *datatype;         /* String for data type */
  dim_t dims[NDF__MXDIM];       /* Dimensions of NDf to be created */
  smfFile *file = NULL;         /* Pointer to smfFile struct */
  char filename[GRP__SZNAM+1];  /* Input filename, derived from GRP */
  int i;                        /* Loop counter */
  int isNDF = 1;                /* Flag to denote whether data are 1 or 2-D */
  int isTstream = 0;            /* Flag to denote time series (3-D) data */
  int nel;                      /* Number of mapped elements */
  int newndf;                   /* NDF identified for new file */
  IRQLocs *qlocs = NULL;        /* Named quality resources */
  char *pname = NULL;           /* Pointer to filename */
  void *pntr[3] = { NULL, NULL, NULL }; /* Array of pointers for smfData */

  if ( *status != SAI__OK ) return;

  /* Return a null pointer to the smfData if the input grp is null */
  if ( igrp == NULL ) {
    *data = NULL;
    return;
  }

  /* Create empty smfData with no extra components */
  flags |= SMF__NOCREATE_DA | SMF__NOCREATE_HEAD | SMF__NOCREATE_FILE;
  *data = smf_create_smfData( flags, status);

  /* Set the requested data type */
  (*data)->dtype = dtype;

  /* Check requested dimensionality: currently only up to 3 dimensions */
  if (ndims == 2 || ndims == 1) {
    isNDF = 1;
    isTstream = 0; /* Data are not in time series format */
  } else if (ndims == 3) { /* Time series data */
    /* Check if we want to write raw timeseries */
    if ( dtype == SMF__USHORT ) {
      isNDF = 0;   /* Data have not been flatfielded */
    } else {
      isNDF = 1;   /* Data have been flatfielded */
    }
    isTstream = 1; /* Data are in `time series' format */
  } else if (ndims == 4) {/* FFT of a data cube */
    isNDF = 0;
    isTstream = 0;
  } else {
    /* Report an error due to an unsupported number of dimensions */
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      msgSeti( "NDIMS", ndims);
      errRep( FUNC_NAME, 
	      "Number of dimensions in output, ^NDIMS, is not in the range 1-4",	      status);
      return;
    }
  }

  /* Set datatype string */
  datatype = smf_dtype_string( *data, status );
  if ( datatype == NULL ) {
    if (*status == SAI__OK) {
      *status = SAI__ERROR;
      errRep( FUNC_NAME, "Unsupported data type. Unable to open new file.", 
	      status );
    }
  }

  /* Create new simple NDF */
  ndgNdfcr( igrp, index, datatype, ndims, lbnd, ubnd, &newndf, status );
  if ( *status != SAI__OK ) {
    errRep(FUNC_NAME, "Unable to create new file", status);
    return;
  }

  ndfMap(newndf, "DATA", datatype, "WRITE", &(pntr[0]), &nel, status);
  if ( *status != SAI__OK ) {
    errRep(FUNC_NAME, "Unable to map data array", status);
    return;
  }
  if ( flags & SMF__MAP_VAR ) {
    ndfMap(newndf, "VARIANCE", datatype, "WRITE", &(pntr[1]), &nel, status);
    if ( *status != SAI__OK ) {
      errRep(FUNC_NAME, "Unable to map variance array", status);
      return;
    }
  }
  if ( flags & SMF__MAP_QUAL ) {

    /* Create the named QUALITY bits extension before calling ndfMap */
    smf_create_qualname( "WRITE", newndf, &qlocs, status );

    ndfMap(newndf, "QUALITY", "_UBYTE", "WRITE", &(pntr[2]), &nel, status);

    /* Done with quality names so free resources */
    irqRlse( &qlocs, status );

    if ( *status != SAI__OK ) {
      errRep(FUNC_NAME, "Unable to map quality array", status);
      return;
    }
  }

  /* Initialize history */
  ndfHcre( newndf, status );

  /* Get filename from the group */
  pname = filename;
  grpGet( igrp, index, 1, &pname, SMF_PATH_MAX, status);
  if ( *status != SAI__OK ) {
    errRep(FUNC_NAME, "Unable to retrieve file name", status);
    return;
  }

  file = smf_construct_smfFile( NULL, newndf, 0, isTstream, pname, 
				status );
  if ( file == NULL ) {
    if ( *status == SAI__OK ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Unable to construct smfFile for new file", status);
    }
  }

  /* Set the dimensions of the new smfData */
  for ( i=0; i<ndims; i++) {
    dims[i] = ubnd[i] - lbnd[i] + 1;
  }

  /* Fill the smfData */
  *data = smf_construct_smfData( *data, file, NULL, NULL, dtype, pntr, 1, dims,
                                 ndims, 0, 0, NULL, NULL, status);

  if ( *data == NULL ) {
    if ( *status == SAI__OK ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Unable to construct smfData for new file", status);
    }
  }

}
