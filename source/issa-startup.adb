--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with Ada.Text_IO;

with Spikedog.HTTP_Session_Managers;
with Spikedog.Servlet_Contexts;

with Issa.Sessions.Managers;

--  List of used servlets:
with Issa.Servlets;
pragma Unreferenced (Issa.Servlets);

package body Issa.Startup is

   overriding procedure On_Startup
    (Self    : in out Servlet_Container_Initializer;
     Context : in out Servlet.Contexts.Servlet_Context'Class)
   is
      pragma Unreferenced (Self);

      Manager : constant Issa.Sessions.Managers.HTTP_Session_Manager_Access :=
        new Sessions.Managers.HTTP_Session_Manager;
   begin
      Ada.Text_IO.Put_Line ("Open: http://localhost:8080/count");

      Spikedog.Servlet_Contexts.Spikedog_Servlet_Context'Class
        (Context).Set_Session_Manager
          (Spikedog.HTTP_Session_Managers.HTTP_Session_Manager_Access
             (Manager));
   end On_Startup;

end Issa.Startup;
