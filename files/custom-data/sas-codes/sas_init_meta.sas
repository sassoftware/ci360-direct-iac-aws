/******************************************************************************/
/* Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. */
/* SPDX-License-Identifier: Apache-2.0                                        */
/* ****************************************************************************/

%let PG_ADDRESS=%sysget(PG_ADDRESS);

data _null_;
    length value $200
           propuri $200;
    rc=metadata_getprop("omsobj:SASClientConnection?@Name='Connection: RDSServer'",
"Connection.DBMS.Property.SERVER.Name.xmlKey.txt",value,propuri);
    put rc= value= propuri=;
    rc=metadata_setprop("omsobj:SASClientConnection?@Name='Connection: RDSServer'",
"Connection.DBMS.Property.SERVER.Name.xmlKey.txt",
                        "&PG_ADDRESS",propuri);
    put rc= propuri=;
run;