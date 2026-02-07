library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity acc_to_fifo_tb is
end entity;

architecture tb of acc_to_fifo_tb is

  constant clk_period : time := 10 ns;

  -- Top module generics
  constant FIFO_DEPTH : natural := 1024;
  constant SAMPLES_N  : natural := 1000;
  constant BATCHES_N  : natural := 5;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  -- Input stream
  signal din_valid : std_logic := '0';
  signal din       : std_logic_vector(7 downto 0) := (others => '0');

  -- Read side
  signal rd_en    : std_logic := '0';
  signal rd_valid : std_logic;
  signal rd_data  : std_logic_vector(17 downto 0);

  -- Flags
  signal empty : std_logic;
  signal full  : std_logic;

begin

  -- DUT: top module
  DUT : entity work.acc_to_fifo(rtl)
    generic map (
      FIFO_DEPTH => FIFO_DEPTH,
      SAMPLES_N  => SAMPLES_N,
      BATCHES_N  => BATCHES_N
    )
    port map (
      clk => clk,
      rst => rst,

      din_valid => din_valid,
      din       => din,

      rd_en    => rd_en,
      rd_valid => rd_valid,
      rd_data  => rd_data,

      empty => empty,
      full  => full
    );

  -- clock
  clk <= not clk after clk_period/2;

  -- Stimulus
  stim : process
    variable sent_samples : integer := 0;
    variable got_words    : integer := 0;
  begin
    -- reset
    wait for 10 * clk_period;
    rst <= '0';
    wait until rising_edge(clk);

    -- send 5000 samples (1000*5)
    din_valid <= '1';
    while sent_samples < (SAMPLES_N * BATCHES_N) loop
      din <= std_logic_vector(unsigned(din) + 1); -- 1,2,3... mod 256
      sent_samples := sent_samples + 1;
      wait until rising_edge(clk);
    end loop;
    din_valid <= '0';

    -- now read 5 accumulated results
    rd_en <= '1';
    while got_words < BATCHES_N loop
      wait until rising_edge(clk);
      if rd_valid = '1' then
        got_words := got_words + 1;
        -- İstersen burada expected check de ekleriz.
      end if;
    end loop;
    rd_en <= '0';

    wait for 20 * clk_period;
    finish;
  end process;

end architecture;
