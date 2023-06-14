function c = AK_func_PRSGen(Cinit, len, addon)
% addon = NmaxDLRB - NDLRB

% initial 31 length sequence 
x1_init = [1,zeros(1,30)];
x2_init = de2bi(Cinit,31);

% 3GPP TS 36.211 version 14.2.0 Release 14: page 155
% Generating M-sequences
Nc = 1600 + addon;
x1 = [x1_init, zeros(1, Nc + len - length(x1_init))];
x2 = [x2_init, zeros(1, Nc + len - length(x2_init))];
for n = 1:Nc + len - 31
    x1(n+31) = mod( x1(n+3)                +x1(n), 2);
    x2(n+31) = mod( x2(n+3)+x2(n+2)+x2(n+1)+x2(n), 2);
end

% Generating Gold sequence
c = mod( x1(Nc+1:end)+x2(Nc+1:end) ,2);
