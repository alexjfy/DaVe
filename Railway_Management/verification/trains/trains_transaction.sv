`ifndef __trains_transaction
`define __trains_transaction

class trains_transaction extends uvm_sequence_item;
  
  rand bit t1_i;
  rand bit t2_i;
  rand bit t3_i;
  rand bit t4_i;
  rand bit t5_i;
  rand bit t6_i;
  
  //add transaction to the UVM database
  `uvm_object_utils_begin(trains_transaction)
    `uvm_field_int(t1_i, UVM_ALL_ON)
    `uvm_field_int(t2_i, UVM_ALL_ON)
    `uvm_field_int(t3_i, UVM_ALL_ON)
    `uvm_field_int(t4_i, UVM_ALL_ON)
    `uvm_field_int(t5_i, UVM_ALL_ON)
    `uvm_field_int(t6_i, UVM_ALL_ON)
  `uvm_object_utils_end
  
  constraint t1_c {soft t1_i dist {0 := 8, 1 := 2};}
  constraint t2_c {soft t2_i dist {0 := 8, 1 := 2};}
  constraint t3_c {soft t3_i dist {0 := 8, 1 := 2};}
  constraint t4_c {soft t4_i dist {0 := 8, 1 := 2};}
  constraint t5_c {soft t5_i dist {0 := 8, 1 := 2};}
  constraint t6_c {soft t6_i dist {0 := 8, 1 := 2};}
  
  //declare the class constructor;
  function new(string name = "trains_transaction");
    super.new(name);
  	t1_i = 0;
  	t2_i = 0;
  	t3_i = 0;
  	t4_i = 0;
  	t5_i = 0;
  	t6_i = 0;
  endfunction
  
  // //functie de afisare a unei tranzactii
  // function void afiseaza_informatia_tranzactiei();
  //   int minim_un_tren_a_anuntat = 0; //pornim cu presupunerea ca in tactul curent, niciun tren nu anunta ca vrea sa intre pe linia de interes maxim 
  //   if (this.t1_i ==1) begin
  //     $display("\nTRANZACTIE: Trenul 1 anunta ca vrea sa intre pe linia de interes maxim");
  //     minim_un_tren_a_anuntat = 1;
  //   end
  //   if (this.t2_i ==1) begin
  //     $display("\nTRANZACTIE: Trenul 2 anunta ca vrea sa intre pe linia de interes maxim");
  //     minim_un_tren_a_anuntat = 1;
  //   end
  //   if (this.t3_i ==1) begin
  //     $display("\nTRANZACTIE: Trenul 3 anunta ca vrea sa intre pe linia de interes maxim");
  //     minim_un_tren_a_anuntat = 1;
  //   end
  //   if (this.t4_i ==1) begin
  //     $display("\nTRANZACTIE: Trenul 4 anunta ca vrea sa intre pe linia de interes maxim");
  //     minim_un_tren_a_anuntat = 1;
  //   end
  //   if (this.t5_i ==1) begin
  //     $display("\nTRANZACTIE: Trenul 5 anunta ca vrea sa intre pe linia de interes maxim");
  //     minim_un_tren_a_anuntat = 1;
  //   end
  //   if (this.t6_i ==1) begin
  //     $display("\nTRANZACTIE: Trenul 6 anunta ca vrea sa intre pe linia de interes maxim");
  //     minim_un_tren_a_anuntat = 1;
  //   end
  //   if (minim_un_tren_a_anuntat == 0)
  //     $display("\nTRANZACTIE: Niciun tren nu anunta ca vrea sa intre pe linia de interes maxim");
     
  // endfunction

  function copy (trains_transaction t);
    this.t1_i = t.t1_i;
    this.t2_i = t.t2_i;
    this.t3_i = t.t3_i;
    this.t4_i = t.t4_i;
    this.t5_i = t.t5_i;
    this.t6_i = t.t6_i;
  endfunction

endclass : trains_transaction

`endif