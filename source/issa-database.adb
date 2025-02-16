--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

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
     +("SELECT comments.*, likes - dislikes AS karma " &
       "FROM comments INNER JOIN threads ON" &
       " threads.uri=:uri AND comments.tid=threads.id" &
       " AND comments.mode = 1" &
       " AND comments.created > 0");

   -----------
   -- Fetch --
   -----------

   procedure Fetch
     (URI      : League.Strings.Universal_String;
      Callback : not null access procedure (X : Comment))
   is
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
           else Comment_Status'Val (League.Holders.Element (V)));

      Q : SQL.Queries.SQL_Query := DB.Query;
   begin
      Q.Prepare (Fetch_SQL);
      Q.Bind_Value (+":uri", League.Holders.To_Holder (URI));
      Q.Execute;

      while Q.Next loop
         declare
            V : constant Comment :=
              (Id            => +Q.Value (2),
               Parent        => +Q.Value (3),
               Created       => League.Holders.Element (Q.Value (4)),
               Modified      => League.Holders.Element (Q.Value (5)),
               Mode          => +Q.Value (6),
               Text          => League.Holders.Element (Q.Value (8)),
               Author        => +Q.Value (9),
               Site          => +Q.Value (11),
               Likes         => +Q.Value (12),
               Dislikes      => +Q.Value (13),
               Notifs        => +Q.Value (14),  --  15
               Hash          => +"31fc8afaf7c4",
               Total_Replies => 0);
         begin
            Callback (V);
         end;
      end loop;
   end Fetch;

begin
   DB.Open;
end Issa.Database;
