/*
*+
*  Name:
*     smf_updateprov

*  Purpose:
*     Update the output NDF provenance to include a new input NDF.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     void smf_updateprov( int ondf, const smfData *data, int indf,
*                          const char *creator, int *status )

*  Arguments:
*     ondf = int (Given)
*        The output NDF identifier. NDF__NOID may be supplied if and only
*        if a non-NULL value is supplied for "modprov".
*     data = const smfData * (Given)
*        Pointer to the structure describing the current input NDF. If
*        NULL, then the "indf" is used instead.
*     indf = int (Given)
*        NDF identifier for the current input NDF. Only accessed if "data"
*        is NULL.
*     creator = const char * (Given)
*        A string such as "SMURF:MAKECUBE" indicating the calling app.
*     modprov = NdgProvenance ** (Given & Returned)
*        If "modprov" is NULL, any existing provenance is read from the
*        supplied output NDF, updated to include the input NDF as an ancestor,
*        and then immediately written back to the output NDF. The local
*        provenance structure is then freed.
*
*        If "modprov" is non-NULL but "*modprov" is NULL, any existing
*        provenance is read from the supplied output NDF. If no output
*        NDF is supplied, a new empty provenance structure is created to
*        store the output provenance. Either way, the output provenance is
*        updated to include the input NDF as an ancestor, but it is not
*        written back to the output NDF, or freed. Instead, a pointer to
*        the output provenance structure is returned in "*modprov".
*
*        If both "modprov" and "*modprov" are non-NULL, any supplied
*        output NDF identifier is ignored. Instead, the supplied provenance
*        structure pointed to by "*modprov" is updated to include the
*        input NDF as an ancestor.
*     status = int * (Given and Returned)
*        Inherited status value.

*  Description:
*     This function records the current input NDF as a parent of the
*     output NDF. It includes the input OBSIDSS value in the output
*     provenance information.

*  Notes:
*     - Always propagates provenance if we have OBSIDSS available or if
*     we have ancestors in the input provenance. Does not propagate if
*     we have no ancestors and no OBSIDSS.
*     - If an external provenance pointer is provided the caller
*     is responsible for writing the provenance to the output file and
*     freeing the structure.

*  Authors:
*     David S Berry (JAC, UCLan)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     23-NOV-2007 (DSB):
*        Initial version.
*     15-APR-2008 (DSB):
*        Use smf_getobsidss to get the OBSIDSS value from the FitsChan.
*        This means that an OBSIDSS value can be formed from OBSID and
*        SUBSYSNR headers if OBSIDSS is not present in the FitsChan.
*     25-APR-2008 (DSB):
*        Added "indf" and "creator" arguments. Changed to retain
*        information about ancestors if one of the ancestors refers to
*        the OBSIDSS value of the input NDF.
*     31-JUL-2008 (TIMJ):
*        Use thread-safe obsidss API.
*     29-JUN-2009 (DSB):
*        Use new NDG provenance API.
*     2009-11-27 (TIMJ):
*        Only store provenance if we are a root (OBSIDSS is available)
*        or we have provenance to propagate. Allow there to be no
*        fits header at all.
*     2010-10-15 (TIMJ):
*        Allow provenance structure to be retained between calls.
*     28-JAN-2011 (DSB):
*        Allow "ondf" to be NDF__NOID.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2007-2009 Science & Technology Facilities Council.
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
*     Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
*     MA 02110-1301, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Starlink includes */
#include "sae_par.h"
#include "star/ndg.h"
#include "mers.h"

/* SMURF includes */
#include "libsmf/smf.h"

#include <string.h>

