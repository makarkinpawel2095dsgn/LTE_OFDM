%% model ofdm-lte

% fd fsample
fd = 1.92e6;
% fsignal_qpsk
fs = fd/2.5;
% couter period signal in bit
N_sample_bit = 8;
% bitrate 
bitRate = fs/N_sample_bit;

r = randi([0 3],1000,1);

y = pskmod(r, 4, pi/4);
[cosx, jsinx, phasex, jphasex] = qpsk_mod(r, bitRate,  N_sample_bit, 0, fs, fd, 1);
plot(real(y));

