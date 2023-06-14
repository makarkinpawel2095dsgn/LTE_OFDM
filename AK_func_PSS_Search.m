function [Positions, PSS_IDs, Amps, Thresholds, dFreqs, Responses] = AK_func_PSS_Search(Data)
% Computing PSS position for Data
%
% Data              - Complex samples vector @1.92 MHz
%
% Positions         - Indexex of valid responses
% PSS_IDs           - Index of PSS sequence (0..2)
% Amps              - Amplitudes of valid responses
% Thresholds        - Dynamic threshold values for valid responses
% dFreqs            - Frequency mismatch estimations
%
% Responses         - ALL responses and (4-th) thresholds



    PSS_COEFS_WIDTH             = 17;
    CORDIC_ABS_ITERATION_QTY    = 18; % CORDIC_ABS iteration quantity from Xilinx IP-core
    PSS_Half_Bound              = 70;
    THRESHOLD_ATT               = 0.5;        % Theretical maximum threshold attenuation
    length_FIR_compiler_1_92    = 141;    
    DETECT_INTERVAL             = 8;        % Check for DETECT_INTERVAL-1 samples near detect 1st peak for find max
    Fs                          = 1.92e6;
    
    
    dt = 1 / Fs;
    
    S_ds = Data;

    
    % Current version works with abs() function (CORDIC_abs at hardware)
    % Lower LUTs (but more DSP48s) will be at sqr() version
    [PSS_filters, PSS_filters_gain] = AK_func_get_quant_PSS_coefs_v2(PSS_COEFS_WIDTH);

    % Arithmetic difference
    % Responses2_Center_diff = ( (size(PSS_filters, 2) - (PSS_Half_Bound +1))/2 + (PSS_Half_Bound +1) ) - ...
    %                          ( (1 + PSS_Half_Bound) /2 + 1);
    % Weight-corrected difference
    Responses2_Center_diff = ( (size(PSS_filters, 2) - (PSS_Half_Bound +1))/2 + (PSS_Half_Bound +1) ) - ...
                             ( (1 + PSS_Half_Bound) /2 + 1) ...
                             -2.5;

    pss_Responses  = zeros(3, length(S_ds));
    pss_Responses2 = zeros(2, 3, length(S_ds));

    
    % calculate correlations
    for pss_i = 1:3
    %     % Simple complex arithmetics
    %     pss_Responses(pss_i, :) = round( filter( PSS_filters(pss_i,:), PSS_filters_gain, S_ds ) );    

        A = real(S_ds);
        B = imag(S_ds);
        C = real(PSS_filters(pss_i,:));
        D = imag(PSS_filters(pss_i,:));

%         Coefs0 = C.';
%         Coefs1 = (C-D).';
%         Coefs2 = (C+D).';

        % 3-Mult scheme
        BmAC = round( filter(C,   PSS_filters_gain, B-A) );
        BCmD = round( filter(C-D, PSS_filters_gain, B)   );
        ACpD = round( filter(C+D, PSS_filters_gain, A)   );
        pss_Responses(pss_i, :) = complex(BCmD - BmAC, BmAC + ACpD);    


        T1 = round( filter( PSS_filters(pss_i, 1: PSS_Half_Bound), PSS_filters_gain, S_ds ) );
        T2 = round( filter( PSS_filters(pss_i,(PSS_Half_Bound+1):size(PSS_filters, 2) ), PSS_filters_gain, S_ds ) );

        pss_Responses2(1, pss_i, (PSS_Half_Bound+1):end) = T1( (PSS_Half_Bound+1):end );
        pss_Responses2(2, pss_i, (PSS_Half_Bound+1):end) = T2( 1:(end-PSS_Half_Bound) );

    %     pss_Responses(1, :) = pss_Responses2(1, pss_i, :) + pss_Responses2(2, pss_i, :);    
    end

    % Threshold computing
    Threshold_filter = ones(size(PSS_filters, 2), 1);
    Threshold_filter_gain = 128; %sum(abs(Threshold_filter));

    Threshold_minimal = length(Threshold_filter);
    abs_S_ds = CORDIC_abs2(S_ds, CORDIC_ABS_ITERATION_QTY);
    TH_Responses = filter( Threshold_filter, 1, abs_S_ds );
    TH_Responses = fix( TH_Responses / Threshold_filter_gain * THRESHOLD_ATT );

    % Check and setup minimal threshold
    TH_Responses( TH_Responses < Threshold_minimal ) = Threshold_minimal;

    %% Check detection and compute angle
    % I suppose, 1st high response will be main - he will be maximum amplitude
    % 7 responses after main (If there will be) supposed are reflected rays.
    % These secondary rays can be averaged or ignored.

    Positions = [];
    PSS_IDs = []; 
    Amps = []; 
    Thresholds = []; 
    dFreqs = []; 
    Responses = zeros(4, size(pss_Responses, 2));
    
    for pss_i = 1:3
        [A, P] = CORDIC_abs2( pss_Responses(pss_i, :).', CORDIC_ABS_ITERATION_QTY );
        Response_valid = (A >= TH_Responses);
        Response_valid(1:length_FIR_compiler_1_92) = 0;
        only_valid_Responses = A .* Response_valid;
        primary_Responses = only_valid_Responses;

        % attenuation lower responses in DETECT_INTERVAL 
        for idx = DETECT_INTERVAL:length(A)
            [~, max_idx] = max( primary_Responses( 1 + idx - DETECT_INTERVAL : idx) );
            max_idx = 1 + idx - DETECT_INTERVAL + max_idx -1;

            t = primary_Responses( max_idx );
            primary_Responses( 1 + idx - DETECT_INTERVAL : idx) = 0;
            primary_Responses( max_idx ) = t;
        end

        Response_indexes = find(primary_Responses > 0);
        Phases = zeros(size(Response_indexes));
        for idx = 1:length(Response_indexes)

            the_idx = Response_indexes(idx);
            Phases(idx) = P(Response_indexes(idx));
            [~, P2] = CORDIC_abs2( pss_Responses2(2, pss_i, the_idx), CORDIC_ABS_ITERATION_QTY );
            [~, P1] = CORDIC_abs2( pss_Responses2(1, pss_i, the_idx), CORDIC_ABS_ITERATION_QTY );
            dP = ( P2 - P1 );

            if dP >= (2*pi)
                dP = dP - 2*pi;
            end
            if dP < (-2*pi)
                dP = dP + 2*pi;
            end

            dFreq = dP / (2*pi) / Responses2_Center_diff / dt;

%             fprintf('PSS_ID = %d:  at %6d position  with  Amp = %6d (Threshold = %6d);    dFreq =  %9.2f Hz\n', pss_i-1, the_idx, A(the_idx), TH_Responses(the_idx), dFreq );
            
            Positions   = [Positions;   the_idx];
            PSS_IDs     = [PSS_IDs;     (pss_i-1)]; 
            Amps        = [Amps;        A(the_idx)]; 
            Thresholds  = [Thresholds;  TH_Responses(the_idx) ]; 
            dFreqs      = [dFreqs;      dFreq]; 
            
            Responses(pss_i, :) = A;
        end
        Responses(4, :) = TH_Responses;

    end


end