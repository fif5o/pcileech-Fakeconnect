pcileech_bar_impl_fake_ethernet i_barX(
    .rst            ( rst                           ),
    .clk            ( clk                           ),
    .wr_addr        ( wr_addr                       ),
    .wr_be          ( wr_be                         ),
    .wr_data        ( wr_data                       ),
    .wr_valid       ( wr_valid && wr_bar[X]         ),  //sample
    .rd_req_ctx     ( rd_req_ctx                    ),
    .rd_req_addr    ( rd_req_addr                   ),
    .rd_req_valid   ( rd_req_valid && rd_req_bar[X] ),
    .rd_rsp_ctx     ( bar_rsp_ctx[X]                ),
    .rd_rsp_data    ( bar_rsp_data[X]               ),
    .rd_rsp_valid   ( bar_rsp_valid[X]              )
);

module pcileech_bar_impl_fake_ethernet(
    input               rst,
    input               clk,
    // incoming BAR writes:
    input [31:0]        wr_addr,
    input [3:0]         wr_be,
    input [31:0]        wr_data,
    input               wr_valid,
    // incoming BAR reads:
    input  [87:0]       rd_req_ctx,
    input  [31:0]       rd_req_addr,
    input               rd_req_valid,
    // outgoing BAR read replies:
    output reg [87:0]   rd_rsp_ctx,
    output reg [31:0]   rd_rsp_data,
    output reg          rd_rsp_valid
);

    localparam REG_LINK_STATUS = 32'h0000;
    localparam REG_RX_DATA     = 32'h0004;
    localparam REG_TX_DATA     = 32'h0008;

    reg link_up;
    reg [31:0] rx_data;
    reg [31:0] tx_data;
    reg [31:0] rx_counter;

    // 虚拟链路始终为up
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            link_up    <= 1'b1;
            rx_data    <= 32'h11223344;
            tx_data    <= 32'h0;
            rx_counter <= 0;
        end else begin
            // RECEIVE
            rx_counter <= rx_counter + 1;
            rx_data    <= 32'hAABB0000 | rx_counter[15:0];
            // TRANSMIT
            if (wr_valid && wr_addr == REG_TX_DATA)
                tx_data <= wr_data;
        end
    end

    // request
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_rsp_ctx   <= 0;
            rd_rsp_data  <= 0;
            rd_rsp_valid <= 0;
        end else if (rd_req_valid) begin
            rd_rsp_ctx   <= rd_req_ctx;
            rd_rsp_valid <= 1'b1;
            case (rd_req_addr)
                REG_LINK_STATUS: rd_rsp_data <= 32'h1;         
                REG_RX_DATA:     rd_rsp_data <= rx_data;       
                REG_TX_DATA:     rd_rsp_data <= tx_data;       
                default:         rd_rsp_data <= 32'hDEADBEEF;
            endcase
        end else begin
            rd_rsp_valid <= 0;
        end
    end

endmodule