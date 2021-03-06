% Utility to remove one validation ground truth data set (both fast and full)
%
% Usage: ieDeleteValidationFile()

function ieDeleteValidationFile()

    validationFileToBeDeleted =  selectValidationFile();
    
    list = rdtListLocalArtifacts(...
        getpref('isetbio', 'remoteDataToolboxConfig'), ...
        'validation', 'artifactId', validationFileToBeDeleted);

    if isempty(list)
        fprintf('Did not find any artifacts matching ''%s''.', validationFileToBeDeleted)
    else
        fprintf('Found the following local/remote artifacts: \n');
        for k = 1:numel(list)
            fprintf('[%02d].  ''%s''  remotePath:%s   localPath: %s  \n', k, list(k).artifactId, list(k).remotePath, list(k).localPath);
        end
        fprintf('Hit enter to delete these %d artifacts.', numel(list))
        pause;
        client = RdtClient('isetbio');
        % Log into archiva
        client.credentialsDialog();
        for k = 1:numel(list)
            fprintf('Deleting local %s/%s\n', list(k).remotePath, list(k).artifactId);
            deleted = rdtDeleteLocalArtifacts(client.configuration, list(k));
            deleted = rdtDeleteArtifacts(client.configuration, list(k));
        end
    end
end

function validationFileToBeDeleted = selectValidationFile()

    % We will use preferences for the 'isetbioValidation' project
    thisProject = 'isetbio';
    UnitTest.usePreferencesForProject(thisProject, 'reset');
    
    validationFileToBeDeleted = UnitTest.selectScriptFromExistingOnes();
    idx = strfind(validationFileToBeDeleted,'/');
    validationFileToBeDeleted = validationFileToBeDeleted(idx(end)+1:end);
    validationFileToBeDeleted = strrep(validationFileToBeDeleted, 'v_', '');
    validationFileToBeDeleted = strrep(validationFileToBeDeleted, '.m', '');
end