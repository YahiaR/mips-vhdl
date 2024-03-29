
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_LOGIC_arith.ALL;
use IEEE.std_logic_unsigned.ALL;

entity MicroMIPS is
	port (
		Clk : in std_logic; -- Reloj
		NRst : in std_logic; -- Reset as�ncrono a nivel bajo
		MemProgAddr : out std_logic_vector(31 downto 0); -- Salida para la memoria de programa
		MemProgData : in std_logic_vector(31 downto 0); -- entrada de memoria de programa
		MemDataDataRead : in std_logic_vector(31 downto 0); -- entrada de memoria de datos
		MemDataAddr : out std_logic_vector(31 downto 0); -- Direcci�n para la memoria de datos
		MemDataDataWrite : out std_logic_vector(31 downto 0); -- Dato a guardar en la memoria de datos
		MemDataWe : out std_logic --Salida de escritura en memoria de datos
	);
end MicroMIPS;

architecture Practica of MicroMIPS is

	component RegsMIPS 
		port (
        Clk : in std_logic; -- Reloj
        NRst : in std_logic; -- Reset as�ncrono a nivel bajo
        Wd3 : in std_logic_vector(31 downto 0); --Valor que tomara el registro A3
        A3 : in std_logic_vector(4  downto 0); -- Direcci�n del registro destino
        A2 : in std_logic_vector(4  downto 0); -- Se�al de entrada
        A1 : in std_logic_vector(4 downto 0); -- Se�al de entrada
        Rd1 : out std_logic_vector(31 downto 0); -- Salida 
        Rd2 : out std_logic_vector(31 downto 0); -- Salida 
        We3 : in std_logic --Se�al de habilitaci�n
    );
	end component;

	component ALUMIPS
		port (
        Op1 : in std_logic_vector(31 downto 0); -- Operando
        Op2 : in std_logic_vector(31 downto 0); -- Operando
        ALUControl : in std_logic_vector(2 downto 0); -- Selecci�n de operaci�n
        Res : out std_logic_vector(31 downto 0); -- Resultado
        Z : out std_logic -- Salida de estado
	);
	end component;

	component UnidadControl
		port(
			OPCode: in std_logic_vector(31 downto 26); --Entrada de la Unidad de control
			Funct: in std_logic_vector(5 downto 0); --Entrada de la Unidad de control
			Jump:  out std_logic; --Se�al de control (salida)
			Branch: out std_logic;--Se�al de control (salida)
			MemToReg: out std_logic;--Se�al de control (salida)
			MemWrite: out std_logic;--Se�al de control (salida)
			ALUSrc: out std_logic;--Se�al de control (salida)
			ALUControl: out std_logic_vector(2 downto 0);--Se�al de control (salida)
			ExtCero: out std_logic;--Se�al de control (salida)
			RegWrite: out std_logic;--Se�al de control (salida)
			ShiftReg: out std_logic;--Se�al de control (salida)
			RegDest: out std_logic--Se�al de control (salida)
	);
	 end component;
	 
