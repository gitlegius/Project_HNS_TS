clear
fclose all;

%% ------------------file open-----------------------------------
% fid = fopen('D:\HNS\Yml402_Ku1V_11225_DVB_30Ms_7(3)_24(2)_10000_3050_30s.ts','rb');
% fid = fopen('D:\HNS\Yml402_Ku1V_11225_30Ms_v1.ts','rb');
% fid = fopen('D:\HNS\Turk_1.ts');
fid = fopen('xxx_11606.ts','rb');
if fid == -1
    error('File is not opened');
end
fseek(fid,0,'eof'); filesize = ftell(fid); fseek(fid,0,'bof');
k_read = 0;%36651061 %16598041 - 17939045
find_start_mpeg = 0;
fseek(fid, k_read, 'bof');
% ---------------------------------------------------------------
%% -------------------Initialization parameters------------------
TABLES_ON = 0; % PSI tables decoding: 1 - turn on, 0 - turn off

MAC_PDU_sections_buff = zeros(1,1024*32);
Datagram_fragments_buff = zeros(1,1024*32); % MAX length of IP packet 1500 byte
PSI_section = 0;
FullDatagram = 1;

arr_continuity_counter_dec = zeros(1,1024*32);
arr_new_PID = zeros(1,8191);
m = uint32(0);

% -----------------CRC8 for MPEG packets------------------------
% pol_8 = [1 1 1 0 1 0 1 0 1];
% ------------------CRC32 for MAC PDU---------------------------
pol_32 = zeros(1,33);
ind_pol_2 = abs([33 27 24 23 17 13 12 11 9 8 6 5 3 2 1]-34);
pol_32(ind_pol_2) = 1;
pol_32 = pol_32(end:-1:1);
CRC32_res = ones(1,32);
%---------------------------------------------------------------

PlFrameId_lost = -1;
PlFrameId_last = 0;

for l = 0:5
    l_str = int2str(l);
    for ll = 0:15
        ll_str = int2str(ll);
        eval(['Identification_last_40' l_str  '_' ll_str ' =  -1;']);
        eval(['Frame_number_last_40' l_str '_' ll_str ' =  -1;']);
        eval(['BAP_failed_40' l_str '_' ll_str ' =  -1;']);
    end
end
% PID_dec_all = zeros(1,20);
% Group_number_all = zeros(1,20);
% ind_pid = 0;
% ind_group = 0;

BAD_CRC_MAC_PDU = 0;

%% --------------test_data_processing parameters for time analizing-----------------
part_percent = 100/filesize;
percent_period = 1; % (update period in %)
next_percent = percent_period;
start_time = 0;
time_elapsed = 0;
time_left_last = 0;
%% --------------------------------------------------------------

