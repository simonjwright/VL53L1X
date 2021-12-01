pragma Ada_2012;
pragma Style_Checks (Off);
pragma Warnings ("U");

with Interfaces.C; use Interfaces.C;
with sys_ustdint_h;

package vl53l1_platform_h is

   --  skipped anonymous struct anon_anon_1

   type VL53L1_Dev_t is record
      dummy : aliased sys_ustdint_h.uint32_t;  -- ../platform/vl53l1_platform.h:19
   end record
   with Convention => C_Pass_By_Copy;  -- ../platform/vl53l1_platform.h:20

   type VL53L1_DEV is access all VL53L1_Dev_t;  -- ../platform/vl53l1_platform.h:22

   function VL53L1_WriteMulti
     (dev : VL53L1_DEV;
      index : sys_ustdint_h.uint16_t;
      pdata : access sys_ustdint_h.uint8_t;
      count : sys_ustdint_h.uint32_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:27
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_WriteMulti";

   function VL53L1_ReadMulti
     (dev : VL53L1_DEV;
      index : sys_ustdint_h.uint16_t;
      pdata : access sys_ustdint_h.uint8_t;
      count : sys_ustdint_h.uint32_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:35
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_ReadMulti";

   function VL53L1_WrByte
     (dev : VL53L1_DEV;
      index : sys_ustdint_h.uint16_t;
      data : sys_ustdint_h.uint8_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:43
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_WrByte";

   function VL53L1_WrWord
     (dev : VL53L1_DEV;
      index : sys_ustdint_h.uint16_t;
      data : sys_ustdint_h.uint16_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:50
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_WrWord";

   function VL53L1_WrDWord
     (dev : VL53L1_DEV;
      index : sys_ustdint_h.uint16_t;
      data : sys_ustdint_h.uint32_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:57
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_WrDWord";

   function VL53L1_RdByte
     (dev : VL53L1_DEV;
      index : sys_ustdint_h.uint16_t;
      pdata : access sys_ustdint_h.uint8_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:64
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_RdByte";

   function VL53L1_RdWord
     (dev : VL53L1_DEV;
      index : sys_ustdint_h.uint16_t;
      pdata : access sys_ustdint_h.uint16_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:71
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_RdWord";

   function VL53L1_RdDWord
     (dev : VL53L1_DEV;
      index : sys_ustdint_h.uint16_t;
      pdata : access sys_ustdint_h.uint32_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:78
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_RdDWord";

   function VL53L1_WaitMs (dev : VL53L1_DEV; wait_ms : sys_ustdint_h.int32_t) return sys_ustdint_h.int8_t  -- ../platform/vl53l1_platform.h:85
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1_WaitMs";

end vl53l1_platform_h;
