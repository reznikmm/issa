--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with Servlet.Container_Initializers;
with Servlet.Contexts;

package Issa.Startup is

   type Servlet_Container_Initializer is limited
     new Servlet.Container_Initializers.Servlet_Container_Initializer with
   null record;

   overriding procedure On_Startup
    (Self    : in out Servlet_Container_Initializer;
     Context : in out Servlet.Contexts.Servlet_Context'Class);

end Issa.Startup;
