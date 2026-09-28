module sramSDpSync #( parameter nrOfAddressBits = 5,
                      parameter nrOfDataBits = 32 )
                    ( input wire                       clock,
                                                       writeEnable,
                      input wire [nrOfAddressBits-1:0] writeAddress,
                      input wire [nrOfAddressBits-1:0] readAddress,
                      input wire [nrOfDataBits-1:0]    writeData,
                      output reg [nrOfDataBits-1:0]    readDataW,
                      output reg [nrOfDataBits-1:0]    readDataR );

  reg [nrOfDataBits-1:0] s_memory [(2**nrOfAddressBits)-1:0];
  
  always @(posedge clock )
  begin
    if (writeEnable == 1'b1) s_memory[writeAddress] <= writeData;
    readDataW <= s_memory[writeAddress];
    readDataR <= s_memory[readAddress];
  end
endmodule

