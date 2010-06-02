/*
 *+
 *  Name:
 *     smf_typ.h

 *  Purpose:
 *     type definitions for the smf library

 *  Language:
 *     Starlink ANSI C

 *  Type of Module:
 *     Header File

 *  Invocation:
 *     #include "smf_typ.h"

 *  Description:
 *     Data types used by the smf library.

 *  Authors:
 *     Andy Gibb (UBC)
 *     Tim Jenness (JAC)
 *     Ed Chapin (UBC)
 *     David Berry (JAC, UCLan)
 *     {enter_new_authors_here}

 *  History:
 *     2005-11-02 (AGG):
 *        Initial test version
 *     2005-11-07 (TIMJ):
 *        Document some of the struct items
 *     2005-11-23 (TIMJ):
 *        HDS Locator has changed type
 *     2005-12-14 (TIMJ):
 *        Add reference counter to smfData
 *     2005-12-21 (AGG):
 *        Add index to current timeslice
 *     2006-01-25 (TIMJ):
 *        - Create SMF__NOCREATE flags
 *        - sc2head is now embedded in the smfHead struct
 *     2006-01-27 (TIMJ):
 *        - Add allsc2heads to header
 *        - sc2head now a pointer into allsc2heads
 *        - remove dksquid from DA until it is needed
 *        - smfFile.xloc no longer needed
 *        - Add smfHead.isCloned
 *     2006-02-17 (AGG):
 *        Add ncoeff and poly for scanfit polynomial coefficients
 *     2006-03-23 (AGG):
 *        Add nframes and curframe to smfHead
 *     2006-04-21 (AGG):
 *        Add history to smfData
 *     2006-06-12 (EC):
 *        Added smurfloc/mapcoordid to smfFile & lut to smfData
 *     2006-06-25 (AGG):
 *        Add smfGroup, smfArray
 *     2006-07-12 (EC):
 *        Added enumerated typedef smf_modeltype
 *     2006-07-26 (TIMJ):
 *        sc2head replaced by JCMTState
 *     2006-07-28 (TIMJ):
 *        Add time series wcs (tswcs) to distinguish from 2d wcs in smfHead
 *     2006-08-01 (AGG):
 *        Add SMF__MAP_VAR and SMF__MAP_QUAL flags
 *     2006-09-01 (EC):
 *        Added telpos to smfHead
 *     2006-09-07 (EC)
 *        Added instap to smfHead
 *     2006-09-15 (AGG):
 *        Add new smfDream struct
 *     2006-10-2 (DSB):
 *        Add detpos to smfHead
 *     2006-10-2 (DSB):
 *        Add detname to smfHead
 *     2006-12-13 (DSB):
 *        Add tsys to smfHead
 *     2007-02-07 (EC):
 *        Updated smf_modeltype
 *     2007-02-12 (EC):
 *        Add smf_calcmodelptr;
 *     2007-03-05 (EC):
 *        Add SMF__DIMM_FIRSTCOMP/FIRSTITER bit flags;
 *        Add SMF__EXT to smf_modeltype
 *     2007-06-13 (EC):
 *        Add SMF__LUT to smf_modeltype
 *        Add SMF__DIMM_SUFFIX
 *        Add DIMMbuf and DIMMlen to smfData
 *     2007-06-13 (EC):
 *        Added DIMMfd and moved DIMMbuf and DIMMlen to smfFile
 *     2007-06-25 (EC):
 *        Removed DIMMbuf/DIMMlen, renamed DIMMfd to fd in smfFile
 *     2007-07-10 (EC):
 *        -increased SMF__MXSMF to 8 from 4
 *        -made smfData.sdata static array of size SMF__MXSMF
 *        -modified smf_calcmodelptr prototype
 *     2007-08-21 (EC):
 *        Added SMF__NUL to typedef smf_modeltype
 *     2007-08-21 (DSB):
 *        Added smfBox and smfTile.
 *     2007-09-13 (EC):
 *        Added isTordered to smfData.
 *     2007-10-29 (EC):
 *        Added definition of SMF__NOCREATE_DATA for use by smf_open_file
 *     2007-11-15 (EC):
 *        Added SMF__NOCREATE_LUT flag for file I/O
 *     2008-1-15 (DSB):
 *        Added qlbnd/qubnd to the smfTile structure.
 *     2008-2-8 (EC):
 *        -Added SMF__NOCREATE_QUALITY flag, and data quality SMF__Q* flags
 *        -Added SMF__NOCREATE_VARIANCE, SMF__QUA model component
 *        -Added SMF__UBYTE data type
 *     2008-03-04 (EC):
 *        -Added smfDIMMData; updated smf_calcmodelptr prototype
 *     2008-04-16 (EC):
 *        -Added chunk to smfGroup
 *     2008-04-18 (EC):
 *        -Added chisquared to smfDIMMData
 *        -Added SMF__MINCHUNKSAMP and SMF__MINSTATSAMP
 *     2008-04-24 (EC):
 *        -Added SMF__MB definition
 *     2008-04-30 (EC):
 *        -Added EXT to smfDIMMData
 *     2008-06-06 (EC):
 *        -Add smfFilter definition
 *     2008-06-12 (EC):
 *        -Switch to split real/imaginary arrays for smfFilter
 *     2008-06-23 (EC)
 *        -Added WCS to smfFilter
 *     2008-06-24 (EC)
 *        -Added SMF__Q_PAD quality flag
 *     2008-07-03 (EC)
 *        -Changed type to dim_t from int for smfArray.ndat and
 *         smfGroup.ngroups/nrelated
 *     2008-07-10 (TIMJ):
 *        DA struct now includes dark squid
 *     2008-07-14 (TIMJ):
 *        smfArray can be dynamic
 *     2008-07-25 (TIMJ):
 *        Add SMF__BADIDX
 *     2008-07-28 (TIMJ):
 *        Add steptime to smfHead so that we don't have to extract
 *        it from the FITS header each time.
 *     2008-08-20 (EC):
 *        Add obsidss to smfHead
 *     2008-08-25 (EC)
 *        Add smfDIMMHead
 *     2009-03-10 (EC)
 *        Add SMF__FLT to smf_modeltype
 *     2009-04-24 (TIMJ):
 *        Add ACSIS observing modes.
 *     2009-05-20 (TIMJ):
 *        Add switching modes.
 *     2009-12-09 (TIMJ):
 *        Add _BIT values from sc2headman_struct.h
 *     2010-01-08 (TIMJ):
 *        Add sub instrument enums.
 *     2010-01-11 (EC):
 *        Add SMF__Q_GAP (bits that indicate where gaps should be filled)
 *     2010-03-19 (EC):
 *        Renamed SMF__Q_BADS to SMF__Q_BADDA, and added SMF__Q_COM
 *     2010-04-20 (EC):
 *        Add map quality (SMF__MAPQ_ZERO, and mapqual in smfDIMMData)
 *     2010-05-19 (EC):
 *        Add mtype to smfHead, and smf_expmodelptr function prototype
 *     2010-05-20 (EC):
 *        Dark squids are now stored in a smfData within smfDA
 *     2010-05-27 (TIMJ):
 *        Add SMF__SMO model.
 *     {enter_further_changes_here}

 *  Copyright:
 *     Copyright (C) 2008-2010 Science and Technology Facilities Council.
 *     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
 *     Copyright (C) 2005-2010 University of British Columbia.
 *     All Rights Reserved.

 *  Licence:
 *     This program is free software; you can redistribute it and/or
 *     modify it under the terms of the GNU General Public License as
 *     published by the Free Software Foundation; either version 3 of
 *     the License, or (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be
 *     useful,but WITHOUT ANY WARRANTY; without even the implied
 *     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 *     PURPOSE. See the GNU General Public License for more details.
 *
 You should have received a copy of the GNU General Public
 *     License along with this program; if not, write to the Free
 *     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
 *     MA 02111-1307, USA

 *  Bugs:
 *     {note_any_bugs_here}
 *-
 */
