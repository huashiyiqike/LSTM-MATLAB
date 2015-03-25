#include "mex.h"
#include <stdio.h>

/* # pixels in image */
#define DIMENSIONS 384

/* Input Arguments */
#define	FILENAME	prhs[0]
#define SELECTROWS      prhs[1]

/* Output Arguments */
#define	DATA	plhs[0]
#define setFilePos   fsetpos
#define fpos_T       fpos_t


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
     
{ 
    FILE *out;
    float *datap;
    /* double *selectp; */
    unsigned long long *selectp;
    char *filenamep;
    int64_T offset; 
    unsigned long nDimensions, nSelectRows, buflen, status, i; 
    
    /* Check for proper number of arguments */
    
    if (nrhs != 2) { 
	mexErrMsgTxt("Two input arguments required."); 
    } else if (nlhs > 1) {
	mexErrMsgTxt("Too many output arguments."); 
    } 

    /* Check the dimensions of DATA. */ 
    nDimensions = DIMENSIONS;

    /* Get number of rows to pick */
    nSelectRows = mxGetN(SELECTROWS); 
    selectp = (unsigned long long*) mxGetPr(SELECTROWS);
    
    /*mexPrintf("nDimensions: %ld nSelectRows: %ld\n",DIMENSIONS,nSelectRows);*/
    DATA = mxCreateNumericMatrix(nDimensions,nSelectRows, mxSINGLE_CLASS, mxREAL);
    datap = (float*) mxGetData(DATA);

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
	
	/* get offset into binary file */
	offset = (int64_T) (selectp[i]-1) * (int64_T) (sizeof(float) * DIMENSIONS);

	/*mexPrintf("ind: %ld offset: %ld\n",i,offset);*/
	/* seek point in file */
	/* fseek(out,offset,SEEK_SET); */
        setFilePos(out, (fpos_T*) &offset);

	/* do binary read direct into datap */
	fread(&(datap[i*DIMENSIONS]),sizeof(float),DIMENSIONS,out);
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
