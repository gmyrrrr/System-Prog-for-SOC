--------------------------------------------------------------------------------
-- $RCSfile: uart_bus_behavior.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.5 $
--           $Date: 2008/06/27 17:38:26 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_bus_behavior.vhdl,v $
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
--  $Log: uart_bus_behavior.vhdl,v $
--  Revision 1.5  2008/06/27 17:38:26  kluter
--  Changed multi-processor startup behavior and profiling indication.
--  The processors are now capable of starting up by a bit in a SPR, and
--  their jump address is also defined in an SPR. Now processor 1 can
--  enable in the bios which processor needs to start up, to which address they
--  should jump, and if they have their profiling module enabled or not.
--  However the current implemented software does not use all the posibilities
--  provided by the new hardware module, currently is does:
--  1) It enables ALL processors when USB download is complete.
--  2) It enables the profiling to ALL processors if profiling is requested.
--  3) It does not change any jump address, but uses the default address 0x100
--     for ALL processors.
--
--  Revision 1.4  2008/05/18 12:20:42  kluter
--  Added PS/2 Master interface
--
--  Revision 1.3  2008/05/16 11:11:08  kluter
--  Added UART to system template
--
--  Revision 1.2  2008/05/16 10:54:15  kluter
--  Fixed typo
--
--  Revision 1.1  2008/05/16 10:42:59  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