#ifndef SMF_TYP_DEFINED
#define SMF_TYP_DEFINED

#include "smf_threads.h"
#include "star/hds_types.h"
#include "jcmt/state.h"
#include "sc2da/sc2store_par.h"
#include "sc2da/dream_par.h"
#include "sc2da/sc2ast.h"
#include "ast.h"
#include "ndf.h"
#include "star/grp.h"
#include "smurf_typ.h"
#include "smurf_par.h"
#include "fftw3.h"

#define SMF_PATH_MAX GRP__SZNAM
#define SMF_NAME_MAX GRP__SZFNM
#define SMF_MODEL_MAX 64   /* Maximum model components for iterative map maker*/
#define SMF__MXSMF 8       /* Maximum number of smfDatas in a smfArray */
#define SMF__MB 1048576    /* SMURF definition of a megabyte = 2^20 */
#define SMF__MXNOTCH 64    /* Arbitrary maximum number of notch filters */
#define SMF__F_WHITELO 2   /* Lower freq. over which to calculate NEP/NEFD */
#define SMF__F_WHITEHI 10  /* Upper freq. over which to calculate NEP/NEFD */
#define SMF__MAXAPLEN (size_t)-1 /* tell smf_apodize to use maximum interval */

/* Minimum number of time samples for a data chunk to be useful*/
#define SMF__MINCHUNKSAMP 100

