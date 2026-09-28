--------------------------------------------------------------------------------
-- $RCSfile: uart_rx.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.1 $
--           $Date: 2008/05/16 10:43:00 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_rx.vhdl,v $
--
--------------------------------------------------------------------------------
--
-- Copyright (C) 2007/2008 Theo Kluter <ties.kluter@epfl.ch> EPFL-ISIM-LAP
--
--  This file is subject to the terms and conditions of the GNU General Public
--  License.
--
--------------------------------------------------------------------------------
--
--  HISTORY :
--
--  $Log: uart_rx.vhdl,v $
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

ARCHITECTURE behav OF uart_rx_controler IS

   SIGNAL s_bit_counter_load_value  : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_bit_counter_reg         : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_baud_counter_reg        : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_sample_tick             : std_logic;
   SIGNAL s_do_shift                : std_logic;
   SIGNAL s_shift_reg               : std_logic_vector( 10 DOWNTO 0 );
   SIGNAL s_state_machine_reg       : std_logic_vector( 1 DOWNTO 0 );
   SIGNAL s_frame_error_reg         : std_logic;
   SIGNAL s_break_reg               : std_logic;
   SIGNAL s_overrun_reg             : std_logic;
   SIGNAL s_5_bit_break             : std_logic;
   SIGNAL s_6_bit_break             : std_logic;
   SIGNAL s_7_bit_break             : std_logic;
   SIGNAL s_8_bit_break             : std_logic;
   SIGNAL s_is_break                : std_logic;
   SIGNAL s_data_bits               : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_parity                  : std_logic;
   SIGNAL s_data_parity             : std_logic;
   SIGNAL s_data_reg                : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_parity_error            : std_logic;
   SIGNAL s_parity_error_reg        : std_logic;
   SIGNAL s_delay_reg               : std_logic;
   SIGNAL s_write_fifo              : std_logic;
   SIGNAL s_filtered_rx_reg         : std_logic;
   SIGNAL s_filtered_rx_delayed_reg : std_logic;
   SIGNAL s_rx_neg_edge             : std_logic;
   SIGNAL s_rx_pipe_reg             : std_logic_vector( 2 DOWNTO 0 );

BEGIN
-- Assign outputs
   fifo_data      <= s_data_reg;
   frame_error    <= s_frame_error_reg;
   break_detected <= s_break_reg;
   overrun_error  <= s_overrun_reg;
   parity_error   <= s_parity_error_reg;
   
-- Assign control signals
   s_sample_tick <= baud_rate_x_16_tick WHEN s_baud_counter_reg = "0111" ELSE '0';
   s_do_shift    <= '0' WHEN s_bit_counter_reg = "0000" ELSE s_sample_tick;
   s_5_bit_break <= '1' WHEN s_shift_reg(6 DOWNTO 0) = "0000000" ELSE '0';
   s_6_bit_break <= '1' WHEN s_shift_reg(7 DOWNTO 0) = "00000000" ELSE '0';
   s_7_bit_break <= '1' WHEN s_shift_reg(8 DOWNTO 0) = "000000000" ELSE '0';
   s_8_bit_break <= '1' WHEN s_shift_reg(9 DOWNTO 0) = "0000000000" ELSE '0';
   s_is_break    <= s_5_bit_break WHEN control_reg(1 DOWNTO 0) = "00" ELSE
                    s_6_bit_break WHEN control_reg(1 DOWNTO 0) = "01" ELSE
                    s_7_bit_break WHEN control_reg(1 DOWNTO 0) = "10" ELSE
                    s_8_bit_break;
   s_parity      <= NOT(s_shift_reg(1) XOR control_reg(4));
   s_parity_error<= (s_parity XOR s_data_parity) AND control_reg(3)
                       WHEN control_reg(5) = '0' ELSE
                    NOT(s_shift_reg(1)  XOR control_reg(4)) AND control_reg(3);
   s_write_fifo  <= NOT(s_overrun_reg);

