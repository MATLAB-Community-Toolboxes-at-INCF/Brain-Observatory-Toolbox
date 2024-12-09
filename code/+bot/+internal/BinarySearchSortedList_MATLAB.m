% BinarySearchSortedList_MATLAB - FUNCTION Perform binary search between two sorted lists

function vnPreviousSample = BinarySearchSortedList_MATLAB(vfList, vfItems)
   % - Set up indices
   nNumItems = numel(vfItems);
   vnBoundIndices = [1 numel(vfList)];

   % - Preallocate return vector
   vnPreviousSample = nan(nNumItems, 1);

   % - Find first item
   vnPreviousSample(1) = fhBSSL(vfList, vfItems(1), vnBoundIndices);
   
   % - Find last item
   if (nNumItems > 1)
      vnBoundIndices(1) = vnPreviousSample(1);
      vnPreviousSample(end) = fhBSSL(vfList, vfItems(end), vnBoundIndices);
      vnBoundIndices(2) = vnPreviousSample(end);
   else
      return;
   end

   % - Find other items
   for (nItemIndex = 2:nNumItems-1)
      % - Find the current item
      nThisLocation = fhBSSL(vfList, vfItems(nItemIndex), vnBoundIndices);

      % - Restrict binary search domains
      vnBoundIndices(1) = nThisLocation;

      % - Record item location
      vnPreviousSample(nItemIndex) = nThisLocation;
   end
end


function nTargetIndex = fhBSSL(vfList, fSearchItem, vnBounds)

   % - Get midpoint
   nListIndex = round((vnBounds(1)+vnBounds(2))/2);

   while true
      fListItem = vfList(nListIndex);

      if (fSearchItem < fListItem)
         % - Subdivide lower
         vnBounds(2) = nListIndex;
         nListIndex = floor((vnBounds(1)+vnBounds(2))/2);

      else %(fSearchItem >= fListItem)
         if (nListIndex == vnBounds(2))
            % - Accept condition
            nTargetIndex = nListIndex;
            return;

         elseif (nListIndex < vnBounds(2)) && (fSearchItem < vfList(nListIndex+1))
            % - Accept condition
            nTargetIndex = nListIndex;
            return;

         else % (fSearchItem >= vfList(nListIndex+1))
            % - Subdivide upper
            vnBounds(1) = nListIndex;
            nListIndex = ceil((vnBounds(1)+vnBounds(2))/2);
         end
      end
   end
end