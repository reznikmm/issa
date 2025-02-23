--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with League.Holders;
with League.Strings;

package Issa.Database is

   type Comment_Status is (Valid, Pending, Soft_Deleted);
   --  1 = valid, 2 = pending, 4 = soft-deleted

   type Comment is record
      Id             : League.Holders.Universal_Integer;
      Parent         : League.Holders.Universal_Integer;
      Created        : League.Holders.Universal_Integer;
      --  League.Calendars.Date_Time;
      Modified       : League.Holders.Universal_Integer;
      Mode           : Comment_Status;
      Text           : League.Strings.Universal_String;
      Author         : League.Strings.Universal_String;
      Site           : League.Strings.Universal_String;
      Likes          : League.Holders.Universal_Integer;
      Dislikes       : League.Holders.Universal_Integer;
      Notifs         : League.Holders.Universal_Integer;
      Hash           : League.Strings.Universal_String;
      Total_Replies  : League.Holders.Universal_Integer;
      --  Hidden_Replies : League.Holders.Universal_Integer;
   end record;
   --  CREATE TABLE IF NOT EXISTS threads (
   --      id INTEGER PRIMARY KEY,
   --      uri VARCHAR(256) UNIQUE,
   --      title VARCHAR(256)
   --  );

   --  CREATE TABLE IF NOT EXISTS comments (
   --      tid REFERENCES threads(id),
   --      id INTEGER PRIMARY KEY,
   --      parent INTEGER,
   --      created FLOAT NOT NULL DEFAULT current_timestamp,
   --      modified FLOAT NOT NULL DEFAULT current_timestamp,
   --      mode INTEGER,
   --      remote_addr VARCHAR,
   --      text VARCHAR NOT NULL,
   --      author VARCHAR,
   --      email VARCHAR,
   --      website VARCHAR,
   --      likes INTEGER DEFAULT 0,
   --      dislikes INTEGER DEFAULT 0,
   --      --  voters BLOB NOT NULL,
   --      notification INTEGER DEFAULT 0
   --  );

   procedure Fetch
     (URI      : League.Strings.Universal_String;
      Callback : not null access procedure (X : Comment));

   procedure Select_Or_Insert_Thread
     (URI : League.Strings.Universal_String;
      Id  : out Positive);

   procedure Add_Comment
     (Thread : Natural;
      Parent : Natural;
      Mode   : Comment_Status;
      Text   : League.Strings.Universal_String;
      Author : League.Strings.Universal_String;
      Email  : League.Strings.Universal_String;
      Site   : League.Strings.Universal_String);

end Issa.Database;
