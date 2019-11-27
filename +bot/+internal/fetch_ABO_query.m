function response = fetch_ABO_query(strModel, strQueryString, nPageSize, strFormat, strRMAPrefix, strHost, strScheme)

DEF_strScheme = "http";
DEF_strHost = "api.brain-map.org";
DEF_strRMAPrefix = "api/v2/data";
DEF_nPageSize = 5000;
DEF_strFormat = "query.json";

% -- Default arguments
if ~exist('strScheme', 'var') || isempty(strScheme)
   strScheme = DEF_strScheme;
end

if ~exist('strHost', 'var') || isempty(strHost)
   strHost = DEF_strHost;
end

if ~exist('strRMAPrefix', 'var') || isempty(strRMAPrefix)
   strRMAPrefix = DEF_strRMAPrefix;
end

if ~exist('nPageSize', 'var') || isempty(nPageSize)
   nPageSize = DEF_nPageSize;
end

if ~exist('strFormat', 'var') || isempty(strFormat)
   strFormat = DEF_strFormat;
end

% - Build a URL
strURL = string(strScheme) + "://" + string(strHost) + "/" + ...
   string(strRMAPrefix) + "/" + string(strFormat) + "?" + ...
   string(strModel);

if ~isempty(strQueryString)
   strURL = strURL + "," + strQueryString;
end

% - Set up options
options = weboptions('ContentType', 'JSON', 'TimeOut', 60);

nTotalRows = [];
nStartRow = 0;

response = table();

while isempty(nTotalRows) || nStartRow < nTotalRows
   % - Add page parameters
   strURLQueryPage = strURL + ",rma::options[start_row$eq" + nStartRow + "][num_rows$eq" + nPageSize + "][order$eq'id']";
   
   % - Perform query
   response_raw = webread(strURLQueryPage, options);
   
   % - Convert response to a table
   if isa(response_raw.msg, 'cell')
      response_page = cell_messages_to_table(response_raw.msg);
   else
      response_page = struct2table(response_raw.msg);
   end
   
   % - Append response page to table
   if isempty(response)
      response = response_page;
   else
      response = bot.internal.merge_tables(response, response_page);
   end
   
   % - Get total number of rows
   if isempty(nTotalRows)
      nTotalRows = response_raw.total_rows;
   end
   
   % - Move to next page
   nStartRow = nStartRow + nPageSize;
   
   % - Display progress if we didn't finish
   if (nStartRow < nTotalRows)
      fprintf('Downloading.... [%.0f%%]\n', round(nStartRow / nTotalRows * 100))
   end
end

end

function tMessages = cell_messages_to_table(cMessages)
% - Get an exhaustive list of fieldnames
cFieldnames = cellfun(@fieldnames, cMessages, 'UniformOutput', false);
cFieldnames = unique(vertcat(cFieldnames{:}), 'stable');

% - Make sure every message has all required field names
   function sData = enforce_fields(sData)
      vbHasField = cellfun(@(c)isfield(sData, c), cFieldnames);
      
      for strField = cFieldnames(~vbHasField)'
         sData.(strField{1}) = [];
      end
   end

cMessages = cellfun(@(c)enforce_fields(c), cMessages, 'UniformOutput', false);

% - Convert to a table
tMessages = struct2table([cMessages{:}]);

end
