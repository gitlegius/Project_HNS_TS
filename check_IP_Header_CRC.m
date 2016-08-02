function CRC = check_IP_Header_CRC( header_IP )

CRC = 0;

header_IP_ = reshape( header_IP , 16,10 )';
header_IP_dec = BinToDec(logical(header_IP_), false );
sum_header_IP_dec = de2bi(sum(header_IP_dec),32,'left-msb');

if  ( BinToDec(logical(sum_header_IP_dec(1:16)),false) + BinToDec(logical(sum_header_IP_dec(17:32)),false) ) == 65535
    CRC = 1;
end