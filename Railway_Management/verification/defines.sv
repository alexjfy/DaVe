`ifndef DEFINES_SVH
`define DEFINES_SVH

`ifndef MIN_TRANSACTION_NR
  `define MIN_TRANSACTION_NR 20
`endif

//declare an enum to represent the different railway states
typedef enum {NO_TRAIN,TRAIN1,TRAIN2,TRAIN3,TRAIN4,TRAIN5,TRAIN6} train_state_t;

`endif