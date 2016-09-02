//
// Upto 16-bit dual-port binary counter. Uses grey code to cross clock domains.
//
// - reset_n: async reset, active low
// - clock: primary (write) clock for the counter
// - inc: increment counter on raising edge of clock, active high
// - count: current counter value
// - clk_a: secondary (read) clock
// - count_a: value of count synchronized to clk_a
//

module counter_dp (reset_n, clock, inc, count, clk_a, count_a);
parameter W = 12;

input reset_n, clock, inc, clk_a;
output [W-1:0] count, count_a;

localparam D = 16-W;
localparam [D-1:0] D0 = 0;
localparam [W-1:0] V0 = 0, V1 = 1;

reg [W-1:0] count, count_a;

function [15:0] b2g16;
  input [15:0] b;
begin
  b2g16[15:0] = {b[15], b[14:0] ^ b[15:1]};
end
endfunction

// low propagation delay grey->binary converter
// See more: https://www.google.com/patents/US3373421
function [15:0] g2b16;
  input [15:0] g;

  reg [7:0] t0;
  reg [11:0] t1;
  reg [13:0] t2;
  integer i;
begin
  for (i=0; i < 8; i=i+1) begin
    t0[i] = g[i] ^ g[i+8];
  end
  for (i=0; i < 12; i=i+1) begin
    t1[i] = (i < 4 ? t0[i] ^ t0[i+4] : i < 8 ? t0[i] ^ g[i+4] : g[i] ^ g[i+4]);
  end
  for (i=0; i < 14; i=i+1) begin
    t2[i] = (i < 10 ? t1[i] ^ t1[i+2] : i < 12 ? t1[i] ^ g[i+2] : g[i] ^ g[i+2]);
  end
  for (i=0; i < 13; i=i+1) begin
    g2b16[i] = t2[i] ^ t2[i+1];
  end
  g2b16[13] = t2[13] ^ g[14];
  g2b16[14] = g[14] ^ g[15];
  g2b16[15] = g[15];
end
endfunction

// write clock domain: increment counter
always @(posedge clock or negedge reset_n) begin
  if (~reset_n) begin
    count <= 0;
  end
  else begin
    count <= (inc ? count + V1 : count);
  end
end

// read clock domain: convert counter to grey, sync to clk_a, convert back to binary

reg [W-1:0] g0, g1;

always @(posedge clk_a or negedge reset_n) begin
  if (~reset_n) begin
    count_a <= 0;
    g0 <= 0;
    g1 <= 0;
  end
  else begin
    g0 <= (D == 0 ? b2g16(count[W-1:0]) : b2g16({D0, count[W-1:0]}));
    g1 <= g0;
    count_a <= (D == 0 ? g2b16(g1[W-1:0]) : g2b16({D0, g1[W-1:0]}));
  end
end

endmodule
