do  
        local p_GZTP = Proto("GZTP","GZTP")
        local f_identifier = ProtoField.bytes("GZTP.identifier","Identifier")
        local f_frametype = ProtoField.uint8("GZTP.frametype","FrameType",base.HEX,{ [1] = "up-data", [129] = "resp-up", [2] = "request-data", [130] = "down-data"})
        local f_len = ProtoField.uint8("GZTP.length","Data Length",base.DEC)
        local f_address = ProtoField.uint16("GZTP.address","Address",base.HEX)
        local f_control = ProtoField.uint16("GZTP.Control","Control",base.HEX)
  local f_data = ProtoField.bytes("gztp.data","Data")
        p_GZTP.fields = { f_identifier, f_frametype, f_len,f_address,f_control,f_data}
        
        local data_dis = Dissector.get("data")
        local function GWData_dissector(buf,pkf,root)
                local buf_len = buf:len();
                if buf_len < 6 then return false end
    if(buf(0,1):uint()~=255) then
      return false
    end
                local t = root:add(buf(0,buf_len),"GWData")
    local f_sym = ProtoField.uint8("GWData.Sym","Sym",base.HEX)
    t:add(f_sym,buf(0,1))
    return true
  end
        local function GZTP_dissector(buf,pkt,root)
                local buf_len = buf:len();
                if buf_len < 8 then return false end
                local v_identifier = buf(0,2)
                if ((buf(0,1):uint()~=254) or (buf(1,1):uint()~=254))
                        then return false end
                local v_frametype = buf(2,1)
                local i_operator = v_frametype:uint()
                
    local v_len = buf(3,1)
    local v_address = buf(4,2)
    local v_control = buf(6,2)  --控制字
                local t = root:add(p_GZTP,buf(0,buf_len))
                pkt.cols.protocol = "GZTP"
                t:add(f_identifier,v_identifier)
                t:add(f_frametype,v_frametype)
                t:add(f_len,v_len)
                t:add(f_address,v_address)
                t:add(f_control,v_control)
    local i_len = v_len:uint()
    if i_len > 0 then
      local deal = false
      local dissector = Dissector.get("gwdata")
      if dissector ~= nil then
        local databuf = buf(8,i_len):tvb()
        if dissector:call(databuf,pkt,root) then
          deal = true
        end
      else
        t:add(buf(8,i_len),"Data:")
      end
                end
                return true
        end
        
        function p_GZTP.dissector(buf,pkt,root) 
                if GZTP_dissector(buf,pkt,root) then
                        --valid GZTP diagram
                else
                        data_dis:call(buf,pkt,root)
                end
        end
        
        local udp_encap_table = DissectorTable.get("udp.port")
        udp_encap_table:add(10110,p_GZTP)
end
   
