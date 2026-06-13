`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

import apb_pkg::*;
`include "uvm_macros.svh"

class apb_coverage extends uvm_subscriber#(apb_trans);

    `uvm_component_utils(apb_coverage)

    covergroup apb_packet_cg with function sample(apb_trans apb_item);

        setup_delay_cp :coverpoint apb_item.trans_delay {
            bins NO_DELAY     = {0};
            bins SMALL_DELAY  = {[1:10]};
            bins MEDIUM_DELAY = {[11:20]};
            bins BIG_DELAY    = {[21:$]};
        }

        addr_cp :coverpoint apb_item.addr{
            bins ADDR0_config       = {8'd0};
            bins ADDR1_clearCh      = {8'd2};
            bins ADDR4_redCh        = {8'd4};
            bins ADDR6_greenCh      = {8'd6};
            bins ADDR8_blueCh       = {8'd8};
            bins ADDR12_infraredCh  = {8'd12};
            bins ADDR16_seed        = {8'd16};
            bins ADDR18_status      = {8'd18};
        }

        data_cp :coverpoint apb_item.data {
            bins DATA_bins[4]  = {[0: 2**`APB_DW]};
        }

        access_cp :coverpoint apb_item.access {
            bins READ  = {1};
            bins WRITE = {0};
        }

        slv_error_cp : coverpoint apb_item.slv_error {
            bins NO_SLV_ERR = {0};
            bins SLV_ERR    = {1};
        }

        dataXaddress_cc   : cross addr_cp, data_cp;
        dataXaccess_cc    : cross access_cp, data_cp;
        accessXaddress_cc : cross addr_cp, access_cp;  
        accessXslv_error_cp : cross access_cp, slv_error_cp;
    endgroup

    function new(string name = "apb_coverage",uvm_component parent);
        super.new(name,parent);
        apb_packet_cg = new();
    endfunction : new


    virtual function void write(apb_trans t);
        apb_packet_cg.sample(t);
    endfunction : write

endclass : apb_coverage

`endif