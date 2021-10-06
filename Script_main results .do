****Serossurvey
use "/Users/insp/Dropbox/INSP 2020/ENSANUT COVID 2020/BASES NUEVO PONDERADOR/toma_de_sangre_ensanut2020_covid_w_Censo/toma_de_sangre_ensanut2020_covid_w112", clear
***Merge with household individuals to get socioeconomic information. 
merge 1:1 folio_int using  "/Users/insp/Dropbox/INSP 2020/ENSANUT COVID 2020/BASES NUEVO PONDERADOR/hogar_ensanut2020_wwCenso/integrantes_ensanut2020_w112.dta"
keep if _merge==3
drop _merge
***Merge with nse
merge m:1 folio_i using "/Users/insp/Dropbox/INSP 2020/ENSANUT COVID 2020/nse/NSE.dta"
keep if _merge==3
drop _merge


svyset [pweight =ponde_g20], strata(est_sel) psu(upm) singleunit(centered)


gen f_ini = date(fecha_ini, "DM20Y")
gen f_fin = date(fecha_fin, "DM20Y")


bysort region: egen min=min(f_ini)
bysort region: egen max=max(f_fin)

format min %d
format max %d


****Education
gen escolaridad=h0317a
recode escolaridad 0/1=2 6=3 7=4 5=4 8/12=5
label define escolaridad 2 "Primaria o menos" 3"Secundaria" 4"Prepa" 5"Licenciatura o más" 
label values escolaridad escolaridad


****Employment status
gen ocupacion=h0322a
recode ocupacion 1=0 2=0 3=1 4=2 5=0 6=.
replace ocupacion=3 if h0323!=.
replace ocupacion=0 if h0323esp=="YA NO TRABAJO POR FALTA DE EMPLEO"
replace ocupacion=0 if h0323esp=="DESEMPLEADO"
replace ocupacion=0 if h0323esp=="POR QUE ES UNA PERSONA DIABETICA Y ADULTA"
replace ocupacion=3 if h0322==1 | h0322==2 | h0322==3 | h0322==4 | h0322==5  
replace ocupacion=0 if h0322==6 & ocupacion==.
replace ocupacion=. if edad<15
label define ocupacion 0 "Desempleado" 1 "Estudiante" 2 "Jubilado/pensionado" 3 "Empleado_formal" 4"Empleado_informal"
label values ocupacion ocupacion
****Formal and informal
gen trabajo_formal=.
replace trabajo_formal=1 if h0324a==1
replace trabajo_formal=1 if h0324j==1
replace trabajo_formal=0 if trabajo_formal==. & ocupacion==3

replace ocupacion=4 if trabajo_formal==0


label define trabajo_formal 0 "No" 1 "Sí" 
label values trabajo_formal trabajo_formal

***age categories
egen agecat=cut(edad), at (1,20 (20) 60, 120)


****Table 1 
tabout agecat sexo rural_20 escolaridad ocupacion region_cv nseF valor using "/Users/insp/Dropbox/INSP 2020/ENSANUT COVID 2020/Manuscritos/seroprevalencia/tablas.xls",replace  `modo' cells(row ci) format(1) `encabezado' h3("`vlabel' `encabezado2'") svy percent
****Thiss table gives us the observed seroprevalence by the socioeocnomic characteristics. 
*You need to run the excel to correct for sensitivity and specificity. 

****For regressiion models (Table 2)
gen ab=valor
recode ab 2=0

*****cuando usamos ocupación es solo para 15 años y más. Creo que vale la pena hacer un modelo para niños sin ocupación y otros para adulotos 
egen agecat_adol=cut(edad), at (1,10 (10) 20)
egen agecat3=cut(edad), at (20 (10) 70, 120)


***Adolescents
svy, sub(if edad<20): poisson ab i.agecat_adol i.sexo i.rural_20 ib3.nseF ib(6).region_cv, irr

***Adults
svy, sub(if edad>=20): poisson ab i.agecat3 i.sexo i.rural_20 ib3.nseF ib5.escolaridad i.ocupacion ib(6).region_cv, irr