-- Make processes
   make_signal_regs : PROCESS( clock , reset , s_state_machine_reg,
                               s_write_fifo , s_delay_reg )
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_delay_reg <= '0';
                               fifo_we     <= '0';
                          ELSE fifo_we     <= s_delay_reg AND s_write_fifo;
                               IF (s_state_machine_reg = "11") THEN s_delay_reg <= '1'; 
                                                               ELSE s_delay_reg <= '0'; 
                               END IF;
         END IF;
      END IF;
   END PROCESS make_signal_regs;
   
   make_error_regs : PROCESS( clock , reset , s_is_break , fifo_full,
                              s_state_machine_reg , s_shift_reg , s_data_bits,
                              s_parity_error)
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_frame_error_reg  <= '0';
                               s_break_reg        <= '0';
                               s_overrun_reg      <= '0';
                               s_parity_error_reg <= '0';
                               s_data_reg         <= (OTHERS => '0');
         ELSIF (s_state_machine_reg = "11") THEN 
            s_frame_error_reg  <= NOT( s_shift_reg(0) ) AND NOT( s_is_break );
            s_break_reg        <= s_is_break;
            s_overrun_reg      <= fifo_full AND NOT( s_is_break );
            s_data_reg         <= s_data_bits;
            s_parity_error_reg <= s_parity_error;
         END IF;
      END IF;
   END PROCESS make_error_regs;
      
   make_bc_load : PROCESS( control_reg )
      VARIABLE v_switch : std_logic_vector( 2 DOWNTO 0 );
   BEGIN
      v_switch := control_reg(3)&control_reg( 1 DOWNTO 0 );
      CASE v_switch IS
         WHEN  "000" => s_bit_counter_load_value <= "0111";
         WHEN  "001" => s_bit_counter_load_value <= "1000";
         WHEN  "010" => s_bit_counter_load_value <= "1001";
         WHEN  "011" => s_bit_counter_load_value <= "1010";
         WHEN  "100" => s_bit_counter_load_value <= "1000";
         WHEN  "101" => s_bit_counter_load_value <= "1001";
         WHEN  "110" => s_bit_counter_load_value <= "1010";
         WHEN OTHERS => s_bit_counter_load_value <= "1011";
      END CASE;
   END PROCESS make_bc_load;
   
   make_bc_counter_reg : PROCESS( clock , reset , s_do_shift ,
                                  s_bit_counter_load_value ,
                                  s_bit_counter_reg , s_state_machine_reg )
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_bit_counter_reg <= "0000";
         ELSIF (s_state_machine_reg = "01") THEN s_bit_counter_reg <= s_bit_counter_load_value;
         ELSIF (s_do_shift = '1') THEN s_bit_counter_reg <= unsigned( s_bit_counter_reg ) - 1;
         END IF;
      END IF;
   END PROCESS make_bc_counter_reg;
   
   make_baud_counter : PROCESS( clock , reset , baud_rate_x_16_tick ,
                                s_state_machine_reg , s_baud_counter_reg )
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1' OR s_state_machine_reg = "01") THEN s_baud_counter_reg <= "0000";
         ELSIF (s_state_machine_reg = "10" AND
                baud_rate_x_16_tick = '1') THEN 
            s_baud_counter_reg <= unsigned(s_baud_counter_reg) + 1;
         END IF;
      END IF;
   END PROCESS make_baud_counter;
   
   make_shift_reg : PROCESS( clock , reset , s_do_shift ,
                             s_filtered_rx_reg )
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_shift_reg <= (OTHERS=> '0');
         ELSIF (s_do_shift = '1') THEN s_shift_reg <= s_shift_reg(9 DOWNTO 0)&
                                                      s_filtered_rx_reg;
         END IF;
      END IF;
   END PROCESS make_shift_reg;
   
   make_state_machine : PROCESS( clock , reset , s_rx_neg_edge ,
                                 s_bit_counter_reg , s_state_machine_reg )
      VARIABLE v_next_state : std_logic_vector( 1 DOWNTO 0 );
   BEGIN
      CASE s_state_machine_reg IS
         WHEN  "00"  => IF (s_rx_neg_edge = '1') THEN v_next_state := "01";
                                                 ELSE v_next_state := "00";
                        END IF;
         WHEN  "01"  => v_next_state := "10";
         WHEN  "10"  => IF (s_bit_counter_reg = "0000") THEN v_next_state := "11";
                                                        ELSE v_next_state := "10";
                        END IF;
         WHEN OTHERS => v_next_state := "00";
      END CASE;
      
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_state_machine_reg <= "00";
                          ELSE s_state_machine_reg <= v_next_state;
         END IF;
      END IF;
   END PROCESS make_state_machine;
   
   make_data_bits : PROCESS( s_shift_reg , control_reg )
      VARIABLE v_switch : std_logic_vector( 2 DOWNTO 0 );
   BEGIN
      v_switch(2) := control_reg(3);
      v_switch( 1 DOWNTO 0 ) := control_reg( 1 DOWNTO 0 );
      CASE v_switch IS
         WHEN  "000" => s_data_bits(7) <= '0';
                        s_data_bits(6) <= '0';
                        s_data_bits(5) <= '0';
                        s_data_bits(4) <= s_shift_reg(1);
                        s_data_bits(3) <= s_shift_reg(2);
                        s_data_bits(2) <= s_shift_reg(3);
                        s_data_bits(1) <= s_shift_reg(4);
                        s_data_bits(0) <= s_shift_reg(5);
         WHEN  "001" => s_data_bits(7) <= '0';
                        s_data_bits(6) <= '0';
                        s_data_bits(5) <= s_shift_reg(1);
                        s_data_bits(4) <= s_shift_reg(2);
                        s_data_bits(3) <= s_shift_reg(3);
                        s_data_bits(2) <= s_shift_reg(4);
                        s_data_bits(1) <= s_shift_reg(5);
                        s_data_bits(0) <= s_shift_reg(6);
         WHEN  "010" => s_data_bits(7) <= '0';
                        s_data_bits(6) <= s_shift_reg(1);
                        s_data_bits(5) <= s_shift_reg(2);
                        s_data_bits(4) <= s_shift_reg(3);
                        s_data_bits(3) <= s_shift_reg(4);
                        s_data_bits(2) <= s_shift_reg(5);
                        s_data_bits(1) <= s_shift_reg(6);
                        s_data_bits(0) <= s_shift_reg(7);
         WHEN  "011" => s_data_bits(7) <= s_shift_reg(1);
                        s_data_bits(6) <= s_shift_reg(2);
                        s_data_bits(5) <= s_shift_reg(3);
                        s_data_bits(4) <= s_shift_reg(4);
                        s_data_bits(3) <= s_shift_reg(5);
                        s_data_bits(2) <= s_shift_reg(6);
                        s_data_bits(1) <= s_shift_reg(7);
                        s_data_bits(0) <= s_shift_reg(8);
         WHEN  "100" => s_data_bits(7) <= '0';
                        s_data_bits(6) <= '0';
                        s_data_bits(5) <= '0';
                        s_data_bits(4) <= s_shift_reg(2);
                        s_data_bits(3) <= s_shift_reg(3);
                        s_data_bits(2) <= s_shift_reg(4);
                        s_data_bits(1) <= s_shift_reg(5);
                        s_data_bits(0) <= s_shift_reg(6);
         WHEN  "101" => s_data_bits(7) <= '0';
                        s_data_bits(6) <= '0';
                        s_data_bits(5) <= s_shift_reg(2);
                        s_data_bits(4) <= s_shift_reg(3);
                        s_data_bits(3) <= s_shift_reg(4);
                        s_data_bits(2) <= s_shift_reg(5);
                        s_data_bits(1) <= s_shift_reg(6);
                        s_data_bits(0) <= s_shift_reg(7);
         WHEN  "110" => s_data_bits(7) <= '0';
                        s_data_bits(6) <= s_shift_reg(2);
                        s_data_bits(5) <= s_shift_reg(3);
                        s_data_bits(4) <= s_shift_reg(4);
                        s_data_bits(3) <= s_shift_reg(5);
                        s_data_bits(2) <= s_shift_reg(6);
                        s_data_bits(1) <= s_shift_reg(7);
                        s_data_bits(0) <= s_shift_reg(8);
         WHEN OTHERS => s_data_bits(7) <= s_shift_reg(2);
                        s_data_bits(6) <= s_shift_reg(3);
                        s_data_bits(5) <= s_shift_reg(4);
                        s_data_bits(4) <= s_shift_reg(5);
                        s_data_bits(3) <= s_shift_reg(6);
                        s_data_bits(2) <= s_shift_reg(7);
                        s_data_bits(1) <= s_shift_reg(8);
                        s_data_bits(0) <= s_shift_reg(9);
      END CASE;
   END PROCESS make_data_bits;
   
   make_data_parity : PROCESS( s_data_bits )
      VARIABLE v_xor_stage_0 : std_logic_vector( 3 DOWNTO 0 );
      VARIABLE v_xor_stage_1 : std_logic_vector( 1 DOWNTO 0 );
   BEGIN
      FOR n IN 3 DOWNTO 0 LOOP
         v_xor_stage_0(n) := s_data_bits(n*2) XOR s_data_bits((n*2)+1);
      END LOOP;
      v_xor_stage_1(0) := v_xor_stage_0(1) XOR v_xor_stage_0(0);
      v_xor_stage_1(1) := v_xor_stage_0(3) XOR v_xor_stage_0(2);
      s_data_parity    <= v_xor_stage_1(1) XOR v_xor_stage_1(0);
   END PROCESS make_data_parity;
   
