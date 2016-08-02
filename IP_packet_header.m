function [Version,HdrLen,TOS,TotalLength,Identification,Flags,FragmentOffset,TimeToLive,Protocol,HeaderChecksum,SourceIPAddress,DestinationIPAddress,Options] = IP_packet_header(DatagramBytes)

% -----------IP_header-------------
Version = bi2de(DatagramBytes(1:4),'left-msb');
HdrLen = bi2de(DatagramBytes(5:8),'left-msb')*32;
TOS = DatagramBytes(9:16);
TotalLength = bi2de(DatagramBytes(17:32),'left-msb');
Identification = bi2de(DatagramBytes(33:48),'left-msb');
Flags = DatagramBytes(49:51);
FragmentOffset = DatagramBytes(52:64);
TimeToLive = DatagramBytes(65:72);
Protocol = DatagramBytes(73:80);
HeaderChecksum = DatagramBytes(81:96);
SourceIPAddress = DatagramBytes(97:128);
DestinationIPAddress = DatagramBytes(129:160);
Options = DatagramBytes(161:192);

% CRC = check_IP_Header_CRC(DatagramBytes(1:160));
% --------------------------------