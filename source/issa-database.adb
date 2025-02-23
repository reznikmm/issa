--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with League.Holders.Integers;
with SQL.Databases;
with SQL.Options;
with SQL.Queries;

package body Issa.Database is

   function "+"
    (Item : Wide_Wide_String) return League.Strings.Universal_String
       renames League.Strings.To_Universal_String;

   function Options return SQL.Options.SQL_Options;

   function Options return SQL.Options.SQL_Options is
   begin
      return DB_Options : SQL.Options.SQL_Options do
         DB_Options.Set (+"filename", +"issa.db");
      end return;
   end Options;

   Driver : constant League.Strings.Universal_String := +"SQLITE3";

   DB : aliased SQL.Databases.SQL_Database :=
     SQL.Databases.Create (Driver, Options);

   Fetch_SQL : constant League.Strings.Universal_String :=
     +("SELECT comments.id, parent, unixepoch(created), " &
       "unixepoch(modified), mode, text, author, website, likes, dislikes, " &
       "notification, likes - dislikes AS karma  " &
       "FROM comments INNER JOIN threads ON" &
       " threads.uri=:uri AND comments.tid=threads.id" &
       " AND comments.mode = 1" &
       " AND comments.created > 0");

   Select_Thread : constant League.Strings.Universal_String :=
     +"select id from threads where uri=:uri";

   Insert_Thread : constant League.Strings.Universal_String :=
     +"insert into threads (uri) values (:uri)";

   Insert_Comment : constant League.Strings.Universal_String :=
     +("insert into comments " &
       "(tid, parent, mode, text, author, email, website) values " &
       "(:tid, :parent, :mode, :text, :author, :email, :website)");

   -----------------
   -- Add_Comment --
   -----------------

   procedure Add_Comment
     (Thread : Natural;
      Parent : Natural;
      Mode   : Comment_Status;
      Text   : League.Strings.Universal_String;
      Author : League.Strings.Universal_String;
      Email  : League.Strings.Universal_String;
      Site   : League.Strings.Universal_String)
   is
      function "+" (V : Natural) return League.Holders.Holder is
        (if V = 0 then League.Holders.Empty_Holder
         else League.Holders.Integers.To_Holder (V));

      function "+" (V : League.Strings.Universal_String)
        return League.Holders.Holder renames
          League.Holders.To_Holder;

      Q : SQL.Queries.SQL_Query := DB.Query;

   begin
      Q.Prepare (Insert_Comment);
      Q.Bind_Value (+":tid", +Thread);
      Q.Bind_Value (+":parent", +Parent);
      Q.Bind_Value (+":mode", +(Comment_Status'Pos (Mode) + 1));
      Q.Bind_Value (+":text", +Text);
      Q.Bind_Value (+":author", +Author);
      Q.Bind_Value (+":email", +Email);
      Q.Bind_Value (+":website", +Site);
      Q.Execute;
   end Add_Comment;

   -----------
   -- Fetch --
   -----------

   procedure Fetch
     (URI      : League.Strings.Universal_String;
      Callback : not null access procedure (X : Comment))
   is
      use type League.Holders.Universal_Integer;

      function "+"
        (V : League.Holders.Holder) return League.Holders.Universal_Integer is
          (if League.Holders.Is_Empty (V) then 0
           else League.Holders.Element (V));

      function "+"
        (V : League.Holders.Holder) return League.Strings.Universal_String is
          (if League.Holders.Is_Empty (V)
           then League.Strings.Empty_Universal_String
           else League.Holders.Element (V));

      function "+"
        (V : League.Holders.Holder) return Comment_Status is
          (if League.Holders.Is_Empty (V) then Valid
           else Comment_Status'Val (League.Holders.Element (V) - 1));

      Q : SQL.Queries.SQL_Query := DB.Query;
   begin
      Q.Prepare (Fetch_SQL);
      Q.Bind_Value (+":uri", League.Holders.To_Holder (URI));
      Q.Execute;

      while Q.Next loop
         declare
            V : constant Comment :=
              (Id            => +Q.Value (1),
               Parent        => +Q.Value (2),
               Created       => League.Holders.Element (Q.Value (3)),
               Modified      => League.Holders.Element (Q.Value (4)),
               Mode          => +Q.Value (5),
               Text          => League.Holders.Element (Q.Value (6)),
               Author        => +Q.Value (7),
               Site          => +Q.Value (8),
               Likes         => +Q.Value (9),
               Dislikes      => +Q.Value (10),
               Notifs        => +Q.Value (11),
               Hash          => +"31fc8afaf7c4",
               Total_Replies => 0);
         begin
            Callback (V);
         end;
      end loop;
   end Fetch;

   -----------------------------
   -- Select_Or_Insert_Thread --
   -----------------------------

   procedure Select_Or_Insert_Thread
     (URI : League.Strings.Universal_String;
      Id  : out Positive)
   is

      Q : SQL.Queries.SQL_Query := DB.Query;
   begin
      Q.Prepare (Select_Thread);
      Q.Bind_Value (+":uri", League.Holders.To_Holder (URI));
      Q.Execute;

      if Q.Next then
         Id := League.Holders.Integers.Element (Q.Value (1));
         return;
      end if;

      Q.Prepare (Insert_Thread);
      Q.Bind_Value (+":uri", League.Holders.To_Holder (URI));
      Q.Execute;

      Select_Or_Insert_Thread (URI, Id);
   end Select_Or_Insert_Thread;

begin
   DB.Open;
end Issa.Database;