ARCHITECTURE behave OF uart_bus IS

   COMPONENT uart_fifo
      PORT ( reset            : IN  std_logic;
             clock            : IN  std_logic;
             fifo_re          : IN  std_logic;
             fifo_we          : IN  std_logic;
             fifo_full        : OUT std_logic;
             fifo_empty       : OUT std_logic;
             data_in          : IN  std_logic_vector( 7 DOWNTO 0 );
             data_out         : OUT std_logic_vector( 7 DOWNTO 0 ));
   END COMPONENT;
   
   COMPONENT uart_rx_fifo
      PORT ( reset            : IN  std_logic;
             clock            : IN  std_logic;
             fifo_re          : IN  std_logic;
             clear_error      : IN  std_logic;
             fifo_we          : IN  std_logic;
             fifo_full        : OUT std_logic;
             fifo_empty       : OUT std_logic;
             frame_error_in   : IN  std_logic;
             parity_error_in  : IN  std_logic;
             break_in         : IN  std_logic;
             data_in          : IN  std_logic_vector( 7 DOWNTO 0 );
             frame_error_out  : OUT std_logic;
             parity_error_out : OUT std_logic;
             break_out        : OUT std_logic;
             fifo_error       : OUT std_logic;
             nr_of_entries    : OUT std_logic_vector( 4 DOWNTO 0 );
             data_out         : OUT std_logic_vector( 7 DOWNTO 0 ));
   END COMPONENT;
   
   COMPONENT baud_rate_generator IS
      PORT( clock           : IN  std_logic;
            clock_50MHz     : IN  std_logic;
            reset           : IN  std_logic;
         
            baudDivisor     : IN  std_logic_vector( 15 DOWNTO 0 );
         
            baudRateX16Tick : OUT std_logic;
            baudRateX2Tick  : OUT std_logic);
   END COMPONENT;
   
   COMPONENT uart_tx_controller
      PORT( clock               : IN  std_logic;
            reset               : IN  std_logic;
            baud_rate_x_2_tick  : IN  std_logic;
            control_reg         : IN  std_logic_vector( 6 DOWNTO 0 );
            fifo_data           : IN  std_logic_vector( 7 DOWNTO 0 );
            fifo_empty          : IN  std_logic;
            fifo_read_ack       : OUT std_logic;
            uart_tx             : OUT std_logic;
            busy                : OUT std_logic);
   END COMPONENT;
   
   COMPONENT uart_rx_controler
      PORT( clock               : IN  std_logic;
            reset               : IN  std_logic;
            baud_rate_x_16_tick : IN  std_logic;
            uart_rx             : IN  std_logic;
            control_reg         : IN  std_logic_vector( 5 DOWNTO 0 );
            fifo_full           : IN  std_logic;
            fifo_data           : OUT std_logic_vector( 7 DOWNTO 0 );
            fifo_we             : OUT std_logic;
            frame_error         : OUT std_logic;
            break_detected      : OUT std_logic;
            parity_error        : OUT std_logic;
            overrun_error       : OUT std_logic);
   END COMPONENT;
   
   SIGNAL s_bus_address_reg        : std_logic_vector(31 DOWNTO 0 );
   SIGNAL s_read_n_write_reg       : std_logic;
   SIGNAL s_transaction_active_reg : std_logic;
   SIGNAL s_start_transaction_reg  : std_logic;
   SIGNAL s_burst_size_reg         : std_logic_vector( 2 DOWNTO 0 );
   SIGNAL s_is_my_transaction      : std_logic;
   SIGNAL s_bus_data_in_reg        : std_logic_vector(31 DOWNTO 0 );
   SIGNAL s_bus_data_in_valid_reg  : std_logic;
   SIGNAL s_write_burst_count_reg  : std_logic_vector( 2 DOWNTO 0 );
   SIGNAL s_read_value             : std_logic_vector(31 DOWNTO 0 );
   SIGNAL s_read_burst_active_reg  : std_logic;
   SIGNAL s_read_burst_count_reg   : std_logic_vector( 2 DOWNTO 0 );
   SIGNAL s_data_out_reg           : std_logic_vector(31 DOWNTO 0 );
   SIGNAL s_data_valid_out_reg     : std_logic;
   SIGNAL s_end_trans_reg          : std_logic;

   SIGNAL s_baud_rate_x_16_tick    : std_logic;
   SIGNAL s_baud_rate_x_2_tick     : std_logic;

   SIGNAL s_we_regs_vector         : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_line_control_reg       : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_divisor_reg            : std_logic_vector(15 DOWNTO 0 );
   SIGNAL s_scratch_reg            : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_receiver_buffer_reg    : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_modem_control_reg      : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_line_status_reg        : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_interrupt_enable_reg   : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_fifo_control_reg       : std_logic_vector( 7 DOWNTO 6 );
   SIGNAL s_interrupt_ident_reg    : std_logic_vector( 7 DOWNTO 0 );

   SIGNAL s_uart_rx                : std_logic;
   SIGNAL s_uart_rx_reg            : std_logic;
   SIGNAL s_uart_tx                : std_logic;
   SIGNAL s_uart_tx_next           : std_logic;
   SIGNAL s_rx_fifo_full           : std_logic;
   SIGNAL s_rx_fifo_empty          : std_logic;
   SIGNAL s_rx_fifo_data           : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_rx_fifo_we             : std_logic;
   SIGNAL s_rx_frame_error         : std_logic;
   SIGNAL s_rx_break_detected      : std_logic;
   SIGNAL s_rx_parity_error        : std_logic;
   SIGNAL s_overrun_error          : std_logic;
   SIGNAL s_rx_fifo_re_reg         : std_logic;
   SIGNAL s_clear_error            : std_logic;
   SIGNAL s_reset_rx_fifo          : std_logic;
   SIGNAL s_reset_tx_fifo          : std_logic;
   SIGNAL s_tx_fifo_full           : std_logic;
   SIGNAL s_tx_fifo_we             : std_logic;
   SIGNAL s_tx_fifo_data           : std_logic_vector( 7 DOWNTO 0 );
   SIGNAL s_tx_fifo_empty          : std_logic;
   SIGNAL s_tx_fifo_re             : std_logic;
   SIGNAL s_tx_busy                : std_logic;
   SIGNAL s_nr_rx_bytes            : std_logic_vector( 4 DOWNTO 0 );
   
   SIGNAL s_line_status_irq        : std_logic;
   SIGNAL s_rx_available_irq       : std_logic;
   SIGNAL s_tx_empty_edge_reg      : std_logic_vector( 1 DOWNTO 0 );
   SIGNAL s_tx_empty_irq           : std_logic;

BEGIN
-- Assign outputs
   irq <= s_line_status_irq OR s_rx_available_irq OR s_tx_empty_irq;

