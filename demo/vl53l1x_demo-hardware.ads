with STM32.Device;
with STM32.GPIO;
with STM32.I2C;
with Ravenscar_Time;

with VL53L1X;

package VL53L1X_Demo.Hardware is

   Sensor_Port : STM32.I2C.I2C_Port renames STM32.Device.I2C_1;

   --  These are my two VL53L1X devices, named for their supplier.
   --  Only the Polulu breakout has XSHUT exported (disables the
   --  device's I2C interface if taken to ground).
   Pimoroni : VL53L1X.VL53L1X_Ranging_Sensor
     (Port   => Sensor_Port'Access,
      Timing => Ravenscar_Time.Delays);
   Polulu   : VL53L1X.VL53L1X_Ranging_Sensor
     (Port   => Sensor_Port'Access,
      Timing => Ravenscar_Time.Delays);

   Pimoroni_INT : STM32.GPIO.GPIO_Point renames STM32.Device.PE1;

   Polulu_GPIO1 : STM32.GPIO.GPIO_Point renames STM32.Device.PD0;
   Polulu_XSHUT : STM32.GPIO.GPIO_Point renames STM32.Device.PC7;
   --  Clear to shut down the device's I2C interface

   procedure Initialize_I2C_GPIO (Port : in out STM32.I2C.I2C_Port);
   procedure Configure_I2C (Port : in out STM32.I2C.I2C_Port);

   procedure Configure_Pimoroni;

   procedure Configure_Polulu;

   --  Of the two breakouts, only the Polulu one breaks out the XSHUT signal.
   procedure Disable_Polulu;
   procedure Enable_Polulu;

   type Breakout is (On_Pimoroni, On_Polulu);

   type Data_Available is array (Breakout) of Boolean;

   procedure Wait_For_Data_Available (Available : out Data_Available);
   --  Blocks until one or both breakouts have data available.

end VL53L1X_Demo.Hardware;
