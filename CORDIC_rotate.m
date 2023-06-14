function [DO, rem_angle] = CORDIC_rotate(DI, angle, iterations)
% Complex sample rotate by CORDIC algorithm
    
%     angle = mod(angle, 2*pi); % Приводим угол к интервалу [0..2*pi)
    angle = rem(angle, 2*pi); % Приводим угол к интервалу [-pi..+pi)
    
    % 0-я итерация
    % Приведение к интервалу [-pi/2..+pi/2)
    if (angle >= pi/2) || (angle < -pi/2)
        angle = angle -sign(angle)*pi;
        DI = -DI;
    end
    
    C = 1;
    
    % Основной цикл CORDIC
    for k = 1:iterations
        s = 1-2*(angle<0);% sign(), рассматривающий 0 как "+"
        x = real(DI) - s*imag(DI)*(2.^(1-k));
        y = imag(DI) + s*real(DI)*(2.^(1-k));
        DI = complex(x, y);
        angle = angle - s*atan(2.^(1-k));
        C = C * ((1 + 2.^(2*(1-k))).^0.5);
    end
    DO = complex(x, y) / C;
    rem_angle = angle;
end

% $HeadURL: https://qak/svn/SymLab/models/LTE_PSS_SSS_Search_Quant_mat/CORDIC_rotate.m $
% $Author: korolev $
% $Date:: 2022-08-22 14:25#$
% $Rev: 27 $