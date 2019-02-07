--  Copyright (C) 2018 Componolit GmbH
--
--  This file is part of the Componolit Ada runtime, which is distributed
--  under the terms of the GNU Affero General Public License version 3.
--
--  As a special exception under Section 7 of GPL version 3, you are granted
--  additional permissions described in the GCC Runtime Library Exception,
--  version 3.1, as published by the Free Software Foundation.

with System;
with System.Storage_Elements;
use all type System.Address;
use all type System.Storage_Elements.Integer_Address;

package String_Utils
   with SPARK_Mode
is
   pragma Preelaborate;

   function Length (C_Str      : System.Address;
                    Max_Length : Natural := Natural'Last) return Integer
     with
       Post => Length'Result <= Max_Length,
       Contract_Cases =>
         (C_Str = System.Null_Address  => Length'Result <= 0,
          C_Str /= System.Null_Address => Length'Result >= 0);

   function Convert_To_Ada (C_Str      : System.Address;
                            Default    : String;
                            Max_Length : Natural :=
                              Natural'Last) return String;

private

   package SSE renames System.Storage_Elements;

   subtype Pointer is SSE.Integer_Address;

   Null_Pointer : constant Pointer := 0;

   function Get_Char (Ptr : Pointer) return Character
     with
       Pre => Ptr /= Null_Pointer;

   function Incr (Ptr : Pointer) return Pointer
     with
       Pre => Ptr /= Null_Pointer,
       Post => Incr'Result /= Null_Pointer;

   function To_Address (Value : Pointer) return System.Address
     with
       Contract_Cases =>
         (Value = Null_Pointer => To_Address'Result = System.Null_Address,
          Value /= Null_Pointer => To_Address'Result /= System.Null_Address);

   function To_Pointer (Addr : System.Address) return Pointer
     with
       Contract_Cases =>
         (Addr = System.Null_Address => To_Pointer'Result = Null_Pointer,
          Addr /= System.Null_Address => To_Pointer'Result /= Null_Pointer);

end String_Utils;