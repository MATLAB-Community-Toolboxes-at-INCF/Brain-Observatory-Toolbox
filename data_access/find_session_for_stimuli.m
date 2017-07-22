function filtered_session = find_session_for_stimuli (stimuli,session_by_stimuli)
filtered_session = {};
fields = fieldnames(session_by_stimuli);
    for i = 1 :length(fields)
        if sum(ismember(session_by_stimuli.(char(fields(i))),stimuli)) >= 1
            filtered_session(length(filtered_session)+1) = cellstr(fields(i));
        end
    end
end
