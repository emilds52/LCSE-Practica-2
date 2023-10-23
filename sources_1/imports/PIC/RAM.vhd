
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

library util;
USE util.PIC_pkg.all;

ENTITY ram IS
PORT (
   Clk      : in    std_logic;
   Reset    : in    std_logic;
   write_en : in    std_logic;
   oe       : in    std_logic;
   address  : in    std_logic_vector(7 downto 0);
   databus  : inout std_logic_vector(7 downto 0);
   Switches : out   std_logic_vector(7 downto 0);
   Temp_H   : out   std_logic_vector(6 downto 0);
   Temp_L   : out   std_logic_vector(6 downto 0)
);
END ram;

ARCHITECTURE behavior OF ram IS

  component RAMe
    port(
      Clk      : in    std_logic;
      Reset    : in    std_logic;
      write_en : in    std_logic;
      oe       : in    std_logic;
      address  : in    std_logic_vector(7 downto 0);
      databus  : inout std_logic_vector(7 downto 0);
      Switches : out   std_logic_vector(7 downto 0);
      Temp_H   : out   std_logic_vector(6 downto 0);
      Temp_L   : out   std_logic_vector(6 downto 0)
    );
  end component;

  component RAMg
    port(
      Clk      : in    std_logic;
      write_en : in    std_logic;
      oe       : in    std_logic;
      address  : in    std_logic_vector(7 downto 0);
      databus  : inout std_logic_vector(7 downto 0)
    );
  end component;

BEGIN

  RAM_especifica : RAMe
  port map (
    Clk      => Clk      ,
    Reset    => Reset    ,
    write_en => write_en ,
    oe       => oe       ,
    address  => address  ,
    databus  => databus  ,
    Switches => Switches , 
    Temp_H   => Temp_H   ,
    Temp_L   => Temp_L
  );

  RAM_generico : RAMg
  port map (
    Clk      => Clk      ,
    write_en => write_en ,
    oe       => oe       ,
    address  => address  ,
    databus  => databus
  );

END behavior;