/* Minimum number of samples for meaningful stats (like sample variance) */
#define SMF__MINSTATSAMP 5

/* Define the size of strings defining NDF char components (Units, label) */
#define SMF__CHARLABEL  80

/* Different data types supported by SMURF */
typedef enum smf_dtype {
  SMF__NULL,
  SMF__INTEGER,
  SMF__FLOAT,
  SMF__DOUBLE,
  SMF__USHORT,
  SMF__UBYTE
} smf_dtype;

/* Different types of model components used by iterative map-maker. These are
   powers of 2 so they can be used in bit masks. */
typedef enum smf_modeltype {
  SMF__NUL=0,               /* Null model */
  SMF__CUM=1,               /* Cumulative time-stream model */
  SMF__RES=2,               /* Residual time-stream signal */
  SMF__AST=4,               /* Astronomical time-stream signal */
  SMF__COM=8,               /* Common-mode signal */
  SMF__NOI=16,              /* Noise model */
  SMF__EXT=32,              /* Extinction correction */
  SMF__LUT=64,              /* Pointing LUT */
  SMF__QUA=128,             /* Quality flags */
  SMF__DKS=256,             /* Dark squid signals */
  SMF__GAI=512,             /* Relative Gain/Offset for each bolometer */
  SMF__FLT=1024,            /* Frequency domain filter */
  SMF__PLN=2048,            /* Spatial plane removal */
  SMF__SMO=4096             /* Time series smoothing */
} smf_modeltype;

/* Observing mode and type */

typedef enum smf_obsmode {
  SMF__OBS_NULL,
  SMF__OBS_DREAM,
  SMF__OBS_STARE,
  SMF__OBS_SCAN,
  SMF__OBS_GRID,
  SMF__OBS_JIGGLE
} smf_obsmode;

typedef enum smf_swmode {
  SMF__SWM_NULL,
  SMF__SWM_CHOP,
  SMF__SWM_PSSW,
  SMF__SWM_FREQSW,
  SMF__SWM_SELF
} smf_swmode;

typedef enum smf_obstype {
  SMF__TYP_NULL,
  SMF__TYP_SCIENCE,
  SMF__TYP_POINTING,
  SMF__TYP_FOCUS,
  SMF__TYP_SKYDIP,
  SMF__TYP_FLATFIELD,
  SMF__TYP_NOISE,
  SMF__TYP_FASTFLAT
} smf_obstype;

