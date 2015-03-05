function [CaseList, N_case, activeindex] = loadCaseList(matDir, CaseListFile, lock_filedir, folder_string)  %loads/creates master caselist
%attempts to load CaseListFile in matDir; 
%if CaseListFile does not exist, it creates it by making directory of
%folders with form defined by folder_string (ignoring CaseList.mat and other folders, such as
%MU029.58.noABP or Locked) 


if exist(CaseListFile, 'file')
   temp = load(CaseListFile, 'CaseList');   %contains CaseList struct
   CaseList = temp.CaseList;      
else 
   CaseDir = dir([matDir folder_string]);
   N_case = length(CaseDir);
   
      CaseList = struct;
      for j=1:N_case
         CaseList(j).id = CaseDir(j).name;  %just takes 1st component of stringsplit
         CaseList(j).caseindex = j;
         CaseList(j).valid = 1;
         CaseList(j).lock = 0;
         CaseList(j).date = '';
      end 
          
 save(CaseListFile, 'CaseList')    %save it when I make it for 1st time
 
 if ~exist(lock_filedir, 'dir')   %make lock folder if it doesn't already exist
      mkdir(lock_filedir)
 end
end  %if


N_case = length(CaseList);
activeindex = 1; 

end


