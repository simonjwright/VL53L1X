------------------------------------------------------------------------------
--                                                                          --
--                    Copyright (C) 2021, AdaCore                           --
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
--                                                                          --
--   This file is based on STSW-IMG009, issue 3.5.1/UM2150 Rev 4.
--                                                                          --
--   COPYRIGHT(c) 2021 STMicroelectronics                                   --
------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;
with Interfaces.C.Pointers;

with HAL; use HAL;

with VL53L1X_api_h;
with sys_ustdint_h;

--  exploratory stuff
with Interfaces.C;

package body VL53L1X is

   package Registers is
      pragma Style_Checks (Off);

      --  These values are copied from those derived from vl53l1x_api.h,
      --  except that the encoding of the C double-underscore as "_u_"
      --  has been replaced by a single underscore.

      VL53L1X_IMPLEMENTATION_VER_MAJOR : constant := 3;
      VL53L1X_IMPLEMENTATION_VER_MINOR : constant := 5;
      VL53L1X_IMPLEMENTATION_VER_SUB : constant := 1;
      VL53L1X_IMPLEMENTATION_VER_REVISION : constant := 8#000#;

      SOFT_RESET : constant := 16#0000#;
      VL53L1_I2C_SLAVE_DEVICE_ADDRESS : constant := 16#0001#;
      VL53L1_VHV_CONFIG_TIMEOUT_MACROP_LOOP_BOUND : constant := 16#0008#;
      ALGO_CROSSTALK_COMPENSATION_PLANE_OFFSET_KCPS : constant := 16#0016#;
      ALGO_CROSSTALK_COMPENSATION_X_PLANE_GRADIENT_KCPS : constant := 16#0018#;
      ALGO_CROSSTALK_COMPENSATION_Y_PLANE_GRADIENT_KCPS : constant := 16#001A#;
      ALGO_PART_TO_PART_RANGE_OFFSET_MM : constant := 16#001E#;
      MM_CONFIG_INNER_OFFSET_MM : constant := 16#0020#;
      MM_CONFIG_OUTER_OFFSET_MM : constant := 16#0022#;
      GPIO_HV_MUX_CTRL : constant := 16#0030#;
      GPIO_TIO_HV_STATUS : constant := 16#0031#;
      SYSTEM_INTERRUPT_CONFIG_GPIO : constant := 16#0046#;
      PHASECAL_CONFIG_TIMEOUT_MACROP : constant := 16#004B#;
      RANGE_CONFIG_TIMEOUT_MACROP_A_HI : constant := 16#005E#;
      RANGE_CONFIG_VCSEL_PERIOD_A : constant := 16#0060#;
      RANGE_CONFIG_VCSEL_PERIOD_B : constant := 16#0063#;
      RANGE_CONFIG_TIMEOUT_MACROP_B_HI : constant := 16#0061#;
      RANGE_CONFIG_TIMEOUT_MACROP_B_LO : constant := 16#0062#;
      RANGE_CONFIG_SIGMA_THRESH : constant := 16#0064#;
      RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT_MCPS : constant := 16#0066#;
      RANGE_CONFIG_VALID_PHASE_HIGH : constant := 16#0069#;
      VL53L1_SYSTEM_INTERMEASUREMENT_PERIOD : constant := 16#006C#;
      SYSTEM_THRESH_HIGH : constant := 16#0072#;
      SYSTEM_THRESH_LOW : constant := 16#0074#;
      SD_CONFIG_WOI_SD0 : constant := 16#0078#;
      SD_CONFIG_INITIAL_PHASE_SD0 : constant := 16#007A#;
      ROI_CONFIG_USER_ROI_CENTRE_SPAD : constant := 16#007F#;
      ROI_CONFIG_USER_ROI_REQUESTED_GLOBAL_XY_SIZE : constant := 16#0080#;
      SYSTEM_SEQUENCE_CONFIG : constant := 16#0081#;
      VL53L1_SYSTEM_GROUPED_PARAMETER_HOLD : constant := 16#0082#;
      SYSTEM_INTERRUPT_CLEAR : constant := 16#0086#;
      SYSTEM_MODE_START : constant := 16#0087#;
      VL53L1_RESULT_RANGE_STATUS : constant := 16#0089#;
      VL53L1_RESULT_DSS_ACTUAL_EFFECTIVE_SPADS_SD0 : constant := 16#008C#;
      RESULT_AMBIENT_COUNT_RATE_MCPS_SD : constant := 16#0090#;
      VL53L1_RESULT_FINAL_CROSSTALK_CORRECTED_RANGE_MM_SD0 : constant := 16#0096#;
      VL53L1_RESULT_PEAK_SIGNAL_COUNT_RATE_CROSSTALK_CORRECTED_MCPS_SD0 : constant := 16#0098#;
      VL53L1_RESULT_OSC_CALIBRATE_VAL : constant := 16#00DE#;
      VL53L1_FIRMWARE_SYSTEM_STATUS : constant := 16#00E5#;
      VL53L1_IDENTIFICATION_MODEL_ID : constant := 16#010F#;
      VL53L1_ROI_CONFIG_MODE_ROI_CENTRE_SPAD : constant := 16#013E#;

      pragma Style_Checks (On);
   end Registers;
   use Registers;

   --  The VL53L1X is a big-endian device. Register addresses are two
   --  bytes wide. The data is mainly (arrays of) single bytes, but
   --  some is two bytes wide, some 4.

   subtype Two_Byte_Array is HAL.UInt8_Array (1 .. 2);
   function To_Device (Value : HAL.UInt16) return Two_Byte_Array;
   function From_Device (Value : Two_Byte_Array) return HAL.UInt16;

   subtype Four_Byte_Array is HAL.UInt8_Array (1 .. 4);
   function To_Device (Value : HAL.UInt32) return Four_Byte_Array;
   function From_Device (Value : Four_Byte_Array) return HAL.UInt32;

   --  In all cases (aside from e.g. VL53L1X_SetDistanceMode(), where
   --  it's an out-of-bounds error that won't happen in Ada) the
   --  return value of the API function merely indicates an I2C
   --  error. I'm going to raise exceptions for I2C errors (on the
   --  grounds that I have no idea how one would recover from them).
   --
   --  I'm retaining the low-level (I2C) status because the API
   --  functions use it.

   -----------------
   -- Boot_Device --
   -----------------

   procedure Boot_Device
     (This             : in out VL53L1X_Ranging_Sensor;
      Loop_Interval_Ms :        Positive := 10;
      Status           :    out Boot_Status)
   is
      function Convert is new Ada.Unchecked_Conversion
        (System.Address, vl53l1_platform_h.VL53L1_DEV);
      State : aliased sys_ustdint_h.uint8_t := 0;
      use type sys_ustdint_h.uint8_t;
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
      I2C_Status : HAL.I2C.I2C_Status;
      use all type HAL.I2C.I2C_Status;
   begin
      --  The C code thinks that VL53L1_DEV is a pointer to <something>,
      --  but it never tries to access any component of it.
      This.Dev := Convert (This'Address);

      --  Allow the VL53L1X to do its internal initialization.
      This.Timing.Delay_Milliseconds (100);

      Get_Device_Status :
      for J in 1 .. 10 loop
         --  We're going to do a low-level read using HAL.I2C
         --  directly, because we don't want to raise an exception if
         --  there's a failure.
         HAL.I2C.Master_Transmit
           (This    => This.Port.all,
            Addr    => This.I2C_Address,
            Data    => To_Device (HAL.UInt16'(VL53L1_FIRMWARE_SYSTEM_STATUS)),
            Status  => I2C_Status);
         exit Get_Device_Status when I2C_Status /= Ok;

         declare
            Buffer : HAL.UInt8_Array (1 .. 1);
         begin
            HAL.I2C.Master_Receive
              (This    => This.Port.all,
               Addr    => This.I2C_Address,
               Data    => Buffer,
               Status  => I2C_Status);
            if I2C_Status = Ok and then Buffer (1) = 3 then
               --  '3' is undocumented; UM2150 says 1.
               This.State := Booted;
               exit Get_Device_Status;
            end if;
         end;

         This.Timing.Delay_Milliseconds (Loop_Interval_Ms);
      end loop Get_Device_Status;

      Status := (case I2C_Status is
                    when Ok          => Ok,
                    when Err_Error   => I2C_Error,
                    when Err_Timeout => I2C_Timeout,
                    when Busy        => I2C_Busy);
   end Boot_Device;

   ------------------------
   -- Set_Device_Address --
   ------------------------

   procedure Set_Device_Address
     (This : in out VL53L1X_Ranging_Sensor;
      Addr :        HAL.I2C.I2C_Address)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_SetI2CAddress
        (dev         => This.Dev,
         new_address => sys_ustdint_h.uint8_t (Addr));
      This.I2C_Address := Addr;
   end Set_Device_Address;

   -----------------
   -- Sensor_Init --
   -----------------

   procedure Sensor_Init
     (This : in out VL53L1X_Ranging_Sensor)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_SensorInit
        (dev => This.Dev);
      This.State := Initialized;
   end Sensor_Init;

   -----------------------
   -- Get_Distance_Mode --
   -----------------------

   procedure Get_Distance_Mode
     (This : in out VL53L1X_Ranging_Sensor;
      Mode :    out Distance_Mode)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
      LL_Mode : aliased sys_ustdint_h.uint16_t;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_GetDistanceMode
        (dev           => This.Dev,
         pDistanceMode => LL_Mode'Access);
      Mode := (case LL_Mode is
                  when 1      => Short,
                  when 2      => Long,
                  when others =>
                     raise VL53L1X_Error
                         with "invalid distance mode" & LL_Mode'Image);
   end Get_Distance_Mode;

   -----------------------
   -- Set_Distance_Mode --
   -----------------------

   procedure Set_Distance_Mode
     (This : in out VL53L1X_Ranging_Sensor;
      Mode :        Distance_Mode := Long)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_SetDistanceMode
        (dev          => This.Dev,
         DistanceMode => (case Mode is
                             when Short => 1,
                             when Long  => 2));
   end Set_Distance_Mode;

   -----------------
   -- Get_Timings --
   -----------------

   procedure Get_Timings
     (This                    : in out VL53L1X_Ranging_Sensor;
      Measurement_Budget_Ms   :    out Budget_Millisec;
      Between_Measurements_Ms :    out Natural)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
      Ms : aliased sys_ustdint_h.uint16_t;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_GetTimingBudgetInMs
        (dev               => This.Dev,
         pTimingBudgetInMs => Ms'Access);
      Measurement_Budget_Ms := Budget_Millisec (Ms);

      Dummy := VL53L1X_api_h.VL53L1X_GetInterMeasurementInMs
        (dev => This.Dev,
         pIM => Ms'Access);
      Between_Measurements_Ms := Natural (Ms);
   end Get_Timings;

   -----------------
   -- Set_Timings --
   -----------------

   procedure Set_Timings
     (This                    : in out VL53L1X_Ranging_Sensor;
      Measurement_Budget_Ms   :        Budget_Millisec := 100;
      Between_Measurements_Ms :        Natural := 100)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_SetTimingBudgetInMs
        (dev              => This.Dev,
         TimingBudgetInMs =>
           sys_ustdint_h.uint16_t (Measurement_Budget_Ms));
      Dummy := VL53L1X_api_h.VL53L1X_SetInterMeasurementInMs
        (dev => This.Dev,
         InterMeasurementInMs =>
           sys_ustdint_h.uint32_t (Between_Measurements_Ms));
   end Set_Timings;

   -------------------
   -- Start_Ranging --
   -------------------

   procedure Start_Ranging
     (This : in out VL53L1X_Ranging_Sensor)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_StartRanging
        (dev => This.Dev);
      This.State := Ranging;
   end Start_Ranging;

   --------------------------
   -- Wait_For_Measurement --
   --------------------------

   procedure Wait_For_Measurement
     (This             : in out VL53L1X_Ranging_Sensor;
      Loop_Interval_Ms :        Positive := 10)
   is
   begin
      loop
         exit when Is_Measurement_Ready (This);
         This.Timing.Delay_Milliseconds (Loop_Interval_Ms);
      end loop;
   end Wait_For_Measurement;

   --------------------------
   -- Is_Measurement_Ready --
   --------------------------

   function Is_Measurement_Ready
     (This : in out VL53L1X_Ranging_Sensor) return Boolean
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
      Result : aliased sys_ustdint_h.uint8_t;
      use type sys_ustdint_h.uint8_t;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_CheckForDataReady
        (dev         => This.Dev,
         isDataReady => Result'Access);
      return Result = 1;
   end Is_Measurement_Ready;

   ---------------------
   -- Get_Measurement --
   ---------------------

   procedure Get_Measurement
     (This        : in out VL53L1X_Ranging_Sensor;
      Distance_Mm :    out Natural;
      Valid       :    out Boolean;
      Status      :    out Ranging_Status)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
      Result : aliased VL53L1X_api_h.VL53L1X_Result_t;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_GetResult
        (dev     => This.Dev,
         pResult => Result'Access);

      Status :=
        (case Result.Status is
            when 0      => Ok,
            when 1      => Sigma_Failure,
            when 2      => Signal_Failure,
            when 4      => Out_Of_Bounds,
            when 7      => Wraparound,
            when others => raise VL53L1X_Error
                   with "invalid status " & Result.Status'Image);
      Valid := Status = Ok;

      if Status = Ok then
         Distance_Mm := Natural (Result.Distance);
      end if;
   end Get_Measurement;

   -------------------------------
   -- Clear_Interrupt --
   -------------------------------

   procedure Clear_Interrupt
     (This : in out VL53L1X_Ranging_Sensor)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_ClearInterrupt
        (dev => This.Dev);
   end Clear_Interrupt;

   ------------------
   -- Stop_Ranging --
   ------------------

   procedure Stop_Ranging
     (This : in out VL53L1X_Ranging_Sensor)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Dummy := VL53L1X_api_h.VL53L1X_StopRanging
        (dev => This.Dev);
      This.State := Initialized;
   end Stop_Ranging;

   --  Local stuff.

   function To_Device (Value : HAL.UInt16) return Two_Byte_Array
   is
      As_Bytes : Two_Byte_Array with Address => Value'Address;
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First =>
            return As_Bytes;
         when System.Low_Order_First =>
            return (1 => As_Bytes (2),
                    2 => As_Bytes (1));
      end case;
   end To_Device;

   function From_Device (Value : Two_Byte_Array) return HAL.UInt16
   is
      function Convert
      is new Ada.Unchecked_Conversion (Two_Byte_Array, HAL.UInt16);
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First =>
            return Convert (Value);
         when System.Low_Order_First =>
            return Convert ((1 => Value (2),
                             2 => Value (1)));
      end case;
   end From_Device;

   function To_Device (Value : HAL.UInt32) return Four_Byte_Array
   is
      As_Bytes : Four_Byte_Array with Address => Value'Address;
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First =>
            return As_Bytes;
         when System.Low_Order_First =>
            return (1 => As_Bytes (4),
                    2 => As_Bytes (3),
                    3 => As_Bytes (2),
                    4 => As_Bytes (1));
      end case;
   end To_Device;

   function From_Device (Value : Four_Byte_Array) return HAL.UInt32
   is
      function Convert
      is new Ada.Unchecked_Conversion (Four_Byte_Array, HAL.UInt32);
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First =>
            return Convert (Value);
         when System.Low_Order_First =>
            return Convert ((1 => Value (4),
                             2 => Value (3),
                             3 => Value (2),
                             4 => Value (1)));
      end case;
   end From_Device;

   --  These are low-level comms routines used in vl53l1_platform.h.
   --  The idea is that the C code can call these.
   --  The specs here are created from the those generated from the C
   --  vl53l1_platform.h in vl53l1_platform_h.ads by replacing
   --  'dev : VL53L1_DEV' by 'dev : in out VL53L1X_Ranging_Sensor'
   --  and 'with Import' by 'with Export'.
   --  To be deleted when we've replaced all the C code!!

   pragma Style_Checks (Off);

   function VL53L1_WriteMulti
     (Dev : in out VL53L1X_Ranging_Sensor;
      Index : HAL.UInt16;
      Pdata : access HAL.UInt8;
      Count : HAL.UInt32) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:25
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_WriteMulti";

   function VL53L1_ReadMulti
     (Dev : in out VL53L1X_Ranging_Sensor;
      Index : HAL.UInt16;
      Pdata : access HAL.UInt8;
      Count : HAL.UInt32) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:33
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_ReadMulti";

   function VL53L1_WrByte
     (Dev : in out VL53L1X_Ranging_Sensor;
      Index : HAL.UInt16;
      Data : HAL.UInt8) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:41
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_WrByte";

   function VL53L1_WrWord
     (Dev : in out VL53L1X_Ranging_Sensor;
      Index : HAL.UInt16;
      Data : HAL.UInt16) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:48
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_WrWord";

   function VL53L1_WrDWord
     (Dev : in out VL53L1X_Ranging_Sensor;
      Index : HAL.UInt16;
      Data : HAL.UInt32) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:55
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_WrDWord";

   function VL53L1_RdByte
     (Dev : in out VL53L1X_Ranging_Sensor;
      Index : HAL.UInt16;
      Pdata : access HAL.UInt8) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:62
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_RdByte";

   function VL53L1_RdWord
     (Dev : in out VL53L1X_Ranging_Sensor;
      Index : HAL.UInt16;
      Pdata : access HAL.UInt16) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:69
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_RdWord";

   function VL53L1_RdDWord
     (Dev : in out VL53L1X_Ranging_Sensor;
      Index : HAL.UInt16;
      Pdata : access HAL.UInt32) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:76
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_RdDWord";

   function VL53L1_WaitMs
     (Dev : in out VL53L1X_Ranging_Sensor;
      Wait_Ms : Interfaces.Integer_32) return Interfaces.Integer_8  -- ../platform/vl53l1_platform.h:83
   with Export => True,
     Convention => C,
     External_Name => "VL53L1_WaitMs";

   pragma Style_Checks (On);

   type UInt8_Array is array (Natural range <>) of aliased HAL.UInt8;

   package C_Pointers is new Interfaces.C.Pointers
     (Index              => Natural,
      Element            => HAL.UInt8,
      Element_Array      => UInt8_Array,
      Default_Terminator => 0);

   -----------------------
   -- VL53L1_WriteMulti --
   -----------------------

   function VL53L1_WriteMulti
     (Dev   : in out VL53L1X_Ranging_Sensor;
      Index :        HAL.UInt16;
      Pdata : access HAL.UInt8;
      Count :        HAL.UInt32)
     return Interfaces.Integer_8
   is
      Data_P : C_Pointers.Pointer := C_Pointers.Pointer (Pdata);
      Buffer : HAL.UInt8_Array (1 .. Natural (Count) + 2);
      Ret : HAL.I2C.I2C_Status;
   begin
      Buffer (1) := HAL.UInt8 (Shift_Right (Index, 8));
      Buffer (2) := HAL.UInt8 (Index and 16#ff#);
      for J in 3 .. Buffer'Last loop
         Buffer (J) := Data_P.all;
         C_Pointers.Increment (Data_P);
      end loop;
      HAL.I2C.Master_Transmit
        (This    => Dev.Port.all,
         Addr    => Dev.I2C_Address,
         Data    => HAL.UInt8_Array (Buffer),
         Status  => Ret);
      case Ret is
         when HAL.I2C.Ok =>
            return 0;
         when others =>
            return raise VL53L1X_Error with "I2C Write error: " & Ret'Image;
      end case;
   end VL53L1_WriteMulti;

   ----------------------
   -- VL53L1_ReadMulti --
   ----------------------

   function VL53L1_ReadMulti
     (Dev   : in out VL53L1X_Ranging_Sensor;
      Index :        HAL.UInt16;
      Pdata : access HAL.UInt8;
      Count :        HAL.UInt32)
     return Interfaces.Integer_8
   is
      Ret : HAL.I2C.I2C_Status;
      use all type HAL.I2C.I2C_Status;
   begin
      HAL.I2C.Master_Transmit
        (This    => Dev.Port.all,
         Addr    => Dev.I2C_Address,
         Data    => (1 => HAL.UInt8 (Shift_Right (Index, 8)),
                     2 => HAL.UInt8 (Index and 16#ff#)),
         Status  => Ret);
      if Ret = Ok then
         Read_Buffer :
         declare
            Buffer : HAL.UInt8_Array (1 .. Natural (Count));
            Data_P : C_Pointers.Pointer := C_Pointers.Pointer (Pdata);
         begin
            HAL.I2C.Master_Receive
              (This    => Dev.Port.all,
               Addr    => Dev.I2C_Address,
               Data    => Buffer,
               Status  => Ret);
            if Ret = Ok then
               for J in Buffer'Range loop
                  Data_P.all := Buffer (J);
                  C_Pointers.Increment (Data_P);
               end loop;
            end if;
         end Read_Buffer;
      end if;
      case Ret is
         when HAL.I2C.Ok =>
            return 0;
         when others =>
            return raise VL53L1X_Error with "I2C Read error: " & Ret'Image;
      end case;
   end VL53L1_ReadMulti;

   -------------------
   -- VL53L1_WrByte --
   -------------------

   function VL53L1_WrByte
     (Dev   : in out VL53L1X_Ranging_Sensor;
      Index :        HAL.UInt16;
      Data  :        HAL.UInt8) return Interfaces.Integer_8
   is
      To_Transmit : aliased HAL.UInt8 := Data;
   begin
      return VL53L1_WriteMulti
        (Dev   => Dev,
         Index => Index,
         Pdata => To_Transmit'Access,
         Count => 1);
   end VL53L1_WrByte;

   -------------------
   -- VL53L1_WrWord --
   -------------------

   function VL53L1_WrWord
     (Dev   : in out VL53L1X_Ranging_Sensor;
      Index :        HAL.UInt16;
      Data  :        HAL.UInt16) return Interfaces.Integer_8
   is
      --  Convert to big-endian.
      subtype Two_Byte_Array is UInt8_Array (1 .. 2);
      As_Bytes : Two_Byte_Array with Address => Data'Address;
      To_Transmit : Two_Byte_Array := (1 => As_Bytes (2),
                                       2 => As_Bytes (1));
   begin
      return VL53L1_WriteMulti
        (Dev   => Dev,
         Index => Index,
         Pdata => To_Transmit (1)'Access,
         Count => To_Transmit'Length);
   end VL53L1_WrWord;

   --------------------
   -- VL53L1_WrDWord --
   --------------------

   function VL53L1_WrDWord
     (Dev   : in out VL53L1X_Ranging_Sensor;
      Index :        HAL.UInt16;
      Data  :        HAL.UInt32) return Interfaces.Integer_8
   is
      --  Convert to big-endian.
      subtype Four_Byte_Array is UInt8_Array (1 .. 4);
      As_Bytes : Four_Byte_Array with Address => Data'Address;
      To_Transmit : Four_Byte_Array := (1 => As_Bytes (4),
                                        2 => As_Bytes (3),
                                        3 => As_Bytes (2),
                                        4 => As_Bytes (1));
   begin
      return VL53L1_WriteMulti
        (Dev   => Dev,
         Index => Index,
         Pdata => To_Transmit (1)'Access,
         Count => To_Transmit'Length);
   end VL53L1_WrDWord;

   -------------------
   -- VL53L1_RdByte --
   -------------------

   function VL53L1_RdByte
     (Dev   : in out VL53L1X_Ranging_Sensor;
      Index :        HAL.UInt16;
      Pdata : access HAL.UInt8) return Interfaces.Integer_8
   is
   begin
      return VL53L1_ReadMulti
        (Dev   => Dev,
         Index => Index,
         Pdata => Pdata,
         Count => 1);
   end VL53L1_RdByte;

   -------------------
   -- VL53L1_RdWord --
   -------------------

   function VL53L1_RdWord
     (Dev   : in out VL53L1X_Ranging_Sensor;
      Index :        HAL.UInt16;
      Pdata : access HAL.UInt16) return Interfaces.Integer_8
   is
      --  Convert from big-endian.
      subtype Two_Byte_Array is UInt8_Array (0 .. 1);
      --  Zero-based indexing for easy byte-reversal arithmetic.
      As_Received : Two_Byte_Array;
      As_Bytes : Two_Byte_Array with Address => Pdata.all'Address;
      Data_P : C_Pointers.Pointer
        := C_Pointers.Pointer'(As_Bytes (As_Bytes'First)'Unchecked_Access);
      Status : Interfaces.Integer_8;
   begin
      Status := VL53L1_ReadMulti
        (Dev   => Dev,
         Index => Index,
         Pdata => As_Received (0)'Access,
         Count => As_Received'Length);
      for J in As_Received'Range loop
         As_Bytes (As_Bytes'Last - J) := As_Received (J);
      end loop;
      return Status;
   end VL53L1_RdWord;

   --------------------
   -- VL53L1_RdDWord --
   --------------------

   function VL53L1_RdDWord
     (Dev   : in out VL53L1X_Ranging_Sensor;
      Index :        HAL.UInt16;
      Pdata : access HAL.UInt32) return Interfaces.Integer_8
   is
      --  Convert from big-endian.
      subtype Four_Byte_Array is UInt8_Array (0 .. 3);
      --  Zero-based indexing for easy byte-reversal arithmetic.
      As_Received : Four_Byte_Array;
      As_Bytes : Four_Byte_Array with Address => Pdata.all'Address;
      Data_P : C_Pointers.Pointer
        := C_Pointers.Pointer'(As_Bytes (As_Bytes'First)'Unchecked_Access);
      Status : Interfaces.Integer_8;
   begin
      Status := VL53L1_ReadMulti
        (Dev   => Dev,
         Index => Index,
         Pdata => As_Received (0)'Access,
         Count => As_Received'Length);
      for J in As_Received'Range loop
         As_Bytes (As_Bytes'Last - J) := As_Received (J);
         C_Pointers.Increment (Data_P);
      end loop;
      return Status;
   end VL53L1_RdDWord;

   -------------------
   -- VL53L1_WaitMs --
   -------------------

   function VL53L1_WaitMs
     (Dev : in out VL53L1X_Ranging_Sensor;
      Wait_Ms : Interfaces.Integer_32)
     return Interfaces.Integer_8
   is
   begin
      Dev.Timing.Delay_Milliseconds (Integer (Wait_Ms));
      return 0;
   end VL53L1_WaitMs;

end VL53L1X;
