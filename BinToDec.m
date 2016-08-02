function out = BinToDec(A,flag)

len = length(A);

if ~flag
    out = A*(2.^(len-1:-1:0))';  % Most significant bit first
elseif flag == 1
    out = A*(2.^(0:len-1))';     % Least significant bit first
else
    error('second argument is not equal 1 or 0');
end