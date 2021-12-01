pragma Ada_2012;
pragma Style_Checks (Off);
pragma Warnings ("U");

with Interfaces.C; use Interfaces.C;
with System;

package stddef_h is

   --  unsupported macro: NULL __null
   --  arg-macro: procedure offsetof (TYPE, MEMBER)
   --    __builtin_offsetof (TYPE, MEMBER)
   subtype ptrdiff_t is int;  -- /opt/gcc-11.2.0/lib/gcc/arm-eabi/11.2.0/include/stddef.h:143

   subtype size_t is unsigned;  -- /opt/gcc-11.2.0/lib/gcc/arm-eabi/11.2.0/include/stddef.h:209

   --  skipped anonymous struct anon_anon_0

   type max_align_t is record
      uu_max_align_ll : aliased Long_Long_Integer;  -- /opt/gcc-11.2.0/lib/gcc/arm-eabi/11.2.0/include/stddef.h:416
      uu_max_align_ld : aliased long_double;  -- /opt/gcc-11.2.0/lib/gcc/arm-eabi/11.2.0/include/stddef.h:417
   end record
   with Convention => C_Pass_By_Copy;  -- /opt/gcc-11.2.0/lib/gcc/arm-eabi/11.2.0/include/stddef.h:426

   subtype nullptr_t is System.Address;  -- /opt/gcc-11.2.0/lib/gcc/arm-eabi/11.2.0/include/stddef.h:433

end stddef_h;
