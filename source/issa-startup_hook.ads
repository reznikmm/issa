--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: MIT
----------------------------------------------------------------

with Spikedog.Generic_Application_Initializer;

with Issa.Startup;
package Issa.Startup_Hook is
  new Spikedog.Generic_Application_Initializer
    (Issa.Startup.Servlet_Container_Initializer);