while k_read < filesize %~feof(fid)
    %% -------------------file read------------------
    [packet,packet_with_UW,k_read] = read_ts(fid,find_start_mpeg);
    %%
    if ~isequal(packet_with_UW(1:8),[0 1 0 0 0 1 1 1])% 0x47
        disp('MPEG sync_byte not found!!!!!');
        k_read = ftell(fid);
        find_start_mpeg = 0;
    else
        if ~find_start_mpeg
            packet = fread(fid,1496,'ubit1')';
            k_read = ftell(fid);
            B = reshape(packet,8,187);
            B = B(end:-1:1,:);
            packet = reshape(B,1,1496);
            find_start_mpeg = 1;
            filesize = filesize - mod((filesize - k_read),188);
        end
        %% -----------------TS processing---------------
        transport_error_indicator = packet(1);
        if transport_error_indicator == 0
            payload_unit_start_indicator = packet(2);
            transport_priority = packet(3);
            PID = packet(4:16);
            transport_scrambling_control = packet(17:18);
            adaptation_field_control = packet(19:20);
            continuity_counter = packet(21:24);
            
            if isequal(adaptation_field_control,[0 1]) % ismember(PID_dec,[0 16 41 42 43 44]) % No adaptation_field, payload only
                PSI_section = 1;
                end_of_UP_header = 33;
                len_header_MAC_PDU = 64;
            elseif isequal(adaptation_field_control,[1 0]) % Adaptation_field only, no payload
                keyboard;
            elseif isequal(adaptation_field_control,[1 1]) % Adaptation_field followed by payload
                PSI_section = 0;
                end_of_UP_header = 57;
                len_header_MAC_PDU = 96;
            elseif isequal(adaptation_field_control,[0 0]) % Reserved
                keyboard;
            end
            if ~isequal(PID,[1 1 1 1 1 1 1 1 1 1 1 1 1]) % reserved
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PID_dec = BinToDec_mex(logical(PID),false);
                
                PID_dec_str = int2str(PID_dec);
                arr_continuity_counter_dec_str = ['arr_continuity_counter_dec_' PID_dec_str];
                MAC_PDU_sections_buff_str = ['MAC_PDU_sections_buff_' PID_dec_str];
                start_MAC_PDU_str = ['start_MAC_PDU_' PID_dec_str];
                len_sections_MAC_PDU_str = ['len_sections_MAC_PDU_' PID_dec_str];
                Datagram_fragments_buff_str = ['Datagram_fragments_buff_' PID_dec_str];
                len_DatagramBytes_str = ['len_DatagramBytes_' PID_dec_str];
                start_fragment_str = ['start_fragment_' PID_dec_str];
                
                if ~ismember2_mex(uint32(PID_dec),uint32(arr_new_PID(1:m)),m)
                    m = m + 1;
                    arr_new_PID(m) = PID_dec;
                    eval([start_MAC_PDU_str ' = 0;']);
                    eval([MAC_PDU_sections_buff_str ' = MAC_PDU_sections_buff;']);
                    eval([arr_continuity_counter_dec_str '= arr_continuity_counter_dec;']);
                    eval([Datagram_fragments_buff_str ' = Datagram_fragments_buff;']);
                    eval([start_fragment_str ' = 0;']);
                    eval([len_DatagramBytes_str ' = 0;']);
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 continuity_counter_dec = BinToDec_mex(logical(continuity_counter),false);
                %                 eval([arr_continuity_counter_dec_str ' = [' arr_continuity_counter_dec_str '(2:end) continuity_counter_dec];']);
                
                %% MAC PDU
                if payload_unit_start_indicator
                    
                    if PSI_section == 1
                        Pointer = BinToDec_mex(logical(packet(25:32)),false)*8;
                    else
                        adaptation_field_length = packet(25:32);
                        adaptation_flags = packet(33:40);
                        adaptation_stuff_bytes = packet(41:48);
                        Pointer = BinToDec_mex(logical(packet(49:56)),false)*8;
                    end
                    
                    if eval([start_MAC_PDU_str ' == 1;']);
                        
                        eval([len_sections_MAC_PDU_str ' = ' len_sections_MAC_PDU_str ' + Pointer;']);
                        eval([MAC_PDU_sections_buff_str ' = [' MAC_PDU_sections_buff_str '(Pointer + 1:end) packet(end_of_UP_header:end_of_UP_header+Pointer-1)];']);
                        
                        MAC_PDU_with_FF_0 = eval(['[' MAC_PDU_sections_buff_str '(end-' len_sections_MAC_PDU_str '+1:end)];']);
                        
                        % ----------MAC_SI_header1--------------
                        table_id_0 = MAC_PDU_with_FF_0(1:8); % 0x3E - IPoS MAC; 0x00 - PAT and 0x02 - PMT for PSI section
                        section_syntax_indicator_0 = MAC_PDU_with_FF_0(9);
                        private_indicator_0 = MAC_PDU_with_FF_0(10);
                        Reserved_1_0 = MAC_PDU_with_FF_0(11:12);
                        section_length_0 = BinToDec_mex(logical(MAC_PDU_with_FF_0(13:24)),false)*8+24;
                        % ------------------------------------
                        eval(['len_MAC_PDU_with_FF = ' len_sections_MAC_PDU_str ';']);
                        if len_MAC_PDU_with_FF < section_length_0
                            disp('UP is lost!!!  MAC_PDU_0 without all sections!!! -> CRC MAC PDU_0 BAD!!!!');
                        else
                            
                            MAC_PDU_0 = MAC_PDU_with_FF_0(1:section_length_0); % MAC_PDU with header and CRC32 inclusive
                            r_0 = pol_div2_mex(logical(MAC_PDU_0(end:-1:1)),logical(pol_32)); % CRC32
                            n = 0;
                            
                            MAC_PDU_with_FF_1 = MAC_PDU_with_FF_0(section_length_0+1:end);
                            
                            if (len_MAC_PDU_with_FF-24) > section_length_0 && isequal(MAC_PDU_with_FF_1(1:8),[0 0 1 1 1 1 1 0]) %0x3E
                                
                                table_id_1 = [0 0 1 1 1 1 1 0];
                                section_syntax_indicator_1 = MAC_PDU_with_FF_1(9);
                                private_indicator_1 = MAC_PDU_with_FF_1(10);
                                Reserved_1_1 =  MAC_PDU_with_FF_1(11:12);
                                section_length_1 = BinToDec_mex(logical(MAC_PDU_with_FF_1(13:24)),false)*8+24;
                                
                                if (len_MAC_PDU_with_FF - section_length_0) < section_length_1
                                    disp('UP is lost!!!  MAC_PDU_1 without all sections!!! -> CRC MAC PDU_1 BAD!!!!');
                                    n = 0;
                                else
                                    MAC_PDU_1 = MAC_PDU_with_FF_1(1:section_length_1);
                                    r_1 = pol_div2_mex(logical(MAC_PDU_1(end:-1:1)),logical(pol_32)); % CRC32
                                    n = 1;
                                end
                            end
                            
                            for nn = 0:n
                                nn_str = int2str(nn);
                                eval(['MAC_PDU = ' 'MAC_PDU_' nn_str ';']);
                                
                                if eval(['isequal(r_' nn_str ',CRC32_res)'])
                                    %                                 disp('MAC_PDU CRC OK')
                                    if PSI_section == 0
                                        %% ----------MAC_header2--------------
                                        MAC_address_6 = MAC_PDU(25:32);
                                        MAC_address_5 = MAC_PDU(33:40);
                                        Reserved_2 = MAC_PDU(41:42);
                                        payload_scrambling_control = MAC_PDU(43:44);  % 0 - unencrypted; 1 - not used; 2 or 3 - encrypted;
                                        address_scrambling_control = MAC_PDU(45:46);
                                        LLC_SNAP_flag = MAC_PDU(47);
                                        current_next_indicator = MAC_PDU(48);
                                        section_number = BinToDec_mex(logical(MAC_PDU(49:56)),false);
                                        % -------last_section_number--------
                                        last_section_number = MAC_PDU(57:64);
                                        % For DVB-S2 outroute supporting ACM
                                        ModcodRequested = last_section_number(1:5);
                                        FastBlock = last_section_number(6);
                                        Reserved_3 = last_section_number(7);
                                        MoreFragments = last_section_number(8); % 1 - The system supports multiple fragmentations
                                        %-----------------------------------
                                        MAC_address_4 = MAC_PDU(65:72);
                                        MAC_address_3 = MAC_PDU(73:80);
                                        MAC_address_2 = MAC_PDU(81:88);
                                        MAC_address_1 = MAC_PDU(89:96);
                                        
                                        MAC_address_all = [MAC_address_1 MAC_address_2 MAC_address_3 MAC_address_4 MAC_address_5 MAC_address_6];
                                        % ------------------------------------
                                        %% -------MAC_Payload-----------------
                                        MAC_payload = MAC_PDU(97:end-32);
                                        
                                        % ---------Format of Datagramm-----------
                                        if isequal(payload_scrambling_control,[1 0]) || isequal(payload_scrambling_control,[1 1]) % encrypted
                                            SequenceNumber = MAC_payload(1:8);
                                            if ~MoreFragments&&~section_number % not fragmented and encrypted
                                                InitializationVector = MAC_payload(9:64);
                                                DatagramBytes = MAC_payload(65:end);
                                                FullDatagram = 1;
                                            elseif MoreFragments||section_number % fragmented and encrypted
                                                InitializationVector = MAC_payload(9:48);
                                                FragmentationID = BinToDec_mex(logical(MAC_payload(49:64)),false);
                                                if ~FragmentationID
                                                    eval([start_fragment_str ' = 1;']);
                                                end
                                                DatagramBytes_fragment = MAC_payload(65:end);
                                            end
                                        elseif MoreFragments||section_number
                                            % fragmented and unencrypted
                                            Reserved_MAC_Payload = MAC_payload(1:48);
                                            FragmentationID = BinToDec_mex(logical(MAC_payload(49:64)),false);
                                            DatagramBytes_fragment = MAC_payload(65:end);
                                            if ~FragmentationID
                                                DatagramBytes = DatagramBytes_fragment;
                                                FullDatagram = 1;
                                            end
                                        elseif ~MoreFragments&&~section_number
                                            DatagramBytes = MAC_payload(1:end);
                                            FullDatagram = 1;
                                        end
                                        %----------------------------------------
                                        
                                        % -------Defragmentation of IP packet-----
                                        eval(['len_DatagramBytes = section_length_' int2str(nn) ' - 192;']); % 192 = MAC_header + CRC32 + Datagram_header
                                        
                                        if (~MoreFragments&&section_number)&&eval(start_fragment_str)&&FragmentationID
                                            eval(['DatagramBytes = [' Datagram_fragments_buff_str '(end - ' len_DatagramBytes_str ' + 1:end) DatagramBytes_fragment];']);
                                            FullDatagram = 1;
                                            eval([len_DatagramBytes_str ' = 0;']);
                                            eval([start_fragment_str ' = 0;']);
                                            
                                        elseif MoreFragments
                                            eval([len_DatagramBytes_str ' = ' len_DatagramBytes_str ' + len_DatagramBytes;']);
                                            eval([Datagram_fragments_buff_str ' = [' Datagram_fragments_buff_str '(len_DatagramBytes+1:end) DatagramBytes_fragment];']);
                                            if ~section_number
                                                eval([start_fragment_str ' = 1;']);
                                            end
                                            FullDatagram = 0;
                                        end
                                        % -----------------------------------------
                                        
                                        if FullDatagram % Full IP packet
                                            
                                            if ismember2_mex(uint32(PID_dec),uint32([400,401,402]),uint32(3)) %%%%%%%%%%%%%%%%%
                                                %                                         IP_packet_header = struct('Version',BinToDec_mex(logical(DatagramBytes(1:4)),false),'HdrLen',BinToDec_mex(logical(DatagramBytes(5:8)),false)*32,'TOS',DatagramBytes(9:16),'TotalLength',BinToDec_mex(logical(DatagramBytes(17:32)),false),'Identification',BinToDec_mex(logical(DatagramBytes(33:48)),false),'Flags',DatagramBytes(49:51),'FragmentOffset',DatagramBytes(52:64),'TimeToLive',DatagramBytes(65:72),'Protocol',DatagramBytes(73:80),'HeaderChecksum',DatagramBytes(81:96),'SourceIPAddress',DatagramBytes(97:128),'DestinationIPAddress',DatagramBytes(129:160),'Options',DatagramBytes(161:192));
                                                [Version,HdrLen,TOS,TotalLength,Identification,Flags,FragmentOffset,TimeToLive,Protocol,HeaderChecksum,SourceIPAddress,DestinationIPAddress,Options] = IP_packet_header(DatagramBytes);
                                                if Version~=4
                                                    keyboard;
                                                end
                                            end
                                            
                                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                            if isequal(MAC_address_all(1:16),[0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0]) % 0x0300 IPoS Return Broadcast
                                                
                                                DataOfDatagram = DatagramBytes(225:end); % start 28*8+1
                                                Frame_type = DataOfDatagram(1:8);
                                                
                                                if isequal(Frame_type,[0 0 0 0 0 0 1 0]) % 2 - IGDP ?????????????? -> not full tested
                                                    Inroute_group_ID = BinToDec_mex(logical(DataOfDatagram(9:15)),false); % +7
                                                    Frequency_offset = DataOfDatagram(16:20);% +5
                                                    Return_channel_type = DataOfDatagram(21:24);% +4
                                                    Has_serial_number_range = DataOfDatagram(25);% +1
                                                    Sequence_number_for_RLL_traffic = DataOfDatagram(26);% +1
                                                    Aloha_CRC = DataOfDatagram(27);% +1
                                                    InrouteOutroute_overlay = DataOfDatagram(28);% +1
                                                    Reserved_10 = DataOfDatagram(29:32);% +4
                                                    Ranging_metric_LDPC = DataOfDatagram(33:40);% +8
                                                    Ranging_backoff = DataOfDatagram(41:44);% +4
                                                    Ranging_retries = DataOfDatagram(45:48);% +4
                                                    
                                                    Ranging_max_backoff = DataOfDatagram(49:64);% +16
                                                    BandwidthAloha_metric_LDPC = DataOfDatagram(65:80);% +16
                                                    Small_Aloha_backoff = DataOfDatagram(81:84);% +4
                                                    Small_Aloha_retries = DataOfDatagram(85:88);% +4
                                                    OverheadSlotsForNormalAperture = DataOfDatagram(89:92);% +4
                                                    OverheadSlotsForReducedNormalAperture = DataOfDatagram(93:96);% +4
                                                    Aloha_max_backoff = DataOfDatagram(97:112);% +16
                                                    Eb_No_switchup = BinToDec_mex(logical(DataOfDatagram(113:120)),false)*0.1*2;% +8 (SNR in db)
                                                    
                                                    Eb_No_target = BinToDec_mex(logical(DataOfDatagram(120:128)),false)*0.1*2;% +8 (SNR in db)
                                                    Eb_No_min  = BinToDec_mex(logical(DataOfDatagram(129:136)),false)*0.1*2;% +8 (SNR in db)
                                                    Frequency_band = DataOfDatagram(137:140);% +4 (0 - Ku, 1 - Ka, 2 - C, 3 - custom)
                                                    Reserved_11 = DataOfDatagram(141:144);% +4
                                                    Reserved_12 = DataOfDatagram(145:160);% +16
                                                    Rain_fade_rate_backoff = DataOfDatagram(161:176);% +16
                                                    Symbol_rate = BinToDec_mex(logical(DataOfDatagram(177:192)),false)*100;% +16 (symbol rate in Hz)
                                                    
                                                    FEC_type = DataOfDatagram(193:196);% +4 (0 – No FEC specified, 1- R1/3, 2 – R1/2, 3 – R2/3, 4 – R4/5)
                                                    Adaptation_CRC  = DataOfDatagram(197:200);% +4
                                                    ClosedLoopTiming = DataOfDatagram(201);% +1
                                                    ClosedLoopPower = DataOfDatagram(202);% +1
                                                    AdaptiveCoding = DataOfDatagram(203);% +1
                                                    Ranging_aperture_size = DataOfDatagram(204:211);% +8
                                                    RangingPayloadSize = DataOfDatagram(212:215);% +4
                                                    ESS_Encryption = DataOfDatagram(216);% +1
                                                    ESS_OutrouteAuthentication = DataOfDatagram(217);% +1
                                                    ESS_InrouteAuthentication = DataOfDatagram(218);% +1
                                                    Reserved_13 = DataOfDatagram(219);% +1
                                                    Mesh_support = DataOfDatagram(220:222);% +3
                                                    SpreadingFactor = DataOfDatagram(223:227);% +5
                                                    ESS_KeySetVersion = DataOfDatagram(228:243);% +16
                                                    BaseFrequency = DataOfDatagram(244:275);% +32
                                                    Reserved_14 = DataOfDatagram(276:283);% +8
                                                    %                                                     ParkFrequency = DataOfDatagram(284:307);% +24
                                                    %                                                     EncodingType = DataOfDatagram(308:311);% +4
                                                    %                                                     IGDPMessageVersion = DataOfDatagram(312:315);% +4
                                                    %                                                     Ranging_MetricForLDPC = DataOfDatagram(316:323);% +8
                                                    %                                                     Bandwidth_MetricForLDPC = DataOfDatagram(324:339);% +16
                                                    %                                                     Reserved_15 = DataOfDatagram(340:345);% +6
                                                    %                                                     Serial_number_starts = DataOfDatagram(346:371);% +26
                                                    %                                                     Reserved_16 = DataOfDatagram(372:377);% +6
                                                    %                                                     Serial_number_ends = DataOfDatagram(378:403);% +16
                                                    %                                         for
                                                    %                                             Frequency_table =
                                                    %                                         end
                                                    %                                         ESSAuthCode
                                                    %                                         end
                                                    
                                                elseif isequal(Frame_type,[0 0 0 0 0 0 1 1]) % 3 - BAP
                                                    
                                                    Group_number = BinToDec_mex(logical(MAC_address_all(end-15:end)),false);
                                                    
                                                    if ~Group_number % ??????????
                                                        %                                                         Group_number = 1;
                                                        keyboard;
                                                    end
                                                    
                                                    Group_number_str = int2str(Group_number);
                                                    
                                                    Frame_number = BinToDec_mex(logical(DataOfDatagram(9:24)),false);
                                                    len_Burst_allocation_record = (length(DataOfDatagram(25:end))-mod(length(DataOfDatagram(25:end)),24));
                                                    Burst_allocation_record = DataOfDatagram(25:len_Burst_allocation_record + 24);
                                                    len_Burst_allocation_record = len_Burst_allocation_record - 24;
                                                    
                                                    diff_Identification_str = ['diff_Identification_' PID_dec_str '_' Group_number_str];
                                                    Identification_str = ['Identification_' PID_dec_str '_' Group_number_str];
                                                    Identification_last_str = ['Identification_last_' PID_dec_str '_' Group_number_str];
                                                    diff_Frame_number_str = ['diff_Frame_number_' PID_dec_str '_' Group_number_str];
                                                    Frame_number_last_str = ['Frame_number_last_' PID_dec_str '_' Group_number_str];
                                                    Frame_number_str = ['Frame_number_' PID_dec_str '_' Group_number_str];
                                                    BAP_failed_str = ['BAP_failed_' PID_dec_str '_' Group_number_str];
                                                    
                                                    %                                                     flag_pid_memb = ~ismember2_mex(uint32(PID_dec),uint32(PID_dec_all),uint32(ind_pid));
                                                    %                                                     flag_group_memb = ~ismember2_mex(uint32(Group_number),uint32(Group_number_all),uint32(ind_group));
                                                    %                                                     if flag_pid_memb && flag_group_memb
                                                    %                                                         eval([BAP_failed_str ' = -1;'])
                                                    %                                                         PID_dec_all(ind_pid) = PID_dec;
                                                    %                                                         Group_number_all(ind_group) = Group_number;
                                                    %                                                         ind_group = ind_group + 1;
                                                    %                                                     end
                                                    
                                                    eval([Frame_number_str ' = Frame_number;']);
                                                    eval([Identification_str ' = Identification;']);
                                                    
                                                    eval([diff_Identification_str ' = ' Identification_str ' - ' Identification_last_str ';']);
                                                    if eval([Identification_str '~=' Frame_number_str]);
                                                        eval(diff_Identification_str);
                                                        keyboard;
                                                    end
                                                    
                                                    eval([diff_Frame_number_str ' = ' Frame_number_str ' - ' Frame_number_last_str ';']);
                                                    if eval([diff_Frame_number_str ' > 1'])
                                                        if eval([BAP_failed_str ' == - 1;']);
                                                            eval([BAP_failed_str ' = ' BAP_failed_str ' + 1;']);
                                                        else
                                                            eval([BAP_failed_str ' = ' BAP_failed_str ' + ' diff_Frame_number_str '-1;']);
                                                            disp([BAP_failed_str ' = ' int2str(eval(BAP_failed_str))]);
                                                        end
                                                    end
                                                    
                                                    %                                                     if eval([Identification_str ' - ' Identification_last_str ' > 1'])
                                                    %                                                         lost = lost + 1;
                                                    %                                                     end
                                                    
                                                    eval([Frame_number_last_str ' = ' Frame_number_str ';']);
                                                    eval([Identification_last_str ' = ' Identification_str ';']);
                                                    
                                                    % ------------------Burst_allocation_record-----------------
