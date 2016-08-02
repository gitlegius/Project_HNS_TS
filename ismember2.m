function [out, ind_k] = ismember2(in_1,in_2,len)

out = false;
ind_k = uint32(0);
% len = length(in_1);
for k = 1:len
    if in_2(k) == in_1
        out = true;
        ind_k = k;
        return;
    end
end