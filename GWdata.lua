do
  function GetTimeOfMinVal(Value)
    local val = Value
    local minVal = val % 60
    val = val / 60
    local hour = val % 24
    val = val / 24
    local day = val % 32
    val = val / 32
    local month = val % 12 + 1
    local year = val / 12    
    return string.format("%04d-%02d-%02d %02d:%02d",year,month,day,hour,minVal)
  end
end
do
  runinfo_proto = Proto("runinfo","RUNINFO","RunInfo Protocol")
  function runinfo_proto.dissector(buffer,pinfo,tree)
    pinfo.cols.info = "GWData run info"
    local t = tree:add(runinfo_proto,buffer(),"Run Info Protocol Data")
  end
end

--雨量分钟数据
do
  raindata_proto = Proto("raindata","RAINDATA","Rain Data Protocol")
  local f_ctype = ProtoField.uint8("RAINDATA.ctype","CType",base.DEC,{ [0] = "sample",[1] = "compress"})
  raindata_proto.fields = {f_ctype}
  function raindata_proto.dissector(buffer,pinfo,tree)
    local str_minutes = string.format("%d",buffer(2,2):le_uint())   --分钟数
    local str_time = GetTimeOfMinVal(buffer(4,4):le_uint())         --时间
    pinfo.cols.protocol = "RAIN DATA"
    pinfo.cols.info = "Time: "..str_time .. " Minutes: " .. str_minutes
                --local buf_len = buffer:len();
    local t = tree:add(raindata_proto,buffer(),"Rain Data Protocol Data")
    t:add(f_ctype,buffer(0,1))
    t:add(buffer(1,1),"Res: " .. string.format("0x%02X",buffer(1,1):uint()))
    t:add(buffer(2,2),"Minutes: " .. str_minutes)
    t:add(buffer(4,4),"Time: ".. str_time)
    t:add(buffer(8),"Data: ")
  end
end
do
    -- declare our protocol
    gwdata_proto = Proto("gwdata","GWDATA","GWDATA Protocol")
    local f_datatype = ProtoField.uint8("GWDATA.datatype","DataType",base.HEX,{ [0x02] = "run info",[0x12] = "rain data",  [3] = "gprs"})
    local f_trantype = ProtoField.uint8("GWDATA.trantype","TranType",base.HEX,{ [1] = "net", [2] = "modem", [3] = "gprs"})
    gwdata_proto.fields = {f_datatype,f_trantype}
    local protos ={
      [0x02] = Dissector.get("runinfo"),
      [0x12] = Dissector.get("raindata"),
    }
    -- create a function to dissect it
    function gwdata_proto.dissector(buffer,pinfo,tree)
        pinfo.cols.protocol = "GWDATA"
        if (buffer(0,1):uint()~=255) then
          return false
        end
        local subtree = tree:add(gwdata_proto,buffer(),"GWData Protocol Data")
        subtree:add(buffer(0,1),"Sym: " .. string.format("0x%02X",buffer(0,1):uint()))
        subtree:add(buffer(1,1),"Length: " .. buffer(1,1):uint())
        subtree:add(f_datatype,buffer(2,1))
        subtree:add(f_trantype,buffer(3,1))
        subtree:add(buffer(4,2),"Addr: " .. buffer(4,2):le_uint())
        
        local data_len = buffer(1,1):uint()
        local proto_id = buffer(2,1):uint()
        local dissector = protos[proto_id]
        if dissector ~= nil then
          dissector:call(buffer(6,data_len):tvb(),pinfo,tree)
        end
      return true
    end
end             
