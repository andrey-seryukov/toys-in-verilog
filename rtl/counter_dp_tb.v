/* test bench for counter_dp() */
//`timescale 1ns/100ps

module counter_dp_tb ();

reg clk_50, clk_33;
reg rst_l, inc;

wire [15:0] count,count_33;

counter_dp cdp (
  .reset_n	(rst_l),
  .clock    (clk_50),
  .inc      (inc),
  .count    (count),

  .clk_a    (clk_33),
  .count_a  (count_33)
);

always // invert every 10ns
  #10 clk_50 = ~clk_50; 

always // invert every 15ns
  #15 clk_33 = ~clk_33;

initial begin
  $display($time, " << Starting the Simulation >>");
  clk_50 = 1'b0;
  clk_33 = 1'b0;
  // at time 0
  rst_l = 0;  // reset is active
  inc = 0;
  #20 rst_l = 1'b1;

  $display($time, " << Coming out of reset >>");
  @(negedge clk_50); // wait till the negedge of clk_50 then continue
  inc <= 1'b1;
  @(negedge clk_50); // add 1
  inc <= 1'b0;
  #150               // let count propagate
  $display($time, "... count_33 = %d", count_33);
  @(negedge clk_50);
  inc = 1'b1;
  #150              // let coiunt free-run at the speed of clock
  inc = 1'b0;
  #150              // let count finish propagating
  $display($time, "... count_33 = %d", count_33);
  #20
  $display($time, " << Simulation Complete >>");
  $stop;
end

initial begin
  // $monitor will print whenever a signal changes in the design
  $monitor($time, " rst_l=%b clk_50=%b clk_33=%b inc=%b, count=%h count_33=%h", rst_l, clk_50, clk_33, inc, count, count_33);
end

endmodule