--------------------------------
-- Here the filter is defined --
--------------------------------
   s_rx_neg_edge <= s_filtered_rx_delayed_reg AND NOT(s_filtered_rx_reg);

   make_rx_pipe_reg : PROCESS( clock , reset , baud_rate_x_16_tick , uart_rx )
   BEGIN
      IF (reset = '1') THEN s_rx_pipe_reg <= (OTHERS => '1');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (baud_rate_x_16_tick = '1') THEN
            s_rx_pipe_reg( 2 DOWNTO 1 ) <= s_rx_pipe_reg( 1 DOWNTO 0 );
            s_rx_pipe_reg( 0 )          <= uart_rx;
         END IF;
      END IF;
   END PROCESS make_rx_pipe_reg;  
   
   make_filtered_rx_regs : PROCESS( clock , reset , uart_rx , baud_rate_x_16_tick ,
                                    s_rx_pipe_reg )
      VARIABLE v_trigger : std_logic_vector( 3 DOWNTO 0 );
   BEGIN
      v_trigger := uart_rx&s_rx_pipe_reg;
      IF (reset = '1') THEN s_filtered_rx_delayed_reg <= '1';
                            s_filtered_rx_reg         <= '1';
      ELSIF (clock'event AND (clock = '1')) THEN
         s_filtered_rx_delayed_reg <= s_filtered_rx_reg;
         IF (baud_rate_x_16_tick = '1' AND
             v_trigger = X"0") THEN s_filtered_rx_reg <= '0';
         ELSIF (baud_rate_x_16_tick = '1' AND
                v_trigger = X"F") THEN s_filtered_rx_reg <= '1';
         END IF;
      END IF;
   END PROCESS make_filtered_rx_regs;

END behav;
