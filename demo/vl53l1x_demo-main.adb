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

   procedure Exercise_Sensor (Sensor : in out VL53L1X.VL53L1X_Ranging_Sensor);

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
      Status : Boolean;
   begin
      VL53L1X.Boot_Device (Sensor, Status => Status);
      pragma Assert (Status, "couldn't boot device");

      VL53L1X.Set_Device_Address (Sensor, Addr => Address, Status => Status);
      pragma Assert (Status, "couldn't set device address");

      VL53L1X.Sensor_Init (Sensor,
                           Status => Status);
      pragma Assert (Status, "couldn't init the sensor");

      declare
         Mode : VL53L1X.Distance_Mode;
      begin
         VL53L1X.Get_Distance_Mode
           (Sensor,
            Mode   => Mode,
            Status => Status);
         pragma Assert (Status, "couldn't get the distance mode");
         Semihosting.Log_Line ("distance mode: " & Mode'Image);
      end;

      VL53L1X.Set_Distance_Mode
        (Sensor,
         Mode   => VL53L1X.Short,
         Status => Status);
      pragma Assert (Status, "couldn't set the distance mode");

      declare
         Mode : VL53L1X.Distance_Mode;
      begin
         VL53L1X.Get_Distance_Mode
           (Sensor,
            Mode   => Mode,
            Status => Status);
         pragma Assert (Status, "couldn't get the distance mode");
         Semihosting.Log_Line ("distance mode: " & Mode'Image);
      end;

      VL53L1X.Set_Distance_Mode
        (Sensor,
         Mode   => VL53L1X.Long,
         Status => Status);
      pragma Assert (Status, "couldn't set the distance mode");

      declare
         Mode : VL53L1X.Distance_Mode;
      begin
         VL53L1X.Get_Distance_Mode
           (Sensor,
            Mode   => Mode,
            Status => Status);
         pragma Assert (Status, "couldn't get the distance mode");
         Semihosting.Log_Line ("distance mode: " & Mode'Image);
      end;

      declare
         Budget   : Natural;
         Interval : Natural;
      begin
         VL53L1X.Get_Timings
           (Sensor,
            Measurement_Budget_Ms   => Budget,
            Between_Measurements_Ms => Interval,
            Status                  => Status);
         pragma Assert (Status, "couldn't get the timings");
         Semihosting.Log_Line
           ("timing budget:" & Budget'Image & ", interval:" & Interval'Image);
      end;

      VL53L1X.Set_Timings
        (Sensor,
         Measurement_Budget_Ms   => 500,
         Between_Measurements_Ms => 1_500,
         Status                  => Status);
      pragma Assert (Status, "couldn't set timings");
   end Setup_Sensor;

   procedure Exercise_Sensor (Sensor : in out VL53L1X.VL53L1X_Ranging_Sensor)
   is
      Status : Boolean;
   begin
      VL53L1X.Start_Ranging (Sensor, Status);
      pragma Assert (Status, "didn't start ranging");

      declare
         Budget   : Natural;
         Interval : Natural;
      begin
         VL53L1X.Get_Timings
           (Sensor,
            Measurement_Budget_Ms   => Budget,
            Between_Measurements_Ms => Interval,
            Status                  => Status);
         pragma Assert (Status, "couldn't get the timings");
         Semihosting.Log_Line
           ("timing budget:" & Budget'Image & ", interval:" & Interval'Image);
      end;

      declare
         Start : Ada.Real_Time.Time;
         use type Ada.Real_Time.Time;
         use type Ada.Real_Time.Time_Span;
      begin
         Semihosting.Log_Line ("started ranging");
         for J in 1 .. 10 loop
            Start := Ada.Real_Time.Clock;
            delay until
              Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (500);
            declare
               Distance : Natural;
               Valid : Boolean;
               Ranging_Status : VL53L1X.Ranging_Status;
            begin
               declare
                  Ready : Boolean;
               begin
                  loop
                     VL53L1X.Is_Measurement_Ready (Sensor, Ready, Status);
                     pragma Assert (Status, "didn't get measurement-ready");
                     exit when Ready;
                  end loop;
               end;

               VL53L1X.Get_Measurement
                 (Sensor, Distance, Valid, Ranging_Status);
               pragma Assert (Status, "didn't get measurement");

               VL53L1X.Clear_Interrupt (Sensor, Status);
               pragma Assert (Status, "didn't clear interrupt");

               Semihosting.Log_Line
                 ("distance:" & (if Valid
                                 then Distance'Image
                                 else " ---")
                    & ", r.status: " & Ranging_Status'Image
                    & ", interval (ms):" &
                    Integer'Image
                      ((Ada.Real_Time.Clock - Start)
                         / Ada.Real_Time.Milliseconds (1)));
            end;
         end loop;

         Semihosting.Log_Line ("stopping ranging");
      end;
   end Exercise_Sensor;

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

   Semihosting.Log_Line ("exercising the breakouts");
   for J in 1 .. 10 loop
      Semihosting.Log_Line ("exercising the Pimoroni breakout");
      Exercise_Sensor (Pimoroni);
      Semihosting.Log_Line ("exercising the Polulu breakout");
      Exercise_Sensor (Polulu);
   end loop;

   Semihosting.Log_Line ("stopping the exercise & resetting the breakouts");
   declare
      Status : Boolean;
   begin
      VL53L1X.Set_Device_Address (Pimoroni, 16#52#, Status);
      VL53L1X.Set_Device_Address (Polulu, 16#52#, Status);
      --  Now we can restart the program without having to power cycle
      --  the breakouts.
   end;

   delay until Ada.Real_Time.Time_Last;
end VL53L1X_Demo.Main;