%                                                     disp('|-------------------start of BAP-----------------------|');
%                                                     disp(['PID_dec = ' PID_dec_str '; Group number = ' Group_number_str]);
%                                                     disp(['Frame number = ' int2str(Frame_number)]);
%                                                     
%                                                     Burst_all = 0;
%                                                     num_channel = 0;
%                                                     for kkkk = 0:24:len_Burst_allocation_record
%                                                         AssignID = binaryVectorToHex(Burst_allocation_record(kkkk+1:kkkk+16),'MSBFirst'); % Star: 1 – 32767; Mesh: 32768 – 65534;
%                                                         Ranging = Burst_allocation_record(kkkk+17);
%                                                         Final_burst = Burst_allocation_record(kkkk+18);
%                                                         Burst_size = BinToDec_mex(logical(Burst_allocation_record(kkkk+19:kkkk+24)),false);
%                                                         if ~isequal(Burst_allocation_record(kkkk+1:kkkk+24),[1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 1])
%                                                             Burst_all = Burst_size + Burst_all;
%                                                             disp(['AssignID: ' AssignID '  Ranging: ' int2str(Ranging) ' Final_burst: ' int2str(Final_burst) ' Burst_size: ' int2str(Burst_size)]);
%                                                         else
%                                                             num_channel = num_channel + 1;
%                                                             disp(['----------------frequency channel ' int2str(num_channel) '---------------------']);
%                                                         end
%                                                     end
%                                                     disp(['Burst_all = ' int2str(Burst_all)]);
%                                                     disp(['number of channels = ' int2str(num_channel)]);
%                                                     disp('|---------------------end of BAP-----------------------|');
                                                    %-----------------------------------------------------------
                                                elseif isequal(Frame_type,[0 0 0 0 0 1 0 0]) % 4 - IAP
