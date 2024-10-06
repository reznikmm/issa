--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

package body Issa.Sessions.Managers is

   -----------------------
   -- Change_Session_Id --
   -----------------------

   overriding procedure Change_Session_Id
    (Self    : in out HTTP_Session_Manager;
     Session : not null access Servlet.HTTP_Sessions.HTTP_Session'Class) is
   begin
      raise Program_Error with "Unimplemented";
   end Change_Session_Id;

   -----------------
   -- Get_Session --
   -----------------

   overriding function Get_Session
     (Self       : in out HTTP_Session_Manager;
      Identifier : League.Strings.Universal_String)
      return access Servlet.HTTP_Sessions.HTTP_Session'Class
   is
   begin
      if Identifier.To_Wide_Wide_String = "aaa" then
         return Self.One;
      else
         return null;
      end if;
   end Get_Session;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out HTTP_Session_Manager) is
   begin
      Self.One := null;
   end Initialize;

   ---------------------------------
   -- Is_Session_Identifier_Valid --
   ---------------------------------

   overriding function Is_Session_Identifier_Valid
     (Self       : HTTP_Session_Manager;
      Identifier : League.Strings.Universal_String)
      return Boolean
   is
   begin
      return Identifier.To_Wide_Wide_String = "aaa";
   end Is_Session_Identifier_Valid;

   -----------------
   -- New_Session --
   -----------------

   overriding function New_Session
     (Self : in out HTTP_Session_Manager)
      return access Servlet.HTTP_Sessions.HTTP_Session'Class
   is
      New_Id : constant League.Strings.Universal_String :=
        League.Strings.To_Universal_String ("aaa");

   begin
      Self.One := new Sessions.HTTP_Session'
        (Servlet.HTTP_Sessions.HTTP_Session with Id => New_Id, Count => 0);

      return Self.One;
   end New_Session;

end Issa.Sessions.Managers;