/* Source of tau for extinction correction */
typedef enum smf_tausrc {
  SMF__TAUSRC_NULL,     /* No correction */
  SMF__TAUSRC_WVMRAW,   /* Use WVM raw time series */
  SMF__TAUSRC_CSOTAU,   /* Use CSO tau scaled to filter */
  SMF__TAUSRC_TAU,      /* Use this tau number */
  SMF__TAUSRC_AUTO      /* Use WVM or CSO */
} smf_tausrc;

/* Method to use for extinction correction */
typedef enum smf_extmeth {
  SMF__EXTMETH_NONE,   /* No correction */
  SMF__EXTMETH_SINGLE, /* Assume all bolometers at same airmass */
  SMF__EXTMETH_FULL,   /* Calculate airmass of each bolometer */
  SMF__EXTMETH_ADAPT   /* Switch between FAST and FULL dynamically */
} smf_extmeth;


/* Ways of removing dark */
typedef enum smf_dark_sub_meth {
  SMF__DKSUB_NONE,        /* Ignore the dark */
  SMF__DKSUB_MEAN,        /* Use mean of previous and next dark */
  SMF__DKSUB_INTERP,      /* Interpolate dark over time */
  SMF__DKSUB_PREV,        /* Use previous dark */
  SMF__DKSUB_NEXT,        /* Use following dark */
  SMF__DKSUB_CHOOSE       /* Use one of mean, prev or next */
} smf_dark_sub_meth;

/* Ways of applying a bad bolometer mask - equivalent to bits */
typedef enum smf_bbm_meth {
  SMF__BBM_DATA=1,        /* Apply mask to dat array */
  SMF__BBM_QUAL=2,        /* Apply mask to quality array */
  SMF__BBM_QQUAL=4        /* Apply mask to first slice of quality array */
} smf_bbm_meth;

/* Parts of a header that can have their metadata fixed */
typedef enum smf_metadata_fixups {
  SMF__FIXED_FITSHDR=1,   /* Updated FITS header */
  SMF__FIXED_JCMTSTATE=2, /* Updated JCMTSTATE information */
  SMF__FIXED_ACSIS=4     /* Updated ACSIS extension information */
} smf_metadata_fixups;

/* Flatfield method */
typedef enum smf_flatmeth {
  SMF__FLATMETH_NULL,
  SMF__FLATMETH_TABLE,
  SMF__FLATMETH_POLY
} smf_flatmeth;

/* Indicate a bad array index */
static const size_t SMF__BADIDX = (size_t)-1;

/* suffix for simple binary files that store DIMM model components */
#define SMF__DIMM_SUFFIX ".dimm"

/* SMURF NDF extension name and type */
#define SMURF__EXTNAME "SMURF"
#define SMURF__EXTTYPE "SMURF_EXT"

/* Name of SMURF history component */
#define SMURF__HISTEXT "SMURFHIST"

/* Bit flags for smf_calcmodel* model component calculations */
#define SMF__DIMM_FIRSTCOMP 1 /* First component in the solution */
#define SMF__DIMM_FIRSTITER 2 /* First iteration */
#define SMF__DIMM_INVERT 4    /* Inverse of the model calculation */
#define SMF__DIMM_LASTITER 8  /* Is this the last iteration? */

/* Flags for smf_create_smf*, smf_open_file and smf_concat_smfGroup
   Must be individual bits in a single integer
*/
#define SMF__NOCREATE_DA 1       /* Don't open DA data */
#define SMF__NOCREATE_HEAD 2     /* Don't open header */
#define SMF__NOCREATE_FILE 4     /* Don't open file */
#define SMF__NOCREATE_DATA 8     /* Don't open DATA/QUALITY/VARIANCE */
#define SMF__NOCREATE_VARIANCE 16/* If !SMF__NOCREATE_DATA don't map VARIANCE*/
#define SMF__NOCREATE_QUALITY 32 /* If !SMF__NOCREATE_DATA don't map QUALITY */
#define SMF__NOCREATE_LUT 64     /* Don't open pointing LUT */
#define SMF__NOFIX_METADATA 128 /* Do not fix up metadata */
#define SMF__NOTTSERIES   256    /* File is not time series data */

