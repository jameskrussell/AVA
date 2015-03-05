function [invalidList, lockList, unlockList] = updateSubLists(CaseList, N_case) 
%makes sublists from CaseList using id, valid, and lock fields
      invalidList=struct; lockList=struct; unlockList=struct;   %reset each time it is called
        %otherwise, it is difficult to remove cases from given list
      c1=0; c2=0; c3=0;  %different list counters
      for j=1:N_case
         if CaseList(j).valid
            if CaseList(j).lock
               c2 = c2 + 1;
               lockList(c2).id = CaseList(j).id;
               lockList(c2).caseindex = c2;
            else
               c3 = c3 + 1;
               unlockList(c3).id = CaseList(j).id;
               unlockList(c3).caseindex = c3;
            end
         else
            c1 = c1 + 1;
            invalidList(c1).id = CaseList(j).id;
            invalidList(c1).caseindex = c1;  %index for THIS list
         end
      end
end

