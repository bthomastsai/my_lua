do
	local mydocsis = Proto("US_FPGA_Header","US FPGA DOCSIS HEADER")
    --local f_ds_type = ProtoField.uint8("Fpga.ds_type","DS_Priority", base.Hex, { [2] = "NORMAL", [3] = "Invalid", [1] = "LOW", [4] = "HIGH" } )
    --local f_ds_ch = ProtoField.uint8("Fpga.ds_channel","DS_Channel", base.DEC)
    --local f_reserved = ProtoField.uint16("Fpga.reserved","reserved", base.HEX);
    --local f_framelen = ProtoField.uint16("Fpga.framelen","FrameLen", base.DEC)
	--mydocsis.fields = { f_ds_type , f_ds_ch, f_reserved, f_framelen}
	
	local function ranging_header(buf,pkt,root)
		local buf_len = buf:len();
		if buf_len < 6 then return false end
		--local i_operator = v_operator:uint()
        local v_header = buf(0,1)
        local v_type = v_header:uint()
        if ( (v_type==0xC8) ) then
		    local t = root:add(mydocsis,buf)
		    return true
        else 
            return false 
        end
	end

	function mydocsis.dissector(buf,pkt,root) 
		if ranging_header(buf,pkt,root) then
			--valid ds fpga diagram
            local data_dis = Dissector.get("docsis")
			data_dis:call(buf(128):tvb(),pkt,root)
        else
            local data_dis2 = Dissector.get("docsis")
            data_dis2:call(buf(16):tvb(),pkt,root)
		end
	end
	
	local wtap_encap_table = DissectorTable.get("wtap_encap")
	wtap_encap_table:add(wtap.DOCSIS,mydocsis)
end
