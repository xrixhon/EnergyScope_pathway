## Constraints needed to reproduce the scenario for CH in 2011
## All data are calculated in Excel file


subject to elec_prod_NUCLEAR: sum {t in PERIODS}   (   F_Mult_t ['YEAR_2015','NUCLEAR',t] * t_op[t] ) = 24340;
subject to elec_prod_CCGT: sum {t in PERIODS} (        F_Mult_t ['YEAR_2015','CCGT',t] * t_op[t] ) = 20023;#15693;
subject to elec_prod_COAL_US: sum {t in PERIODS} (     F_Mult_t ['YEAR_2015','COAL_US',t] * t_op[t] ) = 1631;
subject to elec_prod_COAL_IGCC: sum {t in PERIODS} (   F_Mult_t ['YEAR_2015','COAL_IGCC',t] * t_op[t] ) = 0;
subject to elec_prod_PV: sum {t in PERIODS} (F_Mult_t ['YEAR_2015','PV',t] * t_op[t] ) = 3376;
subject to elec_prod_WIND_ONSHORE: sum {t in PERIODS}  ( F_Mult_t ['YEAR_2015','WIND_ONSHORE' ,t] * t_op[t])  = 2509;#Data from ELIA 2015
subject to elec_prod_WIND_OFFSHORE: sum {t in PERIODS} ( F_Mult_t ['YEAR_2015','WIND_OFFSHORE',t] * t_op[t] ) = 2500;#Data from ELIA 2015
# subject to elec_prod_HYDRO_RIVER: sum {t in PERIODS} (F_Mult_t ['YEAR_2015','HYDRO_RIVER',t] * t_op[t] ) = 365;
subject to elec_prod_GEOTHERMAL: sum {t in PERIODS} (F_Mult_t ['YEAR_2015','GEOTHERMAL',t] * t_op[t] ) = 0;


let fmin_perc ['YEAR_2015','NON_ENERGY_OIL'] := 0.86;
let fmin_perc ['YEAR_2015','NON_ENERGY_NG'] := 0.14;
let fmax_perc ['YEAR_2015','NON_ENERGY_OIL'] := 0.86;
let fmax_perc ['YEAR_2015','NON_ENERGY_NG'] := 0.14;


let fmin_perc['YEAR_2015','TRUCK_NG'] := 0.103;
let fmax_perc['YEAR_2015','TRUCK_NG'] := 0.103;
let f_max['YEAR_2015','TRUCK_FUEL_CELL'] := 0;
let f_min['YEAR_2015','BOAT_FREIGHT_NG'] := 0;
let f_max['YEAR_2015','BOAT_FREIGHT_NG'] := 0;


#SOURCE : # Eurostat2017 p49
let fmin_perc['YEAR_2015','TRAMWAY_TROLLEY'] := 0.045;
let fmin_perc['YEAR_2015','BUS_COACH_DIESEL'] := 0.47;# 90%  du service publique hors train est en tram/metro
let fmin_perc['YEAR_2015','BUS_COACH_HYDIESEL'] := 0;
let fmin_perc['YEAR_2015','BUS_COACH_CNG_STOICH'] := 0.10;# 90%  du service publique hors train est en tram/metro
let fmin_perc['YEAR_2015','BUS_COACH_FC_HYBRIDH2'] := 0;
let fmin_perc['YEAR_2015','TRAIN_PUB'] := 0.385; #slide 4 de #slide 10 of https://mobilit.belgium.be/sites/default/files/chiffres_cles_mobilite_2017.pdf
let fmax_perc['YEAR_2015','TRAMWAY_TROLLEY'] := 0.045;
let fmax_perc['YEAR_2015','BUS_COACH_DIESEL'] := 1;
let fmax_perc['YEAR_2015','BUS_COACH_HYDIESEL'] := 0;
let fmax_perc['YEAR_2015','BUS_COACH_CNG_STOICH'] := 0.10;
let fmax_perc['YEAR_2015','BUS_COACH_FC_HYBRIDH2'] := 0;
let fmax_perc['YEAR_2015','TRAIN_PUB'] := 0.385;#slide 4 de #slide 10 of https://mobilit.belgium.be/sites/default/files/chiffres_cles_mobilite_2017.pdf

# Private mobility
let fmin_perc['YEAR_2015','CAR_GASOLINE'] := 0.0;#slide 10 of https://mobilit.belgium.be/sites/default/files/chiffres_cles_mobilite_2017.pdf
let fmin_perc['YEAR_2015','CAR_DIESEL'] := 0.0;#slide 10 of https://mobilit.belgium.be/sites/default/files/chiffres_cles_mobilite_2017.pdf
let fmin_perc['YEAR_2015','CAR_NG'] := 0.01;
let fmin_perc['YEAR_2015','CAR_HEV'] := 0.0;#slide 10 of https://mobilit.belgium.be/sites/default/files/chiffres_cles_mobilite_2017.pdf
let fmin_perc['YEAR_2015','CAR_PHEV'] := 0.0;
let fmin_perc['YEAR_2015','CAR_BEV'] := 0.0;
let fmin_perc['YEAR_2015','CAR_FUEL_CELL'] := 0.0;
let fmax_perc['YEAR_2015','CAR_GASOLINE'] := 1; #slide 10 of https://mobilit.belgium.be/sites/default/files/chiffres_cles_mobilite_2017.pdf
let fmax_perc['YEAR_2015','CAR_DIESEL'] := 1;#slide 10 of https://mobilit.belgium.be/sites/default/files/chiffres_cles_mobilite_2017.pdf
let fmax_perc['YEAR_2015','CAR_NG'] := 0.01;
let fmax_perc['YEAR_2015','CAR_HEV'] := 0.0;#slide 10 of https://mobilit.belgium.be/sites/default/files/chiffres_cles_mobilite_2017.pdf
let fmax_perc['YEAR_2015','CAR_PHEV'] := 0.0;
let fmax_perc['YEAR_2015','CAR_BEV'] := 0.0;
let fmax_perc['YEAR_2015','CAR_FUEL_CELL'] := 0.0;