void smf_updateprov( int ondf, const smfData *data, int indf,
                     const char *creator, NdgProvenance **modprov, int *status ){

/* Local Variables */
   AstFitsChan *fc = NULL;      /* AST FitsChan holding input FITS header */
   AstKeyMap *anc = NULL;       /* KeyMap holding ancestor info */
   AstKeyMap *tkm = NULL;       /* KeyMap holding contents of MORE */
   NdgProvenance *prov = NULL;  /* Pointer to input provenance structure */
   char *obsidss = NULL;        /* Pointer to OBSIDSS buffer */
   char obsidssbuf[SZFITSTR];   /* OBSIDSS value in input file */
   const char *vptr = NULL;     /* Pointer to OBSIDSS string */
   int found;                   /* Was OBSIDSS value found in an input ancestor? */
   int ianc;                    /* Ancestor index */
   int isroot;                  /* Ignore any ancestors in the input NDF? */

/* Check the inherited status */
   if( *status != SAI__OK ) return;

/* Get a FitsChan holding the contents of the input NDF FITS extension. */
   if( !data ) {
      kpgGtfts( indf, &fc, status );
   } else if (data->hdr) {
      fc = data->hdr->fitshdr;
   }

/* Get the input NDF identifier. */
   if( data && data->file &&
       data->file->ndfid != NDF__NOID) indf = data->file->ndfid;

/* Get a structure holding provenance information from indf. */
   prov = ndgReadProv( indf, " ", status );

/* Initially, assume that we should include details of ancestor NDFs. */
   isroot = 0;

/* Get the OBSIDSS keyword value from the input FITS header if we have a FITS
   header. There can be cases (eg in STACKFRAMES) where we do not have a
   FITS header so handle that gracefully. */
   if (fc) obsidss = smf_getobsidss( fc, NULL, 0, obsidssbuf,
                                     sizeof(obsidssbuf), status );
   if( obsidss ) {

/* Search through all the ancestors of the input NDF (including the input
   NDF itself) to see if any of them refer to the same OBSIDSS value. */
      found = 0;
      ianc = 0;
      anc = ndgGetProv( prov, ianc, status );
      while( anc ) {
         if( astMapGet0A( anc, "MORE", &tkm ) ) {
            if( astMapGet0C( tkm, "OBSIDSS", &vptr ) ) {
               found = !strcmp( obsidss, vptr );
            }
            tkm = astAnnul( tkm );
         }
         anc = astAnnul( anc );
         if( ! found ) anc = ndgGetProv( prov, ++ianc, status );
      }

/* If the OBSIDSS value was not found in any ancestor, then we add it
   now. So put the OBSIDSS keyword value in an AST KeyMap that will be
   stored with the output provenance information. */
      if( ! found ) {
         tkm = astKeyMap( " " );
         astMapPut0C( tkm, "OBSIDSS", obsidss, NULL );

/* Ignore ancestor NDFs if none of them referred to the correct OBSIDSS. */
         isroot = 1;
      }
   }

/* Update the provenance for the output NDF to include the input NDF as
   an ancestor. Indicate that each input NDF is a root NDF (i.e. has no
   parents). Do nothing if we have no provenance to propagate, unless
   we have root information and are propagating that. */
   if ( ndgCountProv( prov, status ) > 0 || tkm) {
     NdgProvenance *oprov = NULL;
     if (modprov && *modprov) {
       oprov = *modprov;
     } else {
       oprov = ndgReadProv( ondf, creator, status );
       if (modprov) *modprov = oprov;
     }
     ndgPutProv( oprov, indf, tkm, isroot, status );
     /* do not update the file or free provenance if we
        are using an external provenance struct or returning
        it to the caller */
     if (!modprov) {
       if( ondf != NDF__NOID ) {
         ndgWriteProv( oprov, ondf, 1, status );
         oprov = ndgFreeProv( oprov, status );
       } else if( *status == SAI__OK ){
         *status = SAI__ERROR;
         errRep( " ", "smf_updateprov: Provenance is to be stored in the "
                 "output NDF but no output NDF identifier was supplied "
                 "(programming error).", status );
       }
     }
   }

/* Free resources. */
   if( prov ) prov = ndgFreeProv( prov, status );
   if( tkm ) tkm = astAnnul( tkm );
   if( !data && fc ) fc = astAnnul( fc );
}

