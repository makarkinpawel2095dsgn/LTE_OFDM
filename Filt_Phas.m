function [CRS_phass] = Filt_Phas( CRSPhases, Kp , K1, K2)
%%
% CRSPhases matrix NxM CRS phases
% D dispers 0 ... 1;
% T time slot
% qx - 0.05 ... 0.1
% qvx - 0.001 ... 0.01
% dvx - 0.05 ... 0.1
%fix width
bitFix = 8;
shift = 13;
phaseWidth = 20;

% Matrix filter dpll
CRSPhas = fix(CRSPhases.*2^phaseWidth)./2^phaseWidth;

ph_phase = zeros(size(CRSPhas));
size_crs = size(CRSPhas);
pho = zeros(1,  size_crs(2));
ph1 = zeros(1,  size_crs(2));
for i = 1 : size_crs(1)
    % amplif dpll
    ph_v_p = CRSPhas(i,:).*Kp;
    ph_v_i = CRSPhas(i,:);
    
    LPF = K1.*pho+K2.*ph1+ph_v_i;
    % delay 
    ph1 = pho;
    pho = ph_v_i;
    ph_phase(i,:) = LPF + ph_v_p;
end;

CRS_phass = ph_phase;
stackedplot(CRSPhas);
figure
stackedplot(CRS_phass);

