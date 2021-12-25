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
      Stop_Time : constant Ada.Real_Time.Time
        := Ada.Real_Time.Clock + Ada.Real_Time.Seconds (20);
      Status : Boolean;
   begin
      VL53L1X.Start_Ranging (Pimoroni, Status);
      pragma Assert (Status, "pimoroni didn't start ranging");
      VL53L1X.Start_Ranging (Polulu, Status);
      pragma Assert (Status, "polulu didn't start ranging");

      loop
         exit when Ada.Real_Time.Clock >= Stop_Time;
         declare
            Breakout_Available : Data_Available;
            Status : Boolean;
            Ready : Boolean;
            Distance : Natural;
            Valid : Boolean;
            Ranging_Status : VL53L1X.Ranging_Status;
         begin
            Wait_For_Data_Available (Breakout_Available);
            if Breakout_Available (On_Pimoroni) then
               Semihosting.Log_Line ("pimoroni data");
               VL53L1X.Is_Measurement_Ready (Pimoroni, Ready, Status);
               pragma Assert (Status, "didn't get measurement-ready");

               if not Ready then
                  Semihosting.Log_Line ("not ready");
               else
                  VL53L1X.Get_Measurement
                    (Pimoroni, Distance, Valid, Ranging_Status);

                  VL53L1X.Clear_Interrupt (Pimoroni, Status);
                  pragma Assert (Status, "didn't clear interrupt");

                  Semihosting.Log_Line
                    ("distance:" & (if Valid
                                    then Distance'Image
                                    else " ---")
                       & ", r.status: " & Ranging_Status'Image);
               end if;
            end if;
            if Breakout_Available (On_Polulu) then
               Semihosting.Log_Line ("polulu data");
               VL53L1X.Is_Measurement_Ready (Polulu, Ready, Status);
               pragma Assert (Status, "didn't get measurement-ready");

               if not Ready then
                  Semihosting.Log_Line ("not ready");
               else
                  VL53L1X.Get_Measurement
                    (Polulu, Distance, Valid, Ranging_Status);

                  VL53L1X.Clear_Interrupt (Polulu, Status);
                  pragma Assert (Status, "didn't clear interrupt");

                  Semihosting.Log_Line
                    ("distance:" & (if Valid
                                    then Distance'Image
                                    else " ---")
                       & ", r.status: " & Ranging_Status'Image);
               end if;
            end if;
         end;
      end loop;
   end Exercise;

   Semihosting.Log_Line ("stopping the exercise & resetting the breakouts");
   declare
      Status : Boolean;
   begin
      VL53L1X.Stop_Ranging (Pimoroni, Status);
      VL53L1X.Stop_Ranging (Polulu, Status);
      VL53L1X.Set_Device_Address (Pimoroni, 16#52#, Status);
      VL53L1X.Set_Device_Address (Polulu, 16#52#, Status);
      --  Now we can restart the program without having to power cycle
      --  the breakouts.
   end;

   delay until Ada.Real_Time.Time_Last;
end VL53L1X_Demo.Main;
