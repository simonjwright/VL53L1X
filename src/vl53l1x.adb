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

   --  In all cases (aside from e.g. VL53L1X_SetDistanceMode(), where
   --  it's an out-of-bounds error that won't happen in Ada) the
   --  return value of the API function merely indicates an I2C
   --  error. I'm going to raise exceptions for I2C errors (on the
   --  grounds that I have no idea how one would recover from them).
   --
   --  I'm retaining the low-level (I2C) status because the API
   --  functions use it.

   pragma Warnings (Off, "useless assignment to ""Status""");

   -----------------
   -- Boot_Device --
   -----------------

   procedure Boot_Device
     (This             : in out VL53L1X_Ranging_Sensor;
      Loop_Interval_Ms :        Positive := 10;
      Status           :    out Boolean)
   is
      function Convert is new Ada.Unchecked_Conversion
        (System.Address, vl53l1_platform_h.VL53L1_DEV);
      State : aliased sys_ustdint_h.uint8_t := 0;
      use type sys_ustdint_h.uint8_t;
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Status := False;
      --  The C code thinks that VL53L1_DEV is a pointer to <something>,
      --  but it never tries to access any component of it.
      This.Dev := Convert (This'Address);

      --  Allow the VL53L1X to do its internal initialization.
      This.Timing.Delay_Milliseconds (100);
      for J in 1 .. 10 loop
         Dummy := VL53L1X_api_h.VL53L1X_BootState
           (dev   => This.Dev,
            state => State'Unchecked_Access);
         if State = 3  -- undocumented; UM2150 says 1
         then
            This.Booted := True;
         end if;
         This.Timing.Delay_Milliseconds (Loop_Interval_Ms);
      end loop;

      Status := This.Booted;
   end Boot_Device;

   ------------------------
   -- Set_Device_Address --
   ------------------------

   procedure Set_Device_Address
     (This   : in out VL53L1X_Ranging_Sensor;
      Addr   :        HAL.I2C.I2C_Address;
      Status :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Status := False;
      Dummy := VL53L1X_api_h.VL53L1X_SetI2CAddress
        (dev         => This.Dev,
         new_address => sys_ustdint_h.uint8_t (Addr));
      Status := True;
      This.I2C_Address := Addr;
   end Set_Device_Address;

   -----------------
   -- Sensor_Init --
   -----------------

   procedure Sensor_Init
     (This          : in out VL53L1X_Ranging_Sensor;
      Status        : out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Status := False;
      Dummy := VL53L1X_api_h.VL53L1X_SensorInit
        (dev => This.Dev);
      Status := True;
      This.Sensor_Initialized := True;
   end Sensor_Init;

   -----------------------
   -- Get_Distance_Mode --
   -----------------------

   procedure Get_Distance_Mode
     (This   : in out VL53L1X_Ranging_Sensor;
      Mode   :    out Distance_Mode;
      Status :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
      LL_Mode : aliased sys_ustdint_h.uint16_t;
   begin
      Status := False;
      Dummy := VL53L1X_api_h.VL53L1X_GetDistanceMode
        (dev           => This.Dev,
         pDistanceMode => LL_Mode'Access);
      Mode := (case LL_Mode is
                  when 1      => Short,
                  when 2      => Long,
                  when others =>
                     raise VL53L1X_Error
                         with "invalid distance mode" & LL_Mode'Image);
      Status := True;
   end Get_Distance_Mode;

   -----------------------
   -- Set_Distance_Mode --
   -----------------------

   procedure Set_Distance_Mode
     (This   : in out VL53L1X_Ranging_Sensor;
      Mode   :        Distance_Mode := Long;
      Status :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Status := False;
      Dummy := VL53L1X_api_h.VL53L1X_SetDistanceMode
        (dev          => This.Dev,
         DistanceMode => (case Mode is
                             when Short => 1,
                             when Long  => 2));
      Status := True;
   end Set_Distance_Mode;

   -----------------
   -- Get_Timings --
   -----------------

   procedure Get_Timings
     (This                    : in out VL53L1X_Ranging_Sensor;
      Measurement_Budget_Ms   :    out Budget_Millisec;
      Between_Measurements_Ms :    out Natural;
      Status                  :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
      Ms : aliased sys_ustdint_h.uint16_t;
   begin
      Status := False;

      Dummy := VL53L1X_api_h.VL53L1X_GetTimingBudgetInMs
        (dev               => This.Dev,
         pTimingBudgetInMs => Ms'Access);
      Measurement_Budget_Ms := Budget_Millisec (Ms);

      Dummy := VL53L1X_api_h.VL53L1X_GetInterMeasurementInMs
        (dev => This.Dev,
         pIM => Ms'Access);
      Between_Measurements_Ms := Natural (Ms);

      Status := True;
   end Get_Timings;

   -----------------
   -- Set_Timings --
   -----------------

   procedure Set_Timings
     (This                    : in out VL53L1X_Ranging_Sensor;
      Measurement_Budget_Ms   :        Budget_Millisec := 100;
      Between_Measurements_Ms :        Natural := 100;
      Status                  :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Status := True;
      Dummy := VL53L1X_api_h.VL53L1X_SetTimingBudgetInMs
        (dev              => This.Dev,
         TimingBudgetInMs =>
           sys_ustdint_h.uint16_t (Measurement_Budget_Ms));
      Dummy := VL53L1X_api_h.VL53L1X_SetInterMeasurementInMs
        (dev => This.Dev,
         InterMeasurementInMs =>
           sys_ustdint_h.uint32_t (Between_Measurements_Ms));
      Status := True;
   end Set_Timings;

   -------------------
   -- Start_Ranging --
   -------------------

   procedure Start_Ranging
     (This   : in out VL53L1X_Ranging_Sensor;
      Status :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Status := False;
      Dummy := VL53L1X_api_h.VL53L1X_StartRanging
        (dev => This.Dev);
      This.Ranging_Started := True;
      Status := True;
   end Start_Ranging;

   --------------------------
   -- Wait_For_Measurement --
   --------------------------

   procedure Wait_For_Measurement
     (This             : in out VL53L1X_Ranging_Sensor;
      Loop_Interval_Ms :        Positive := 10;
      Status           :    out Boolean)
   is
      Ready : Boolean;
   begin
      Status := False;
      loop
         Is_Measurement_Ready (This,
                               Ready  => Ready,
                               Status => Status);
         exit when Ready;
         This.Timing.Delay_Milliseconds (Loop_Interval_Ms);
      end loop;
      Status := True;
   end Wait_For_Measurement;

   --------------------------
   -- Is_Measurement_Ready --
   --------------------------

   procedure Is_Measurement_Ready
     (This   : in out VL53L1X_Ranging_Sensor;
      Ready  :    out Boolean;
      Status :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
      Result : aliased sys_ustdint_h.uint8_t;
      use type sys_ustdint_h.uint8_t;
   begin
      Status := False;
      Dummy := VL53L1X_api_h.VL53L1X_CheckForDataReady
        (dev         => This.Dev,
         isDataReady => Result'Access);
      Ready := Result = 1;
      Status := True;
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
     (This     : in out VL53L1X_Ranging_Sensor;
      Status   :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Status := False;
      Dummy := VL53L1X_api_h.VL53L1X_ClearInterrupt
        (dev => This.Dev);
      Status := True;
   end Clear_Interrupt;

   ------------------
   -- Stop_Ranging --
   ------------------

   procedure Stop_Ranging
     (This   : in out VL53L1X_Ranging_Sensor;
      Status :    out Boolean)
   is
      Dummy : VL53L1X_api_h.VL53L1X_ERROR;
   begin
      Status := False;
      Dummy := VL53L1X_api_h.VL53L1X_StopRanging
        (dev => This.Dev);
      This.Ranging_Started := False;
      Status := True;
   end Stop_Ranging;

   --  Local stuff.

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
