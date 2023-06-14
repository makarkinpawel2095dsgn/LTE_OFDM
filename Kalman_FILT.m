function [CRS_phass] = Kalman_FILT( CRSPhases, Kp , K1)
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

%reference phase
phRef = fix(pi/4*2^phaseWidth)/2^phaseWidth; 

%phases on channels
CRS_Phases1=CRSPhases(:,1);
CRS_Phases2=CRSPhases(:,2);
CRS_Phases3=CRSPhases(:,3);
CRS_Phases4=CRSPhases(:,4);
CRS_Phases5=CRSPhases(:,5);
CRS_Phases6=CRSPhases(:,6);
CRS_Phases7=CRSPhases(:,7);
CRS_Phases8=CRSPhases(:,8);
CRS_Phases9=CRSPhases(:,9);
CRS_Phases10=CRSPhases(:,10);
CRS_Phases11=CRSPhases(:,11);
CRS_Phases12=CRSPhases(:,12);

%phases on channels fix
Ph1 = fix(CRS_Phases1*2^phaseWidth)/2^phaseWidth;
Ph2 = fix(CRS_Phases2*2^phaseWidth)/2^phaseWidth;
Ph3 = fix(CRS_Phases3*2^phaseWidth)/2^phaseWidth;
Ph4 = fix(CRS_Phases4*2^phaseWidth)/2^phaseWidth;
Ph5 = fix(CRS_Phases5*2^phaseWidth)/2^phaseWidth;
Ph6 = fix(CRS_Phases6*2^phaseWidth)/2^phaseWidth;
Ph7 = fix(CRS_Phases7*2^phaseWidth)/2^phaseWidth;
Ph8 = fix(CRS_Phases8*2^phaseWidth)/2^phaseWidth;
Ph9 = fix(CRS_Phases9*2^phaseWidth)/2^phaseWidth;
Ph10 = fix(CRS_Phases10*2^phaseWidth)/2^phaseWidth;
Ph11 = fix(CRS_Phases11*2^phaseWidth)/2^phaseWidth;
Ph12 = fix(CRS_Phases12*2^phaseWidth)/2^phaseWidth;

%% FAPCH 
ph_phase = zeros(1, length(Ph1));
pho = 0;

for i = 1 : length(Ph1)
    % amplif dpll
    ph_v_p = Ph1(i)*Kp;
    ph_v_i = Ph1(i)*K1;
    
    LPF = (1-K1)*pho+ph_v_i;
    % delay 
    pho = ph_v_i;
    ph_phase(i) = LPF + ph_v_p;
end;

% Matrix filter dpll
CRSPhas = fix(CRSPhases.*2^phaseWidth)./2^phaseWidth;

ph_phase = zeros(size(CRSPhas));
size_crs = size(CRSPhas);
pho = zeros(1,  size_crs(2));

for i = 1 : length(Ph1)
    % amplif dpll
    ph_v_p = CRSPhas(i,:).*Kp;
    ph_v_i = CRSPhas(i,:);
    
    LPF = pho+ph_v_i;
    % delay 
    pho = ph_v_i;
    ph_phase(i,:) = LPF*K1 + ph_v_p;
end;

%% params Kalman
% matrix state Kalman
% H = [1 0]; F = [1 T; 0 1]; Q = [qx 0; 0 qvx]; R = Dd;
% xe = [Ph1; 0];  xf = [Ph1(1); 0];
% De = [Dd 0; 0 dvx];
% D   = [Dd 0; 0 dvx];
% 
% aXest = zeros(length(CRS_Phases1),1);
% 
% for i=1:length(CRS_Phases1)
%     xe = F * xf;
%     De = F * D * F' + Q;
%     
%     S  = H*De*H' + R;
%     
%     K = De * H' / ( H*De*H' + R);
%     
%     xf = xe + K * (Ph1(i) - H * xe);
%     
%     D = ([1 0; 0 1] - K * H) * De;
%     
%     aXest(i) = xf(1);
%     
% end
% CRS_phases_kalman = aXest;
CRS_phass = ph_phase;
stackedplot(CRSPhas);
figure
stackedplot(CRS_phass);

