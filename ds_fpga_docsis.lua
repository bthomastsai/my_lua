do
	local p_ds_docsis = Proto("Fpga_header","DS FPGA HEADER")
    local f_ds_type = ProtoField.uint8("Fpga.ds_type","DS_Priority", base.Hex, { [2] = "NORMAL", [3] = "Invalid", [1] = "LOW", [4] = "HIGH" } )
    local f_ds_ch = ProtoField.uint8("Fpga.ds_channel","DS_Channel", base.DEC)
    --local f_reserved = ProtoField.bytes("Fpga.reserved","reserved");
    local f_reserved = ProtoField.uint16("Fpga.reserved","reserved", base.HEX);
    local f_framelen = ProtoField.uint16("Fpga.framelen","FrameLen", base.DEC)
	p_ds_docsis.fields = { f_ds_type , f_ds_ch, f_reserved, f_framelen}
	
	local function p_docsis(buf,pkt,root)
		local buf_len = buf:len();
		if buf_len < 17 then return false end
		--local i_operator = v_operator:uint()
        local v_ds_fpga_type = buf(0,1)
        local i_fpga_type = v_ds_fpga_type:uint()
        if ( (i_fpga_type~=1) and (i_fpga_type~=2) and (i_fpga_type~=3) and (i_fpga_type~=4) )
            then return false end

        local v_ds_ch = buf(1,3)
		local v_rsvd = buf(4,2)
        local v_flen = buf(6,2)
		
		local t = root:add(p_ds_docsis,buf)
		--pkt.cols.protocol = "DOCSIS"
		t:add(f_ds_type,v_ds_fpga_type)
        t:add(f_ds_ch, v_ds_ch)
		t:add(f_reserved, v_rsvd)
        t:add(f_framelen, v_flen)
		
		return true
	end

    local function no_fpga_docsis(buf, pkt, root)
		local buf_len = buf:len();
		if buf_len < 6 then return false end
        local v_fc_param = buf(0,1)
        local v_fc_type_h = bit.rshift(v_fc_param:uint(), 4)
        local v_fs_type = v_fc_param:uint()
        if ( (v_fc_type_h==0xC) or (v_fc_type==1) ) then
		    local t = root:add(mydocsis,buf)
		    --pkt.cols.protocol = "DOCSIS"
		    return true
        else 
            return false 
        end
	end

	function p_ds_docsis.dissector(buf,pkt,root) 
		if p_docsis(buf,pkt,root) then
			--valid ds fpga diagram
            local data_dis = Dissector.get("docsis")
			data_dis:call(buf(8):tvb(),pkt,root)
		else if no_fpga_docsis(buf, pkt, root) then
            local data_dis2 = Dissector.get("docsis")
            data_dis2:call(buf, pkt, root)
        --    local data_dis2 = Dissector.get("data")
		--	  data_dis2:call(buf,pkt,root)
        	end
		end
	end
	
	local wtap_encap_table = DissectorTable.get("wtap_encap")
	wtap_encap_table:add(wtap.ETHERNET,p_ds_docsis)
end