-- Assign control signals
   s_uart_rx           <= s_uart_rx_reg WHEN s_modem_control_reg(4) = '0' ELSE
                          s_uart_tx;
   s_uart_tx_next      <= s_uart_tx OR s_modem_control_reg(4);
   s_we_regs_vector(0) <= '1' WHEN s_bus_data_in_valid_reg = '1' AND
                                   s_write_burst_count_reg = "000" AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "000" ELSE '0';
   s_we_regs_vector(1) <= '1' WHEN s_bus_data_in_valid_reg = '1' AND
                                   s_write_burst_count_reg = "000" AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "001" ELSE '0';
   s_we_regs_vector(2) <= '1' WHEN s_bus_data_in_valid_reg = '1' AND
                                   s_write_burst_count_reg = "000" AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "010" ELSE '0';
   s_we_regs_vector(3) <= '1' WHEN s_bus_data_in_valid_reg = '1' AND
                                   s_write_burst_count_reg = "000" AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "011" ELSE '0';
   s_we_regs_vector(4) <= '1' WHEN s_bus_data_in_valid_reg = '1' AND
                                   s_write_burst_count_reg = "000" AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "100" ELSE '0';
   s_we_regs_vector(5) <= '1' WHEN s_bus_data_in_valid_reg = '1' AND
                                   s_write_burst_count_reg = "000" AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "101" ELSE '0';
   s_we_regs_vector(6) <= '1' WHEN s_bus_data_in_valid_reg = '1' AND
                                   s_write_burst_count_reg = "000" AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "110" ELSE '0';
   s_we_regs_vector(7) <= '1' WHEN s_bus_data_in_valid_reg = '1' AND
                                   s_write_burst_count_reg = "000" AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "111" ELSE '0';
   s_clear_error       <= '1' WHEN s_read_burst_active_reg = '1' AND
                                   s_read_burst_count_reg = s_burst_size_reg AND
                                   s_bus_address_reg( 2 DOWNTO 0 ) = "101" AND
                                   busy_in = '1' ELSE '0';
   s_reset_rx_fifo     <= '1' WHEN reset = '1' OR
                                   (s_we_regs_vector(2) = '1' AND
                                    s_bus_data_in_reg(17) = '1') ELSE '0';
   s_reset_tx_fifo     <= '1' WHEN reset = '1' OR
                                   (s_we_regs_vector(2) = '1' AND
                                    s_bus_data_in_reg(18) = '1') ELSE '0';
   s_tx_fifo_we        <= '1' WHEN s_tx_fifo_full = '0' AND
                                   s_we_regs_vector(0) = '1' AND
                                   s_line_control_reg(7) = '0' ELSE '0';
   
   -- Map processes 
   make_rx_fifo_re_reg : PROCESS( clock , reset , s_read_burst_active_reg , s_read_burst_count_reg ,
                                  s_bus_address_reg , s_rx_fifo_empty , s_burst_size_reg , busy_in )
   BEGIN
      IF (reset = '1') THEN s_rx_fifo_re_reg <= '0';
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_read_burst_active_reg = '1' AND
             s_read_burst_count_reg = s_burst_size_reg AND
             s_bus_address_reg( 2 DOWNTO 0 ) = "000" AND
             busy_in = '0') THEN s_rx_fifo_re_reg <= NOT(s_rx_fifo_empty);
                              ELSE s_rx_fifo_re_reg <= '0';
         END IF;
      END IF;
   END PROCESS make_rx_fifo_re_reg;
                                   
