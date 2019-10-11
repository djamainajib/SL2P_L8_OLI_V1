function [flag]=input_out_of_range_flag_function (NNT,data,r,c)
Definition_Domain=NNT.Definition_Domain;


Nb_Cas=length(data);
CL=ceil((data-repmat(Definition_Domain.Extreme(1,:),Nb_Cas,1))./repmat(Definition_Domain.Extreme(2,:)-Definition_Domain.Extreme(1,:),Nb_Cas,1).*Definition_Domain.Step);
CL(CL>99)=99;
CL(CL<0)=99;
UCL=0;
for ii=1:size(CL,2),
    UCL=UCL+CL(:,ii)*(100^(ii-1));
end;

%%%%
CL_ref=Definition_Domain.Grid;
UCL_ref=0;
for ii=1:size(CL_ref,2),
    UCL_ref=UCL_ref+CL_ref(:,ii)*(100^(ii-1));
end;

flag=reshape(~ismember(UCL,UCL_ref),r,c);
end



