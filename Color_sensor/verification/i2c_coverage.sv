`ifndef I2C_COVERAGE_SV
`define I2C_COVERAGE_SV

   `include "i2c_defines.sv"
   `include "i2c_types.sv"
   `include "i2c_trans.sv"
class i2c_coverage extends uvm_subscriber#(i2c_trans);

  `uvm_component_utils(i2c_coverage)

  bit [7:0]                                   i2c_data  ;
  i2c_trans                                   i2c_item  ;

  function new(string name="i2c_coverage", uvm_component parent);
    super.new(name, parent);
    i2c_cov = new();
  endfunction:new

  covergroup i2c_cov with function sample (i2c_trans i2c_item);
    option.per_instance = 1;
    addr_cov               : coverpoint i2c_item.addr                                        {
      bins bin0 = {[0  :15 ]};
      bins bin1 = {[16 :31 ]};
      bins bin2 = {[32 :47 ]};
      bins bin3 = {[48 :63 ]};
      bins bin4 = {[64 :79 ]};
      bins bin5 = {[80 :95 ]};
      bins bin6 = {[96 :111]};
      bins bin7 = {[112:127]};
    }
    data_resp_cov          : coverpoint i2c_item.data_resp                                   {
      bins ACK  = {0};
      bins NACK = {1};
    }
    addr_resp_cov          : coverpoint i2c_item.addr_resp                                   {
      bins ACK  = {0};
      bins NACK = {1};
    }
    data_cov               : coverpoint i2c_data                                             {
      wildcard bins bin0  = {8'b???????1}; wildcard bins bin1  = {8'b??????1?};
      wildcard bins bin2  = {8'b?????1??}; wildcard bins bin3  = {8'b????1???};
      wildcard bins bin4  = {8'b???1????}; wildcard bins bin5  = {8'b??1?????};
      wildcard bins bin6  = {8'b?1??????}; wildcard bins bin7  = {8'b1???????};
    }
  endgroup

  virtual function void write(i2c_trans i2c_transaction);
    if(!$cast(i2c_item, i2c_transaction))
      `uvm_error("write_i2c", "$cast failed, check type compatability")
    `uvm_info(get_type_name(), $sformatf("I2C transfer received:\n%s",i2c_item.sprint()), UVM_MEDIUM)
    
    
    foreach(i2c_item.data[i]) begin
      i2c_data = i2c_item.data[i];
      i2c_cov.sample(i2c_transaction);
    end
  endfunction:write




endclass:i2c_coverage

`endif