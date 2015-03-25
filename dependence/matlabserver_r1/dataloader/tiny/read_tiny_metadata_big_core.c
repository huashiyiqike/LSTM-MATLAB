#include "mex.h"
#include <stdio.h>

/* Fast version of convert_matlab_auton_slow.m */
#define DIMENSIONS 768
#define NUM_FIELDS 14

/* Input Arguments */
#define	FILENAME	prhs[0]
#define SELECTROWS      prhs[1]
#define SELECTFIELDS    prhs[2]

/* Output Arguments */
#define	DATA	plhs[0]

/* Set sizes of fields in metadata structure */

/* 1.max length of noun */
#define  KEYWORD_LENGTH  80;
  /* 2. max length of filename */
#define   NAME_LENGTH 95;
  /* 3. max length of width */
#define   WIDTH_LENGTH  2;
  /* 4. max length of height */
#define   HEIGHT_LENGTH  2;
  /* 5. max length of color */
#define   COLORS_LENGTH  1;
  /* 6. max date length */
#define   DATE_LENGTH  32;
  /* 7. engine length */
#define   ENGINE_LENGTH  10;
  /* 8. max length of thumbnail url */
#define   THUMB_URL_LENGTH  200;
  /* 9. max length of source url */
#define   SOURCE_URL_LENGTH  328;
  /* 10. page length */
#define   PAGE_LENGTH  4;
  /* 11. ind_page length */
#define   IND_PAGE_LENGTH  4;
  /* 12. ind_engine length */
#define   IND_ENGINE_LENGTH  4;
  /* 13. ind_overall length */
#define   IND_OVERALL_LENGTH  4;
  /* 14. label length */
#define   LABEL_LENGTH  2;
  

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
     
{ 
    FILE *out;
    unsigned char *datap[NUM_FIELDS];
    /* double *selectp; */
    unsigned long long *selectp;
    mxArray* cell_ptr[NUM_FIELDS];
    char *filenamep;
    int nFields, j;
    int dims[2];
    unsigned int *selectf;
    unsigned long long selectind, offset, nDimensions, nSelectRows, buflen, status, i; 
    int field_size[NUM_FIELDS];
    int str_offset[NUM_FIELDS];

    /* Set field sizes */
    field_size[0] = KEYWORD_LENGTH;
    field_size[1] = NAME_LENGTH;
    field_size[2] = WIDTH_LENGTH;
    field_size[3] = HEIGHT_LENGTH;
    field_size[4] = COLORS_LENGTH;
    field_size[5] = DATE_LENGTH;
    field_size[6] = ENGINE_LENGTH;
    field_size[7] = THUMB_URL_LENGTH;
    field_size[8] = SOURCE_URL_LENGTH;
    field_size[9] = PAGE_LENGTH;
    field_size[10] = IND_PAGE_LENGTH;
    field_size[11] = IND_ENGINE_LENGTH;
    field_size[12] = IND_OVERALL_LENGTH;
    field_size[13] = LABEL_LENGTH;

    /* now compute offsets */
    str_offset[0]=0;
    for (i=1;i<NUM_FIELDS;i++){
      str_offset[i] = str_offset[i-1] + field_size[i-1];
    }

    /*for (i=0;i<NUM_FIELDS;i++){
        mexPrintf("str_offset[%d]=%d, field_size[%d]=%d\n",i,str_offset[i],i,field_size[i]);
	}*/

    /* Check for proper number of arguments */
    
    if (nrhs >3 ) { 
	mexErrMsgTxt("Two or three input arguments required."); 
    } else if (nlhs > 1) {
	mexErrMsgTxt("Too many output arguments."); 
    } 

    /* Check the dimensions of DATA. */ 
    nDimensions = DIMENSIONS;

    /* Get number of rows to pick */
    nSelectRows = mxGetN(SELECTROWS); 
    selectp = (unsigned long long*) mxGetPr(SELECTROWS);

    if (nrhs==3){
      /* Get number of rows to pick */
      nFields = mxGetN(SELECTFIELDS); 
      selectf = (unsigned int*) mxGetPr(SELECTFIELDS);
    }
    else{
      nFields = NUM_FIELDS;
      selectf = mxCalloc(NUM_FIELDS, sizeof(unsigned int));
      for (i=0;i<NUM_FIELDS;i++){ selectf[i]=i+1; };
    }
      
    /* Loop over all fields requested and make cell arrays as output */
    dims[0] = 1; dims[1] = nFields;
    DATA = mxCreateCellArray(2,dims);
    for (i=0;i<nFields;i++){
      /*  mexPrintf("i: %d, selectf[%d]=%d, field_size=%d\n",i,i,selectf[i]-1,field_size[selectf[i]-1]);*/
      /*dims[0]=field_size[selectf[i]]; dims[1]=nSelectRows;
	cell_ptr[i] = mxCreateCharArray(2,dims); */
      cell_ptr[i] = mxCreateNumericMatrix(field_size[selectf[i]-1],nSelectRows, mxUINT8_CLASS, mxREAL);
      mxSetCell(DATA, i, cell_ptr[i]);
      datap[i] = mxGetData(cell_ptr[i]);
    }

    /* Input must be a string. */
    if (mxIsChar(FILENAME) != 1)
      mexErrMsgTxt("Filename must be a string.");
    
    /* Input must be a row vector. */
    if (mxGetM(FILENAME) != 1)
      mexErrMsgTxt("Filename must be a row vector.");
    
    /* Get the length of the input string. */
    buflen = (mxGetM(FILENAME) * mxGetN(FILENAME)) + 1;

    /* Allocate memory for input and output strings. */
    filenamep = mxCalloc(buflen, sizeof(char));

    /* Copy the string data from FILENAME into a C string input_buf. */
    status = mxGetString(FILENAME, filenamep, buflen);
    if (status != 0) 
      mexWarnMsgTxt("Not enough space. String is truncated.");

    /**********************************************************************************/

    /* Open file */
    out = fopen(filenamep, "rb" );

    if( out != NULL ){

      /* loop over selected rows */
      for (i=0;i<nSelectRows;i++){
	
	for (j=0;j<nFields;j++){

	  /* get offset into binary file */
	  offset = ((selectp[i]-1) * sizeof(unsigned char) * DIMENSIONS) + str_offset[selectf[j]-1];

	  /*	  mexPrintf("j: %d, selectf[%d]=%d, str_offset %d, field_size: %d\n",j,j,selectf[j]-1,str_offset[selectf[j]-1],field_size[selectf[j]-1]);*/
	  
	  /*	  mexPrintf("ind: %ld offset: %ld\n",i,offset);*/
	  /* seek point in file */
	  fseek(out,offset,SEEK_SET);   
	  
	  /* do binary read direct into datap */
	  
	  fread(&(datap[j][i*field_size[selectf[j]-1]]),sizeof(unsigned char),field_size[selectf[j]-1],out);
	}

      }

      /* Flush buffer and close file */
      fclose(out);
    
    }
    else{
      /* Error */
       /*   mexPrintf("Error opening file: %s\n",filenamep);*/
    
    }

   return;
    
}


/* size_t fread(void *ptr, size_t size_of_elements, size_t number_of_elements, FILE *a_file);*/
