with Semihosting;
with Ada.Real_Time;

with HAL.I2C;
with Ravenscar_Time;

with VL53L1X;

with VL53L1X_Demo.Hardware; use VL53L1X_Demo.Hardware;

procedure VL53L1X_Demo.Main is

   --  Override the default task stack sizes used by Cortex GNAT RTS,
   --  which aren't enough for this code.

   --  For the environment task.
   Environment_Task_Storage_Size : constant Natural := 3072
     with
       Export,
       Convention => Ada,
       External_Name => "_environment_task_storage_size";

   procedure Setup_Sensor
     (Sensor  : in out VL53L1X.VL53L1X_Ranging_Sensor;
      Address :        HAL.I2C.I2C_Address := 16#52#);

   --  (a) only one sensor can have a given I2C address, which
   --  initializes to 16#52#. Start off with all but one shut down,
   --  configure it to the required address, then do the rest one by
   --  one.
   --
   --  (b) the address is only reset by cycling power to the device.
   procedure Setup_Sensor
     (Sensor  : in out VL53L1X.VL53L1X_Ranging_Sensor;
      Address :        HAL.I2C.I2C_Address := 16#52#)
   is
      Status : VL53L1X.Boot_Status;
      use type VL53L1X.Boot_Status;
   begin
      VL53L1X.Boot_Device (Sensor, Status => Status);
      pragma Assert (Status = VL53L1X.Ok,
                     "couldn't boot device: " & Status'Image);

      VL53L1X.Set_Device_Address (Sensor, Addr => Address);

      VL53L1X.Sensor_Init (Sensor);

      Semihosting.Log_Line
        ("timing budget:"
           & VL53L1X.Get_Measurement_Budget (Sensor)'Image
           & ", interval:"
           & VL53L1X.Get_Inter_Measurement_Time (Sensor)'Image);

      Semihosting.Log_Line ("distance mode: "
                              & VL53L1X.Get_Distance_Mode (Sensor)'Image);

      VL53L1X.Set_Distance_Mode (Sensor, Mode => VL53L1X.Short);

      Semihosting.Log_Line ("distance mode: "
                              & VL53L1X.Get_Distance_Mode (Sensor)'Image);

      VL53L1X.Set_Distance_Mode (Sensor, Mode => VL53L1X.Long);

      Semihosting.Log_Line ("distance mode: "
                              & VL53L1X.Get_Distance_Mode (Sensor)'Image);

      Semihosting.Log_Line
        ("timing budget:"
           & VL53L1X.Get_Measurement_Budget (Sensor)'Image
           & ", interval:"
           & VL53L1X.Get_Inter_Measurement_Time (Sensor)'Image);

      VL53L1X.Set_Measurement_Budget (Sensor, Budget => 500);
      VL53L1X.Set_Inter_Measurement_Time (Sensor, Interval => 1_500);
   end Setup_Sensor;

begin
   Semihosting.Log_Line ("vl53l1x_demo");

   Initialize_I2C_GPIO (Sensor_Port);
   Configure_I2C (Sensor_Port);

   Configure_Pimoroni;
   Configure_Polulu;

   Semihosting.Log_Line ("Setting up the Pimoroni breakout");
   Disable_Polulu;
   Setup_Sensor (Pimoroni, Address => 16#50#);

   Semihosting.Log_Line ("Setting up the Polulu breakout");
   Enable_Polulu;
   Setup_Sensor (Polulu, Address => 16#54#);

   Exercise : declare
      use type Ada.Real_Time.Time;
      --  Note, Semihosting output, being done via the debugger,
      --  suspends the program while the output is going on; this
      --  effectively stops the clock, so the program runs about 2
      --  times slower overall; the exercise takes about 20 seconds.
      Stop_Time : constant Ada.Real_Time.Time
        := Ada.Real_Time.Clock + Ada.Real_Time.Seconds (10);
   begin
      VL53L1X.Start_Ranging (Pimoroni);
      VL53L1X.Start_Ranging (Polulu);

      loop
         exit when Ada.Real_Time.Clock >= Stop_Time;
         declare
            Breakout_Available : Data_Available;
            Measurement : VL53L1X.Measurement;
            use all type VL53L1X.Ranging_Status;
         begin
            Wait_For_Data_Available (Breakout_Available);
            if Breakout_Available (On_Pimoroni) then
               if not VL53L1X.Is_Measurement_Ready (Pimoroni) then
                  --  Is this right?
                  VL53L1X.Clear_Interrupt (Pimoroni);

                  Semihosting.Log_Line ("pimoroni: not ready");
               else
                  Measurement := VL53L1X.Get_Measurement (Pimoroni);

                  VL53L1X.Clear_Interrupt (Pimoroni);

                  Semihosting.Log_Line
                    ("pimoroni: distance:"
                       & (if Measurement.Status = Ok then
                             Measurement.Distance'Image
                          else
                             " ---")
                       & ", status: " & Measurement.Status'Image);
               end if;
            end if;
            if Breakout_Available (On_Polulu) then
               if not VL53L1X.Is_Measurement_Ready (Polulu) then
                  --  Is this right?
                  VL53L1X.Clear_Interrupt (Polulu);

                  Semihosting.Log_Line ("polulu: not ready");
               else
                  Measurement := VL53L1X.Get_Measurement (Polulu);

                  VL53L1X.Clear_Interrupt (Polulu);

                  Semihosting.Log_Line
                    ("polulu: distance:"
                       & (if Measurement.Status = Ok then
                             Measurement.Distance'Image
                          else
                             " ---")
                       & ", status: " & Measurement.Status'Image);
               end if;
            end if;
         end;
      end loop;
   end Exercise;

   Semihosting.Log_Line ("stopping the exercise & resetting the breakouts");
   VL53L1X.Stop_Ranging (Pimoroni);
   VL53L1X.Stop_Ranging (Polulu);
   VL53L1X.Set_Device_Address (Pimoroni, 16#52#);
   VL53L1X.Set_Device_Address (Polulu, 16#52#);
   --  Now we can restart the program without having to power cycle
   --  the breakouts.

   delay until Ada.Real_Time.Time_Last;
end VL53L1X_Demo.Main;