/* Data quality bit mask (bits in single byte for QUALITY arrays) */
#define SMF__Q_BADDA 1    /* Bad sample flagged by DA system  */
#define SMF__Q_BADB 2     /* All samples from this bolo should be ignored */
#define SMF__Q_SPIKE 4    /* Location of a spike */
#define SMF__Q_JUMP 8     /* Location of a DC jump */
#define SMF__Q_PAD 16     /* Padded data */
#define SMF__Q_APOD 32    /* Apodized/boundary data */
#define SMF__Q_STAT 64    /* Telescope stationary */
#define SMF__Q_COM 128    /* Flagged as bad chunk in common-mode rejection */

/* These macros are for several commonly-used combinations of quality flags */
#define SMF__Q_GOOD 255            /* Samples that don't go into the map. Also
                                      don't include in chi^2 */
#define SMF__Q_MOD (SMF__Q_BADDA|SMF__Q_BADB|SMF__Q_PAD) /* Samples that can't
                                                           be modified
                                                           by fitted models */
#define SMF__Q_FIT ~(SMF__Q_APOD|SMF__Q_STAT|SMF__Q_JUMP)/*Samples that can't
                                                           be used to fit
                                                           time-domain models */
#define SMF__Q_GAP (SMF__Q_BADDA|SMF__Q_SPIKE|SMF__Q_JUMP|SMF__Q_COM)/* Samples
                                                           that should
                                                           be gap-filled */
#define SMF__Q_BOUND (SMF__Q_PAD|SMF__Q_APOD)            /* apodized/padded
                                                            boundary */

/* Number of active quality bits */
#define SMF__NQBITS 8

/* Quality bits for maps */
#define SMF__MAPQ_ZERO 1     /* Pixels that have been constrained to 0 */

/* Flags for smf_open_newfile
   Must be individual bits in a single integer
*/
#define SMF__MAP_VAR 8
#define SMF__MAP_QUAL 16

/* Define a structure used to hold information cached by smf_create_lutwcs. */
typedef struct smfCreateLutwcsCache {
  AstMapping *map;
  AstFrameSet *frameset;

  /* The SkyFrame used to represent final spherical (Az,El) coords */
  AstSkyFrame *skyframe;

  /* Mappings needed in the tangent plane to celestial longitude,latitude
     Mapping. */
  AstMapping *azel[ 2 ];

  /* The instap values which were hard-wired into the cached Mapping. */
  double instap[ 2 ];

} smfCreateLutwcsCache;

/* Define a structure used to hold information cached by smf_detpos_wcs. */
typedef struct smfDetposWcsCache {
  double *latlut;
  double *lonlut;
  AstPermMap *pmap;
  AstFrame *grid;
  AstSkyFrame *sky;
} smfDetposWcsCache;

/* Global information about the data file itself */

typedef struct smfFile {
  int fd;                    /* file descriptor if data array was mmap'd */
  int ndfid;                 /* NDF ID of file if opened by SMURF */
  int isSc2store;            /* True if file opened by sc2store library */
  int isTstream;             /* True if file contains time series data */
  char name[SMF_PATH_MAX+1]; /* Name of file */
  int mapcoordid;            /* NDF identifier for SMURF.MAPCOORD */
} smfFile;

/* Contains header general header information obtained from the file */

