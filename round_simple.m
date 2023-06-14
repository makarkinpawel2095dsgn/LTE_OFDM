function R = round_simple(D)
% Simple round = round without correction.
% Королёв А.И. 2015.08
% Функция округления числа без коррекции. Допустимо использовать при
% количестве отбрасываемых разрядов = 1 или > 4..6 .
% D - массив данных. Может содержать действительные или комплексные значения.

    if isreal(D) 
        A = fix( mod(D, 1)*2);
        R = floor(D)+A;
    else
        % Для каждой составляющей отдельно (рекурсивно) выполняем округление
        R = complex(round_simple( real(D) ), round_simple( imag(D) ) );
    end

end