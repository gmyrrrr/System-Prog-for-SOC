module spm8k #(parameter [31:0] slaveBaseAddress = 0,
               parameter [31:0] spmBaseAddress = 32'hC0000000)
             ( input wire         clock,
                                  reset,
               input wire [31:0]  dataToSpm,
               output wire [31:0] dataFromSpm,
               input wire [17:0]  spmAddress,
               input wire [3:0]   spmByteEnables,
               input wire         spmCs,
               input wire         spmWe,
               output wire        irq,

               // here the bus interface is defined
               output wire        requestTransaction,
               input wire         transactionGranted,
               input wire         beginTransactionIn,
                                  endTransactionIn,
                                  readNotWriteIn,
                                  dataValidIn,
                                  busErrorIn,
                                  busyIn,
               input wire [31:0]  addressDataIn,
               input wire [3:0]   byteEnablesIn,
               input wire [7:0]   burstSizeIn,
               output wire        beginTransactionOut,
                                  endTransactionOut,
                                  dataValidOut,
                                  readNotWriteOut,
                                  busErrorOut,
                                  busyOut,
               output wire [3:0]  byteEnablesOut,
               output wire [7:0]  burstSizeOut,
               output wire [31:0] addressDataOut);
  
  reg[7:0] s_mem0 [2047:0];
  reg[7:0] s_mem1 [2047:0];
  reg[7:0] s_mem2 [2047:0];
  reg[7:0] s_mem3 [2047:0];
  
  reg[31:0] s_dataFromSpm, s_dmaLookupData, s_dataFromSpmReg;
  reg       s_CsReg;
  
  wire [31:0] s_dmaAddress, s_dmaDataOut;
  wire        s_weSpm = spmCs & spmWe;
  wire        s_dmaWe;
  wire [7:0]  s_weData0 = (spmByteEnables[0] == 1'b1) ? dataToSpm[ 7: 0] : s_dmaLookupData[ 7: 0];
  wire [7:0]  s_weData1 = (spmByteEnables[1] == 1'b1) ? dataToSpm[15: 8] : s_dmaLookupData[15: 8];
  wire [7:0]  s_weData2 = (spmByteEnables[2] == 1'b1) ? dataToSpm[23:16] : s_dmaLookupData[23:16];
  wire [7:0]  s_weData3 = (spmByteEnables[3] == 1'b1) ? dataToSpm[31:24] : s_dmaLookupData[31:24];
  wire [10:0] s_lookupAddress = (s_weSpm == 1'b1) ? spmAddress[10:0] : s_dmaAddress[12:2];

  assign      dataFromSpm = s_dataFromSpmReg;
  
  always @(posedge clock)
    begin
      s_CsReg          <= (reset == 1'b1) ? 1'b0 : spmCs;
      s_dataFromSpmReg <= (reset == 1'b1) ? 32'd0 : (s_CsReg == 1'b1) ? s_dataFromSpm : s_dataFromSpmReg;
    end

  always @(posedge clock)
    begin
      if (s_weSpm == 1'b1)
        begin
          s_mem0[spmAddress[10:0]] <= s_weData0;
          s_mem1[spmAddress[10:0]] <= s_weData1;
          s_mem2[spmAddress[10:0]] <= s_weData2;
          s_mem3[spmAddress[10:0]] <= s_weData3;
        end
      s_dataFromSpm[ 7: 0] <= s_mem0[spmAddress[10:0]];
      s_dataFromSpm[15: 8] <= s_mem1[spmAddress[10:0]];
      s_dataFromSpm[23:16] <= s_mem2[spmAddress[10:0]];
      s_dataFromSpm[31:24] <= s_mem3[spmAddress[10:0]];
    end
  
  always @(negedge clock)
    begin
      if (s_dmaWe == 1'b1)
        begin
          s_mem0[s_lookupAddress] <= s_dmaDataOut[ 7: 0];
          s_mem1[s_lookupAddress] <= s_dmaDataOut[15: 8];
          s_mem2[s_lookupAddress] <= s_dmaDataOut[23:16];
          s_mem3[s_lookupAddress] <= s_dmaDataOut[31:24];
        end
      s_dmaLookupData[ 7: 0] <= s_mem0[s_lookupAddress];
      s_dmaLookupData[15: 8] <= s_mem1[s_lookupAddress];
      s_dmaLookupData[23:16] <= s_mem2[s_lookupAddress];
      s_dmaLookupData[31:24] <= s_mem3[s_lookupAddress];
    end
    
  reg [31:0] s_dmaLookupDataReg;
  
  always @(posedge clock) s_dmaLookupDataReg <= (s_weSpm == 1'b1) ? s_dmaLookupDataReg : s_dmaLookupData;
  
  wire [31:0] s_dmaReData = (s_weSpm == 1'b1) ? s_dmaLookupDataReg : s_dmaLookupData;

  spmDma #(.slaveBaseAddress(slaveBaseAddress),
           .spmBaseAddress(spmBaseAddress),
           .spmSizeInBytes(8*1024)) dma
          (.clock(clock),
           .reset(reset),
           .irq(irq),
           .spmBusy(s_weSpm),
           .spmAddress(s_dmaAddress),
           .spmWe(s_dmaWe),
           .spmWeData(s_dmaDataOut),
           .spmReData(s_dmaReData),
           .requestTransaction(requestTransaction),
           .transactionGranted(transactionGranted),
           .beginTransactionIn(beginTransactionIn),
           .endTransactionIn(endTransactionIn),
           .readNotWriteIn(readNotWriteIn),
           .dataValidIn(dataValidIn),
           .busErrorIn(busErrorIn),
           .busyIn(busyIn),
           .addressDataIn(addressDataIn),
           .byteEnablesIn(byteEnablesIn),
           .burstSizeIn(burstSizeIn),
           .beginTransactionOut(beginTransactionOut),
           .endTransactionOut(endTransactionOut),
           .dataValidOut(dataValidOut),
           .readNotWriteOut(readNotWriteOut),
           .busErrorOut(busErrorOut),
           .busyOut(busyOut),
           .byteEnablesOut(byteEnablesOut),
           .burstSizeOut(burstSizeOut),
           .addressDataOut(addressDataOut));
endmodule
