do
	local p_iperf = Proto("iPerf","iperf data")
	local f_seq = ProtoField.uint32("iperf.seq_no","seq_no", base.Dec)
    local f_data = ProtoField.bytes("iperf.data","data");
--	local f_operator = ProtoField.uint8("iperf.operator","Operator",base.HEX,{ [0] = "get-value", [1] = "set-value", [128] = "resp-value", [16] = "get-color", [17] = "set-color", [144] = "resp-color"})
--	local f_left = ProtoField.uint32("iperf.left","Value Left",base.DEC)
--	local f_right = ProtoField.uint32("iperf.right","Value Right",base.DEC)
--	local f_red = ProtoField.uint8("iperf.red","Color Red",base.DEC)
--	local f_green = ProtoField.uint8("iperf.green","Color Green",base.DEC)
--	local f_blue = ProtoField.uint8("iperf.blue","Color Blue",base.DEC)
--	p_iperf.fields = { f_seq, f_operator, f_left, f_right, f_red, f_green, f_blue }
	p_iperf.fields = { f_seq , f_data}
	
	local data_dis = Dissector.get("data")
	
	local function iperf_dissector(buf,pkt,root)
		local buf_len = buf:len();
		if buf_len < 17 then return false end
		local v_identifier = buf(0,4)
		-- if ((buf(0,1):uint()~=226) or (buf(1,1):uint()~=203) or (buf(2,1):uint()~=181) or (buf(3,1):uint()~=128)
		--	or (buf(4,1):uint()~=203) or (buf(5,1):uint()~=9) or (buf(6,1):uint()~=78) or (buf(7,1):uint()~=186)
		--	or (buf(8,1):uint()~=163) or (buf(9,1):uint()~=107) or (buf(10,1):uint()~=246) or (buf(11,1):uint()~=7)
		--	or (buf(12,1):uint()~=206) or (buf(13,1):uint()~=149) or (buf(14,1):uint()~=63) or (buf(15,1):uint()~=43))
		--	then return false end
		local v_data = buf(4,buf_len-4)
		--local i_operator = v_operator:uint()
		
		local t = root:add(p_iperf,buf)
		pkt.cols.protocol = "iPerf"
		t:add(f_seq,v_identifier)
		t:add(f_data,v_data)
        pkt.cols.info = "Sequence no: "
        pkt.cols.info:append(v_identifier:uint())
		
		--if ((i_operator == 1) or (i_operator == 128)) and (buf_len >= 25) then
		--	t:add(f_left,buf(17,4))
		--	t:add(f_right,buf(21,4))
		--elseif ((i_operator == 17) or (i_operator == 144)) and (buf_len >= 20) then
		--	t:add(f_red,buf(17,1))
		--	t:add(f_green,buf(18,1))
		--	t:add(f_blue,buf(19,1))
		--end
		return true
	end
	
	function p_iperf.dissector(buf,pkt,root) 
		if iperf_dissector(buf,pkt,root) then
			--valid iperf diagram
		else
			data_dis:call(buf,pkt,root)
		end
	end
	
	local udp_encap_table = DissectorTable.get("udp.port")
	udp_encap_table:add(5001,p_iperf)
end
