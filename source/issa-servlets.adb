--  SPDX-FileCopyrightText: 2024-2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with Ada.Wide_Wide_Text_IO;

with League.Calendars;
with League.Holders;
with League.JSON.Arrays;
with League.JSON.Documents;
with League.JSON.Values;
with League.String_Vectors;

--  with Issa.Sessions;
with Issa.Database;

package body Issa.Servlets is

   use type League.String_Vectors.Universal_String_Vector;

   function "+"
     (Text : Wide_Wide_String) return League.Strings.Universal_String
      renames League.Strings.To_Universal_String;

   procedure Set_Common_Headers
    (Self     : Issa_Servlet'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class);

   procedure Get_Config
    (Self     : Issa_Servlet'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class);

   procedure Get_Comments
    (Self     : Issa_Servlet'Class;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class);

   Config : League.String_Vectors.Universal_String_Vector;
   Empty : League.String_Vectors.Universal_String_Vector;

   Application_JSON : constant League.Strings.Universal_String :=
     +"application/json";

   UTF_8 : constant League.Strings.Universal_String := +"utf-8";

   ------------
   -- Do_Get --
   ------------

   overriding procedure Do_Get
    (Self     : in out Issa_Servlet;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class)
   is
      --  Session   : constant not null Sessions.HTTP_Session_Access :=
      --    Sessions.HTTP_Session_Access (Request.Get_Session);

      Path : constant League.String_Vectors.Universal_String_Vector :=
        Request.Get_Path_Info;
   begin
      Ada.Wide_Wide_Text_IO.Put_Line ("Path_Info:");
      for J in 1 .. Path.Length loop
         Ada.Wide_Wide_Text_IO.Put_Line (Path.Element (J).To_Wide_Wide_String);
      end loop;

      if Path.Is_Empty or Path = Empty then
         Self.Get_Comments (Request, Response);
      elsif Path = Config then
         Self.Get_Config (Response);
      else
         Response.Set_Status (Servlet.HTTP_Responses.Not_Found);
         Response.Set_Content_Type (+"text/plain");
         Response.Set_Character_Encoding (UTF_8);
         Response.Get_Output_Stream.Write (+"No such request: ");
         Response.Get_Output_Stream.Write (Path.Join ('/'));
      end if;

      --  Session.Count (Counter);
   end Do_Get;

   ----------------
   -- Do_Options --
   ----------------

   overriding procedure Do_Options
    (Self     : in out Issa_Servlet;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class) is
   begin
      Self.Set_Common_Headers (Response);
      Response.Set_Status (Servlet.HTTP_Responses.OK);
      Response.Set_Content_Type (+"text/plain");
      Response.Set_Character_Encoding (UTF_8);
   end Do_Options;

   ------------------
   -- Get_Comments --
   ------------------

   procedure Get_Comments
    (Self     : Issa_Servlet'Class;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class)
   is
      procedure Callback (V : Issa.Database.Comment);

      function Format (V : League.Strings.Universal_String)
        return League.Strings.Universal_String is (V);

      List : League.JSON.Arrays.JSON_Array;

      procedure Callback (V : Issa.Database.Comment) is
         use type League.Holders.Universal_Integer;
         use type League.Holders.Universal_Float;
         Object : League.JSON.Objects.JSON_Object;

         Mode_Map : constant array (Issa.Database.Comment_Status)
           of League.Holders.Universal_Integer :=
             [Issa.Database.Valid => 1,
              Issa.Database.Pending => 2,
              Issa.Database.Soft_Deleted => 4];
      begin
         Object.Insert (+"id", League.JSON.Values.To_JSON_Value (V.Id));

         Object.Insert
           (+"parent",
            (if V.Parent = 0 then League.JSON.Values.Null_JSON_Value
             else League.JSON.Values.To_JSON_Value (V.Parent)));

         Object.Insert
           (+"created", League.JSON.Values.To_JSON_Value (V.Created));

         Object.Insert
           (+"modified",
            (if V.Created = V.Modified then League.JSON.Values.Null_JSON_Value
             else League.JSON.Values.To_JSON_Value (V.Modified)));

         Object.Insert
           (+"mode",
            League.JSON.Values.To_JSON_Value (Mode_Map (V.Mode)));

         Object.Insert
           (+"text", League.JSON.Values.To_JSON_Value (Format (V.Text)));

         Object.Insert
           (+"author", League.JSON.Values.To_JSON_Value (V.Author));

         Object.Insert (+"website", League.JSON.Values.To_JSON_Value (V.Site));
         Object.Insert (+"likes", League.JSON.Values.To_JSON_Value (V.Likes));

         Object.Insert
           (+"dislikes", League.JSON.Values.To_JSON_Value (V.Dislikes));

         Object.Insert
           (+"notification", League.JSON.Values.To_JSON_Value (V.Notifs));

         Object.Insert
           (+"hash", League.JSON.Values.To_JSON_Value (+"0"));

         Object.Insert
           (+"total_replies",
            League.JSON.Values.To_JSON_Value (V.Total_Replies));

         Object.Insert
           (+"hidden_replies",
            League.JSON.Values.To_JSON_Value (0));

         Object.Insert
           (+"replies",
            League.JSON.Arrays.Empty_JSON_Array.To_JSON_Value);

         List.Append (Object.To_JSON_Value);
      end Callback;

      URI    : constant League.Strings.Universal_String :=
        Request.Get_Parameter (+"uri");
      Total  : League.Holders.Universal_Integer := 0;
      Hidden : constant League.Holders.Universal_Integer := 0;
      JSON : League.JSON.Objects.JSON_Object;
      Text : League.Strings.Universal_String;
   begin
      Ada.Wide_Wide_Text_IO.Put_Line ("URI=" & URI.To_Wide_Wide_String);
      Issa.Database.Fetch (URI, Callback'Access);
      JSON.Insert (+"id", League.JSON.Values.Null_JSON_Value);
      --  Id of the comment `replies` is the list of replies of. `null` for the
      --  list of top-level comments.

      JSON.Insert (+"replies", List.To_JSON_Value);
      --  The list of comments. Each comment also has the `total_replies`,
      --  `replies`, `id` and `hidden_replies` properties to represent nested
      --  comments.

      Total := League.Holders.Universal_Integer (List.Length);
      --  ???

      JSON.Insert (+"total_replies", League.JSON.Values.To_JSON_Value (Total));
      --  The number of replies if the `limit` parameter was not set. If
      --  `after` is set to `X`, this is the number of comments that were
      --  created after `X`. So setting `after` may change this value!

      JSON.Insert
        (+"hidden_replies", League.JSON.Values.To_JSON_Value (Hidden));
      --  The number of comments that were omitted from the results because of
      --  the `limit` request parameter. Usually, this will be `total_replies`
      --  - `limit`.

      JSON.Insert (+"config", Self.Config.To_JSON_Value);
      Self.Set_Common_Headers (Response);
      Response.Set_Status (Servlet.HTTP_Responses.OK);
      Response.Set_Content_Type (Application_JSON);
      Response.Set_Character_Encoding (UTF_8);
      Text := JSON.To_JSON_Document.To_JSON;
      Response.Get_Output_Stream.Write (Text);
   end Get_Comments;

   ----------------
   -- Get_Config --
   ----------------

   procedure Get_Config
    (Self     : Issa_Servlet'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class)
   is
      JSON : League.JSON.Objects.JSON_Object;
      Text : League.Strings.Universal_String;
   begin
      JSON.Insert (+"config", Self.Config.To_JSON_Value);
      Self.Set_Common_Headers (Response);
      Response.Set_Status (Servlet.HTTP_Responses.OK);
      Response.Set_Content_Type (Application_JSON);
      Response.Set_Character_Encoding (UTF_8);
      Text := JSON.To_JSON_Document.To_JSON;
      Response.Get_Output_Stream.Write (Text);
   end Get_Config;

   ----------------------
   -- Get_Servlet_Info --
   ----------------------

   overriding function Get_Servlet_Info
    (Self : Issa_Servlet) return League.Strings.Universal_String
   is
      pragma Unreferenced (Self);
      Text : constant Wide_Wide_String :=
        "Hello servlet renders Hello_World result";
   begin
      return +Text;
   end Get_Servlet_Info;

   -----------------
   -- Instantiate --
   -----------------

   overriding function Instantiate
    (Parameters : not null access
       Servlet.Generic_Servlets.Instantiation_Parameters'Class)
         return Issa_Servlet
   is
      pragma Unreferenced (Parameters);

      JSON_False : constant League.JSON.Values.JSON_Value :=
        League.JSON.Values.To_JSON_Value (False);
   begin
      return Result : Issa_Servlet :=
        (Servlet.HTTP_Servlets.HTTP_Servlet with
           Server => +"http://192.168.1.121:8081",
         Config => <>)
      do
         --  Result.Config.Insert (+"avatar", JSON_False);
         Result.Config.Insert (+"feed", JSON_False);
         Result.Config.Insert (+"gravatar", JSON_False);
         Result.Config.Insert (+"reply-notifications", JSON_False);
         Result.Config.Insert (+"reply-to-self", JSON_False);
         Result.Config.Insert (+"require-author", JSON_False);
         Result.Config.Insert (+"require-email", JSON_False);
      end return;
   end Instantiate;

   ------------------------
   -- Set_Common_Headers --
   ------------------------

   procedure Set_Common_Headers
    (Self     : Issa_Servlet'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class)
   is
      pragma Unreferenced (Self);
   begin
      Response.Set_Header (+"Access-Control-Allow-Credentials", +"true");

      Response.Set_Header
        (+"Access-Control-Allow-Headers", +"Origin, Referer, Content-Type");

      Response.Set_Header
        (+"Access-Control-Allow-Methods", +"HEAD, GET, POST, PUT, DELETE");

      Response.Set_Header
        (+"Access-Control-Allow-Origin", +"http://192.168.1.121:8081");

      Response.Set_Header
        (+"Access-Control-Expose-Headers", +"X-Set-Cookie, Date");

      Response.Add_Date_Header (+"Last-Modified", League.Calendars.Clock);
   end Set_Common_Headers;

begin
   Config.Append (+"config");
   Empty.Append (+"");
end Issa.Servlets;
