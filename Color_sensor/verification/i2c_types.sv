`ifndef I2C_TYPES_SV
`define I2C_TYPES_SV
 
typedef enum bit { I2C_WRITE, I2C_READ }   i2c_access_kind_t   ;
typedef enum bit { ACK, NACK }             i2c_resp_kind_t     ;
typedef enum bit { STOP, SR }              i2c_trans_end_kind_t;


`endif