module    mult_man
  #(parameter N=16,
    parameter M=16)
   (
      input                     clk,
      input                     rstn,

      input                     data_rdy ,
      input [N:0]             mult1_signed,
      input [M:0]             mult2_signed,
      
      output [N+M-1:0]       res            ,
      output [N+M+1:0]         res_signed     ,
      output                    res_rdy ,
      output [N+M:0]          res_final    
    );

   wire [N-1:0]         mult1           ;
   wire [M-1:0]         mult2           ;
   wire [N+M-1:0]       mult1_t [M-1:0] ;
   wire [M-1:0]         mult2_t [M-1:0] ;
   wire [N+M-1:0]       mult1_acc_t [M-1:0] ;
   wire [M-1:0]         flag_t          ;
   wire [M-1:0]         rdy_t ;
   wire                 flag           ;

   assign flag          =  mult1_signed[N]   +  mult2_signed[M]   ;
   assign mult1   =     (mult1_signed[N]==1'b1)?{~(mult1_signed[N-1:0]-1'b1)} : mult1_signed[N-1:0]  ;
   assign mult2   =     (mult2_signed[M]==1'b1)?{~(mult2_signed[M-1:0]-1'b1)} : mult2_signed[M-1:0]  ;


   mult_cell      #(.N(N), .M(M))
   u_mult_step0
     (
      .clk              (clk),
      .rstn             (rstn),
      //input
      .en               (data_rdy),
      .mult1            ({{(M){1'b0}}, mult1}),
      .mult2            (mult2),
      .mult1_acci       ({(N+M){1'b0}}),
      .flag             (flag)         ,
      //output
      .mult1_acco       (mult1_acc_t[0]),
      .mult2_shift      (mult2_t[0]),
      .mult1_o          (mult1_t[0]),
      .rdy              (rdy_t[0]),
      .flag_r           (flag_t[0]) 
      );

   genvar               i ;
   generate
      for(i=1; i<=M-1; i=i+1) begin: mult_stepx
         mult_cell      #(.N(N), .M(M))
         u_mult_step
         (
          .clk              (clk),
          .rstn             (rstn),
          //input
          .en               (rdy_t[i-1]),
          .mult1            (mult1_t[i-1]),
          .mult2            (mult2_t[i-1]),
          .mult1_acci       (mult1_acc_t[i-1]),
          .flag             (flag_t[i-1])      ,
          //output
          .mult1_acco       (mult1_acc_t[i]),
          .mult1_o          (mult1_t[i]),
          .mult2_shift      (mult2_t[i]),
          .rdy              (rdy_t[i]),
          .flag_r           (flag_t[i])   
          );
      end // block: sqrt_stepx
   endgenerate

   reg   [N+M+1:0]  res_a                           ;

   always @(*) begin
      if(mult1_acc_t[M-1]==0)begin
         res_a       =     'd0            ;
      end
      else if((mult1_acc_t[M-1]!=0)&&(flag_t[M-1]==1))begin
         res_a       =      {1'b1,(~res_final + 1'b1)} ;
      end
      else begin
         res_a       =     'd0            ;
      end
   end


   assign res_rdy       = rdy_t[M-1];
   assign res           = mult1_acc_t[M-1];
   assign res_final  =  {1'b0,res}  ;
   assign res_signed =  (flag_t[M-1]==1) ? res_a : {1'b0,res_final}   ; 

endmodule