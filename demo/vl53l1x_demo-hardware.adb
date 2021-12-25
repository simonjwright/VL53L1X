with STM32.EXTI;

with Ada.Interrupts.Names;
with System;

package body VL53L1X_Demo.Hardware is

   procedure Initialize_I2C_GPIO (Port : in out STM32.I2C.I2C_Port)
   is
      Id     : constant STM32.Device.I2C_Port_Id
        := STM32.Device.As_Port_Id (Port);
      use all type STM32.Device.I2C_Port_Id;
      --  SCL, SDA respectively
      Points : constant STM32.GPIO.GPIO_Points (1 .. 2) :=
        (case Id is
            when I2C_Id_1 => (STM32.Device.PB6,  STM32.Device.PB7),
            when I2C_Id_2 => (STM32.Device.PB10, STM32.Device.PB11),
            when I2C_Id_3 => (STM32.Device.PA8,  STM32.Device.PC9));
   begin
      STM32.Device.Enable_Clock (Points);
      STM32.Device.Enable_Clock (Port);
      STM32.Device.Reset (Port);

      STM32.GPIO.Configure_IO
        (Points,
         (AF_Speed       => STM32.GPIO.Speed_25MHz,
          Mode           => STM32.GPIO.Mode_AF,
          AF             =>
            (case Id is
                when I2C_Id_1 => STM32.Device.GPIO_AF_I2C1_4,
                when I2C_Id_2 => STM32.Device.GPIO_AF_I2C2_4,
                when I2C_Id_3 => STM32.Device.GPIO_AF_I2C3_4),
          AF_Output_Type => STM32.GPIO.Open_Drain,
          Resistors      => STM32.GPIO.Floating));
      STM32.GPIO.Lock (Points);
   end Initialize_I2C_GPIO;

   procedure Configure_I2C (Port : in out STM32.I2C.I2C_Port)
   is
   begin
      if not STM32.I2C.Port_Enabled (Port) then
         STM32.I2C.Configure
           (This => Port,
            Conf =>
              (Clock_Speed     => 400_000,
               Mode            => STM32.I2C.I2C_Mode,
               Duty_Cycle      => STM32.I2C.DutyCycle_16_9,
               Addressing_Mode => STM32.I2C.Addressing_Mode_7bit,
               Own_Address     => 0,
               others          => <>));
      end if;
   end Configure_I2C;

   procedure Configure_Pimoroni is
   begin
      STM32.Device.Enable_Clock (Pimoroni_INT);
      STM32.GPIO.Configure_IO
        (Pimoroni_INT,
         Config => (Resistors => STM32.GPIO.Floating,
                    Mode      => STM32.GPIO.Mode_In));
      STM32.EXTI.Clear_External_Interrupt
        (STM32.GPIO.Interrupt_Line_Number (Pimoroni_INT));
      STM32.GPIO.Configure_Trigger
        (Pimoroni_INT,
         Trigger => STM32.EXTI.Interrupt_Rising_Edge);
   end Configure_Pimoroni;

   procedure Configure_Polulu is
   begin
      STM32.Device.Enable_Clock (Polulu_GPIO1);
      STM32.GPIO.Configure_IO
        (Polulu_GPIO1,
         Config => (Resistors => STM32.GPIO.Floating,
                    Mode      => STM32.GPIO.Mode_In));
      STM32.EXTI.Clear_External_Interrupt
        (STM32.GPIO.Interrupt_Line_Number (Polulu_GPIO1));
      STM32.GPIO.Configure_Trigger
        (Polulu_GPIO1,
         Trigger => STM32.EXTI.Interrupt_Rising_Edge);
      STM32.Device.Enable_Clock (Polulu_XSHUT);
      STM32.GPIO.Configure_IO
        (Polulu_XSHUT,
         (Resistors   => STM32.GPIO.Floating,
          Mode        => STM32.GPIO.Mode_Out,
          Output_Type => STM32.GPIO.Push_Pull,
          Speed       => STM32.GPIO.Speed_Low));
      STM32.GPIO.Lock (Polulu_XSHUT);
   end Configure_Polulu;

   procedure Disable_Polulu is
   begin
      STM32.GPIO.Clear (Polulu_XSHUT);
   end Disable_Polulu;

   procedure Enable_Polulu is
   begin
      STM32.GPIO.Set (Polulu_XSHUT);
   end Enable_Polulu;

   protected Handler
   with Interrupt_Priority => System.Interrupt_Priority'Last is
      entry Wait_For_Data_Available (Available : out Data_Available);
   private
      Avail : Boolean := False;
      Available : Data_Available := (others => False);
      procedure Handle_Pimoroni_Interrupt
      with Attach_Handler => Ada.Interrupts.Names.EXTI1_Interrupt;
      procedure Handle_Polulu_Interrupt
      with Attach_Handler => Ada.Interrupts.Names.EXTI0_Interrupt;
   end Handler;

   procedure Wait_For_Data_Available (Available : out Data_Available)
   is
   begin
      Handler.Wait_For_Data_Available (Available);
   end Wait_For_Data_Available;

   protected body Handler is

      entry Wait_For_Data_Available (Available : out Data_Available)
        when Avail
      is
      begin
         Available := Handler.Available;
         Handler.Available := (others => False);
         Avail := False;
      end Wait_For_Data_Available;

      procedure Handle_Pimoroni_Interrupt is
      begin
         Available (On_Pimoroni) := True;
         Avail := True;
         STM32.EXTI.Clear_External_Interrupt
           (STM32.GPIO.Interrupt_Line_Number (Pimoroni_INT));
      end Handle_Pimoroni_Interrupt;

      procedure Handle_Polulu_Interrupt is
      begin
         Available (On_Polulu) := True;
         Avail := True;
         STM32.EXTI.Clear_External_Interrupt
           (STM32.GPIO.Interrupt_Line_Number (Polulu_GPIO1));
      end Handle_Polulu_Interrupt;

   end Handler;

end VL53L1X_Demo.Hardware;
