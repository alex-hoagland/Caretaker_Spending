/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_12)             *
*                                                                        *
* Purpose:   This code identifies non-sample individuals diagnosed 	 *
* 		with an HCC in 2007. Then, calculates the rate at which  *
*		other family members are diagnosed in next 10 years.     *
*                                                                        *
* Note: This file							 *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*									 *
* Created:   October, 2020		                                 *
* Updated:  		                                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*------------------------------------------------------------------------*
 * 		ORDER OF OPERATIONS					  *
 * 0. Identify all with HCC_12 claims in 2006-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics, 2006 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc12; 
   set in.ms_o_2006(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2006(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2007(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2007(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2008(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2008(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2009(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2009(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2010(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2010(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2011(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2011(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2012(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2012(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2013(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2013(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2014(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2014(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2015(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2015(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2016(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2016(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2017(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2017(keep=enrolid age sex year dx1 dx2 svcdate)
       in.ms_o_2018(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2018(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('C4A0', 'C4A10', 'C4A11', 'C4A12', 'C4A20', 'C4A21', 'C4A22', 'C4A30', 'C4A31', 'C4A39', 'C4A4', 'C4A51', 'C4A52', 'C4A59', 'C4A60', 'C4A61', 'C4A62',
		'C4A70', 'C4A71', 'C4A72', 'C4A8', 'C4A9', 'C50011', 'C50012', 'C50019', 'C50021', 'C50022', 'C50029', 'C50111', 'C50112', 'C50119', 'C50121', 'C50122',
		'C50129', 'C50211', 'C50212', 'C50219', 'C50221', 'C50222', 'C50229', 'C50311', 'C50312', 'C50319', 'C50321', 'C50322', 'C50329', 'C50411', 'C50412', 
		'C50419', 'C50421', 'C50422', 'C50429', 'C50511', 'C50512', 'C50519', 'C50521', 'C50522', 'C50529', 'C50611', 'C50612', 'C50619', 'C50621', 'C50622', 
		'C50629', 'C50811', 'C50812', 'C50819', 'C50821', 'C50822', 'C50829', 'C50911', 'C50912', 'C50919', 'C50921', 'C50922', 'C50929', 'C510', 'C511', 'C512', 
		'C518', 'C519', 'C52', 'C530', 'C531', 'C538', 'C539', 'C540', 'C541', 'C542', 'C543', 'C548', 'C549', 'C55', 'C577', 'C578', 'C579', 'C61', 'C661', 
		'C662', 'C669', 'C670', 'C671', 'C672', 'C673', 'C674', 'C675', 'C676', 'C677', 'C678', 'C679', 'C680', 'C681', 'C688', 'C689', 'C6900', 'C6901', 
		'C6902', 'C6910', 'C6911', 'C6912', 'C6920', 'C6921', 'C6922', 'C6930', 'C6931', 'C6932', 'C6940', 'C6941', 'C6942', 'C6950', 'C6951', 'C6952', 'C6960', 
		'C6961', 'C6962', 'C6980', 'C6981', 'C6982', 'C6990', 'C6991', 'C6992', 'C760', 'C761', 'C762', 'C763', 'C7640', 'C7641', 'C7642', 'C7650', 'C7651', 
		'C7652', 'C768', 'C7A00', 'C7A010', 'C7A011', 'C7A012', 'C7A019', 'C7A020', 'C7A021', 'C7A022', 'C7A023', 'C7A024', 'C7A025', 'C7A026', 'C7A029', 
		'C7A090', 'C7A091', 'C7A092', 'C7A093', 'C7A094', 'C7A095', 'C7A096', 'C7A098', 'C7A1', 'C7A8', 'C802', 'C8100', 'C8101', 'C8102', 'C8103', 'C8104', 
		'C8105', 'C8106', 'C8107', 'C8108', 'C8109', 'C8110', 'C8111', 'C8112', 'C8113', 'C8114', 'C8115', 'C8116', 'C8117', 'C8118', 'C8119', 'C8120', 'C8121', 
		'C8122', 'C8123', 'C8124', 'C8125', 'C8126', 'C8127', 'C8128', 'C8129', 'C8130', 'C8131', 'C8132', 'C8133', 'C8134', 'C8135', 'C8136', 'C8137', 'C8138', 
		'C8139', 'C8140', 'C8141', 'C8142', 'C8143', 'C8144', 'C8145', 'C8146', 'C8147', 'C8148', 'C8149', 'C8170', 'C8171', 'C8172', 'C8173', 'C8174', 'C8175', 
		'C8176', 'C8177', 'C8178', 'C8179', 'C8190', 'C8191', 'C8192', 'C8193', 'C8194', 'C8195', 'C8196', 'C8197', 'C8198', 'C8199', 'D1802', 'D320', 'D321', 
		'D329', 'D330', 'D331', 'D332', 'D333', 'D334', 'D337', 'D339', 'D352', 'D353', 'D354', 'D420', 'D421', 'D429', 'D430', 'D431', 'D432', 'D433', 'D434', 
		'D438', 'D439', 'D443', 'D444', 'D445', 'D446', 'D447', 'D496', 'Q851', 'Q858', 'Q859', '1740', '1741', '1742', '1743', '1744', '1745', '1746', '1748', 
		'1749', '1750', '1759', '179', '1800', '1801', '1808', '1809', '1820', '1821', '1828', '1840', '1841', '1842', '1843', '1844', '1848', '1849', '185', 
		'1880', '1881', '1882', '1883', '1884', '1885', '1886', '1887', '1888', '1889', '1892', '1893', '1894', '1898', '1899', '1900', '1901', '1902', '1903', 
		'1904', '1905', '1906', '1907', '1908', '1909', '1950', '1951', '1952', '1953', '1954', '1955', '1958', '1992', '20100', '20101', '20102', '20103', 
		'20104', '20105', '20106', '20107', '20108', '20110', '20111', '20112', '20113', '20114', '20115', '20116', '20117', '20118', '20120', '20121', '20122', 
		'20123', '20124', '20125', '20126', '20127', '20128', '20140', '20141', '20142', '20143', '20144', '20145', '20146', '20147', '20148', '20150', '20151', 
		'20152', '20153', '20154', '20155', '20156', '20157', '20158', '20160', '20161', '20162', '20163', '20164', '20165', '20166', '20167', '20168', '20170', 
		'20171', '20172', '20173', '20174', '20175', '20176', '20177', '20178', '20190', '20191', '20192', '20193', '20194', '20195', '20196', '20197', '20198', 
		'20900', '20901', '20902', '20903', '20910', '20911', '20912', '20913', '20914', '20915', '20916', '20917', '20920', '20921', '20922', '20923', '20924', 
		'20925', '20926', '20927', '20929', '20930', '20931', '20932', '20933', '20934', '20935', '20936', '2250', '2251', '2252', '2253', '2254', '2258', '2259', 
		'2273', '2274', '22802', '2370', '2371', '2373', '2375', '2376', '2379', '2396', '7595', '7596'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc12 as 
   select enrolid from out.allclaims_hcc12
   group by enrolid; 
quit; 

data out.allenrollees_hcc12;
   set out.allenrollees_hcc12;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_12; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_12");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2006 in.ms_a_2007 in.ms_a_2008 in.ms_a_2009 in.ms_a_2010 in.ms_a_2011 in.ms_a_2012 in.ms_a_2013 in.ms_a_2014 in.ms_a_2015 in.ms_a_2016 in.ms_a_2017 in.ms_a_2018;
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 