--Se�ales auxiliares
	signal Rd1, Rd2, Extsign, ExtcerosInm, ExtcerosShamt, Res, SalidamuxALUSrc : std_logic_vector(31 downto 0);
	signal A1, A2: std_logic_vector(4 downto 0);
	signal Dato_Inm: std_logic_vector(15 downto 0);
	signal addr: std_logic_vector(31 downto 0);
	signal salidaPC, siguiente: std_logic_vector(31 downto 0);
	signal z: std_logic;
	signal SalidamuxRegDest: std_logic_vector(4 downto 0);
	signal salidaBTA: std_logic_vector(31 downto 0);
	signal salidamuxPCSrc: std_logic_vector(31 downto 0);
	signal salidamuxJump: std_logic_vector(31 downto 0);
	signal SalidamuxExtCero: std_logic_vector(31 downto 0);
	signal PCSrc: std_logic;
	signal MemDataDataReadaux: std_logic_vector(31 downto 0);
	signal SalidamuxMemToReg: std_logic_vector(31 downto 0);
	signal SalidaShiftReg1: std_logic_vector(31 downto 0);
	signal SalidaShiftReg2: std_logic_vector(31 downto 0);
	signal OPCode: std_logic_vector(5 downto 0) ;
	signal Funct:  std_logic_vector(5 downto 0); 
	signal Shamt: std_logic_vector(4 downto 0);  
	signal MemToReg: std_logic;
	signal MemWrite:  std_logic;
	signal Branch: std_logic;
	signal ALUControl: std_logic_vector(2 downto 0);
	signal ALUSrc: std_logic;
	signal RegDest:  std_logic;
	signal RegWrite:  std_logic;
	signal ExtCero:std_logic;
	signal Jump: std_logic;
	signal ShiftReg: std_logic;


	begin 
	-- Uni�n con Unidad de control
	UnidadControlPM: UnidadControl port map -------------------------------------
		(OPCode => OPCODE,
		Funct => Funct,
		Jump => Jump,
		MemToReg => MemToReg,
		MemWrite => MemWrite,
		Branch => Branch,
		ALUControl => ALUControl,
		ALUSrc => ALUSrc,
		RegDest => RegDest,
		RegWrite => RegWrite,
		ExtCero => ExtCero,
		ShiftReg => ShiftReg);

 
	--Mux de PCSrc
	salidamuxPCSrc <= salidaBTA when PCSrc = '1' else siguiente  ; --En este mux, si la se�al es 0 entonces sale la de suma 4 y PC y pasa a la siguiente instruccion y si es 1 entonces sale el BTA

	--C�lculo del BTA 
	SalidaBTA <= siguiente + (Extsign(29 downto 0) & "00") ;

	--Mux de Jump
	salidamuxJump <= siguiente(31 downto 28) & addr(25 downto 0) & "00" when Jump = '1' else salidamuxPCSrc ;  --En este mux, si la se�al es 0 entonces sale la salida del mux de PCSrc y si es 1 entonces sale el JTA

	--Incrementar en 4 PC
	siguiente <= salidaPC + 4; 

	--Incrementar 4 en cada ciclo de reloj
	process(Clk, Nrst)
		begin
			if NRst= '0' then
				salidaPC <= (others => '0');
			elsif rising_edge(Clk) then
				salidaPC <= salidamuxJump;
		end if;
	end process;

	--Nombramos los cables de la Memoria de instrucciones
	MemProgAddr <= salidaPC;
	addr <= MemProgData;

	--Dividimos instrucci�n en las se�ales que vamos a usar
	OPCode <= addr(31 downto 26);
	A1 <= addr(25 downto 21);
	A2 <= addr(20 downto 16);
	

	--MUX RegDest
	SalidamuxRegDest <= addr(20 downto 16) when RegDest = '0' else addr(15 downto 11) ;

	Shamt <= addr(10 downto 6);
	Dato_Inm <= addr(15 downto 0);
	Funct <= addr(5 downto 0);

	-- Uni�n con el Banco de Registros
	RegsMipsPM: RegsMips port map 
		(A3 => SalidamuxRegDest,
		A2 => A2,
		Rd1 => Rd1,
		Rd2 => Rd2,
		A1 => A1,
		Clk => Clk,
		We3 => RegWrite,
		Wd3 => SalidamuxMemToReg,
		Nrst => Nrst);

	--Extensi�n de ceros de shamt
	ExtcerosShamt <= (31 downto 5 => '0') & Shamt(4 downto 0);

	--Extensi�n de ceros del dato inmediato
	ExtcerosInm <= (31 downto 16 => '0') & Dato_Inm(15 downto 0);
	
	--Extensi�n de signo: ponemos en los primeros 15 bits el primero de Dato_Inm (para ponerlos todos a 0 o 1) y luego concatenamos Dato_Inm
	Extsign <= (31 downto 16 => Dato_Inm(15))& Dato_Inm(15 downto 0);
	
	--Mux de extensi�n de ceros
	SalidamuxExtCero<= ExtcerosInm when ExtCero='1' else Extsign;
	
	--Mux siguiente a extensi�n de ceros
	SalidaShiftReg1 <= ExtcerosShamt when ShiftReg = '1' else SalidamuxExtCero; 
	
	--Mux siguiente al banco de registros
	SalidaShiftReg2 <= Rd1 when ShiftReg = '0' else Rd2; 
	
	--MUX de la ALUSrc
	SalidamuxALUSrc <= Rd2 when ALUSrc='0' else SalidaShiftReg1;

	--Mapa ALU
	ALUMipsPM: ALUMips port map 
		(Op1=>SalidaShiftReg2,
		Op2=>SalidamuxALUSrc,
		ALUControl => ALUControl,
		z =>z,
		Res=> Res);
	
	--Se�al PCSrc
	PCSrc <= z and Branch;
	
	--Uni�n con la memoria de datos
	MemDataDataWrite <= Rd2 ;
	MemDataAddr <= Res; 
	MemDataWe <= MemWrite ;
	MemDataDataReadaux <= MemDataDataRead ;

	--MUX MemToReg
	SalidamuxMemToReg <= MemDataDataReadaux when MemToReg='1' else Res;

end Practica; 
	
	
	
	
	
	
	
	
	
	
	