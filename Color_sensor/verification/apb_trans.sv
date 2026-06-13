`ifndef APB_TRANS_SV
`define APB_TRANS_SV
  
class apb_trans extends uvm_sequence_item;
  
    rand bit [`APB_AW-1:0]  addr;    
    rand bit [`APB_DW-1:0]  data;   
    rand apb_access_kind_t access;       
    rand int               trans_delay;       
    rand bit               slv_error;
    
    `uvm_object_utils_begin(apb_trans)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_enum(apb_access_kind_t, access, UVM_ALL_ON)
        `uvm_field_int(trans_delay, UVM_ALL_ON)  
        `uvm_field_int(slv_error, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constraints
    constraint abp_trans_delay_c { soft trans_delay inside {[1:5]}; };
    
    function new (string name = "apb_trans");
        super.new(name);
    endfunction
  
endclass: apb_trans

`endif
