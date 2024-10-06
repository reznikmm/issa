--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with Spikedog.HTTP_Session_Managers;

package Issa.Sessions.Managers is

   type HTTP_Session_Manager is limited
     new Spikedog.HTTP_Session_Managers.HTTP_Session_Manager with private;

   type HTTP_Session_Manager_Access is access all HTTP_Session_Manager'Class;

   procedure Initialize (Self : in out HTTP_Session_Manager);

private

   type HTTP_Session_Manager is limited
     new Spikedog.HTTP_Session_Managers.HTTP_Session_Manager with
   record
      One : Issa.Sessions.HTTP_Session_Access;
   end record;

   overriding function Is_Session_Identifier_Valid
    (Self       : HTTP_Session_Manager;
     Identifier : League.Strings.Universal_String) return Boolean;

   overriding function Get_Session
    (Self       : in out HTTP_Session_Manager;
     Identifier : League.Strings.Universal_String)
       return access Servlet.HTTP_Sessions.HTTP_Session'Class;

   overriding function New_Session
    (Self : in out HTTP_Session_Manager)
       return access Servlet.HTTP_Sessions.HTTP_Session'Class;

   overriding procedure Change_Session_Id
    (Self    : in out HTTP_Session_Manager;
     Session : not null access Servlet.HTTP_Sessions.HTTP_Session'Class);

end Issa.Sessions.Managers;