typedef struct smfHead {
  const JCMTState *state;   /* Pointer to current STATE */
  inst_t     instrument;    /* Instrument code */
  AstFrameSet * wcs;        /* Frameset for a particular time slice (frame) */
  AstFrameSet * tswcs;      /* Frameset for full time series (if tseries) */
  AstFitsChan * fitshdr;    /* FITS header from the file */
  sc2astCache * cache1;     /* Cached info used by sc2ast_createwcs. */
  smfCreateLutwcsCache * cache2; /* Cached info used by smf_create_lutwcs. */
  smfDetposWcsCache * cache3; /* Cached info used by smf_detpow_wcs. */
  dim_t curframe;           /* Index corresponding to current frame */
  dim_t nframes;            /* Number of frames in smfData */
  smf_obstype obstype;      /* Observation type */
  smf_obsmode obsmode;      /* observing mode */
  smf_swmode swmode;        /* switching mode */
  smf_obstype seqtype;      /* Sequence type */
  int isCloned;             /* If false, allState is owned by this
                               struct, if true it should not be freed */
  JCMTState *allState;     /* Array of STATE for every time slice */
  unsigned int ndet;       /* Number of focal plane detectors */
  double * fplanex;   /* X coords (radians) of focal plane detectors */
  double * fplaney;   /* Y coords (radians) of focal plane detectors */
  double * detpos;    /* Tracking coords (radians) of detectors */
  double * tsys;      /* System Noise temperatures */
  char * detname;     /* Concatenated list of null-terminated detector names */
  int dpazel;               /* Flag: does "detpos" hold AZEL values? */
  double instap[2];         /* instrument aperture (focal plane offsets)  */
  double telpos[3];         /* West LON/LAT/Alt of telescope (deg/deg/m) */
  double steptime;          /* Steptime in seconds */
  char * ocsconfig;           /* Configuration XML */
  char units[SMF__CHARLABEL]; /* Data units */
  char dlabel[SMF__CHARLABEL];/* Label associated with data */
  char title[SMF__CHARLABEL]; /* Title associated with data */
  char obsidss[SZFITSCARD];   /* Unique observation subsys id */
  smf_modeltype mtype;        /* type if iterative map-maker model container */
} smfHead;

/* This structure contains ancilliary information obtained from a raw
   data file that may be useful to SMURF. "heatval" is not read
   directly using smf_open_file but is used for flatfield calculations.
*/

struct smfData;

typedef struct smfDA {
  double *flatcal;           /* pointer to flatfield calibration */
  double *flatpar;           /* pointer to flatfield parameters */
  double *heatval;           /* Heater values in DAC units for flatfield */
  smf_flatmeth flatmeth;     /* Flatfield algorithm name */
  size_t nflat;              /* number of flat coeffs per bol */
  size_t nheat;              /* number of elements in heatval */
  struct smfData *dksquid;   /* dark squid for each column */
} smfDA;

/* This struct stores DREAM parameters */
typedef struct smfDream {
  size_t nvert;              /* Number of jiggle vertices */
  double jigscal;            /* SMU jiggle pattern scale factor (arcsec) */
  int jigvert[DREAM__MXVERT][2];   /* Jiggle vertex positions in DREAM
                                      pattern */
  double jigpath[DREAM__MXSAM][2]; /* X, Y SMU positions during a cycle, in
                                      arcsec */
  size_t ncycles;            /* Number of DREAM cycles in the input file */
  size_t nsampcycle;         /* Number of data samples per cycle */
  size_t ngrid;              /* Number of grid points in reconstruction */
  int gridpts[DREAM__MXGRID][2];   /* X, Y positions for reconstruction grid */
  double gridstep;           /* Spacing of grid in arcsec */
  double *gridwts;           /* Pointer to grid weights array */
  double *invmatx;           /* Pointer to inverse matrix */
} smfDream;

/* This struct is used to contain all information related to a particular
   data file (where possible since sc2store does not return a handle).
*/

