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
