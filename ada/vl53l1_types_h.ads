pragma Ada_2012;
pragma Style_Checks (Off);
pragma Warnings ("U");

with Interfaces.C; use Interfaces.C;
with sys_ustdint_h;

package vl53l1_types_h is

   subtype FixPoint1616_t is sys_ustdint_h.uint32_t;  -- ../platform/vl53l1_types.h:109

end vl53l1_types_h;
