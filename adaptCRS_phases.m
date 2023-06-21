function [find_FallingFront, find_RisingFront, Period_CRS_RissingFront] = adaptCRS_phases( CRS_Phases)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function adaptive CRS_phases 
% 
%
%
%

bitFix = 8;
shift = 13;
phaseWidth = 20;

% Matrix filter dpll
CRSPhas = fix(CRS_Phases.*2^phaseWidth)./2^phaseWidth;

size_CRSPhas = size(CRSPhas);

buff_CRSphas = zeros(1,size_CRSPhas(2));

find_FallingFront = zeros(size_CRSPhas);
find_RisingFront = zeros(size_CRSPhas);

Period_CRS_RissingFront = zeros(size_CRSPhas);
buff_CRSphasPeriod = zeros(1,size_CRSPhas(2));
localMaxPeriod = zeros(size_CRSPhas);

for i = 1 : size_CRSPhas(1)
    %%
    for j = 1 : size_CRSPhas(2)
        %% if falling front
        if ( CRSPhas(i,j) - buff_CRSphas(j) > pi)
            find_FallingFront(i,j) = 1;
        else
            find_FallingFront(i,j) = 0;
        end;
        %% if rissing front
        if ( buff_CRSphas(j) - CRSPhas(i,j) > pi)
            find_RisingFront(i,j) = 1;
            % null couter clock
            Period_CRS_RissingFront(i,j) = 0;
        else
            find_RisingFront(i,j) = 0;
            % clock couter
            % matlab error
            if (i == 1) 
                Period_CRS_RissingFront(i,j) = 1;
            else
                Period_CRS_RissingFront(i,j) = Period_CRS_RissingFront(i-1,j)+1;
            end;
        end;
        
    end;
    buff_CRSphas = CRSPhas(i,:);
    
end;

FIR_aray = zeros(size_CRSPhas);
FIR_del_vect0 = zeros(1, size_CRSPhas(2));
FIR_del_vect1 = zeros(1, size_CRSPhas(2));

for i = 1 : size_CRSPhas(1)
    
    FIR_aray(i,:) = (CRSPhas(i,:) + 0.8.*FIR_del_vect0)./1.8; % + 0.2.*FIR_del_vect1)./3;
    FIR_del_vect1 = FIR_del_vect0;
    FIR_del_vect0 = CRSPhas(i,:);
end;

sum_aver = 0;
sum_averVect = zeros(1, size_CRSPhas(1));
for i = 1 : size_CRSPhas(1)
    
    for j = 1 : size_CRSPhas(2)
        sum_aver = sum_aver + CRSPhas(i,j);
    end;
    sum_averVect(i) = sum_aver/size_CRSPhas(2);
end;

diff_aray = zeros(size_CRSPhas);
diff_vect = zeros(1, size_CRSPhas(2));
for i = 1 : size_CRSPhas(1)
    
    for j = 1 : size_CRSPhas(2)
        diff_aray(i,j) = CRSPhas(i,j) - diff_vect(j);
    end;
    diff_vect = CRSPhas(i,:);
end;


diff = 0;

for i = 1 : size_CRSPhas(1)

    diff_Vect(i) = sum_averVect(i) - diff;
    diff = sum_averVect(i);
end;
figure(1); 
subplot(2,1,1); plot(diff_Vect);
subplot(2,1,2); plot(diff_aray);
figure(1); 
plot(CRS_Phases);
figure(2);
imagesc(rot90(find_FallingFront));
title("Falling Front");
figure(3);
imagesc(rot90(find_RisingFront));
title("Rissing Front");
figure(4)
imagesc(Period_CRS_RissingFront');