typedef struct smfData {
  smfFile * file;            /* File information */
  smfHead * hdr;             /* Header information */
  smfDA * da;                /* If sc2store, associated data arrays */
  smfDream *dream;           /* DREAM parameters */
  smf_dtype dtype;           /* Data type of DATA and VARIANCE arrays */
  void * pntr[3];            /* Array of pointers to DATA/VARIANCE/QUALITY */
  dim_t dims[NDF__MXDIM];    /* Dimensions of data array */
  int lbnd[NDF__MXDIM];      /* Lower PIXEL bounds of data array */
  int isTordered;            /* 0=order by bolo, 1=order by tslice (default) */
  size_t ndims;              /* Number of active dimensions in "dims" */
  int refcount;              /* Reference count for data object */
  int virtual;               /* Flag for extracted timeslices */
  double *poly;              /* Polynomial scan fits */
  size_t ncoeff;             /* Number of coefficients in polynomial */
  int * lut;                 /* Pointing lookup table */
  AstKeyMap *history;        /* History entries */
} smfData;

/* This structure is a container for multiple, usually related,
   smfDatas */

typedef struct smfArray {
  smfData **sdata;            /* pointers to smfData, static or dynamic */
  smfData *stdata[SMF__MXSMF];/* Pointers to pre-allocated smfDatas */
  smfData **dyndata;          /* pointer to dynamically allocated array */
  dim_t ndat;                 /* Number of smfDatas in current smfArray */
  dim_t dynsize;              /* Size of dynamically allocated array */
  int   owndata;              /* If true, the smfDatas are owned by the
                                 smfArray and can be freed by the smfArray */
} smfArray;

/* This struct is used to group related files together */

typedef struct smfGroup {
  Grp *grp;                  /* Copy of input Grp */
  dim_t **subgroups;         /* Indices into Grp [ngroups][nrelated] */
  size_t *chunk;             /* Flag for continuous chunks in time [ngroups]*/
  dim_t ngroups;             /* Number of subgroups */
  dim_t nrelated;            /* Maximum number of related files */
} smfGroup;

/* Structure containing pointers to data required for DIMM component
   calculation */
typedef struct smfDIMMData {
  smfArray **res;            /* array of smfArray's of model residuals */
  smfArray **noi;            /* array of smfArray's of variance estimates */
  smfArray **qua;            /* array of smfArray's of quality flags */
  smfArray **lut;            /* array of smfArray's of pointing LUTs */
  smfArray **ext;            /* array of smfArray's of extinction corrections */
  smfArray **gai;            /* array of smfArray's of bolo gain corrections */
  double *map;               /* pointer to the current map estimate */
  int *hitsmap;              /* pointer to the current hits map */
  unsigned char *mapqual;    /* pointer to the current map quality */
  double *mapvar;            /* pointer to the current map variance estimate */
  double *mapweight;         /* pointer to the current map weight */
  double *mapweightsq;       /* pointer to the current map weight^2 */
  dim_t mdims[2];            /* dimensions of map */
  dim_t msize;               /* number of elements in map */
  double *chisquared;        /* total chisquared at each chunk */
} smfDIMMData;


/* Prototype for function pointer to different models used by DIMM */
typedef void(*smf_calcmodelptr)( smfWorkForce*, smfDIMMData*, int, AstKeyMap*,
                                 smfArray**, int, int* );

/* Prototype for function pointer to expand different DIMM model components */
typedef void(*smf_expmodelptr)( const smfData*, smfData**, int* );

/* Represents a box in some 2D cartesian coordinate system. */
typedef struct smfBox {
  double lbnd[2];
  double ubnd[2];
} smfBox;

/* Represents a single tile from a full size grid. */
typedef struct smfTile {
  int lbnd[ 3 ];
  int ubnd[ 3 ];
  int elbnd[ 3 ];
  int eubnd[ 3 ];
  int glbnd[ 3 ];
  int gubnd[ 3 ];
  int qlbnd[ 3 ];
  int qubnd[ 3 ];
  Grp *grp;
  int *jndf;
  int size;
  AstMapping *map2d;
  AstMapping *map3d;
  int qxl;
  int qxu;
  int qyl;
  int qyu;
} smfTile;

/* Structure to encapsulate frequency-domain filters implemented with FFTW. */
typedef struct smfFilter {
  double df;            /* frequency step for each sample [Hz] */
  dim_t dim;            /* number of samples in filt */
  double *imag;         /* Imaginary part of the filter */
  int isComplex;        /* Set if filter is fftw_complex, otherwise double */
  dim_t ntslice;        /* # of time slices in input data */
  double *real;         /* Real part of the filter */
  AstFrameSet *wcs;     /* Frameset describing filter */
} smfFilter;

