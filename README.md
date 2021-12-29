This is an Ada-language driver for the STMicroelectronics [VL53L1X](https://www.st.com/en/imaging-and-photonics-solutions/vl53l1x.html) ranging sensor.

It's based on STMicroelectronics's STSW-IMG009 C-language driver, and initially includes that driver via an automatically-generated binding. The plan is to reduce the dependence on C in stages.

## Usage ##

You can see an example of usage in the `demo/` folder.

The essentials are:

* configure your I2C and GPIO pins, specifically enabling interrupts on the GPIO1 pin (default, interrupt on rising edge).
* call `Boot_Device`. This waits for a period to allow the VL53L1X to boot, then checks that the device is ready.
* call `Sensor_Init`.
* call `Start_Ranging`.
* loop, waiting for interrupts; on interrupt,
  * call `Get_Measurement`
  * call `Clear_Interrupt` (note, this is aside from the MCU's GPIO interrupt processing: it clears the interrupt indication on GPIO1 and restarts the device's ranging process).

If you don't want to use the device's interrupt-generating feature, you can do a "busy" loop using `Wait_For_Measurement` (whose `Loop_Interval_Ms` parameter controls the delay between each check).

Other controls provided are:

* `Set_Device_Address` allows to change the I2C address from the default (`16#52#`). This is useful if you have more than one VL53L1X connected: disable all the devices' I2C communications by clearing their XSHUT pins, then enable them one-by-one setting distinct addresses.
* `Set_Distance_Mode`: the choices are `Long` (default) and `Short`. `Short` mode has better ambient light immunity but the maximum distance measurable is limited to 1.3 m. `Long` distance mode ranges up to 4 m but is less performant under ambient light.
* `Set_Timings`.
  * `Measurement_Budget_Ms` (20 to 1_000 ms, default 100 ms) is the time allowed to make one measurement: longer times provide increased measurement precision at the expense of increased power consumption.
  * `Between_Measurements_Ms` (no less than `Measurement_Budget_Ms`) is the interval between measurement initiations.

Further controls are available to be implemented, in particular controlling the field of view (size and, possibly, offset).

## Exceptions ##

Exceptions are raised for I2C errors, largely on the grounds that it's not obvious how to recover from them.

This extends to failure of `Boot_Device` to connect, possibly because of using the wrong I2C address. This is an undesirable behaviour (aka bug) which will be corrected.
