function reGrid = AK_func_OFDMDemodulate_Slot_Normal_72(waveform)
% Configured demodulation over 1 slot (Normal_CP mode)

NsymbDL = 7;
NFFT = 128;
% Symb_starts = [6,  143, 280, 417, 554, 691, 828]; % for Cicle_prefixes = [10, 9, 9, 9, 9, 9, 9] with    cpFraction = 0.55
% Symb_starts = [7,  144, 281, 418, 555, 692, 829]; % for Cicle_prefixes = [10, 9, 9, 9, 9, 9, 9] with    cpFraction 
% Symb_starts = [8,  145, 282, 419, 556, 693, 830]; % for Cicle_prefixes = [10, 9, 9, 9, 9, 9, 9] with    cpFraction ~ 0.75
% Symb_starts = [9,  146, 283, 420, 557, 694, 831]; % for Cicle_prefixes = [10, 9, 9, 9, 9, 9, 9] with    cpFraction ~ 0.75
% Symb_starts = [10, 147, 284, 421, 558, 695, 832]; % for Cicle_prefixes = [10, 9, 9, 9, 9, 9, 9]
Symb_starts = [11, 148, 285, 422, 559, 696, 833]; % for Cicle_prefixes = [10, 9, 9, 9, 9, 9, 9]
% dP = -[1, 1, 1, 1, 1, 1, 1] / NFFT;
% dP = [0, 0, 0, 0, 0, 0, 0] / NFFT;

Grid_indexes = [(29 : 64) (66:101)];% Picked from "AF_func_OFDMDemodulate_5Subframes.m"

% idx = ( 0: (NFFT-1) );

reGrid = zeros(NsymbDL, 72);


for symbol = 0:(NsymbDL-1)
    
    % Create vector of phase corrections, one per FFT sample,
    % to compensate for FFT performed away from zero phase
    % point on the original subcarriers.
%     phaseCorrection = exp(-1i*2*pi*dP(symbol+1)*idx)';
    
    compensated_Wave = waveform( Symb_starts(symbol+1) : (Symb_starts(symbol+1) + NFFT -1) );% .* phaseCorrection;
%     compensated_Wave = waveform( Symb_starts(symbol+1)+1 : (Symb_starts(symbol+1) + NFFT ) );% .* phaseCorrection;
    
    fftOutput = round( fft( compensated_Wave ) );
    fftOutput = fftshift( fftOutput );
    
    % Assign the active subcarriers into the appropriate column
    % of the received GRID, for each antenna.
    reGrid(symbol+1, :) = fftOutput(Grid_indexes);
end
