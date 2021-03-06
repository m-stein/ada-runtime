package body Componolit.Runtime.Drivers.GPIO with
   SPARK_Mode,
   Refined_State => (Configuration_State        => Config_Registers,
                     GPIO_State                 => IO_Registers,
                     Shadow_Configuration_State => (Shadow_Config,
                                                    Modes,
                                                    Pins))
is

   use type SSE.Integer_Address;

   --  The GPIOs on a STM32F0 are divided into several so called Ports. Each
   --  Port has its own set of registers but they're all identical. To prevent
   --  code duplication the register sets are contained in arrays. Since some
   --  registers have different volatile properties than others there are two
   --  register arrays. Both span over the whole GPIO memory region as arrays
   --  of GPIO ports. While they might overlap each other their components
   --  only access slices of memory that are non-overlapping:
   --
   --  Port:   |     A     |     B     |
   --          ---------------------------
   --  Config: | 1 |       | 1 |       |
   --          ---------------------------
   --  IO:     |   | 2 |   |   | 2 |   |
   --          ---------------------------
   --
   --  The Config registers only access region 1 of each port while the
   --  IO registers only access region 2.

   Config_Registers : Configuration with
      Import,
      Address => SSE.To_Address (16#4800_0000#),
      Volatile,
      Async_Readers,
      Effective_Writes;

   IO_Registers : Input_Output with
      Import,
      Address => SSE.To_Address (16#4800_0000#),
      Volatile,
      Async_Readers,
      Async_Writers,
      Effective_Writes;

   Shadow_Config : Pull_Config := (others => (others => Port_In));

   Modes : Proof_Pin_Mode := (others => Port_In) with Ghost;

   Pins : Configured_Pins := (others => False) with Ghost;

   --  Proof procedure to help gnatprove unrolling the loop
   --  over all pins.
   procedure Prf_Unfold_Valid with
      Ghost,
      Pre  => (for all Pn in Pin => Valid (Pn)),
      Post => (for all Pn in Pin =>
                  Modes (Pn) =
                     Shadow_Config (Bank_Select (Pn)) (Pin_Offset (Pn)));

   procedure Prf_Unfold_Valid
   is
   begin
      for P in Pin loop
         pragma Assert (Valid (P));
         pragma Loop_Invariant (for all Q in Pin'First .. P =>
                                   Modes (Q) =
                                      Shadow_Config
                                         (Bank_Select (Q)) (Pin_Offset (Q)));
      end loop;
   end Prf_Unfold_Valid;

   procedure Initialize
   is
   begin
      for C in RCC.Clock loop
         RCC.Set (C, True);
      end loop;
      Shadow_Config := (A => Config_Registers (A).Port_Mode,
                        B => Config_Registers (B).Port_Mode,
                        C => Config_Registers (C).Port_Mode,
                        D => Config_Registers (D).Port_Mode,
                        E => (others => Port_In),
                        --  Port E is available on STM32F07x
                        --  and STM32F09x devices only.
                        F => Config_Registers (F).Port_Mode);
      Modes := (others => Port_In);
      for P in Pin'Range loop
         Modes (P) :=
            Shadow_Config (Bank_Select (P)) (Pin_Offset (P));
         pragma Loop_Invariant (for all Q in Pin'First .. P =>
                                   Modes (Q) =
                                      Shadow_Config
                                         (Bank_Select (Q)) (Pin_Offset (Q)));
      end loop;
      Pins := (others => False);
   end Initialize;

   procedure Configure (P : Pin;
                        M : Mode;
                        D : Value := Low)
   is
   begin
      Prf_Unfold_Valid;
      Shadow_Config (Bank_Select (P)) (Pin_Offset (P)) := M;
      case M is
         when Port_In =>
            Config_Registers (Bank_Select (P)).Pull_Mode (Pin_Offset (P))
               := (if D = Low then Down else Up);
         when Port_Out =>
            Config_Registers (Bank_Select (P)).Pull_Mode (Pin_Offset (P))
               := Pull_None;
      end case;
      Config_Registers (Bank_Select (P)).Port_Mode :=
         Shadow_Config (Bank_Select (P));
      Modes (P) := Shadow_Config (Bank_Select (P)) (Pin_Offset (P));
      Pins (P)  := True;
   end Configure;

   function Pin_Mode (P : Pin) return Mode is
      (Shadow_Config (Bank_Select (P)) (Pin_Offset (P)));

   procedure Write (P : Pin;
                    V : Value)
   is
      Bits : Bit_Register := (others => 0);
   begin
      Bits (Pin_Offset (P)) := 1;
      case V is
         when Low =>
            IO_Registers (Bank_Select (P)).Set_Reset
               := Set_Reset_Register'(Set   => (others => 0),
                                      Reset => Bits);
         when High =>
            IO_Registers (Bank_Select (P)).Set_Reset
               := Set_Reset_Register'(Set   => Bits,
                                      Reset => (others => 0));
      end case;
   end Write;

   procedure Read (P :     Pin;
                   V : out Value)
   is
      B : Bit;
   begin
      B := IO_Registers (Bank_Select (P)).Input.Data (Pin_Offset (P));
      V := Value'Val (B);
   end Read;

   function Bank_Select (P : Pin) return Bank_Id is
      (case P is
         when PA0 .. PA15 => A,
         when PB0 .. PB15 => B,
         when PC0 .. PC15 => C,
         when PD0 .. PD15 => D,
         when PF0 .. PF15 => F);

   function Pin_Offset (P : Pin) return Pin_Index is
      (Pin_Index (Pin'Pos (P) mod 16));

   function Pin_Modes return Proof_Pin_Mode is (Modes);

   function Valid (P : Pin) return Boolean is
      (Shadow_Config (Bank_Select (P)) (Pin_Offset (P)) = Modes (P));

   function Pins_Configured return Configured_Pins is (Pins);

   function Configured (P : Pin) return Boolean is (Pins (P));

end Componolit.Runtime.Drivers.GPIO;
