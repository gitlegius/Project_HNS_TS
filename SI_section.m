function SI_section(MAC_payload,table_id)
% ---------------------------
if isequal(table_id,[0 0 0 0 0 0 0 0]) % PAT
    len_MAC_Payload = length(MAC_payload)-(32+32);
    for k = 0:32:len_MAC_Payload
        program_number = bi2de(MAC_payload(1+k:16+k),'left-msb');
        Reserved_5 = MAC_payload(17+k:19+k);
        program_map_PID = bi2de(MAC_payload(20+k:32+k),'left-msb'); % PMT PID
        disp(['program_number ' int2str(program_number) ' program_map_PID ' int2str(program_map_PID)]);
    end
elseif isequal(table_id,[0 0 0 0 0 0 1 0]) % PMT
    Reserved_6 = MAC_payload(1:3);
    PCR_PID = MAC_payload(4:16);
    Reserved_7 = MAC_payload(17:20);
    program_info_length = bi2de(MAC_payload(21:32),'left-msb')*8; % This is a 12-bit field, the first two bits of which shall be '00'. The remaining 10 bits specify the number of bytes of the descriptors immediately following the program_info_length field.
    
    % ---------descriptor_1------------------
    descriptor_PMT_1 = MAC_payload(33:32+program_info_length);
    descriptor_tag_PMT_1 = descriptor_PMT_1(1:8);  % 0x48 - service_descriptor;
    descriptor_length_PMT_1 = bi2de(descriptor_PMT_1(9:16),'left-msb')*8;
    if isequal(descriptor_tag_PMT_1,[0 1 0 0 1 0 0 0])
        % ------------0x48-----------------------
        service_type = descriptor_PMT_1(17:24);
        service_provider_name_length = bi2de(descriptor_PMT_1(25:32),'left-msb')*8;
        
        disp(['service_provider_name - ' char(sum(bsxfun(@times, reshape(descriptor_PMT_1(33:32+service_provider_name_length),8,[]), 2.^(7:-1:0).')))])
        
        service_name_length = bi2de(descriptor_PMT_1(33+service_provider_name_length:40+service_provider_name_length),'left-msb')*8;
        
        disp(['service_name - ' char(sum(bsxfun(@times, reshape(descriptor_PMT_1(41+service_provider_name_length:40+service_provider_name_length+service_name_length),8,[]), 2.^(7:-1:0).')))]);
        
        %----------------------------------------
    end
    %----------------------------------------
    
    stream_type = MAC_payload(33+program_info_length:40+program_info_length); % 0x6 PES packets containing private data
    Reserved_8 = MAC_payload(41+program_info_length:43+program_info_length);
    elementary_PID = bi2de(MAC_payload(44+program_info_length:56+program_info_length),'left-msb');
    
    if isequal(stream_type,[0 0 0 0 0 1 1 0])
        stream_type_str = ' stream_type - PES packets containing private data';
    else
        stream_type_str = ' stream_type - UNDEFINED';
    end
    disp(['PID: ' int2str(elementary_PID) stream_type_str]);
    
    Reserved_9 = MAC_payload(57+program_info_length:60+program_info_length);
    ES_info_length = bi2de(MAC_payload(61+program_info_length:72+program_info_length),'left-msb')*8;
    
    %-----------descriptor_2------------------
    descriptor_PMT_2 = MAC_payload(73+program_info_length:72+program_info_length+ES_info_length);
    descriptor_tag_PMT_2 =  descriptor_PMT_2(1:8); % 0x52 - stream_identifier_descriptor
    descriptor_length_PMT_2 = bi2de(descriptor_PMT_2(9:16),'left-msb')*8;
    
    if isequal(descriptor_tag_PMT_2,[0 1 0 1 0 0 1 0]) % stream_identifier_descriptor
        for kkk = 0:8:descriptor_length_PMT_2-8
            component_tag = bi2de(descriptor_PMT_2(17+kkk:24+kkk),'left-msb');
        end
    end
    %-----------------------------------------
    
end