/* Structure for static headers of DIMM files. Only some of the entries
   are used, such as the data dimension fields in data, and steptime
   in hdr. */
typedef struct smfDIMMHead {
  smfData data;
  smfHead hdr;
} smfDIMMHead;

/* Structure used to pass argument values to astRebinSeqF/D running in a
   different thread. */
typedef struct smfRebinSeqArgs {
  int is_double;
  AstMapping *this;
  double wlim;
  int ndim_in;
  const int *lbnd_in;
  const int *ubnd_in;
  void *in;
  void *in_var;
  int spread;
  const double *params;
  int flags;
  double tol;
  int maxpix;
  float badval_f;
  double badval_d;
  int ndim_out;
  const int *lbnd_out;
  const int *ubnd_out;
  int *lbnd;
  int *ubnd;
  void *out;
  void *out_var;
  double *weights;
  int nused;
  int ijob;
} smfRebinSeqArgs;

/* Structure used to pass detector-independent data to smf_rebincube_paste2d/3d
   running in a different thread. */
typedef struct smfRebincubeNNArgs1 {
  int badmask;
  dim_t nchan;
  dim_t nchanout;
  int *spectab;
  int *specpop;
  dim_t nxy;
  int genvar;
  float *data_array;
  float *var_array;
  double *wgt_array;
  int *pop_array;
  dim_t nout;
  int is2d;
} smfRebincubeNNArgs1;

/* Structure used to pass detector-dependent data to smf_rebincube_paste2d/3d
   running in a different thread. */
typedef struct smfRebincubeNNArgs2 {
  smfRebincubeNNArgs1 *common;
  float *work;
  int iv0;
  double wgt;
  double invar;
  float *ddata;
  int nused;
  int nreject;
  int naccept;
} smfRebincubeNNArgs2;

typedef struct smfRebinMapData {
  smfData *data;
  int rebinflags;
  AstSkyFrame *abskyfrm;
  AstMapping *sky2map;
  int moving;
  int spread;
  const double *params;
  int udim[ 2 ];
  double *map;
  double *variance;
  double *weights;
  int ijob;
  double *bolovar;
  int nused;
} smfRebinMapData;

/* Struct to facilitate sorting of data by time.
   Array of these should be built up and passed
   to qsort.
*/

typedef struct {
  double mjd;     /* MJD date - primary sorting key  */
  void *misc;     /* Pointer to additional information */
  int index;      /* an index that will be sorted with the mjd */
  char name [GRP__SZNAM+1]; /* string to carry around naming the item */
} smfSortInfo;


/* These are the bits defined in the DA for use in the SCUBA-2 DRCONTROL
   structure to indicate whether we are missing information from a particular
   DRAMA task. A completely valid state item will have a DRCONTROL flag
   of zero. These definitions should match those defined in sc2headman_struct.h
   in the online software. */

typedef enum {
  DRCNTRL__SMU_BIT = 1,
  DRCNTRL__PTCS_BIT = 2,
  DRCNTRL__SCUBA2_BIT = 4,
  DRCNTRL__RTS_BIT = 8,
  DRCNTRL__FTS2_BIT = 16,
  DRCNTRL__POL2_BIT = 32
} drcntrl_bits;

/* and define a combo value to indicate loss of telescope-ness */
#define DRCNTRL__POSITION ( DRCNTRL__SMU_BIT | DRCNTRL__PTCS_BIT )

/* Sub-instruments */

typedef enum {
  SMF__SUBINST_NONE,
  SMF__SUBINST_850,
  SMF__SUBINST_450,
  SMF__SUBINST_NSUBINST  /* This is always the last entry */
} smf_subinst_t;

#endif /* SMF_TYP_DEFINED */
