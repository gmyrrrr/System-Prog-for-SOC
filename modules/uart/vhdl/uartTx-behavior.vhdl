--------------------------------------------------------------------------------
-- $RCSfile: uart_tx.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.2 $
--           $Date: 2008/05/16 10:51:34 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_tx.vhdl,v $
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
--  $Log: uart_tx.vhdl,v $
--  Revision 1.2  2008/05/16 10:51:34  kluter
--  Fixed typo
--
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

ARCHITECTURE behav OF uart_tx_controller IS

  SIGNAL s_parity                    : std_logic;
  SIGNAL s_parity_bit                : std_logic;
  SIGNAL s_shift_reg                 : std_logic_vector(9 DOWNTO 0);
  SIGNAL s_shift_load_value          : std_logic_vector(9 DOWNTO 0);
  SIGNAL s_shifter_load              : std_logic;
  SIGNAL s_shifter_do_shift          : std_logic;
  SIGNAL s_tx_reg                    : std_logic;
  SIGNAL s_half_bit_count_load_value : std_logic_vector( 4 DOWNTO 0 );
  SIGNAL s_half_bit_count_reg        : std_logic_vector( 4 DOWNTO 0 );
  SIGNAL s_state_machine_reg         : std_logic_vector( 1 DOWNTO 0 );
  SIGNAL s_bit_done_reg              : std_logic;
  SIGNAL s_read_ack_reg              : std_logic;

BEGIN
-- Assign outputs
   uart_tx          <= s_tx_reg;
   fifo_read_ack    <= s_read_ack_reg;
   busy             <= '0' WHEN s_state_machine_reg = "00" ELSE '1';

-- Assign control_signals
   s_shifter_do_shift    <= s_bit_done_reg AND baud_rate_x_2_tick;
   s_shifter_load        <= '1' WHEN s_state_machine_reg = "01" AND
                                     baud_rate_x_2_tick = '1' ELSE
                            '0';
   s_parity_bit          <= '1' WHEN control_reg(3) = '0' ELSE
                            NOT(control_reg(4)) WHEN control_reg(5) = '1' ELSE
                            s_parity;
   s_shift_load_value(9) <= '0';
   s_shift_load_value(8) <= fifo_data(0);
   s_shift_load_value(7) <= fifo_data(1);
   s_shift_load_value(6) <= fifo_data(2);
   s_shift_load_value(5) <= fifo_data(3);
   s_shift_load_value(4) <= fifo_data(4);
   s_shift_load_value(3) <= s_parity_bit WHEN control_reg(1 DOWNTO 0) = "00" ELSE
                            fifo_data(5);
   s_shift_load_value(2) <= s_parity_bit WHEN control_reg(1 DOWNTO 0) = "01" ELSE
                            fifo_data(6) WHEN control_reg(1) = '1' ELSE
                            '1';
   s_shift_load_value(1) <= s_parity_bit WHEN control_reg(1 DOWNTO 0) = "10" ELSE
                            fifo_data(7) WHEN control_reg(1 DOWNTO 0) = "11" ELSE
                            '1';
   s_shift_load_value(0) <= s_parity_bit;
   
