--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with Ada.IO_Exceptions;
with Ada.Streams.Stream_IO;
with League.String_Vectors;
with League.Text_Codecs;

package body Issa.File is

   function "+"
     (Text : Wide_Wide_String) return League.Strings.Universal_String
      renames League.Strings.To_Universal_String;

   ----------------------
   -- Get_Servlet_Info --
   ----------------------

   overriding function Get_Servlet_Info
     (Self : File_Servlet) return League.Strings.Universal_String
   is
      pragma Unreferenced (Self);
      Text : constant Wide_Wide_String :=
        "Hello servlet provides WebSocket upgrade responses";
   begin
      return +Text;
   end Get_Servlet_Info;

   ------------
   -- Do_Get --
   ------------

   overriding procedure Do_Get
     (Self     : in out File_Servlet;
      Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
      Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class)
   is
      Input : Ada.Streams.Stream_IO.File_Type;

      PI : constant League.String_Vectors.Universal_String_Vector'Class :=
        Request.Get_Path_Info;

      Path : League.String_Vectors.Universal_String_Vector :=
        Request.Get_Servlet_Path;

      function File return String is
        (League.Text_Codecs.To_Exception_Message
           (Path.Join ('/')));
   begin
      Path.Append (PI);

      Response.Set_Status (Servlet.HTTP_Responses.OK);
      --  Response.Set_Content_Type (+"text/html");
      Response.Set_Character_Encoding (+"utf-8");

      Response.Set_Header (+"Access-Control-Allow-Credentials", +"true");

      Response.Set_Header
        (+"Access-Control-Allow-Headers", +"Origin, Referer, Content-Type");

      Response.Set_Header
        (+"Access-Control-Allow-Methods", +"HEAD, GET, POST, PUT, DELETE");

      Response.Set_Header
        (+"Access-Control-Allow-Origin", +"http://192.168.1.121:8081");

      Response.Set_Header
        (+"Access-Control-Expose-Heades", +"X-Set-Cookie, Date");

      Ada.Streams.Stream_IO.Open
        (Input, Ada.Streams.Stream_IO.In_File, "install/" & File);
      loop
         declare
            use type Ada.Streams.Stream_Element_Offset;
            Buffer : Ada.Streams.Stream_Element_Array (1 .. 1024);
            Last   : Ada.Streams.Stream_Element_Offset;
         begin
            Ada.Streams.Stream_IO.Read (Input, Buffer, Last);
            exit when Last = 0;
            Response.Get_Output_Stream.Write (Buffer (1 .. Last));
         end;
      end loop;

      Ada.Streams.Stream_IO.Close (Input);
   exception
      when Ada.IO_Exceptions.Use_Error =>
         Response.Set_Status (Servlet.HTTP_Responses.Not_Found);
   end Do_Get;

   -----------------
   -- Instantiate --
   -----------------

   overriding function Instantiate
     (Parameters : not null access Servlet.Generic_Servlets
        .Instantiation_Parameters'
        Class)
      return File_Servlet
   is
      pragma Unreferenced (Parameters);
   begin
      return (Servlet.HTTP_Servlets.HTTP_Servlet with null record);
   end Instantiate;

end Issa.File;
