#include <math.h>
#include <mex.h>
#include <string.h>

/* BinarySearchSortedList_double_mex - MEX FUNCTION Binary search over two sorted array
 *
 * Usage: [nTargetIndex] = BinarySearchSortedList_double_mex(vfList, fSearchItem, vnBounds)
 *
 * Search within 'vfList', over the range 'vnBounds(1)' to 'vnBounds(2)', for the index
 * of the list entry preceding 'fSearchItem'. If 'fSearchItem' is found at location 'vnBounds(2)',
 * then the index of the last item will be returned. If 'fSearchItem' matches
 * multiple items in 'vfList', then the index of the final matching item will be returned.
 * The desired index will be returned in 'nTargetIndex'.
 *
 * Note that 'vfList' MUST be already sorted. This condition is not checked by BinarySearchSortedList_mex.
 */

/* Author: Dylan Muir <dylan.muir@unibas.ch>
 * Created: 3rd September, 2014
 */

/* % BinarySearchSortedList - FUNCTION Perform binary search between two sorted lists
 * function vnPreviousSample = BinarySearchSortedList(vfList, vfItems)
 * % - Set up indices
 * nNumItems = numel(vfItems);
 * nListBound = numel(vfList);
 * vnBoundIndices = [1 nListBound];
 *
 * % - Preallocate return vector
 * vnPreviousSample = nan(1, nNumItems);
 *
 * % - Find first item
 * vnPreviousSample(1) = BinarySearchSortedList_mex(vfList, vfItems(1), vnBoundIndices);
 *
 * % - Find last item
 * if (nNumItems > 1)
 * vnBoundIndices(1) = vnPreviousSample(1);
 * vnPreviousSample(end) = BinarySearchSortedList_mex(vfList, vfItems(end), vnBoundIndices);
 * vnBoundIndices(2) = vnPreviousSample(end);
 * else
 * return;
 * end
 *
 * % - Find other items
 * for (nItemIndex = 2:nNumItems-1)
 * % - Find the current item
 * nThisLocation = BinarySearchSortedList_mex(vfList, vfItems(nItemIndex), vnBoundIndices);
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
 * function nTargetIndex = BinarySearchSortedList(vfList, fSearchItem, vnBounds)
 * nListIndex = round((vnBounds(1)+vnBounds(2))/2);
 *
 * while true
 * fListItem = vfList(nListIndex);
 *
 * if (fSearchItem < fListItem)
 * % - Subdivide lower
 * vnBounds(2) = nListIndex;
 * nListIndex = floor((vnBounds(1)+vnBounds(2))/2);
 *
 * else %(fSearchItem >= fListItem)
 * if (nListIndex == vnBounds(2))
 * % - Accept condition
 * nTargetIndex = nListIndex;
 * return;
 *
 * elseif (nListIndex < vnBounds(2)) && (fSearchItem < vfList(nListIndex+1))
 * % - Accept condition
 * nTargetIndex = nListIndex;
 * return;
 *
 * else % (fSearchItem >= vfList(nListIndex+1))
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

int BinarySearchSortedList(double *vfList, double fSearchItem, int *vnBounds)
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
    mexPrintf("Current bounds: [%d %d]. Current index: [%d]. Search val: [%.2f]. Current val: [%.2f]\n", vnBoundsLocal[0], vnBoundsLocal[1], nListIndex, fSearchItem, vfList[nListIndex]);
#endif

        if (fSearchItem < vfList[nListIndex]) {
            /* Subdivide lower */
            vnBoundsLocal[1] = nListIndex;
            nListIndex = floor((double)(vnBoundsLocal[0] + vnBoundsLocal[1])/2);
            
        } else {	/* (fSearchItem >= vfList[nListIndex]) */
            if (nListIndex == vnBoundsLocal[1]) {
                /* Accept condition */
                return nListIndex;
                
            } else if ((nListIndex < vnBoundsLocal[1]) & (fSearchItem < vfList[nListIndex+1])) {
                /* Accept condition */
                return nListIndex;
                
            } else {	/* (fSearchItem >= vfList[nListIndex+1]) */
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
    double	*vfList, *vfItems, *vnPreviousSample;
    int		nNumItems, nListLength, vnBoundIndices[2], nCurrentIndex;
    int      nItemIndex;
    
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
    plhs[0] = mxCreateDoubleMatrix(nNumItems, 1, mxREAL);
    
    /* - Assign pointers to each input and output. */
    vfList = mxGetPr(prhs[0]);
    vfItems = mxGetPr(prhs[1]);
    vnPreviousSample = mxGetPr(plhs[0]);
    
    /* - Find first item */
    nCurrentIndex = BinarySearchSortedList(vfList, vfItems[0], vnBoundIndices);
    vnPreviousSample[0] = (double) nCurrentIndex+1;
    
#ifdef   DEBUG
    mexPrintf("First item location: %d\n", nCurrentIndex);
#endif
    
    /* - Find last item */
    if (nNumItems > 1) {
        vnBoundIndices[0] = nCurrentIndex;
        nCurrentIndex = BinarySearchSortedList(vfList, vfItems[nNumItems-1], vnBoundIndices);
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
        nCurrentIndex = BinarySearchSortedList(vfList, vfItems[nItemIndex], vnBoundIndices);
        vnPreviousSample[nItemIndex] = (double) nCurrentIndex+1;
        
        /* - Restrict binary search domain */
        vnBoundIndices[0] = nCurrentIndex;
        
#ifdef   DEBUG
        mexPrintf("This item location: %d\n", nCurrentIndex);
        mexPrintf("New bounds: [%d %d]\n", vnBoundIndices[0], vnBoundIndices[1]);
#endif
    }
}
