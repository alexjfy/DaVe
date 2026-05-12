//through coverage, we can see which scenarios (e.g., which transaction types) have been generated during simulation; this allows us to measure verification progress
class apb_coverage;

  apb_transaction trans_covered;

  //to see the coverage value for each element, multiple coverage groups must be created, or a custom display function must be written
  covergroup apb_transaction_cg;
    //the line below is added because, if there are multiple instances for which coverage is computed, we want to know the value for each one separately.
    option.per_instance = 1;
    kind_cov: coverpoint trans_covered.kind;
    addr_cov: coverpoint trans_covered.addr{
      bins range[10] = {[1:10]};
      bins last_addr = {17};
      bins invalid_addr ={[11:16]};
      bins invalid_addr1[2] ={[18:$]};
    }
//     delay_cov: coverpoint trans_covered.delay{
//       bins big_values = {[51:79]};
//       bins medium_values = {[31:50]};
//       bins low_values = {[1:30]};
//       bins lowest_value = {0};
//       bins highest_value = {80};
//     }
    data_cov: coverpoint trans_covered.data {
      bins range[9] = {[1:8]};
      bins range1[3]={[9:254]};
      bins lowest_value = {0};
      bins highest_value = {255};
    }

  endgroup
   //create the coverage group; NOTE! Without the function below, the coverage group will never be able to sample data because so far it was only declared, not created
  function new();
    apb_transaction_cg = new();
  endfunction

  task sample(apb_transaction trans_covered);
  	this.trans_covered = trans_covered;
  	apb_transaction_cg.sample();
  endtask:sample

  function void print_coverage();
    $display ("Kind coverage = %.2f%%", apb_transaction_cg.kind_cov.get_coverage());
    $display ("Address coverage = %.2f%%", apb_transaction_cg.addr_cov.get_coverage());
    $display ("Data coverage = %.2f%%", apb_transaction_cg.data_cov.get_coverage());
//     $display ("Delay coverage = %.2f%%", apb_transaction_cg.delay_cov.get_coverage());
  endfunction

  //another way to end a class declaration is to write "endclass: class_name"; this is especially useful when declaring multiple classes in the same file; however, it is recommended that each file contains no more than one class declaration
endclass: apb_coverage