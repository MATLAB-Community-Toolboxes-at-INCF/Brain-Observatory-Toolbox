#include <math.h>
#include <mex.h>
#include <string.h>

/* BinarySearchSortedList_int32_mex - MEX FUNCTION Binary search over two sorted array
 *
 * Usage: [nTargetIndex] = BinarySearchSortedList_int32_mex(vnList, nSearchItem, vnBounds)
 *
 * Search within 'vnList', over the range 'vnBounds(1)' to 'vnBounds(2)', for the index
 * of the list entry preceding 'nSearchItem'. If 'nSearchItem' is found at location 'vnBounds(2)',
 * then the index of the last item will be returned. If 'nSearchItem' matches
 * multiple items in 'vnList', then the index of the final matching item will be returned.
 * The desired index will be returned in 'nTargetIndex'.
 *
 * Note that 'vnList' MUST be already sorted. This condition is not checked by BinarySearchSortedList_mex.
 */

/* Author: Dylan Muir <dylan.muir@unibas.ch>
 * Created: 3rd September, 2014
 */

/* % BinarySearchSortedList - FUNCTION Perform binary search between two sorted lists
 * function vnPreviousSample = BinarySearchSortedList(vnList, vnItems)
 * % - Set up indices
 * nNumItems = numel(vnItems);
 * nListBound = numel(vnList);
 * vnBoundIndices = [1 nListBound];
 *
 * % - Preallocate return vector
 * vnPreviousSample = nan(1, nNumItems);
 *
 * % - Find first item
 * vnPreviousSample(1) = BinarySearchSortedList_mex(vnList, vnItems(1), vnBoundIndices);
 *
 * % - Find last item
 * if (nNumItems > 1)
 * vnBoundIndices(1) = vnPreviousSample(1);
 * vnPreviousSample(end) = BinarySearchSortedList_mex(vnList, vnItems(end), vnBoundIndices);
 * vnBoundIndices(2) = vnPreviousSample(end);
 * else
 * return;
 * end
 *
 * % - Find other items
 * for (nItemIndex = 2:nNumItems-1)
 * % - Find the current item
 * nThisLocation = BinarySearchSortedList_mex(vnList, vnItems(nItemIndex), vnBoundIndices);
 *
 * % - Restrict binary search domains
 * vnBoundIndices(1) = nThisLocation;
 *
 * % - Record item location
 * vnPreviousSample(nItemIndex) = nThisLocation;
 * end
 * end
 */

/* BinarySearchSortedList - FUNCTION Raw binary search within a sorted list (MATLAB)
 * function nTargetIndex = BinarySearchSortedList(vnList, nSearchItem, vnBounds)
 * nListIndex = round((vnBounds(1)+vnBounds(2))/2);
 *
 * while true
 * fListItem = vnList(nListIndex);
 *
 * if (nSearchItem < fListItem)
 * % - Subdivide lower
 * vnBounds(2) = nListIndex;
 * nListIndex = floor((vnBounds(1)+vnBounds(2))/2);
 *
 * else %(nSearchItem >= fListItem)
 * if (nListIndex == vnBounds(2))
 * % - Accept condition
 * nTargetIndex = nListIndex;
 * return;
 *
 * elseif (nListIndex < vnBounds(2)) && (nSearchItem < vnList(nListIndex+1))
 * % - Accept condition
 * nTargetIndex = nListIndex;
 * return;
 *
 * else % (nSearchItem >= vnList(nListIndex+1))
 * % - Subdivide upper
 * vnBounds(1) = nListIndex;
 * nListIndex = ceil((vnBounds(1)+vnBounds(2))/2);
 * end
 * end
 * end
 * end */

/* - Debug flag */
/* #define DEBUG */

/* - Include a definition for "round", which is not included on windows */
#ifdef _WIN32
#define round(val)  (floor(val + 0.5))
#endif

