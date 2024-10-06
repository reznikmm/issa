--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

package body Issa.Sessions is

   -----------
   -- Count --
   -----------

   procedure Count
     (Self   : in out HTTP_Session'Class;
      Result : out Natural) is
   begin
      Self.Count := Self.Count + 1;
      Result := Self.Count;
   end Count;

end Issa.Sessions;
