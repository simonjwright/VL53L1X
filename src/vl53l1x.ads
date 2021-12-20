------------------------------------------------------------------------------
--                                                                          --
--                     Copyright (C) 2021 AdaCore                           --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of STMicroelectronics nor the names of its       --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
--   This file is based on STSW-IMG009, issue 3.5.1/UM2150 Rev 4.
--                                                                          --
--   COPYRIGHT(c) 2021 STMicroelectronics                                   --
------------------------------------------------------------------------------

with HAL.I2C;
with HAL.Time;
with System;

private with vl53l1_platform_h;

package VL53L1X is

   VL53L1X_Error : exception;

   type VL53L1X_Ranging_Sensor
     (Port   : not null HAL.I2C.Any_I2C_Port;
      Timing : not null HAL.Time.Any_Delays) is limited private;

   function Is_Booted (This : VL53L1X_Ranging_Sensor) return Boolean;

   procedure Boot_Device
     (This             : in out VL53L1X_Ranging_Sensor;
      Loop_Interval_Ms :        Positive := 10;
      Status           :    out Boolean)
   with
     Pre => not Is_Booted (This),
     Post => Is_Booted (This) = Status;

   procedure Set_Device_Address
     (This   : in out VL53L1X_Ranging_Sensor;
      Addr   :        HAL.I2C.I2C_Address;
      Status :    out Boolean)
   with
     Pre => Is_Booted (This);

   function Sensor_Initialized (This : VL53L1X_Ranging_Sensor) return Boolean;

   procedure Sensor_Init
     (This   : in out VL53L1X_Ranging_Sensor;
      Status :    out Boolean)
   with
     Pre => Is_Booted (This),
     Post => Sensor_Initialized (This) = Status;

   type Distance_Mode is (Short, Long);

   procedure Get_Distance_Mode
     (This   : in out VL53L1X_Ranging_Sensor;
      Mode   :    out Distance_Mode;
      Status :    out Boolean)
   with Pre => Sensor_Initialized (This);

   procedure Set_Distance_Mode
     (This   : in out VL53L1X_Ranging_Sensor;
      Mode   :        Distance_Mode := Long;
      Status :    out Boolean)
   with Pre => Sensor_Initialized (This);
   --  The defaulted mode is what the device initializes to.

   subtype Budget_Millisec is Natural range 20 .. 1000;

   procedure Get_Timings
     (This                    : in out VL53L1X_Ranging_Sensor;
      Measurement_Budget_Ms   :    out Budget_Millisec;
      Between_Measurements_Ms :    out Natural;
      Status                  :    out Boolean)
   with
     Pre => Sensor_Initialized (This);

   procedure Set_Timings
     (This                    : in out VL53L1X_Ranging_Sensor;
      Measurement_Budget_Ms   :        Budget_Millisec := 100;
      Between_Measurements_Ms :        Natural := 100;
      Status                  :    out Boolean)
   with
     Pre =>
       Between_Measurements_Ms >= Measurement_Budget_Ms
       and then (Sensor_Initialized (This) and not Ranging_Started (This));

   function Ranging_Started (This : VL53L1X_Ranging_Sensor) return Boolean;

   procedure Start_Ranging
     (This   : in out VL53L1X_Ranging_Sensor;
      Status :    out Boolean)
   with
     Pre => Sensor_Initialized (This),
     Post => Ranging_Started (This);

   procedure Wait_For_Measurement
     (This             : in out VL53L1X_Ranging_Sensor;
      Loop_Interval_Ms :        Positive := 10;
      Status           :    out Boolean)
   with
     Pre => Ranging_Started (This);

   procedure Is_Measurement_Ready
     (This   : in out VL53L1X_Ranging_Sensor;
      Ready  :    out Boolean;
      Status :    out Boolean)
   with
     Pre => Ranging_Started (This);

   type Ranging_Status is
     (Ok, Sigma_Failure, Signal_Failure, Out_Of_Bounds, Wraparound);
   --  Sigma_Failure: the repeatability or standard deviation of the
   --  measurement is bad due to a decreasing signal-to-noise
   --  ratio. Increasing the timing budget can improve the standard
   --  deviation and avoid this problem.
   --
   --  Signal_Failure: the return signal is too weak to return a good
   --  answer. The reason may be that the target is too far, or the
   --  target is not reflective enough, or the target is too
   --  small. Increasing the timing buget might help, but there may
   --  simply be no target available.
   --
   --  Out_Of_Bounds: the sensor is ranging in a “non-appropriated”
   --  zone and the measured result may be inconsistent. This status
   --  is considered as a warning but, in general, it happens when a
   --  target is at the maximum distance possible from the sensor,
   --  i.e. around 5 m. However, this is only for very bright targets.
   --
   --  Wraparound: may occur when the target is very reflective and
   --  the distance to the target is longer than the physical limited
   --  distance measurable by the sensor. Such distances include
   --  approximately 5 m when the senor is in Long distance mode and
   --  approximately 1.3 m when the sensor is in Short distance
   --  mode. Example: a traffic sign located at 6 m can be seen by the
   --  sensor and returns a range of 1 m. This is due to “radar
   --  aliasing”: if only an approximate distance is required, we may
   --  add 6 m to the distance returned. However, that is a very
   --  approximate estimation.

   procedure Get_Measurement
     (This        : in out VL53L1X_Ranging_Sensor;
      Distance_Mm :    out Natural;
      Valid       :    out Boolean;
      Status      :    out Ranging_Status)
   with
     Pre => Ranging_Started (This);

   procedure Clear_Interrupt
     (This     : in out VL53L1X_Ranging_Sensor;
      Status   :    out Boolean)
   with
     Pre => Ranging_Started (This);

   procedure Stop_Ranging
     (This   : in out VL53L1X_Ranging_Sensor;
      Status :    out Boolean)
   with
     Pre => Sensor_Initialized (This),
     Post => not Ranging_Started (This);

private

   type VL53L1X_Ranging_Sensor (Port   : not null HAL.I2C.Any_I2C_Port;
                                Timing : not null HAL.Time.Any_Delays)
      is limited record
         Booted             : Boolean := False;
         Sensor_Initialized : Boolean := False;
         Ranging_Started    : Boolean := False;

         --  Default address: can be changed by software
         I2C_Address : HAL.I2C.I2C_Address := 16#52#;

         --  For use by the C interface; set up in Boot_Device
         Dev : vl53l1_platform_h.VL53L1_DEV;
      end record;

   function Is_Booted (This : VL53L1X_Ranging_Sensor) return Boolean
   is (This.Booted);

   function Sensor_Initialized (This : VL53L1X_Ranging_Sensor) return Boolean
   is (This.Sensor_Initialized);

   function Ranging_Started (This : VL53L1X_Ranging_Sensor) return Boolean
   is (This.Ranging_Started);

end VL53L1X;