%                                                     Frame_number = BinToDec_mex(logical(DataOfDatagram(9:24)),false);
%                                                     len_ACK = (length(DataOfDatagram(25:end))-mod(length(DataOfDatagram(25:end)),24));% ?????
%                                                     ACK = DataOfDatagram(25:len_ACK+24); % ?????????????
%                                                     len_ACK = len_ACK - 24;
%                                                     
%                                                     for kkkk = 0:24:len_ACK  % ????
%                                                         AssignID = binaryVectorToHex(ACK(kkkk+1:kkkk+16),'MSBFirst');
%                                                         Ranging = ACK(kkkk+17);
%                                                         Final_burst = ACK(kkkk+18);
%                                                         Burst_size = BinToDec_mex(logical(ACK(kkkk+19:kkkk+24)),false);
%                                                         disp(['AssignID: ' int2str(AssignID) '  Ranging: ' int2str(Ranging) ' Final_burst: ' int2str(Final_burst) ' Burst_size: ' int2str(Burst_size )]);
%                                                     end
                                                    
                                                end
                                                
                                            end
                                            FullDatagram = 0;
                                        end
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %
                                    else % SI section (tables)
                                        if TABLES_ON
                                            % -------SI_header2----------
                                            network_id = MAC_PDU(25:40);
                                            Reserved_4 = MAC_PDU(41:42);
                                            version_number = MAC_PDU(43:47);
                                            current_next_indicator = MAC_PDU(48);
                                            section_number = MAC_PDU(49:56);
                                            last_section_number = MAC_PDU(57:64);
                                            % ---------------------------
                                            %% MAC_Payload
                                            MAC_payload = MAC_PDU(65:end-32);
                                            % ------- Table --------
                                            SI_section(MAC_payload,table_id_0);
                                            % ----------------------
                                        end
                                    end
                                else
                                    BAD_CRC_MAC_PDU = BAD_CRC_MAC_PDU+1;
                                    disp('MAC_PDU CRC BAD')
                                end
                            end
                        end
                    end
                    
                    eval([start_MAC_PDU_str ' = 1;']);
                    eval([len_sections_MAC_PDU_str ' = 1497-(end_of_UP_header+Pointer);']);
                    eval([MAC_PDU_sections_buff_str ' = [' MAC_PDU_sections_buff_str '(' len_sections_MAC_PDU_str ' + 1:end) packet(end_of_UP_header + Pointer:end)];']);
                    
                elseif eval(['~ payload_unit_start_indicator && ' start_MAC_PDU_str])
                    eval([len_sections_MAC_PDU_str ' = ' len_sections_MAC_PDU_str ' + 1472;']);
                    eval([MAC_PDU_sections_buff_str ' = [' MAC_PDU_sections_buff_str '(1473:end) packet(25:end)];']);
                end
            end
            %%
        else
            disp('TRANSPORT PACKET ERROR!!!');
        end
        
    end
    %%
    [part_percent,next_percent,start_time,time_left_last,time_elapsed] = processing_data_test(part_percent,percent_period,next_percent,start_time,k_read,time_left_last,time_elapsed);
    %%
end

disp('Percent of data proccessing = 100 %');
disp(['time elapsed ~= ' num2str(time_elapsed/60) ' min']);

fclose all;