-- Assign processes
   make_shifter : PROCESS( reset , clock , s_shift_reg ,
                           s_shift_load_value , s_shifter_load ,
                           s_shifter_do_shift )
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_shift_reg <= (OTHERS => '1');
         ELSIF (s_shifter_load = '1') THEN s_shift_reg <= s_shift_load_value;
         ELSIF (s_shifter_do_shift = '1') THEN s_shift_reg <= s_shift_reg(8 DOWNTO 0)&"1";
         END IF;
      END IF;
   END PROCESS make_shifter;
 

   make_tx_reg : PROCESS( reset , clock , s_shift_reg , control_reg )
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_tx_reg <= '1';
                          ELSE s_tx_reg <= s_shift_reg(9) AND 
                               NOT( control_reg(6) );
         END IF;
      END IF;
   END PROCESS make_tx_reg;

   make_parity : PROCESS( fifo_data , control_reg )
      VARIABLE v_xor_stage_1 : std_logic_vector( 3 DOWNTO 0 );
      VARIABLE v_mux_1       : std_logic;
      VARIABLE v_xor_stage_2 : std_logic_vector( 1 DOWNTO 0 );
      VARIABLE v_mux_2       : std_logic;
      VARIABLE v_xor_stage_3 : std_logic;
   BEGIN
      FOR n IN 3 DOWNTO 0 LOOP
         v_xor_stage_1(n) := fifo_data(n*2) XOR fifo_data((n*2)+1);
      END LOOP;
      IF (control_reg(0) = '0') THEN v_mux_1 := fifo_data(6);
                                ELSE v_mux_1 := v_xor_stage_1(3);
      END IF;
      v_xor_stage_2(0) := v_xor_stage_1(0) XOR v_xor_stage_1(1);
      v_xor_stage_2(1) := v_xor_stage_1(2) XOR v_mux_1;
      CASE control_reg( 1 DOWNTO 0) IS
         WHEN  "00"  => v_mux_2 := fifo_data(4);
         WHEN  "01"  => v_mux_2 := v_xor_stage_1(2);
         WHEN OTHERS => v_mux_2 := v_xor_stage_2(1);
      END CASE;
      v_xor_stage_3 := v_mux_2 XOR v_xor_stage_2(0);
      s_parity <= NOT(v_xor_stage_3 XOR control_reg(4));
   END PROCESS make_parity;
   
   make_hb_load_value : PROCESS( control_reg )
   BEGIN
      CASE control_reg( 3 DOWNTO 0 ) IS
         WHEN "0000" => s_half_bit_count_load_value <= "01110"; --  7.0*2
         WHEN "0001" => s_half_bit_count_load_value <= "10000"; --  8.0*2
         WHEN "0010" => s_half_bit_count_load_value <= "10010"; --  9.0*2
         WHEN "0011" => s_half_bit_count_load_value <= "10100"; -- 10.0*2
         WHEN "0100" => s_half_bit_count_load_value <= "01111"; --  7.5*2
         WHEN "0101" => s_half_bit_count_load_value <= "10010"; --  9.0*2
         WHEN "0110" => s_half_bit_count_load_value <= "10100"; -- 10.0*2
         WHEN "0111" => s_half_bit_count_load_value <= "10110"; -- 11.0*2
         WHEN "1000" => s_half_bit_count_load_value <= "10000"; --  8.0*2
         WHEN "1001" => s_half_bit_count_load_value <= "10010"; --  9.0*2
         WHEN "1010" => s_half_bit_count_load_value <= "10100"; -- 10.0*2
         WHEN "1011" => s_half_bit_count_load_value <= "10110"; -- 11.0*2
         WHEN "1100" => s_half_bit_count_load_value <= "10001"; --  8.5*2
         WHEN "1101" => s_half_bit_count_load_value <= "10100"; -- 10.0*2
         WHEN "1110" => s_half_bit_count_load_value <= "10110"; -- 11.0*2
         WHEN OTHERS => s_half_bit_count_load_value <= "11000"; -- 12.0*2
      END CASE;
   END PROCESS make_hb_load_value;
   
   make_hb_count_reg : PROCESS( clock , reset , baud_rate_x_2_tick ,
                                s_state_machine_reg , s_half_bit_count_load_value ,
                                s_half_bit_count_reg )
      VARIABLE v_next_count_value : std_logic_vector( 4 DOWNTO 0 );
   BEGIN
      IF (s_state_machine_reg = "01") THEN v_next_count_value := s_half_bit_count_load_value;
      ELSIF (s_half_bit_count_reg = "00000") THEN v_next_count_value := "00000";
      ELSE v_next_count_value := unsigned(s_half_bit_count_reg) - 1;
      END IF;
      
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_half_bit_count_reg <= (OTHERS => '0');
         ELSIF (baud_rate_x_2_tick = '1') THEN s_half_bit_count_reg <= v_next_count_value;
         END IF;
      END IF;
   END PROCESS make_hb_count_reg;
   
   make_bit_done_reg : PROCESS( clock , baud_rate_x_2_tick ,
                                s_state_machine_reg )
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (s_state_machine_reg(1) = '0') THEN s_bit_done_reg <= '0';
                                           ELSE s_bit_done_reg <= s_bit_done_reg XOR baud_rate_x_2_tick;
         END IF;
      END IF;
   END PROCESS make_bit_done_reg;
   
   make_read_ack : PROCESS( clock , reset , s_shifter_load )
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_read_ack_reg <= '0';
                          ELSE s_read_ack_reg <= s_shifter_load;
         END IF;
      END IF;
   END PROCESS make_read_ack;
   
   make_state_machine : PROCESS( clock , reset , 
                                 fifo_empty , baud_rate_x_2_tick ,
                                 s_half_bit_count_reg , s_state_machine_reg )
      VARIABLE v_next_state : std_logic_vector( 1 DOWNTO 0 );
   BEGIN
      CASE s_state_machine_reg IS
         WHEN  "00"  => IF (fifo_empty = '0') THEN v_next_state := "01";
                                              ELSE v_next_state := "00";
                        END IF;
         WHEN  "01"  => IF (baud_rate_x_2_tick = '1') THEN v_next_state := "11";
                                                      ELSE v_next_state := "01";
                        END IF;
         WHEN  "11"  => IF (s_half_bit_count_reg = "00001" AND
                            fifo_empty = '1') THEN v_next_state := "00";
                        ELSIF (s_half_bit_count_reg = "00001" AND
                               fifo_empty = '0') THEN v_next_state := "01";
                                                 ELSE v_next_state := "11";
                        END IF;
         WHEN OTHERS => v_next_state := "00";
      END CASE;
      
      IF (clock'event AND clock = '1') THEN
         IF (reset = '1') THEN s_state_machine_reg <= "00";
                          ELSE s_state_machine_reg <= v_next_state;
         END IF;
      END IF;
   END PROCESS make_state_machine;
END behav;
         
         
