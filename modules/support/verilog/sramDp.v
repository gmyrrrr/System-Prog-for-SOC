module sramDp #(parameter nrOfAddressBits = 12,
                parameter nrOfDataBits = 8)
               (input wire                       clockA,
                                                 writeEnableA,
                input wire [nrOfAddressBits-1:0] addressA,
                input wire [nrOfDataBits-1:0]    dataInA,
                output reg [nrOfDataBits-1:0]    dataOutA,
                input wire                       clockB,
                                                 writeEnableB,
                input wire [nrOfAddressBits-1:0] addressB,
                input wire [nrOfDataBits-1:0]    dataInB,
                output reg [nrOfDataBits-1:0]    dataOutB);

  reg[nrOfDataBits-1:0] s_memory [(2**nrOfAddressBits)-1:0];
  
  always @ (posedge clockA)
    begin
      if (writeEnableA == 1'b1) s_memory[addressA] <= dataInA;
      dataOutA <= s_memory[addressA];
    end

  always @ (posedge clockB)
    begin
      if (writeEnableB == 1'b1) s_memory[addressB] <= dataInB;
      dataOutB <= s_memory[addressB];
    end
endmodule
