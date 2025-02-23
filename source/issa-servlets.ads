--  SPDX-FileCopyrightText: 2024-2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with League.Strings;
with League.JSON.Objects;

with Servlet.Generic_Servlets;
with Servlet.HTTP_Requests;
with Servlet.HTTP_Responses;
with Servlet.HTTP_Servlets;

package Issa.Servlets is

   type Issa_Servlet is new Servlet.HTTP_Servlets.HTTP_Servlet
     with private;

private

   type Issa_Servlet is new Servlet.HTTP_Servlets.HTTP_Servlet with record
      Server : League.Strings.Universal_String;
      --  Server in form of "http://192.168.1.1:8081"
      Config : League.JSON.Objects.JSON_Object;
      --  The client configuration parameters that depend on server settings.
   end record;

   overriding function Get_Servlet_Info
    (Self : Issa_Servlet) return League.Strings.Universal_String;

   overriding procedure Do_Get
    (Self     : in out Issa_Servlet;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class);

   overriding procedure Do_Options
    (Self     : in out Issa_Servlet;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class);

   overriding procedure Do_Post
    (Self     : in out Issa_Servlet;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class);

   overriding function Instantiate
    (Parameters : not null access
       Servlet.Generic_Servlets.Instantiation_Parameters'Class)
         return Issa_Servlet;

end Issa.Servlets;
