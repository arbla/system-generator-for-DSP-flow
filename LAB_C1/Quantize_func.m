%-----------------------------------------------------------------------
%  Quantization function: [data_Q_N] = Quantize_func(data, N)
%
%  - Inputs:  - data: a float precision data (normalized between 1 and -1)
%             - N: Number of bits to represent the quantized data
%
%  - Output:  - data_Q_N: Quantized data using N bits      
%
%%------------------------------------------------------------------------
function [data_Q_N]=Quantize_func(data,N)


if data>=1-2^-(N-1)
    data_Q_N=1-2^-(N-1);
elseif data<-1
    data_Q_N =-1;
else
    temp0=abs(data);
    temp=temp0;
    temp2=0;
    use_n=zeros(1,N);
    for n=1:(N-1)
        if temp>=2^(-n)
            use_n(1,n+1)=1;
            temp=temp-2^(-n);
            temp2=temp2+2^(-n);        
        end
    end
    
    temp3=temp2+2^-(N-1);
    if abs(temp0-temp3)<abs(temp0-temp2)
        temp_fin=temp3;
    else
        temp_fin=temp2;
    end
    
    if data>=0
        data_Q_N=temp_fin;
    else 
        data_Q_N=-1*temp_fin;
    end
end

%%------------------------------------------------------------------------
