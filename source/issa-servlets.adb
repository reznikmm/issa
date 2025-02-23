--  SPDX-FileCopyrightText: 2024-2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with Ada.Streams;
with Ada.Wide_Wide_Text_IO;

with League.Calendars;
with League.Holders;
with League.JSON.Arrays;
with League.JSON.Documents;
with League.JSON.Values;
with League.Stream_Element_Vectors;
with League.String_Vectors;
with League.Regexps;

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

   procedure New_Comment
     (Self     : Issa_Servlet'Class;
      URI      : League.Strings.Universal_String;
      JSON     : in out League.JSON.Objects.JSON_Object;
      Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class);

   procedure To_JSON
    (Request : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     JSON    : out League.JSON.Objects.JSON_Object);

   Config : League.String_Vectors.Universal_String_Vector;
   Empty : League.String_Vectors.Universal_String_Vector;
   New_Path : League.String_Vectors.Universal_String_Vector;

   Application_JSON : constant League.Strings.Universal_String :=
     +"application/json";

   W  : constant Wide_Wide_String := "[\p{L}\p{N}\p{Pc}]";
   --  letter, digit or underscores

   Wd : constant Wide_Wide_String := "[\p{L}\p{N}\p{Pc}\-]";
   --  letter, digit or underscores and a minus

   Domain : constant Wide_Wide_String :=
     "(?:" &
     W & "(?:" & Wd & "*" & W & ")?" &
     "\.)+" &
     "(?:" & W & "{2,6}\.?|" & Wd & "{2,}\.?)";

   Is_URI_Pattern : constant Wide_Wide_String :=
     "^https?\:\/\/" &
     --  domain
     "(?:" &
     Domain &
     "|localhost|" &  --  or localhost
     "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" &  --  or ip v4
     ")" &
     "(?:\:[0-9]+)?" &  --  optional port
     "(?:[\/\?][\P{Separator}]+|\/?)" &  --  URI segments
     "$";

   Is_URI : constant League.Regexps.Regexp_Pattern :=
     League.Regexps.Compile (+Is_URI_Pattern);

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

   -------------
   -- Do_Post --
   -------------

   overriding procedure Do_Post
    (Self     : in out Issa_Servlet;
     Request  : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class)
   is
      Path : constant League.String_Vectors.Universal_String_Vector :=
        Request.Get_Path_Info;

      URI  : constant League.Strings.Universal_String :=
        Request.Get_Parameter (+"uri");

      JSON : League.JSON.Objects.JSON_Object;
   begin
      To_JSON (Request, JSON);

      if Path = New_Path
        and not JSON.Is_Empty
        and not URI.Is_Empty
      then
         Self.New_Comment (URI, JSON, Response);
      end if;
   end Do_Post;

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

      --------------
      -- Callback --
      --------------

      procedure Callback (V : Issa.Database.Comment) is
         use type League.Holders.Universal_Integer;
         --  use type League.Holders.Universal_Float;
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

   -----------------
   -- New_Comment --
   -----------------

   procedure New_Comment
     (Self     : Issa_Servlet'Class;
      URI      : League.Strings.Universal_String;
      JSON     : in out League.JSON.Objects.JSON_Object;
      Response : in out Servlet.HTTP_Responses.HTTP_Servlet_Response'Class)
   is
      pragma Unreferenced (Self);
      procedure Set_Default (Name : Wide_Wide_String);

      function Verify (Comment : League.JSON.Objects.JSON_Object)
        return League.Strings.Universal_String;

      -----------------
      -- Set_Default --
      -----------------

      procedure Set_Default (Name : Wide_Wide_String) is
         Key : constant League.Strings.Universal_String := +Name;
      begin
         if not JSON.Contains (Key) then
            JSON.Insert (Key, League.JSON.Values.Null_JSON_Value);
         end if;
      end Set_Default;

      ------------
      -- Verify --
      ------------

      function Verify (Comment : League.JSON.Objects.JSON_Object)
        return League.Strings.Universal_String
      is

         Mail : constant League.Strings.Universal_String :=
           Comment (+"email").To_String;

         Text : constant League.Strings.Universal_String :=
           Comment (+"text").To_String;

         Site : constant League.Strings.Universal_String :=
           Comment (+"website").To_String;

         Parent : constant League.JSON.Values.JSON_Value :=
           Comment (+"parent");
      begin
         if Text.Is_Empty then
            return +"text is missing";
         elsif not Parent.Is_Integer_Number and not Parent.Is_Null then
            return +"parent must be an integer or null";
         elsif Text.Length < 3 then
            return +"text is too short (minimum length: 3)";
         elsif Text.Length > 65535 then
            return +"text is too long (maximum length: 65535)";
         elsif Mail.Length > 254 then
            return +"http://tools.ietf.org/html/rfc5321#section-4.5.3";
         elsif Site.Length > 254 then
            return +"website is too long (maximum length: 254)";
         elsif not Site.Is_Empty
           and then not Is_URI.Find_Match (Site).Is_Matched
         then
            return +"website not Django-conform";
         end if;

         return League.Strings.Empty_Universal_String;
      end Verify;

      Thread : Positive;

      Error : constant League.Strings.Universal_String :=
        Verify (JSON);
   begin
      Set_Default ("author");
      Set_Default ("email");
      Set_Default ("website");
      Set_Default ("parent");

      if not Error.Is_Empty then
         Response.Set_Status (Servlet.HTTP_Responses.Bad_Request);
         Response.Set_Content_Type (+"text/plain");
         Response.Set_Character_Encoding (UTF_8);
         Response.Get_Output_Stream.Write (Error);
         return;
      end if;

      --  JSON.Insert (+"mode", League.JSON.Values.To_JSON_Value (Moderated));
      --  JSON.Insert (+"remote_addr", );

      Issa.Database.Select_Or_Insert_Thread (URI, Thread);

      Issa.Database.Add_Comment
        (Thread => Thread,
         Parent => Natural (JSON (+"parent").To_Integer),
         Mode   => Database.Valid,
         Text   => JSON (+"text").To_String,
         Author => JSON (+"author").To_String,
         Email  => JSON (+"email").To_String,
         Site   => JSON (+"website").To_String);
   end New_Comment;

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

   -------------
   -- To_JSON --
   -------------

   procedure To_JSON
    (Request : Servlet.HTTP_Requests.HTTP_Servlet_Request'Class;
     JSON    : out League.JSON.Objects.JSON_Object)
   is
      function "+" (Text : League.Strings.Universal_String)
        return League.String_Vectors.Universal_String_Vector;

      ---------
      -- "+" --
      ---------

      function "+" (Text : League.Strings.Universal_String)
        return League.String_Vectors.Universal_String_Vector is
         Result : League.String_Vectors.Universal_String_Vector;
      begin
         Result.Append (Text);
         return Result;
      end "+";

      Doc    : League.JSON.Documents.JSON_Document;
      Data   : League.Stream_Element_Vectors.Stream_Element_Vector;
      Stream : constant not null access Ada.Streams.Root_Stream_Type'Class :=
        Request.Get_Input_Stream;
   begin
      if Request.Get_Headers (+"Content-Type") /= +Application_JSON then
         return;
      end if;

      loop
         declare
            use type Ada.Streams.Stream_Element_Count;
            Buffer : Ada.Streams.Stream_Element_Array (1 .. 512);
            Last   : Ada.Streams.Stream_Element_Count;
         begin
            Stream.Read (Buffer, Last);
            Data.Append (Buffer (1 .. Last));
            exit when Last = 0;
         end;
      end loop;
      Doc := League.JSON.Documents.From_JSON (Data);

      if Doc.Is_Object then
         JSON := Doc.To_JSON_Object;
      end if;
   exception
      when others =>
         null;
   end To_JSON;

begin
   Config.Append (+"config");
   Empty.Append (+"");
   New_Path.Append (+"new");
end Issa.Servlets;
