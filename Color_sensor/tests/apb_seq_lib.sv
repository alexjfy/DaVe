`ifndef APB_SEQ_LIB_SV
`define APB_SEQ_LIB_SV
  
   `include "apb_defines.sv"
   `include "apb_types.sv"
   `include "apb_trans.sv"
class apb_base_seq extends uvm_sequence;

  // Required macro for sequences automation
  `uvm_object_utils(apb_base_seq)

  apb_trans req;
  function new(string name="apb_base_seq");
    super.new(name);
  endfunction

  task pre_body();
    uvm_phase phase;
    `ifdef UVM_VERSION_1_2
        // in UVM1.2, get starting phase from method
        phase = get_starting_phase();
    `else
        phase = starting_phase;
    `endif
    if (phase != null) begin
      phase.raise_objection(this, get_type_name());
      `uvm_info(get_type_name(), "raise objection", UVM_MEDIUM)
    end
  endtask : pre_body

  task post_body();
    uvm_phase phase;
    `ifdef UVM_VERSION_1_2
    // in UVM1.2, get starting phase from method
    phase = get_starting_phase();
    `else
    phase = starting_phase;
    `endif
    if (phase != null) begin
      #100ns;
      phase.drop_objection(this, get_type_name());
      `uvm_info(get_type_name(), "drop objection", UVM_MEDIUM)
    end
  endtask : post_body

endclass : apb_base_seq

//------------------------------------------------------------------------------
// SEQUENCE: apb_5_packets
//------------------------------------------------------------------------------
class apb_5_packets extends apb_base_seq;
  `uvm_object_utils(apb_5_packets)

  function new(string name="apb_5_packets");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing apb_5_packets sequence", UVM_LOW)
    repeat(5) begin
      `uvm_do(req)
    end
  endtask
endclass : apb_5_packets  

//------------------------------------------------------------------------------
// SEQUENCE: apb_rnd_pkt
// Sends one random packet
//------------------------------------------------------------------------------
class apb_rnd_pkt extends apb_base_seq;
  `uvm_object_utils(apb_rnd_pkt)

  function new(string name="apb_rnd_pkt");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing apb_rnd_pkt sequence", UVM_LOW)
    repeat(1) begin
      `uvm_do(req)
    end
  endtask
endclass : apb_rnd_pkt

//------------------------------------------------------------------------------
// SEQUENCE: apb_write_read
// Sends one random write pkt and then reads the same address
//------------------------------------------------------------------------------
class apb_write_read extends apb_base_seq;
  rand bit [`APB_AW-1:0] m_addr;

  `uvm_object_utils(apb_write_read)

  function new(string name="apb_write_read");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing apb_write_read sequence", UVM_LOW)
    repeat(1) begin
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h1      ;})

      m_addr = req.addr;

      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == m_addr  ; })
    end
  endtask
endclass : apb_write_read

//------------------------------------------------------------------------------
// SEQUENCE: apb_rmw
// Sends one random read pkt, modifies one random bit then writes back to the same address
//------------------------------------------------------------------------------
class apb_rmw extends apb_base_seq;
  bit [`APB_DW-1:0] m_data;
  bit [`APB_AW-1:0] m_addr;
  rand bit [`APB_AW-1:0] index; 
  rand bit rand_bit_value;

  `uvm_object_utils(apb_rmw)

  function new(string name="apb_rmw");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing apb_rmw sequence", UVM_LOW)
    repeat(1) begin
      `uvm_do_with(req, {req.access == APB_READ;})

      m_addr = req.addr;
      m_data = req.data;
      m_data[index] = rand_bit_value;

      `uvm_do_with(req, {
          req.access == APB_WRITE;
          req.addr   == m_addr   ;
          req.data   == m_data   ;
        })
    end
  endtask
endclass : apb_rmw

class registers_seq extends apb_base_seq;

  `uvm_object_utils(registers_seq)

  //bit [5:0] addr [7:0] = {'h0, 'h2, 'h4, 'h6, 'h8, 'hC, 'h10, 'h12};

  function new(string name="registers_seq");
    super.new(name);
  endfunction:new
  
  virtual task body();
    // read default values
   // foreach (addr[i]) begin
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h0;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h2;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h4;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h6;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h8;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'hC;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h10;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h12;})

   // end

    // write random values
   // foreach (addr[i]) begin
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h0;})
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h2;})
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h4;})
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h6;})
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h8;})
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'hC;})
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h10;})
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h12;})
   // end

    // read back values
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h0;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h2;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h4;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h6;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h8;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'hC;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h10;})
      `uvm_do_with(req, { req.access == APB_READ;
                          req.addr   == 'h12;})
  endtask:body

endclass:registers_seq

class color_disable_seq extends apb_base_seq;

  `uvm_object_utils(color_disable_seq)
  
  bit [4:0] color_disable;
  
  function new(string name="color_disable_seq");
    super.new(name);
  endfunction:new
  
  virtual task body();
      // Config register: addr=7'h29, clear/red/green/blue ON, SD=0 (sensor on)
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h0;
                          req.data   == 32'h0000149E;})

      // Seed register - random value
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h10;})

      // Write seed register multiple times with random values
    repeat(10) begin
      `uvm_do_with(req, { req.access == APB_WRITE;
                          req.addr   == 'h10;})
    end
  endtask:body

endclass:color_disable_seq
`endif