-----------------------------------------
-- Here all uart registers are defined --
-----------------------------------------
   s_modem_control_reg( 3 DOWNTO 0 )  <= (OTHERS => '0');
   s_modem_control_reg( 7 DOWNTO 5 )  <= (OTHERS => '0');
   s_line_status_reg(0)               <= NOT(s_rx_fifo_empty);
   s_line_status_reg(5)               <= s_tx_fifo_empty;
   s_line_status_reg(6)               <= s_tx_fifo_empty AND NOT( s_tx_busy ); 
   s_interrupt_enable_reg(7 DOWNTO 3) <= (OTHERS => '0');
   s_interrupt_ident_reg(7 DOWNTO 3)  <= "11000";
   s_interrupt_ident_reg(2)           <= s_line_status_irq OR s_rx_available_irq;
   s_interrupt_ident_reg(1)           <= s_line_status_irq OR s_tx_empty_irq;
   s_interrupt_ident_reg(0)           <= NOT( s_line_status_irq OR s_rx_available_irq OR
                                              s_tx_empty_irq );
   
   make_line_control_reg : PROCESS( clock , reset , s_we_regs_vector , s_bus_data_in_reg )
   BEGIN
      IF (reset = '1') THEN s_line_control_reg <= (OTHERS => '0');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_we_regs_vector(3) = '1') THEN
            s_line_control_reg <= s_bus_data_in_reg( 31 DOWNTO 24 );
         END IF;
      END IF;
   END PROCESS make_line_control_reg;
   
   make_divisor_latch : PROCESS( clock , reset , s_we_regs_vector , s_bus_data_in_reg ,
                                 s_line_control_reg )
   BEGIN
      IF (reset = '1') THEN s_divisor_reg <= (OTHERS => '0');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_we_regs_vector(0) = '1' AND
             s_line_control_reg(7) = '1') THEN 
            s_divisor_reg( 7 DOWNTO 0 ) <= s_bus_data_in_reg( 7 DOWNTO 0 );
         END IF;
         IF (s_we_regs_vector(1) = '1' AND
             s_line_control_reg(7) = '1') THEN 
            s_divisor_reg(15 DOWNTO 8 ) <= s_bus_data_in_reg(15 DOWNTO 8 );
         END IF;
      END IF;
   END PROCESS make_divisor_latch;
   
   make_scratch_reg : PROCESS( clock , reset , s_we_regs_vector , s_bus_data_in_reg )
   BEGIN
      IF (reset = '1') THEN s_scratch_reg <= (OTHERS => '0');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_we_regs_vector(7) = '1') THEN
            s_scratch_reg <= s_bus_data_in_reg( 31 DOWNTO 24 );
         END IF;
      END IF;
   END PROCESS make_scratch_reg;
   
   make_modem_control_reg : PROCESS( clock , reset , s_we_regs_vector , s_bus_data_in_reg )
   BEGIN
      IF (reset = '1') THEN s_modem_control_reg(4) <= '0';
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_we_regs_vector(4) = '1') THEN
            s_modem_control_reg(4) <= s_bus_data_in_reg(4);
         END IF;
      END IF;
   END PROCESS make_modem_control_reg;
   
   make_line_status_reg_1 : PROCESS( clock , s_overrun_error , s_clear_error , s_reset_rx_fifo )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (s_clear_error = '1' OR
             s_reset_rx_fifo = '1') THEN s_line_status_reg(1) <= '0';
                                    ELSE
            s_line_status_reg(1) <= s_line_status_reg(1) OR s_overrun_error;
         END IF;
      END IF;
   END PROCESS make_line_status_reg_1;
   
   make_interrupt_enable_reg : PROCESS( clock , reset , s_we_regs_vector , s_bus_data_in_reg )
   BEGIN
      IF (reset = '1') THEN s_interrupt_enable_reg( 2 DOWNTO 0 ) <= (OTHERS => '0');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_we_regs_vector(1) = '1' AND
             s_line_control_reg(7) = '0') THEN
            s_interrupt_enable_reg( 2 DOWNTO 0 ) <= s_bus_data_in_reg( 18 DOWNTO 16 );
         END IF;
      END IF;
   END PROCESS make_interrupt_enable_reg;
   
   make_fifo_control_reg : PROCESS( clock , reset , s_we_regs_vector , s_bus_data_in_reg )
   BEGIN
      IF (reset = '1') THEN s_fifo_control_reg <= (OTHERS => '0');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_we_regs_vector(2) = '1') THEN
            s_fifo_control_reg <= s_bus_data_in_reg(23 DOWNTO 22);
         END IF;
      END IF;
   END PROCESS make_fifo_control_reg;
   
