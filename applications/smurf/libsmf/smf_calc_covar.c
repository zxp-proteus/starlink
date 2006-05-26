/*
*+
*  Name:
*     smf_calc_covar

*  Purpose:
*     Low-level routine to compute covariance using GSL

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     covar = smf_calc_covar ( const smfData *data, const int i, const int j,
*                      int lo, int hi, int *status ) 

*  Arguments:
*     data = const smfData* (Given)
*        Pointer to input data struct
*     i = const int (Given)
*        Index of bolometer 1
*     j = const int (Given)
*        Index of bolometer 2
*     lo = int (Given)
*        Lower index bound into array
*     hi = int (Given)
*        Upper index bound into array
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine returns the covariance of two time streams, using
*     the GSL routine gsl_stats_covariance. The bolometer indices are
*     given along with the range of values to include in the
*     samples. Note that the range lo to hi is INCLUSIVE. If both lo
*     and hi are zero then the entire range is used. On error a value
*     of VAL__BADD is returned.

*  Notes: 

*  Authors:
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-05-17 (AGG):
*        Initial test version
*     2006-05-26 (AGG):
*        Free allocated resources
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 University of British Columbia. All Rights
*     Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
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
#include <stdio.h>
#include <string.h>

/* GSL includes */
#include <gsl/gsl_statistics_double.h>

/* Starlink includes */
#include "sae_par.h"
#include "ast.h"
#include "mers.h"
#include "msg_par.h"
#include "prm_par.h"

/* SMURF includes */
#include "smf.h"
#include "smurf_par.h"
#include "smurf_typ.h"

/* Simple default string for errRep */
#define FUNC_NAME "smf_calc_covar"

double smf_calc_covar ( const smfData *data, const int i, const int j,
			int lo, int hi, int *status) {

  /* Local variables */
  double *indata = NULL;      /* Pointer to input data array */
  size_t k;                   /* Loop counter */
  int nframes;                /* Max number of data points*/
  int npts;                   /* Number of points in timeseries */
  int nbol;                   /* Number of bolometers */
  double *idata = NULL;       /* Pointer to array for bolometer 1 data */
  double *jdata = NULL;       /* Pointer to array for bolometer 2 data */
  int temp;                   /* Temporary variable */
  double covar = VAL__BADD;   /* Covariance, initialuzed to bad */

  /* Check status */
  if (*status != SAI__OK) return covar;

  /* Do we have 2-D image or 3-D timeseries data? */
  if ( data->ndims != 3 ) {
    /* Abort with an error if the number of dimensions is not  3 */
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      msgSeti("ND", data->ndims);
      errRep(FUNC_NAME,
	     "Number of dimensions of input file is ^ND: should be 3. Meaningless to compute statistics for 2-D data.",
	     status);
      return covar;
    }
  } else {
    nframes = (data->dims)[2];
    nbol =  (data->dims)[0] * (data->dims)[1];
  }

  /* Should check data type for double */
  smf_dtype_check_fatal( data, NULL, SMF__DOUBLE, status);
  if ( *status != SAI__OK) return covar;

  /* Check bolometer indices are in range */
  if ( i > nframes || index < 0 ) {
    if ( *status == SAI__OK) {
      msgSeti("I", i);
      msgSeti("N", nframes);
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Requested bolometer index, ^I, is out of range (0 < i < ^N).", status);
      return covar;
    }
  }
  if ( j > nframes || index < 0 ) {
    if ( *status == SAI__OK) {
      msgSeti("I", j);
      msgSeti("N", nframes);
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Requested bolometer index, ^I, is out of range (0 < i < ^N).", status);
      return covar;
    }
  }

  /* Check requested range is valid */
  if ( lo > nframes || lo < 0 ) {
    if ( *status == SAI__OK) {
      msgSeti("J", lo);
      msgSeti("N", nframes);
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Requested sample, ^J, is out of range (0 < lo < ^N).", status);
      return covar;
    }
  }
  if ( hi > nframes || hi < 0 ) {
    if ( *status == SAI__OK) {
      msgSeti("J", hi);
      msgSeti("N", nframes);
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Requested sample, ^J, is out of range (0 < hi < ^N).", status);
      return covar;
    }
  }

  /* Check hi is larger than lo; swap if not */
  if ( lo > hi ) {
    temp = lo;
    lo = hi;
    hi = temp;
    msgOutif(MSG__VERB, FUNC_NAME, "Oops - lo > hi. Swapping them round.", status);
  }

  /* If lo and hi are both zero then the whole range is assumed */
  if ( lo == 0 && hi == 0 ) {
    hi = nframes - 1;
  }

  /* Allocate memory for data */
  npts = hi - lo + 1;
  idata = smf_malloc( npts, sizeof(double), 1, status );
  if ( idata == NULL ) {
    msgSeti("N",i);
    errRep( FUNC_NAME, "Unable to allocate memory for bolometer ^N timeseries", status );
    return covar;
  }
  jdata = smf_malloc( npts, sizeof(double), 1, status );
  if ( jdata == NULL ) {
    msgSeti("N",j);
    errRep( FUNC_NAME, "Unable to allocate memory for bolometer ^N timeseries", status );
    return covar;
  }

  /* Set range of data. Use <= because the range is inclusive. */
  indata = (data->pntr)[0];
  /* Pick out a bolometer time series */
  for ( k=lo; k<=hi; k++) {
    idata[k] = indata[i + k*nbol];
    jdata[k] = indata[j + k*nbol];
  }

  /* Calculate stats */
  covar = gsl_stats_covariance( idata, 1, jdata, 1, npts );

  /* Free resources */
  if ( idata != NULL)
    smf_free( idata, status );
  if ( jdata != NULL)
    smf_free( jdata, status );

  return covar;

}
