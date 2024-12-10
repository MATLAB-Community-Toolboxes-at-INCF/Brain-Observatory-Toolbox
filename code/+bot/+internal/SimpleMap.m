% SimpleMap - CLASS Cache a set of results, indexed by an integer
%
% Create an empty map: smObj = SimpleMap();
% Assign some results: smObj(1) = [1 2 3];
%                      smObj(2) = 'a';
%                      smObj(4) = {4 5 6};
% Extract the results: a = smObj(1);
%                      b = smObj(3); <- Empty matrix
%
% SimpleMaps are a handle class.
%
% Methods: spy - Return the sparsity structure of the map
%          find - Return the indices containing data in the map
%          empty - Clear the contents of the map

% Author: Dylan Muir <dylan.muir@unibas.ch>
% Created: 26th October, 2016

classdef SimpleMap < handle

   properties (Hidden)
      % - Cell array containing the map
      cMap = {};
   end
   
   methods
      function oOutput = subsref(smObj, S)
         % subsref - METHOD Extract data from the map
         % Usage: oOutput = smObj(nIndex)
         %        oOutput = subsref(smObj, S)
         
         % - Check subscript
         if (~isscalar(S.subs) || ~strcmp(S.type, '()'))
            error('SimpleMap:subsref:LimitedIndexing', ...
               'Only linear ''()'' indexing is supported by a SimpleMap object');
         end
         
         % - Check map cache
         if (numel(smObj.cMap) >= S.subs{1}) && ~isempty(smObj.cMap{S.subs{1}})
            % - Get result from cache
            oOutput = smObj.cMap{S.subs{1}};

         else
            % - Return empty matrix
            oOutput = [];
         end
      end
      
      function smObj = subsasgn(smObj, S, o)
         % subsref - METHOD Insert data into the map
         % Usage: smObj(nIndex) = o
         %        smObj = subsasgn(smObj, S, o)

         % - Check subscript
         if (~isscalar(S.subs) || ~strcmp(S.type, '()'))
            error('SimpleMap:subsref:LimitedIndexing', ...
               'Only linear ''()'' indexing is supported by a SimpleMap object');
         end
         
         % - Assign to cache
         smObj.cMap{S.subs{1}} = o;
      end
      
      function disp(smObj)
         % disp - METHOD Display a short summary of the map
         %
         % Usage: disp(sbObj)
         
         nNumStored = nnz(spy(smObj));
         nMaxIndex = numel(smObj.cMap);
         fprintf('<a href="matlab:helpPopup SimpleMap">SimpleMap</a> containing %d stored values, max index of %d.\n', nNumStored, nMaxIndex);
      end
      
      function vbHasData = spy(smObj)
         % spy - METHOD Return the sparsity pattern of the map
         %
         % Usage: vbHasData = spy(smObj)
         
         % - Get the sparsity pattern
         vbHasData = ~cellfun(@isempty, smObj.cMap, 'UniformOutput', true);
         
         % - Plot the sparsity, if no output argument is requested
         if (nargout == 0)
            spy(vbHasData);
            clear vbHasData;
         end
      end
      
      function vnDataIndices = find(smObj)
         % find - METHOD Return the indices for which data exists in the map
         %
         % Usage: vnDataIndices = find(smObj)
         
         % - Return the indices from the sparsity pattern
         vnDataIndices = find(spy(smObj));
      end
      
      function empty(smObj)
         % empty - METHOD Clear the contents of the map
         %
         % Usage: empty(smObj)
         
         % - Empty the map
         smObj.cMap = {};
      end
      
      function bIsEmpty = isempty(smObj)
         % isempty - METHOD Return whether the map has contents
         %
         % Usage: bIsEmpty = isempty(smObj)
         
         bIsEmpty = isempty(smObj.cMap);
      end
   end
end

% --- END of SimpleMap.m ---
