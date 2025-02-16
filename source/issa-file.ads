--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with League.Strings;

with Servlet.Generic_Servlets;
with Servlet.HTTP_Requests;
with Servlet.HTTP_Responses;
with Servlet.HTTP_Servlets;

package Issa.File is

   type File_Servlet is new Servlet.HTTP_Servlets.HTTP_Servlet
     with private;

private

   type File_Servlet is
     new Servlet.HTTP_Servlets.HTTP_Servlet with null record;

   overriding function Get_Servlet_Info
    (Self : File_Servlet) return League.Strings.Universal_String;

   overriding procedure Do_Get
    (Self     : in out File_Servlet;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class);

   overriding function Instantiate
    (Parameters : not null access
       Servlet.Generic_Servlets.Instantiation_Parameters'Class)
         return File_Servlet;

end Issa.File;
