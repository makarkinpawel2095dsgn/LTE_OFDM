function [Amp, Phase] = CORDIC_abs2(DI, iterations)
% Integer angle and amplitude computing by CORDIC algorithm 

    
    ABQ = 4;    % Количество дополнительных бит (дробной части)
    
    CIQ = 18;   % Количество итераций выходной коррекции
    %CIQ = 16;   % Количество итераций выходной коррекции
    
    % Коэффициент коррекции CORDIC
    C = round( (2.^CIQ) / prod( (1 + 2.^(2*(1-(1:iterations)))).^0.5 ) );

    % Расширение разрядности за счёт добавочных бит
    X = real(DI) .* (2.^ABQ);
    Y = imag(DI)  * (2.^ABQ);
    
    % 0-я итерация
    % Перевод из 2 и 3 четвертей в 4 и 1 соответственно
    Phase = 0 + pi .* (X < 0);
    CA = find(X < 0);
    X(CA) = -X(CA);
    Y(CA) = -Y(CA);

    % Основной цикл CORDIC
    for k = 1:iterations
        At = 2.^(1-k);
        s = 1-2.*(Y>=0);
        X_addon = -s .* floor( Y.* At);
        Y_addon =  s .* floor( X.* At);
        
        X_new = X + X_addon;
        Y_new = Y + Y_addon;
        
        Phase = Phase - s.*atan(At);
        
        X = X_new;
        Y = Y_new;
    end

    BC = de2bi(C, CIQ, 'left-msb');
    
    Y = X;
    X = 0;
    
    for k = 1:CIQ
        At = 2.^(1-k);
        X_addon = + floor( Y .* At .* BC(k) );
        X = X + X_addon;
    end
    Amp = round_simple( X/(2.^(ABQ+1)) );

end

% $HeadURL: https://qak/svn/SymLab/models/LTE_PSS_SSS_withAddr/CORDIC_abs2.m $
% $Author: korolev $
% $Date:: 2023-03-13 14:45#$
% $Rev: 53 $