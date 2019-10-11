function [Mask]=L8_OLI_WSCS_mask(A)

surf=0*A;surf(A>1)=1;surf=sum(sum(surf));
        
A=double(A);
WTR=bitget(A,3,'int16');
SDW=bitget(A,4,'int16');
SNO=bitget(A,5,'int16');
CLW=bitget(A,6,'int16');

Mask=(2^0)*WTR+(2^1)*SDW+(2^2)*CLW+(2^3)*SNO;       
end