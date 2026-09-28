--------------------------------------------------------------------------------
-- $RCSfile: $
--
-- DESC    : OpenRisk 1420 
--
-- AUTHOR  : Dr. Theo Kluter
--
-- CVS     : $Revision: $
--           $Date: $
--           $Author: $
--           $Source: $
--
--------------------------------------------------------------------------------
--
--  HISTORY :
--
--  $Log: 
--------------------------------------------------------------------------------

ARCHITECTURE platform_independent OF bios IS

   TYPE STATETYPE IS (IDLE,INTERPRET,BURST,ENDTRANSACTION,BUSERROR);
   
   COMPONENT bios_rom IS
      PORT ( address : IN  unsigned(10 DOWNTO 0 );
             data    : OUT std_logic_vector(31 DOWNTO 0));
   END COMPONENT;
   
   SIGNAL s_address_reg          : std_logic_vector( 31 DOWNTO 0 );
   SIGNAL s_burst_size_reg       : unsigned( 4 DOWNTO 0 );
   SIGNAL s_extended_burst_size  : unsigned( 5 DOWNTO 0 );
   SIGNAL s_burst_count_reg      : unsigned( 5 DOWNTO 0 );
   SIGNAL s_burst_count_next     : unsigned( 5 DOWNTO 0 );
   SIGNAL s_read_n_write_reg     : std_logic;
   SIGNAL s_RomAddrReg           : unsigned( 10 DOWNTO 0 );
   SIGNAL s_RomAddrNext          : unsigned( 10 DOWNTO 0 );
   SIGNAL s_RomData              : std_logic_vector( 31 DOWNTO 0 );
   
   SIGNAL s_IsMyBurst            : std_logic;
   
   SIGNAL s_StateReg,s_StateNext : STATETYPE;

BEGIN

   prog : bios_rom
      PORT MAP ( address => s_RomAddrReg,
                 data    => s_RomData);

--------------------------------------------------------------------------------
---                                                                          ---
--- Here the outputs are defined                                             ---
---                                                                          ---
--------------------------------------------------------------------------------
   makeOutputs : PROCESS( clock )
   BEGIN
      IF (rising_edge(clock)) THEN
         IF (s_StateReg = BUSERROR) THEN bus_error_out <= '1';
                                    ELSE bus_error_out <= '0';
         END IF;
         IF (s_StateReg = ENDTRANSACTION) THEN end_transaction_out <= '1';
                                          ELSE end_transaction_out <= '0';
         END IF;
         IF (s_stateReg = BURST) THEN data_valid_out   <= '1';
                                      address_data_out <= s_RomData;
                                 ELSE data_valid_out   <= '0';
                                      address_data_out <= (OTHERS => '0');
         END IF;
      END IF;
   END PROCESS makeOutputs;


--------------------------------------------------------------------------------
---                                                                          ---
--- Here the burst pipe-line regs are defined                                ---
---                                                                          ---
--------------------------------------------------------------------------------
   s_IsMyBurst           <= '1' WHEN s_address_reg(31 DOWNTO 28) = X"F" 
                                ELSE '0';
   s_extended_burst_size <= "0"&s_burst_size_reg;
   
   s_burst_count_next    <= s_extended_burst_size-1
                               WHEN s_StateReg = INTERPRET AND
                                    s_IsMyBurst = '1' AND
                                    s_read_n_write_reg = '1' ELSE
                            s_burst_count_reg-1
                               WHEN s_StateReg = BURST ELSE
                            s_burst_count_reg;
   
   s_RomAddrNext         <= unsigned(s_address_reg(12 DOWNTO 2))
                               WHEN s_StateReg = INTERPRET AND
                                    s_IsMyBurst = '1' AND
                                    s_read_n_write_reg = '1' ELSE
                            s_RomAddrReg+1
                               WHEN s_StateReg = BURST ELSE
                            s_RomAddrReg;

   makeBusPipeRegs : PROCESS( clock )
   BEGIN
      IF (rising_edge(clock)) THEN
         IF (reset = '1') THEN
            s_address_reg      <= (OTHERS => '0');
            s_burst_size_reg   <= (OTHERS => '0');
            s_read_n_write_reg <= '0';
         ELSIF (begin_transaction_in = '1') THEN
            s_address_reg      <= address_data_in;
            s_burst_size_reg   <= unsigned(burst_size_in);
            s_read_n_write_reg <= read_n_write_in;
         END IF;
      END IF;
   END PROCESS makeBusPipeRegs;
   
   makeBurstCountReg : PROCESS( clock )
   BEGIN
      IF (rising_edge(clock)) THEN
         IF (s_StateReg = IDLE) THEN s_burst_count_reg <= (OTHERS => '1');
                                     s_RomAddrReg      <= (OTHERS => '0');
                                ELSE s_burst_count_reg <= s_burst_count_next;
                                     s_RomAddrReg      <= s_RomAddrNext;
         END IF;
      END IF;
   END PROCESS makeBurstCountReg;

--------------------------------------------------------------------------------
---                                                                          ---
--- Here the state machine is defined                                        ---
---                                                                          ---
--------------------------------------------------------------------------------
   makeStateNext : PROCESS( s_StateReg , begin_transaction_in , s_IsMyBurst ,
                            s_read_n_write_reg , s_burst_count_reg )
   BEGIN
      CASE (s_StateReg) IS
         WHEN IDLE            => IF (begin_transaction_in = '1') THEN
                                    s_StateNext <= INTERPRET;
                                                                 ELSE
                                    s_StateNext <= IDLE;
                                 END IF;
         WHEN INTERPRET       => IF (s_IsMyBurst = '0') THEN
                                    s_StateNext <= IDLE;
                                 ELSIF (s_read_n_write_reg = '0') THEN
                                    s_StateNext <= BUSERROR;
                                                                  ELSE
                                    s_StateNext <= BURST;
                                 END IF;
         WHEN BURST           => IF (s_burst_count_reg(5) = '1') THEN
                                    s_StateNext <= ENDTRANSACTION;
                                                                 ELSE
                                    s_StateNext <= BURST;
                                 END IF;
         WHEN OTHERS          => s_StateNext <= IDLE;
      END CASE;
   END PROCESS makeStateNext;
   
   makeStateReg : PROCESS( clock )
   BEGIN
      IF (rising_edge(clock)) THEN
         IF (reset = '1') THEN s_StateReg <= IDLE;
                          ELSE s_StateReg <= s_StateNext;
         END IF;
      END IF;
   END PROCESS makeStateReg;

END platform_independent;