-------------------------------
-- Here the IRQs are defined --
-------------------------------
   make_line_status_irq : PROCESS( clock , reset , s_line_status_reg , s_clear_error , s_interrupt_enable_reg )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (reset = '1' OR
             s_clear_error = '1') THEN s_line_status_irq <= '0';
         ELSE s_line_status_irq <= (s_line_status_irq OR s_line_status_reg(3) OR
                                    s_line_status_reg(2) OR s_line_status_reg(4) OR
                                    s_line_status_reg(1)) AND s_interrupt_enable_reg(2);
         END IF;
      END IF;
   END PROCESS make_line_status_irq;
   
   make_rx_available_irq : PROCESS( s_nr_rx_bytes , s_fifo_control_reg ,
                                    reset , clock , s_interrupt_enable_reg )
   BEGIN
      IF (reset = '1') THEN s_rx_available_irq <= '0';
      ELSIF (clock'event AND (clock = '1')) THEN
         CASE (s_fifo_control_reg) IS
            WHEN  "00"  => s_rx_available_irq <= (s_nr_rx_bytes(4) OR s_nr_rx_bytes(3) OR
                                                  s_nr_rx_bytes(2) OR s_nr_rx_bytes(1) OR
                                                  s_nr_rx_bytes(0)) AND 
                                                 s_interrupt_enable_reg(0);
            WHEN  "01"  => s_rx_available_irq <= (s_nr_rx_bytes(4) OR s_nr_rx_bytes(3) OR
                                                  s_nr_rx_bytes(2)) AND 
                                                 s_interrupt_enable_reg(0);
            WHEN  "10"  => s_rx_available_irq <= (s_nr_rx_bytes(4) OR s_nr_rx_bytes(3)) AND
                                                 s_interrupt_enable_reg(0);
            WHEN OTHERS => IF (s_nr_rx_bytes(4) = '1' OR
                               s_nr_rx_bytes(4 DOWNTO 1) = "0111") THEN s_rx_available_irq <= s_interrupt_enable_reg(0);
                                                                   ELSE s_rx_available_irq <= '0';
                           END IF;
         END CASE; 
      END IF;
   END PROCESS make_rx_available_irq;
   
   make_tx_empty_edge_reg : PROCESS( clock , reset , s_line_status_reg )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (reset = '1') THEN s_tx_empty_edge_reg <= "00";
         ELSE s_tx_empty_edge_reg(1) <= s_tx_empty_edge_reg(0);
              s_tx_empty_edge_reg(0) <= s_line_status_reg(6);
         END IF;
      END IF;
   END PROCESS make_tx_empty_edge_reg;
   
   make_tx_empty_irq : PROCESS( clock , reset , s_tx_empty_edge_reg , s_interrupt_enable_reg ,
                                s_read_burst_active_reg , s_read_burst_count_reg , s_burst_size_reg ,
                                s_bus_address_reg , busy_in , s_rx_available_irq , s_line_status_irq )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (reset = '1' OR s_tx_fifo_we = '1' OR
             (s_read_burst_active_reg = '1' AND
              s_read_burst_count_reg = s_burst_size_reg AND
              s_bus_address_reg( 2 DOWNTO 0 ) = "010" AND
              busy_in = '1' AND
              s_rx_available_irq = '0' AND
              s_line_status_irq = '0')) THEN s_tx_empty_irq <= '0';
         ELSIF (s_tx_empty_edge_reg = "01") THEN s_tx_empty_irq <= s_interrupt_enable_reg(1);
         END IF;
      END IF;
   END PROCESS make_tx_empty_irq;
   
----------------------------------------------
-- Here the bus related signals are defined --
----------------------------------------------
   s_read_value(31 DOWNTO 24) <= s_scratch_reg WHEN s_bus_address_reg(2) = '1' ELSE
                                 s_line_control_reg;
   s_read_value(23 DOWNTO 16) <= (OTHERS => '0') WHEN s_bus_address_reg(2) = '1' ELSE
                                 s_interrupt_ident_reg;
   s_read_value(15 DOWNTO  8) <= s_line_status_reg      WHEN s_bus_address_reg(2)  = '1' ELSE
                                 s_interrupt_enable_reg WHEN s_line_control_reg(7) = '0' ELSE
                                 s_divisor_reg( 15 DOWNTO 8 );
   s_read_value( 7 DOWNTO  0) <= s_modem_control_reg   WHEN s_bus_address_reg(2)  = '1' ELSE
                                 s_receiver_buffer_reg WHEN s_line_control_reg(7) = '0' ELSE
                                 s_divisor_reg( 7 DOWNTO 0 );

   -- Assign outputs
   address_data_out      <= s_data_out_reg;
   data_valid_out        <= s_data_valid_out_reg;
   end_transaction_out   <= s_end_trans_reg;

   -- Assign control signals
   s_is_my_transaction <= '1' WHEN s_transaction_active_reg = '1' AND
                                   s_bus_address_reg(31 DOWNTO 3) = 
                                   base_address(31 DOWNTO 3) ELSE '0';
   
   -- Map processes
   make_start_transaction_reg : PROCESS( clock , reset , begin_transaction_in )
   BEGIN
      IF (reset = '1') THEN s_start_transaction_reg <= '0';
      ELSIF (clock'event AND (clock = '1')) THEN
         s_start_transaction_reg <= begin_transaction_in;
      END IF;
   END PROCESS make_start_transaction_reg;
   
   make_transaction_active_reg : PROCESS( clock , reset , begin_transaction_in ,
                                          end_transaction_in )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (end_transaction_in = '1' OR
             reset = '1') THEN s_transaction_active_reg <= '0';
         ELSIF (begin_transaction_in = '1') THEN 
             s_transaction_active_reg <= '1';
         END IF;
      END IF;
   END PROCESS make_transaction_active_reg;
   
   make_bus_regs : PROCESS( clock , reset , begin_transaction_in ,
                            address_data_in , read_n_write_in , byte_enables_in,
                            burst_size_in )
   BEGIN
      IF (reset = '1') THEN s_read_n_write_reg <= '0';
                            s_burst_size_reg   <= (OTHERS => '0');
                            s_bus_address_reg  <= (OTHERS => '0');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (begin_transaction_in = '1') THEN
            s_read_n_write_reg <= read_n_write_in;
            s_burst_size_reg   <= burst_size_in;
            s_bus_address_reg  <= address_data_in;
         END IF;
      END IF;
   END PROCESS make_bus_regs;
   
   make_bus_data_in_regs : PROCESS( clock , reset , busy_in , data_valid_in ,
                                    address_data_in ,
                                    s_is_my_transaction , s_read_n_write_reg )
   BEGIN
      IF (reset = '1') THEN s_bus_data_in_valid_reg <= '0';
                            s_bus_data_in_reg       <= (OTHERS => '0');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_is_my_transaction = '1' AND
             s_read_n_write_reg = '0' AND
             data_valid_in = '1' AND
             busy_in = '0') THEN 
            s_bus_data_in_valid_reg <= '1';
            s_bus_data_in_reg <= address_data_in;
                              ELSE s_bus_data_in_valid_reg <= '0';
         END IF;
      END IF;
   END PROCESS make_bus_data_in_regs;
   
   make_read_burst_count_reg : PROCESS( clock , reset , s_start_transaction_reg , s_read_burst_active_reg ,
                                        busy_in )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (s_start_transaction_reg = '1' OR
             reset = '1') THEN s_read_burst_count_reg <= (OTHERS => '0');
         ELSIF (s_read_burst_active_reg = '1' AND
                busy_in = '0') THEN
            s_read_burst_count_reg <= unsigned(s_read_burst_count_reg) + 1;
         END IF;
      END IF;
   END PROCESS make_read_burst_count_reg;
   
   make_write_burst_count_reg : PROCESS( clock , reset , s_start_transaction_reg , s_bus_data_in_valid_reg )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (s_start_transaction_reg = '1' OR
             reset = '1') THEN s_write_burst_count_reg <= (OTHERS => '0');
         ELSIF (s_bus_data_in_valid_reg = '1') THEN
            s_write_burst_count_reg <= unsigned(s_write_burst_count_reg) + 1;
         END IF;
      END IF;
   END PROCESS make_write_burst_count_reg;
   
   make_read_burst_active_reg : PROCESS( clock , reset , s_start_transaction_reg , s_read_burst_count_reg ,
                                         busy_in , s_is_my_transaction ,  
                                         s_read_n_write_reg , s_burst_size_reg ,
                                         end_transaction_in )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (s_start_transaction_reg = '1' AND
             s_is_my_transaction = '1' AND
             s_read_n_write_reg = '1') THEN s_read_burst_active_reg <= '1';
         ELSIF (end_transaction_in = '1' OR
                (s_read_burst_count_reg = s_burst_size_reg AND
                 busy_in = '0') OR
                reset = '1') THEN s_read_burst_active_reg <= '0';
         END IF;
      END IF;
   END PROCESS make_read_burst_active_reg;
   
   make_data_out_regs : PROCESS( clock , s_read_burst_active_reg , s_read_value )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (s_read_burst_active_reg = '1') THEN 
            s_data_valid_out_reg <= '1';
            s_data_out_reg         <= s_read_value;
                                            ELSE 
            s_data_valid_out_reg <= '0';
            s_data_out_reg         <= (OTHERS => '0');
         END IF;
      END IF;
   END PROCESS make_data_out_regs;
   
   make_n_end_trans_reg : PROCESS( clock , s_read_burst_active_reg , 
                                   s_data_valid_out_reg )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (s_read_burst_active_reg = '0' AND
             s_data_valid_out_reg = '1') THEN s_end_trans_reg <= '1';
                                         ELSE s_end_trans_reg <= '0';
         END IF;
      END IF;
   END PROCESS make_n_end_trans_reg;

------------------------------------------
-- Here all component mappings are done --
------------------------------------------   
   BRG : baud_rate_generator
         PORT MAP ( clock           => clock,
                    clock_50MHz     => clock_50MHz,
                    reset           => reset,
                    baudDivisor     => s_divisor_reg,
                    baudRateX16Tick => s_baud_rate_x_16_tick,
                    baudRateX2Tick  => s_baud_rate_x_2_tick);
                    
   RXF : uart_rx_fifo
         PORT MAP ( reset            => s_reset_rx_fifo,
                    clock            => clock,
                    fifo_re          => s_rx_fifo_re_reg,
                    clear_error      => s_clear_error,
                    fifo_we          => s_rx_fifo_we,
                    fifo_full        => s_rx_fifo_full,
                    fifo_empty       => s_rx_fifo_empty,
                    frame_error_in   => s_rx_frame_error,
                    parity_error_in  => s_rx_parity_error,
                    break_in         => s_rx_break_detected,
                    data_in          => s_rx_fifo_data,
                    frame_error_out  => s_line_status_reg(3),
                    parity_error_out => s_line_status_reg(2),
                    break_out        => s_line_status_reg(4),
                    fifo_error       => s_line_status_reg(7),
                    nr_of_entries    => s_nr_rx_bytes,
                    data_out         => s_receiver_buffer_reg);

   RXC : uart_rx_controler
         PORT MAP ( clock               => clock,
                    reset               => reset,
                    baud_rate_x_16_tick => s_baud_rate_x_16_tick,
                    uart_rx             => s_uart_rx,
                    control_reg         => s_line_control_reg( 5 DOWNTO 0 ),
                    fifo_full           => s_rx_fifo_full,
                    fifo_data           => s_rx_fifo_data,
                    fifo_we             => s_rx_fifo_we,
                    frame_error         => s_rx_frame_error,
                    break_detected      => s_rx_break_detected,
                    parity_error        => s_rx_parity_error,
                    overrun_error       => s_overrun_error);
   
   TXF : uart_fifo
         PORT MAP ( reset            => s_reset_tx_fifo,
                    clock            => clock,
                    fifo_re          => s_tx_fifo_re,
                    fifo_we          => s_tx_fifo_we,
                    fifo_full        => s_tx_fifo_full,
                    fifo_empty       => s_tx_fifo_empty,
                    data_in          => s_bus_data_in_reg( 7 DOWNTO 0 ),
                    data_out         => s_tx_fifo_data);

   TXC : uart_tx_controller
         PORT MAP ( clock               => clock,
                    reset               => reset,
                    baud_rate_x_2_tick  => s_baud_rate_x_2_tick,
                    control_reg         => s_line_control_reg( 6 DOWNTO 0 ),
                    fifo_data           => s_tx_fifo_data,
                    fifo_empty          => s_tx_fifo_empty,
                    fifo_read_ack       => s_tx_fifo_re,
                    uart_tx             => s_uart_tx,
                    busy                => s_tx_busy );


   make_ffs : PROCESS (clock)
   BEGIN
      IF (rising_edge(clock)) THEN
         IF (reset = '1') THEN s_uart_rx_reg <= '1';
                               TxD           <= '1';
                          ELSE s_uart_rx_reg <= RxD;
                               TxD           <= s_uart_tx_next;
         END IF;
      END IF;
   END PROCESS make_ffs;

END behave;
