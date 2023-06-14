function [d0, d5] = AF_func_SSSGen(PSS_ID, SSS_ID)
if (PSS_ID < 0 || PSS_ID > 2)
    error('LTE:error', 'The number of PSS_ID must be within [0:2]')
end
if (SSS_ID < 0 || SSS_ID > 167)
    error('LTE:error', 'The number of SSS_ID must be within [0:167]')
end

% this is to generate SSS sequences
% How to generate description is in Ref (3GPP TS 36.211 version 10.1.0 Release 10)
% SSS generation is explained in 6.11.2

%/////
% M-sequences s (page 93)
%\\\\\
% basement M-sequence generation x(i+5) = mod ( x(i+2)+x(i), 2 )
% initial val [0 1 2 3 4], here MSeq = x;
MSeq_init = [0 0 0 0 1]; % [x(0),x(1),x(2),x(3),x(4)]
MSeq = [MSeq_init, zeros(1,26)]; % sequence x in the standard
for i = 6:numel(MSeq)
    MSeq(i) = mod( MSeq(i-3) + MSeq(i-5), 2 );
end
% M-sequence s
s = 1 - 2*MSeq;

%/////
% scrambling sequences c (page 94)
%\\\\\
% basement M-sequence generation x(i+5) = mod ( x(i+3)+x(i), 2 )
% initial val [0 1 2 3 4], here CSeq = x;
CSeq_init = [0 0 0 0 1]; % [x(0),x(1),x(2),x(3),x(4)]
CSeq = [CSeq_init, zeros(1,26)]; % sequence x in the standard
for i = 6:numel(CSeq)
    CSeq(i) = mod( CSeq(i-2) + CSeq(i-5), 2 );
end
% M-sequence c
c = 1 - 2*CSeq;
%!!!! Note: s and c looks almost similar !!!!

%/////
% scrambling sequences z (page 94)
%\\\\\
% basement M-sequence generation x(i+5) = mod ( x(i+4)+x(i+2)+x(i+1)+x(i), 2 )
% initial val [0 1 2 3 4], here ZSeq = x;
ZSeq_init = [0 0 0 0 1]; % [x(0),x(1),x(2),x(3),x(4)]
ZSeq = [ZSeq_init, zeros(1,26)]; % sequence x in the standard
for i = 6:numel(ZSeq)
    ZSeq(i) = mod( ZSeq(i-1) + ZSeq(i-3) + ZSeq(i-4) + ZSeq(i-5), 2 );
end
% M-sequence c
z = 1 - 2*ZSeq;

% SSS_Triplets is saved to test the correctness
% SSS_Triplets = zeros(168,3);


qq = floor(SSS_ID/30);      % q' in the standard
q = floor( (SSS_ID + qq*(qq+1)/2)/30 );

mm = SSS_ID + q*(q+1)/2;    % m' in the standard

m0 = mod(mm, 31);
m1 = mod(m0 + floor(mm/31) + 1, 31);

% saving triplets to check if the values match with table Table 6.11.2.1-1.
%     SSS_Triplets(SSS_ID + 1,:) = [SSS_ID, m0, m1];

% generation of s0 and s1
s0m0 = zeros(1,31);
s1m1 = zeros(1,31);
% generation of scrambling sequences c0 and c1
c0 = zeros(1,31);
c1 = zeros(1,31);
% generation of scrambling sequences z0 and z1
z1m0 = zeros(1,31);
z1m1 = zeros(1,31);
% generation of SSS for subframe 0 -- d0, and for subframe 5 -- d5
d0 = zeros(62,1);
d5 = zeros(62,1);
for n = 1:31
    s0m0(n) = s( mod(n-1 + m0, 31) + 1 );
    s1m1(n) = s( mod(n-1 + m1, 31) + 1 );
    
    c0(n) = c( mod(n-1 + PSS_ID, 31) + 1 );
    c1(n) = c( mod(n-1 + PSS_ID + 3, 31) + 1 );
    
    z1m0(n) = z( mod(n-1 + mod(m0,8), 31) + 1 );
    z1m1(n) = z( mod(n-1 + mod(m1,8), 31) + 1 );
    
    % if k = 0 1 2, then 2k = 0 2 4, 2k+1 = 1 3 5, hence
    % if m = 1 2 3, then we should take 2m-1 = 1 3 5, 2m = 2 4 6
    % for subframe 0
    d0(2*n - 1) = s0m0(n)*c0(n);
    d0(2*n) = s1m1(n)*c1(n)*z1m0(n);
    % for subframe 5
    d5(2*n - 1) = s1m1(n)*c0(n);
    d5(2*n) = s0m0(n)*c1(n)*z1m1(n);
end