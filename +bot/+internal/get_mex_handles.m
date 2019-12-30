% TS_GetMexFunctionHandles - FUNCTION Compile and return mex function handles

function [fhBSSL_double, fhBSSL_int32] = get_mex_handles
   % - Does the compiled MEX function exist?
   if (exist(which('bot.internal.BinarySearchSortedList_double_mex')) ~= 3) %#ok<EXIST>
      try %#ok<TRYNC>
         % - Move to the MappedTensor private directory
         strBOTInternalDir = fileparts(which('bot.internal.get_mex_handles'));
         strCWD = cd(strBOTInternalDir);
         
         % - Try to compile the MEX functions
         disp('--- BrainObservatoryToolbox: Compiling MEX functions.');
         mex('BinarySearchSortedList_double_mex.c', '-largeArrayDims', '-O');         
         mex('BinarySearchSortedList_int32_mex.c', '-largeArrayDims', '-O');         
      end
      
      % - Move back to previous working directory
      cd(strCWD);      
   end
   
   % - Did we succeed?
   if (exist(which('bot.internal.BinarySearchSortedList_double_mex')) == 3) %#ok<EXIST>
      fhBSSL_double = @bot.internal.BinarySearchSortedList_double_mex;
      
   else
      % - Just use the slow MATLAB version
      warning('BOT:MEXCompilation', ...
         '--- BrainObservatoryToolbox: Could not compile MEX functions.  Using slow MATLAB versions.');
      
      fhBSSL_double = @bot.internal.BinarySearchSortedList_MATLAB;
   end
   
   % - Did we succeed?
   if (exist(which('bot.internal.BinarySearchSortedList_int32_mex')) == 3) %#ok<EXIST>
      fhBSSL_int32 = @bot.internal.BinarySearchSortedList_int32_mex;
      
   else
      % - Just use the slow MATLAB version
      warning('BOT:MEXCompilation', ...
         '--- BrainObservatoryToolbox: Could not compile MEX functions.  Using slow MATLAB versions.');
      
      fhBSSL_int32 = @bot.internal.BinarySearchSortedList_MATLAB;
   end
end