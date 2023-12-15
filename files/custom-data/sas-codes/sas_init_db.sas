/******************************************************************************/
/* Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. */
/* SPDX-License-Identifier: Apache-2.0                                        */
/* ****************************************************************************/


filename sqlin '/sas/software/ci360-cdm-loader-sas/ddl/ci_cdm2_ddl_postgres.sas';
filename sqlout temp;

data _null_;
	infile sqlin;
	file sqlout;
	input;
	retain start 0;
	if find(upcase(_infile_),'EXECUTE') then do;
		start=1;
		put 'PROC SQL NOERRORSTOP;';
		put 'CONNECT using cdm as postgres;';
	end;
/*	if find(upcase(_infile_),'DISABLE FOREIGN KEY CONSTRAINTS') then do;*/
/*		put 'DISCONNECT FROM POSTGRES;';*/
/*		put 'QUIT;';*/
/*		stop;*/
/*	end;*/
	if start=1 then put _infile_;
run;

%let schema=cdm;

%include sqlout / source2;

%let path=%sysget(CDM_TABLES_META_PATH);

data _null_;
	length id pname _uri _parenturi $ 256 path $ 2000;
	_nobj=1; 
	_n=1; 
	do while(_n le _nobj);
		_nobj=metadata_getnobj("omsobj:Tree?@Name='"||scan(%tslit(&path), -1, '/')||"'",_n,_uri);
		_rc=metadata_getattr(_uri,"Id",id);
		path='';
		do while (metadata_getnasn(_uri,"ParentTree",1,_parenturi)>0);
			rc=metadata_getattr(_parenturi,"Name",pname);
			path=cats('/',pname,path);
			_uri=_parenturi;
		end;
		path=cats(path,'/',scan(%tslit(&path), -1, '/'));
		if path = %tslit(&path) then do;
			call symputx('folderId', id);
			stop;
		end;
		_n=_n+1;
	end;
run;


proc metalib;
	omr (library="CDM");
	FOLDERID = "&folderId";
run;
  