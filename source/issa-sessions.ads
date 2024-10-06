--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with League.Strings;
with League.Calendars;

--  limited with Sessions.Managers;

with Servlet.HTTP_Sessions;

package Issa.Sessions is

   type HTTP_Session is new Servlet.HTTP_Sessions.HTTP_Session with private;

   type HTTP_Session_Access is access all HTTP_Session'Class;

   procedure Count
     (Self   : in out HTTP_Session'Class;
      Result : out Natural);
   --  Increment a counter and return current value.

private

   type HTTP_Session is new Servlet.HTTP_Sessions.HTTP_Session with record
      Id    : League.Strings.Universal_String;
      Count : Natural := 0;
   end record;

   overriding function Get_Id
    (Self : HTTP_Session) return League.Strings.Universal_String is (Self.Id);

   overriding function Get_Creation_Time
    (Self : HTTP_Session) return League.Calendars.Date_Time is
       (raise Program_Error with "Unimplemented");

   overriding function Get_Last_Accessed_Time
     (Self : HTTP_Session) return League.Calendars.Date_Time is
       (raise Program_Error with "Unimplemented");

   overriding function Is_New (Self : HTTP_Session) return Boolean is
     (raise Program_Error with "Unimplemented");

end Issa.Sessions;
