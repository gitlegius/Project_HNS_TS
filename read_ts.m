function [packet,packet_with_UW,k_read] = read_ts(fid,find_start_mpeg)
k_read = [];
packet = [];

if ~find_start_mpeg
    packet_with_UW = fread(fid,8,'ubit1')';
    packet_with_UW = packet_with_UW(8:-1:1);
else
    packet_with_UW = fread(fid,1504,'ubit1')';
    k_read = ftell(fid);
    B=reshape(packet_with_UW,8,188);
    B=B(8:-1:1,:);
    packet_with_UW=reshape(B,1,1504);
    packet = packet_with_UW(9:1504);
end