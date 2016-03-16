print("hello world!")
trivial_proto = Proto("trivial","Trivial Protocol")
function trivial_proto.dissector(buffer,pinfo,tree)
	print("HI!")
    pinfo.cols.protocol = "TRIVIAL"
    local subtree = tree:add(trivial_proto,buffer(),"Trivial Protocol Data")
    subtree:add(buffer(0,2),"The first two bytes: " .. buffer(0,2):uint())
    subtree = subtree:add(buffer(2,2),"The next bytes")
    ipdis=Dissector.get("ip")
    tvb=buffer(2)
    ipdis:call(tvb:tvb(),pinfo,tree)
end
udp_table = DissectorTable.get("ethertype")
udp_table:add(0x0801,trivial_proto)