int BinarySearchSortedList(int *vnList, int nSearchItem, int *vnBounds)
{
    int	vnBoundsLocal[2], nListIndex;
    
    /* - Make local copy of bounds */
    memcpy((void *) vnBoundsLocal, (const void *) vnBounds, 2 * sizeof(int));
    
    /* - Find initial index */
    nListIndex = round((double)(vnBoundsLocal[0] + vnBoundsLocal[1])/2);
    
#ifdef   DEBUG
    mexPrintf("Initial bounds: [%d %d]. Initial index: [%d]\n", vnBoundsLocal[0], vnBoundsLocal[1], nListIndex);
#endif
    
    /* - Perform binary search */
    while (true) {
#ifdef   DEBUG
    mexPrintf("Current bounds: [%d %d]. Current index: [%d]. Search val: [%d]. Current val: [%d]\n", vnBoundsLocal[0], vnBoundsLocal[1], nListIndex, nSearchItem, vnList[nListIndex]);
#endif

        if (nSearchItem < vnList[nListIndex]) {
            /* Subdivide lower */
            vnBoundsLocal[1] = nListIndex;
            nListIndex = floor((double)(vnBoundsLocal[0] + vnBoundsLocal[1])/2);
            
        } else {	/* (nSearchItem >= vnList[nListIndex]) */
            if (nListIndex == vnBoundsLocal[1]) {
                /* Accept condition */
                return nListIndex;
                
            } else if ((nListIndex < vnBoundsLocal[1]) & (nSearchItem < vnList[nListIndex+1])) {
                /* Accept condition */
                return nListIndex;
                
            } else {	/* (nSearchItem >= vnList[nListIndex+1]) */
                /* Subdivide upper */
                vnBoundsLocal[0] = nListIndex;
                nListIndex = ceil((double)(vnBoundsLocal[0] + vnBoundsLocal[1])/2);
            }
        }
    }
}

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    int	*vnList, *vnItems, *vnPreviousSample;
    int	nNumItems, nListLength, vnBoundIndices[2], nCurrentIndex;
    int  nItemIndex;
    
#ifdef   DEBUG
    mexPrintf("Entering BinarySearchSortedList_mex\n");
#endif
    
    /* - Set up indices */
    nListLength = mxGetM(prhs[0]) * mxGetN(prhs[0]);
    nNumItems = mxGetM(prhs[1]) * mxGetN(prhs[1]);
    vnBoundIndices[0] = 0;	vnBoundIndices[1] = nListLength-1;
    
#ifdef   DEBUG
    mexPrintf("List sizes: %d, %d\n", nListLength, nNumItems);
#endif
            
    /* - Create matrix for the return argument. */
    plhs[0] = mxCreateNumericMatrix(nNumItems, 1, mxINT32_CLASS, mxREAL);
    
    /* - Assign pointers to each input and output. */
    vnList = (int *) mxGetData(prhs[0]);
    vnItems = (int *) mxGetData(prhs[1]);
    vnPreviousSample = (int *) mxGetData(plhs[0]);
    
#ifdef   DEBUG
    mexPrintf("Input list: [");
    for (int nI = 0; nI < nListLength; nI++)
       mexPrintf("%d, ", vnList[nI]);
    mexPrintf("]\n");
#endif
    
    /* - Find first item */
    nCurrentIndex = BinarySearchSortedList(vnList, vnItems[0], vnBoundIndices);
    vnPreviousSample[0] = nCurrentIndex+1;
    
#ifdef   DEBUG
    mexPrintf("First item location: %d\n", nCurrentIndex);
#endif
    
    /* - Find last item */
    if (nNumItems > 1) {
        vnBoundIndices[0] = nCurrentIndex;
        nCurrentIndex = BinarySearchSortedList(vnList, vnItems[nNumItems-1], vnBoundIndices);
        vnPreviousSample[nNumItems-1] = (double) nCurrentIndex+1;
        /* vnBoundIndices[1] = max(vnBoundIndices[0]+1, nCurrentIndex); */
        vnBoundIndices[1] = (vnBoundIndices[0]+1 > nCurrentIndex) ? vnBoundIndices[0]+1 : nCurrentIndex;
        
#ifdef   DEBUG
        mexPrintf("Final item location: %d\n", nCurrentIndex);
        mexPrintf("New bounds: [%d %d]\n", vnBoundIndices[0], vnBoundIndices[1]);
#endif
    } else return;
    
    /* - Find other items */
    for (nItemIndex = 1; nItemIndex < nNumItems-1; nItemIndex++) {
#ifdef   DEBUG
        mexPrintf("Searching for item %d\n", nItemIndex);
#endif
        
        /* - Find the current item */
        nCurrentIndex = BinarySearchSortedList(vnList, vnItems[nItemIndex], vnBoundIndices);
        vnPreviousSample[nItemIndex] = (double) nCurrentIndex+1;
        
        /* - Restrict binary search domain */
        vnBoundIndices[0] = nCurrentIndex;
        
#ifdef   DEBUG
        mexPrintf("This item location: %d\n", nCurrentIndex);
        mexPrintf("New bounds: [%d %d]\n", vnBoundIndices[0], vnBoundIndices[1]);
#endif
    }
}
