function [f01,f02,num_f0,arr_val_out_] = freq_offset_CnC2(in,Fs,M,Fd,FF,Ndfft)

if nargin==4
    Ndfft = 2^18;
    FF = abs(fft(in.^M, Ndfft));
elseif nargin == 2
    M = 4;
    Fd = Fs/22;
    Ndfft = 2^18;
    FF = abs(fft(in.^M, Ndfft));
end

arr_val_out_ = zeros(2,1);

Ndfft_2 = Ndfft/2;
Fs_Ndfft_M = Fs/Ndfft/M;

FF1 = [FF(Ndfft_2 + 1:Ndfft); FF(1:Ndfft_2)];

lim = Fd/M;
left = fix((Ndfft_2) - (lim / Fs_Ndfft_M));
right = fix((Ndfft_2) + (lim / Fs_Ndfft_M));
FF2 = FF1(left:right);
FF2 = FF2/max(FF2);

num_f0 = 0;
f02 = 0;
f01 = 0;

FF2_pow2 = FF2.^2;

len_FF2 = length(FF2);
ind_max = zeros(1,128);
arr_val_max = zeros(1,128);

FF2_pow2_prod_thr = 20*FF2_pow2;

len_win = 512;
FF2_pow2_prod_len_win = len_win * FF2_pow2;
j = 0;
jj = 0;
val_FF2_pow2_tmp = 0;
sum_buff_win = sum(FF2_pow2_prod_thr(1:len_win));
len_win_plus_1 = len_win + 1;
max_find = 0;

k_tmp = 0;

for k=len_win_plus_1:len_FF2
    
    jj = jj + 1;
    if FF2_pow2_prod_len_win(k)>sum_buff_win&&FF2_pow2_prod_len_win(k)>val_FF2_pow2_tmp     
        val_FF2_pow2_tmp = FF2_pow2_prod_len_win(k);
        max_find = 1;
        k_tmp = k;
        jj = 0;
        FF2_pow2_prod_thr(k) = 0;
        FF2_pow2_prod_thr(k+1) = 0;
%         FF2_pow2_prod_thr(k+2) = 0;
    end
    
    sum_buff_win = sum_buff_win-FF2_pow2_prod_thr(k-len_win)+FF2_pow2_prod_thr(k);
    if max_find == 1 && jj == 8
        jj = 0;
        j = j+1;
        max_find = 0;
        arr_val_max(j) = val_FF2_pow2_tmp;
        val_FF2_pow2_tmp = 0;
        ind_max(j) = k_tmp+left-1;
    end
end

f0_s = (ind_max(1:j)-Ndfft_2)*Fs_Ndfft_M;
arr_val_s = arr_val_max(1:j);

if j>=2
    iii = j;
    ind_del = 1:j;
    
    for ii = 1:j-1
        for jjj = ii:j-1
            
            jjj_plus_1 = jjj+1;
            diff_f0_s = abs((f0_s(ii) - f0_s(jjj_plus_1))*M);
            if abs(Fd - diff_f0_s)<100
                if abs(f0_s(ii))<abs(f0_s(jjj_plus_1))
                    iii = iii - 1;
                    ind_del(ii) = ii;
                    ind_del(ii+1) = ii+1;
                else
                    iii = iii - 1;
                    ind_del(ii) = jjj_plus_1;
                    ind_del(jjj_plus_1) = jjj_plus_1+1;
                end
            end
        end
    end
        num_f0 = iii;
        f0_s_out = f0_s(ind_del(1:iii));
        arr_val_out = arr_val_s(ind_del(1:iii));

    if num_f0 >= 2
        [~,ind] = max(arr_val_out);
        f01 = f0_s_out(ind);
        arr_val_out_(1) = arr_val_out(ind);
        
        arr_val_out(ind) = 0;
        [~,ind] = max(arr_val_out);
        arr_val_out_(2) = arr_val_out(ind);
        f02 = f0_s_out(ind);
    else
        f01 = f0_s_out(1);
    end
    
elseif j == 1
    num_f0 = j;
    f01 = f0_s(1);
end