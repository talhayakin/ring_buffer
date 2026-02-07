library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity acc_to_fifo is
  generic (
    FIFO_DEPTH : natural := 1024;
    SAMPLES_N  : natural := 1000;
    BATCHES_N  : natural := 5
  );
  port (
    clk : in std_logic;
    rst : in std_logic;

    din_valid : in std_logic;
    din       : in std_logic_vector(7 downto 0);

    rd_en    : in std_logic;
    rd_valid : out std_logic;
    rd_data  : out std_logic_vector(17 downto 0);

    empty : out std_logic;
    full  : out std_logic
  );
end entity;

architecture rtl of acc_to_fifo is

  signal wr_en   : std_logic := '0';
  signal wr_data : std_logic_vector(17 downto 0) := (others => '0');

  signal empty_next : std_logic;
  signal full_next  : std_logic;
  signal fill_count : integer range 0 to FIFO_DEPTH-1;

  signal empty_i : std_logic;
  signal full_i  : std_logic;

  signal sum        : unsigned(17 downto 0) := (others => '0');
  signal sample_cnt : integer range 0 to SAMPLES_N-1 := 0;
  signal batch_cnt  : integer range 0 to BATCHES_N   := 0;

begin

  empty <= empty_i;
  full  <= full_i;

  u_fifo : entity work.buffer_ring
    generic map (
      RAM_WIDTH => 18,
      RAM_DEPTH => FIFO_DEPTH
    )
    port map (
      clk => clk,
      rst => rst,

      wr_en   => wr_en,
      wr_data => wr_data,

      rd_en    => rd_en,
      rd_valid => rd_valid,
      rd_data  => rd_data,

      empty      => empty_i,
      empty_next => empty_next,
      full       => full_i,
      full_next  => full_next,

      fill_count => fill_count
    );

  process(clk)
    variable next_sum : unsigned(17 downto 0);
  begin
    if rising_edge(clk) then
      -- ✅ her clock default: yazma yok (tek driver burada!)
      wr_en <= '0';

      if rst = '1' then
        sum        <= (others => '0');
        sample_cnt <= 0;
        batch_cnt  <= 0;
        wr_data    <= (others => '0');
      else
        if batch_cnt < BATCHES_N then
          if din_valid = '1' then
            next_sum := sum + unsigned(din);

            if sample_cnt = SAMPLES_N-1 then
              if full_i = '0' then
                wr_en   <= '1';
                wr_data <= std_logic_vector(next_sum);

                sum        <= (others => '0');
                sample_cnt <= 0;
                batch_cnt  <= batch_cnt + 1;
              else
                -- FIFO full ise bekle
                sum        <= sum;
                sample_cnt <= sample_cnt;
              end if;
            else
              sum        <= next_sum;
              sample_cnt <= sample_cnt + 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture;
