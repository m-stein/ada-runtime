--  Copyright (C) 2018 Componolit GmbH
--
--  This file is part of the Componolit Ada runtime, which is distributed
--  under the terms of the GNU Affero General Public License version 3.
--
--  As a special exception under Section 7 of GPL version 3, you are granted
--  additional permissions described in the GCC Runtime Library Exception,
--  version 3.1, as published by the Free Software Foundation.

with Ss_Utils;

package body System.Secondary_Stack is

   procedure SS_Allocate (
                          Address      : out System.Address;
                          Storage_Size : SSE.Storage_Count
                         )
   is
   begin
      Ss_Utils.S_Allocate (Address, Storage_Size);
   end SS_Allocate;

   function SS_Mark return Mark_Id
   is
      M : Mark_Id;
   begin
      Ss_Utils.S_Mark (M.Sstk, SSE.Storage_Count (M.Sptr));
      return M;
   end SS_Mark;

   procedure SS_Release (
                         M : Mark_Id
                        )
   is
   begin
      Ss_Utils.S_Release (M.Sstk, SSE.Storage_Count (M.Sptr));
   end SS_Release;

end System.Secondary_Stack;
