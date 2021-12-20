with STM32.Device;
with STM32.GPIO;
with STM32.I2C;
with HAL.I2C;
with Ravenscar_Time;

with VL53L1X;

package VL53L1X_Demo.Hardware is

   Sensor_Port : STM32.I2C.I2C_Port renames STM32.Device.I2C_1;

   --  These are my two VL53L1X devices, named for their supplier.
   --  Only the Polulu breakout has XSHUT exported (shuts the device
   --  down if taken to ground).
   Polulu   : VL53L1X.VL53L1X_Ranging_Sensor
     (Port   => Sensor_Port'Access,
      Timing => Ravenscar_Time.Delays);
   Pimoroni : VL53L1X.VL53L1X_Ranging_Sensor
     (Port   => Sensor_Port'Access,
      Timing => Ravenscar_Time.Delays);

   procedure Initialize_I2C_GPIO (Port : in out STM32.I2C.I2C_Port);
   procedure Configure_I2C (Port : in out STM32.I2C.I2C_Port);

   procedure Configure_Pimoroni;

   procedure Configure_Polulu;

   --  Of the two breakouts, only the Polulu one breaks out the XSHUT signal.
   procedure Disable_Polulu;
   procedure Enable_Polulu;

end VL53L1X_Demo.Hardware;
