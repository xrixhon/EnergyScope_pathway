######################################################
#
# Swiss-EnergyScope (SES) MILP modeling framework
# Model file
# Author: Stefano Moret
# Date: 27.10.2017
# Model documentation: Moret S. (2017). "Strategic Energy Planning under Uncertainty". PhD Thesis n. 7961, EPFL, Switzerland (Chapter 1). (http://dx.doi.org/10.5075/epfl-thesis-7961)
# For terms of use and how to cite this work please check the ReadMe file. 
#
######################################################

### SETS [Figure 1.3] ###

## NEW SETS FOR PATHWAY:

set YEARS ;#..  2050 by 25;
set PHASE ;
set YEARS_AFTER ;#..  2050 by 25;
set PHASE_AFTER ;
set PHASE_START {PHASE } within YEARS union YEARS_AFTER;
set PHASE_STOP  {PHASE } within YEARS union YEARS_AFTER;
#set PHASE_START_AFTER {PHASE_AFTER} within YEARS_AFTER;
#set PHASE_STOP_AFTER  {PHASE_AFTER} within YEARS_AFTER;

## MAIN SETS: Sets whose elements are input directly in the data file
set PERIODS; # time periods
set SECTORS; # sectors of the energy system
set END_USES_INPUT; # Types of demand (end-uses). Input to the model
set END_USES_CATEGORIES; # Categories of demand (end-uses): electricity, heat, mobility
set END_USES_TYPES_OF_CATEGORY {END_USES_CATEGORIES}; # Types of demand (end-uses).
set RESOURCES; # Resources: fuels (wood and fossils) and electricity imports 
set BIOFUELS within RESOURCES; # imported biofuels.
set EXPORT within RESOURCES; # exported resources
set END_USES_TYPES := setof {i in END_USES_CATEGORIES, j in END_USES_TYPES_OF_CATEGORY [i]} j; # secondary set
set TECHNOLOGIES_OF_END_USES_TYPE {END_USES_TYPES}; # set all energy conversion technologies (excluding storage technologies)
set STORAGE_TECH; # set of storage technologies 
set STORAGE_OF_END_USES_TYPES {END_USES_TYPES} within STORAGE_TECH; # set all storage technologies related to an end-use types (used for thermal solar (TS))
set INFRASTRUCTURE; # Infrastructure: DHN, grid, and intermediate energy conversion technologies (i.e. not directly supplying end-use demand)

## SECONDARY SETS: a secondary set is defined by operations on MAIN SETS
set LAYERS := (RESOURCES diff BIOFUELS diff EXPORT) union END_USES_TYPES; # Layers are used to balance resources/products in the system
set TECHNOLOGIES := (setof {i in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE [i]} j) union STORAGE_TECH union INFRASTRUCTURE; 
set TECHNOLOGIES_OF_END_USES_CATEGORY {i in END_USES_CATEGORIES} within TECHNOLOGIES := setof {j in END_USES_TYPES_OF_CATEGORY[i], k in TECHNOLOGIES_OF_END_USES_TYPE [j]} k; 
set RE_RESOURCES within RESOURCES; # List of RE resources (including wind hydro solar), used to compute the RE share

## Additional SETS: only needed for printing out results
set COGEN within TECHNOLOGIES; # cogeneration tech
set BOILERS within TECHNOLOGIES; # boiler tech


### PARAMETERS [Table 1.1] ###

## NEW PARAMETERS FOR PATHWAY:
param max_inv_phase {PHASE} default 0;
param t_phase ;
param diff_2015_phase {PHASE};
param gwp_limit_transition >=0 default 1e15; #To limit CO2 emissions over the transition

param end_uses_demand_year {YEARS, END_USES_INPUT, SECTORS} >= 0 default 0; # end_uses_year [GWh]: table end-uses demand vs sectors (input to the model). Yearly values. [Mpkm] or [Mtkm] for passenger or freight mobility.
param end_uses_input {y in YEARS, i in END_USES_INPUT} := sum {s in SECTORS} (end_uses_demand_year [y,i,s]); # end_uses_input (Figure 1.4) [GWh]: total demand for each type of end-uses across sectors (yearly energy) as input from the demand-side model. [Mpkm] or [Mtkm] for passenger or freight mobility.
param i_rate  > 0 default 0.015; # discount rate [-]: real discount rate
param re_share_primary {YEARS} >= 0 default 0; # re_share [-]: minimum share of primary energy coming from RE
param gwp_limit {YEARS} >= 0 default 0;    # [ktCO2-eq./year] maximum gwp emissions allowed.
param share_mobility_public_min {YEARS} >= 0, <= 1 default 0; # %_public,min [-]: min limit for penetration of public mobility over total mobility 
param share_mobility_public_max {YEARS} >= 0, <= 1 default 0; # %_public,max [-]: max limit for penetration of public mobility over total mobility 
# Share train vs truck in freight transportation
param share_freight_train_min {YEARS} >= 0, <= 1 default 0; # % min limit for penetration of train in freight transportation
param share_freight_train_max {YEARS} >= 0, <= 1 default 0; # % max limit for penetration of train in freight transportation
param share_freight_road_min {YEARS}  >= 0, <= 1 default 0; # % min limit for penetration of road in freight transportation
param share_freight_road_max {YEARS}  >= 0, <= 1 default 0; # % max limit for penetration of road in freight transportation
param share_freight_boat_min {YEARS}  >= 0, <= 1 default 0; # % min limit for penetration of boat in freight transportation
param share_freight_boat_max {YEARS}  >= 0, <= 1 default 0; # % max limit for penetration of boat in freight transportation

# Share dhn vs decentralized for low-T heating
param share_heat_dhn_min {YEARS} >= 0, <= 1 default 0; # %_dhn,min [-]: min limit for penetration of dhn in low-T heating
param share_heat_dhn_max {YEARS} >= 0, <= 1 default 0; # %_dhn,max [-]: max limit for penetration of dhn in low-T heating

param t_op {PERIODS}; # duration of each time period [h]
param lighting_month {PERIODS} >= 0, <= 1; # %_lighting: factor for sharing lighting across months (adding up to 1)
param heating_month {PERIODS} >= 0, <= 1; # %_sh: factor for sharing space heating across months (adding up to 1)

# f: input/output Resources/Technologies to Layers. Reference is one unit ([GW] or [Mpkm/h] or [Mtkm/h]) of (main) output of the resource/technology. input to layer (output of technology) > 0.
param layers_in_out {YEARS,RESOURCES union TECHNOLOGIES diff STORAGE_TECH, LAYERS}; 

# Attributes of TECHNOLOGIES
param ref_size {YEARS,TECHNOLOGIES} >= 0; # f_ref: reference size of each technology, expressed in the same units as the layers_in_out table. Refers to main output (heat for cogen technologies). storage level [GWh] for STORAGE_TECH
param c_inv {YEARS,TECHNOLOGIES} >= 0; # Specific investment cost [MCHF/GW].[MCHF/GWh] for STORAGE_TECH
param c_maint {YEARS,TECHNOLOGIES} >= 0; # O&M cost [MCHF/GW/year]: O&M cost does not include resource (fuel) cost. [MCHF/GWh] for STORAGE_TECH
param lifetime {YEARS,TECHNOLOGIES} >= 1; # n: lifetime [years] # if lifetime < t_phase : problem in new constraints
param f_max {YEARS,TECHNOLOGIES} >= 0; # Maximum feasible installed capacity [GW], refers to main output. storage level [GWh] for STORAGE_TECH
param f_min {YEARS,TECHNOLOGIES} >= 0; # Minimum feasible installed capacity [GW], refers to main output. storage level [GWh] for STORAGE_TECH
param fmax_perc {YEARS,TECHNOLOGIES} >= 0, <= 1 default 1; # value in [0,1]: this is to fix that a technology can at max produce a certain % of the total output of its sector over the entire year
param fmin_perc {YEARS,TECHNOLOGIES} >= 0, <= 1 default 0; # value in [0,1]: this is to fix that a technology can at min produce a certain % of the total output of its sector over the entire year
param c_p_t {TECHNOLOGIES, PERIODS} >= 0, <= 1 default 1; # capacity factor of each technology and resource, defined on monthly basis. Different than 1 if F_Mult_t (t) <= c_p_t (t) * F_Mult
param c_p {YEARS,TECHNOLOGIES} >= 0, <= 1 default 1; # capacity factor of each technology, defined on annual basis. Different than 1 if sum {t in PERIODS} F_Mult_t (t) * t_op (t) <= c_p * F_Mult
param tau {y in YEARS, i in TECHNOLOGIES} := i_rate * (1 + i_rate)^lifetime [y,i] / (((1 + i_rate)^lifetime [y,i]) - 1); # Annualisation factor for each different technology
param gwp_constr {YEARS, TECHNOLOGIES} >= 0; # GWP emissions associated to the construction of technologies [ktCO2-eq./GW]. Refers to [GW] of main output
param total_time := sum {t in PERIODS} (t_op [t]); # added just to simplify equations

# Attributes of RESOURCES
param c_op {YEARS,RESOURCES} >= 0; # cost of resources in the different periods [MCHF/GWh]
param avail {YEARS,RESOURCES} >= 0; # Yearly availability of resources [GWh/y]
param gwp_op {YEARS,RESOURCES} >= 0; # GWP emissions associated to the use of resources [ktCO2-eq./GWh]. Includes extraction/production/transportation and combustion

# Attributes of STORAGE_TECH
param storage_eff_in {YEARS,STORAGE_TECH, LAYERS} >= 0, <= 1; # eta_sto_in: efficiency of input to storage from layers.  If 0 storage_tech/layer are incompatible
param storage_eff_out {YEARS,STORAGE_TECH, LAYERS} >= 0, <= 1; # eta_sto_out: efficiency of output from storage to layers. If 0 storage_tech/layer are incompatible
param storage_losses {YEARS,STORAGE_TECH} >= 0, <= 1; # %_sto_loss [-]: Self losses in storage (required for Li-ion batteries). Value = self discharge in 1 hour.
param storage_charge_time    {YEARS,STORAGE_TECH} >= 0; # t_sto_in [h]: Time to charge storage (Energy to Power ratio). If value =  5 <=>  5h for a full charge.
param storage_discharge_time {YEARS,STORAGE_TECH} >= 0; # t_sto_out [h]: Time to discharge storage (Energy to Power ratio). If value =  5 <=>  5h for a full discharge.
param storage_availability {YEARS,STORAGE_TECH} >=0, default 1;# %_sto_avail [-]: Storage technology availability to charge/discharge. Used for EVs 
param loss_network {YEARS,END_USES_TYPES} >= 0 default 0; # 0 in all cases apart from electricity grid and DHN
param peak_sh_factor >= 0;
param c_grid_extra >=0; # Cost to reinforce the grid due to IRE penetration [MCHF].


#NEW : 
param annualised_factor {p in PHASE} := 1 / ((1 + i_rate)^diff_2015_phase[p] ); # Annualisation factor for each different technology
param elec_max_import_share{YEARS};
param limit_LT_renovation >= 0 default 0.25;
param limit_pass_mob_changes >= 0 default 0.25;
param limit_freight_changes >= 0 default 0.25;
param efficiency {YEARS} >=0 default 1;

## VARIABLES [Tables 1.2, 1.3] ###

## NEW VARIABLES FOR PATHWAY:
var F_newBuild {PHASE   union {"2010_2015"}, TECHNOLOGIES} >= 0; # Accounts for the additional new capacity installed in a new phase
var F_decommissioning {PHASE  ,PHASE  union {"2010_2015"}, TECHNOLOGIES} >= 0; # Accounts for the decommissioned capacity in a new phase
var Phase_investment {PHASE } >=0; # Fiw the investment to be the same between each phase.
var TotalTransitionCost >=0; #Overall transition cost.
var Total_opex_cost ; # Total operating (including ressources cost) and maintenance
var Total_capex_cost; # Total cost of assets including the investment during phases
var F_old {PHASE  ,TECHNOLOGIES} >=0, default 0;




var End_Uses {YEARS, LAYERS, PERIODS} >= 0; # total demand for each type of end-uses (monthly power). Defined for all layers (0 if not demand)
# var Number_Of_Units {TECHNOLOGIES} integer; # N: number of units of size ref_size which are installed.
var F_Mult {PHASE, YEARS, TECHNOLOGIES} >= 0; # F: installed size, multiplication factor with respect to the values in layers_in_out table
var F_Mult_t {PHASE, YEARS, RESOURCES union TECHNOLOGIES, PERIODS} >= 0; # F_Mult_t: Operation in each period. multiplication factor with respect to the values in layers_in_out table. Takes into account c_p
var C_inv {YEARS, TECHNOLOGIES} >= 0; # Total investment cost of each technology
var C_maint {YEARS, TECHNOLOGIES} >= 0; # Total O&M cost of each technology (excluding resource cost)
var C_op {YEARS, RESOURCES} >= 0; # Total O&M cost of each resource
var Storage_In {YEARS, i in STORAGE_TECH, LAYERS, PERIODS} >= 0; # Sto_in: Power [GW] input to the storage in a certain period
var Storage_Out {YEARS, i in STORAGE_TECH, LAYERS, PERIODS} >= 0; # Sto_out: Power [GW] output from the storage in a certain period
var Share_Mobility_Public {y in YEARS} >= share_mobility_public_min[y], <= share_mobility_public_max[y]; # %_Public: % of passenger mobility attributed to public transportation
var Share_Freight_Train {y in YEARS}, >= share_freight_train_min[y], <= share_freight_train_max[y]; # %_Rail: % of freight mobility attributed to train
var Share_Freight_Road {y in YEARS}, >= share_freight_road_min[y], <= share_freight_road_max[y]; # %_Rail: % of freight mobility attributed to train
var Share_Freight_Boat {y in YEARS}, >= share_freight_boat_min[y], <= share_freight_boat_max[y]; # %_Rail: % of freight mobility attributed to train
var Share_Heat_Dhn {y in YEARS}, >= share_heat_dhn_min[y], <= share_heat_dhn_max[y]; # %_Dhn: % of low-T heat demand attributed to DHN
var Power_nuclear {YEARS}  >=0; # [GW] P_Nuc: Constant load of nuclear
var Shares_Mobility_Passenger {YEARS, TECHNOLOGIES_OF_END_USES_CATEGORY["MOBILITY_PASSENGER"]} >=0; # %_MobPass [-]: Constant share of passenger mobility
var Shares_Mobility_Freight {YEARS, TECHNOLOGIES_OF_END_USES_CATEGORY["MOBILITY_FREIGHT"]} >=0; # %_Freight [-]: Constant share of passenger mobility
var Shares_LowT_Dec {YEARS, TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}}>=0 ; # %_HeatDec [-]: Constant share of heat Low T decentralised + its specific thermal solar
var F_Solar         {YEARS, TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}} >=0; # F_sol [GW]: Solar thermal installed capacity per heat decentralised technologies
var F_Mult_t_Solar       {PHASE, YEARS, TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"},PERIODS} >= 0; # F_Mult_t_sol [GW]: Solar thermal operating per heat decentralised technologies
#var Y_Solar_Backup {TECHNOLOGIES} binary; # Y_Solar: binary variable. if 1, identifies the decentralized technology (only 1) which is backup for solar. 0 for all other technologies
var Network_losses {YEARS, END_USES_TYPES, PERIODS} >= 0; # Loss: Losses in the networks (normally electricity grid and DHN)
var GWP_constr {YEARS, TECHNOLOGIES} >= 0; # Total emissions of the technologies [ktCO2-eq.]
var GWP_op {YEARS, RESOURCES} >= 0; # Total yearly emissions of the resources [ktCO2-eq./y]
var TotalGWP {YEARS} >= 0; # GWP_tot: Total global warming potential (GWP) emissions in the system [ktCO2-eq./y]
var TotalCost {YEARS} >= 0; # C_tot: Total GWP emissions in the system [ktCO2-eq./y]


#########################################
###      CONSTRAINTS Eqs [1-42]       ###
#########################################

## End-uses demand calculation constraints 

# [Figure 1.4] From annual energy demand to monthly power demand. End_Uses is non-zero only for demand layers.
subject to end_uses_t {y in YEARS, l in LAYERS, t in PERIODS}:
	End_Uses [y,l,t] = (if l == "ELECTRICITY" 
		then
			(end_uses_input[y,l] / total_time + end_uses_input[y,"LIGHTING"] * lighting_month [t] / t_op [t]) + Network_losses [y,l,t]
		else (if l == "HEAT_LOW_T_DHN" then
			(end_uses_input[y,"HEAT_LOW_T_HW"] / total_time + end_uses_input[y,"HEAT_LOW_T_SH"] * heating_month [t] / t_op [t]) * Share_Heat_Dhn [y] + Network_losses [y,l,t]
		else (if l == "HEAT_LOW_T_DECEN" then
			(end_uses_input[y,"HEAT_LOW_T_HW"] / total_time + end_uses_input[y,"HEAT_LOW_T_SH"] * heating_month [t] / t_op [t]) * (1 - Share_Heat_Dhn [y])
		else (if l == "MOB_PUBLIC" then
			(end_uses_input[y,"MOBILITY_PASSENGER"] / total_time) * Share_Mobility_Public [y]
		else (if l == "MOB_PRIVATE" then
			(end_uses_input[y,"MOBILITY_PASSENGER"] / total_time) * (1 - Share_Mobility_Public [y])
		else (if l == "MOB_FREIGHT_RAIL" then
			(end_uses_input[y,"MOBILITY_FREIGHT"] / total_time) * Share_Freight_Train [y]
		else (if l == "MOB_FREIGHT_ROAD" then
			(end_uses_input[y,"MOBILITY_FREIGHT"] / total_time) * Share_Freight_Road [y]
		else (if l == "MOB_FREIGHT_BOAT" then
			(end_uses_input[y,"MOBILITY_FREIGHT"] / total_time) * Share_Freight_Boat [y]
		else (if l == "HEAT_HIGH_T" then
			end_uses_input[y,l] / total_time
		else (if l == "NON_ENERGY" then
			end_uses_input[y,l] / total_time
		else 
			0 )))))))))); # For all layers which don't have an end-use demand
	
subject to Freight_shares {y in YEARS}:
	Share_Freight_Train [y] + Share_Freight_Road [y] + Share_Freight_Boat [y] = 1; # =1 should work... But don't know why it doesn't

## Multiplication factor

# [Eq. 1.1]	
subject to totalcost_cal {y in YEARS}:
	TotalCost [y] = sum {i in TECHNOLOGIES} (tau [y,i]  * C_inv [y,i] + C_maint [y,i]) + sum {j in RESOURCES} C_op [y,j];
	
# [Eq. 1.3] Investment cost of each technology
subject to investment_cost_calc {y in YEARS, i in TECHNOLOGIES}: # add storage investment cost
	C_inv [y,i] =  sum{p in PHASE, y_start in PHASE_START [p]} (c_inv [y_start, i] * F_Mult [p,y,i]);
		
# [Eq. 1.4] O&M cost of each technology
subject to main_cost_calc {y in YEARS, i in TECHNOLOGIES}: # add storage investment
	C_maint [y,i] = sum{p in PHASE, y_start in PHASE_START [p]} (c_maint [y_start,i] * F_Mult [p,y,i]);		

	
# [Eq. 1.10] Total cost of each resource
subject to op_cost_calc {y in YEARS, i in RESOURCES}:
	C_op [y,i] = sum {t in PERIODS, p in PHASE, y_start in PHASE_START [p]} (c_op [y_start,i] * F_Mult_t [p ,y ,i ,t] * t_op [t]);

# [Eq. 1.21]
subject to totalGWP_calc {y in YEARS}:
	TotalGWP [y] =  sum {j in RESOURCES} GWP_op [y,j];
	# JUST RESOURCES : TotalGWP [y] =  sum {j in RESOURCES} GWP_op [y,j];
	#BASED ON LCA:   TotalGWP [y] = sum {i in TECHNOLOGIES} (GWP_constr [y,i] / lifetime [y,i]) + sum {j in RESOURCES} GWP_op [y,j];

# [Eq. 1.5]
subject to gwp_constr_calc {y in YEARS,i in TECHNOLOGIES}:
	GWP_constr [y,i] = sum{p in PHASE, y_start in PHASE_START [p]} (gwp_constr [y_start,i] * F_Mult [p,y ,i]);

# [Eq. 1.10]
subject to gwp_op_calc {y in YEARS, i in RESOURCES}:
	GWP_op [y,i] = gwp_op [y,i] * sum {t in PERIODS} (t_op [t] * sum{p in PHASE} F_Mult_t [p, y, i, t]);	


	
## Multiplication factor
#-----------------------


# [Eq. 9] min & max limit to the size of each technology
subject to size_limit {y in YEARS, i in TECHNOLOGIES}:
	f_min [y,i] <= sum{p in PHASE} F_Mult [p,y,i] <= f_max [y,i];
	
# [Eq. 1.8] relation between mult_t and mult via period capacity factor. This forces max monthly output (e.g. renewables)
subject to capacity_factor_t {p in PHASE, y in YEARS, i in TECHNOLOGIES, t in PERIODS}:
	F_Mult_t [p, y, i, t] <= F_Mult [p, y, i] * c_p_t [ i, t];
	
# [Eq. 1.9] relation between mult_t and mult via yearly capacity factor. This one forces total annual output
subject to capacity_factor {p in PHASE, y_start in PHASE_START [p], y in YEARS, i in TECHNOLOGIES}:
	sum {t in PERIODS} (F_Mult_t [p, y, i, t] * t_op [t]) <= F_Mult [p, y, i] * c_p [y_start, i] * total_time;	
	
	
# [Eq. 1.12] Resources availability equation
subject to resource_availability {y in YEARS, i in RESOURCES}:
	sum {t in PERIODS, p in PHASE} (F_Mult_t [p, y, i, t] * t_op [t]) <= avail [y, i];

## Layers

# [Eq. 1.13] Layer balance equation with storage. Layers: input > 0, output < 0. Demand > 0. Storage: in > 0, out > 0;
# output from technologies/resources/storage - input to technologies/storage = demand. Demand has default value of 0 for layers which are not end_uses
subject to layer_balance {y in YEARS, l in LAYERS, t in PERIODS}:
	sum {i in RESOURCES union TECHNOLOGIES diff STORAGE_TECH, p in PHASE, y_start in PHASE_START [p]} (layers_in_out[y_start,i, l] * F_Mult_t [p, y, i, t]) 
		+ sum {j in STORAGE_TECH} (Storage_Out [y, j, l, t] - Storage_In [y, j, l, t])
		= End_Uses [y, l, t];
	
## Storage	
#---------
	
# [Eq. 1.14] The level of the storage represents the amount of energy stored at a certain time.
subject to storage_level {y in YEARS, i in STORAGE_TECH, t in PERIODS}:
	F_Mult_t [y, i, t] = (if t == 1 then
	 			F_Mult_t [y, i, card(PERIODS)] * (1 - storage_losses[y, i]*t_op[t]) 
				+ ((sum {l in LAYERS: storage_eff_in [y,i,l] > 0} (Storage_In [y, i, l, t] * storage_eff_in [y, i, l])) 
					- (sum {l in LAYERS: storage_eff_out [y,i,l] > 0} (Storage_Out [y, i, l, t] / storage_eff_out [y, i, l]))) * t_op [t]
	else
	 			F_Mult_t [y, i, t-1] * (1 - storage_losses[y, i]*t_op[t]) 
				+ ((sum {l in LAYERS: storage_eff_in [y,i,l] > 0} (Storage_In [y, i, l, t] * storage_eff_in [y, i, l])) 
					- (sum {l in LAYERS: storage_eff_out [y,i,l] > 0} (Storage_Out [y, i, l, t] / storage_eff_out [y, i, l]))) * t_op [t]);
							
# [Eq. 16] Bounding seasonal storage
subject to limit_energy_stored_to_maximum {y in YEARS, j in STORAGE_TECH , t in PERIODS}:
	F_Mult_t [y, j, t] <= F_Mult [y, j];# Never exceed the size of the storage unit
	
# [Eq. 1.15-1.16] Each storage technology can have input/output only to certain layers. If incompatible then the variable is set to 0
subject to storage_layer_in {y in YEARS, i in STORAGE_TECH, l in LAYERS, t in PERIODS}:
	if storage_eff_in [y, i, l]=0 then Storage_In [y, i, l, t] = 0;
subject to storage_layer_out {y in YEARS, i in STORAGE_TECH, l in LAYERS, t in PERIODS}:
	if storage_eff_out [y, i, l]=0 then Storage_Out [y, i, l, t] = 0;

# NO NEED
## [Eq. 19] limit the Energy to power ratio. 
#subject to limit_energy_to_power_ratio {y in YEARS, j in STORAGE_TECH , l in LAYERS, h in HOURS, td in TYPICAL_DAYS}:
#	Storage_in [y, j, l, h, td] * storage_charge_time[y, j] + Storage_out [,j, l, h, td] * storage_discharge_time[y, j] <=  F [y, j] * storage_availability[y, j];
	


## Infrastructure
#----------------

## [Eq. 1.18] Calculation of losses for each end-use demand type (normally for electricity and DHN)
subject to network_losses {y in YEARS, i in END_USES_TYPES, t in PERIODS}:
	Network_losses [y, i,t] = (sum {j in RESOURCES union TECHNOLOGIES diff STORAGE_TECH: layers_in_out [y,j, i] > 0} ((layers_in_out[y,j, i]) * F_Mult_t [y, j, t])) * loss_network [y, i];

# [Eq. 1.28] 9.4 BCHF is the extra investment needed if there is a big deployment of stochastic renewables
# Note that in Moret (2017), page 26, Eq. 1.28 is not correctly reported (the "1 +" term is missing).
# Also, in Moret (2017) there is a ">=" sign instead of an "=". The two formulations are equivalent as long as the problem minimises cost and the grid has a cost > 0
subject to extra_grid {y in YEARS}:
	F_Mult [y,"GRID"] = 1 + (c_grid_extra / c_inv[y,"GRID"]) * (F_Mult [y,"WIND_ONSHORE"] + F_Mult [y,"WIND_OFFSHORE"] + F_Mult [y,"PV"]) / (f_max [y,"WIND_ONSHORE"] + f_max [y,"WIND_OFFSHORE"] + f_max [y,"PV"]);
## [Eq. 1.26] DHN: assigning a cost to the network
# Note that in Moret (2017), page 26, there is a ">=" sign instead of an "=". The two formulations are equivalent as long as the problem minimises cost and the DHN has a cost > 0
subject to extra_dhn {y in YEARS}:
	F_Mult [y,"DHN"] = sum {j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DHN"]} (F_Mult [y,j]);


## Additional constraints
#------------------------
	
# [Eq. 24] Fix nuclear production constant : 
subject to constantNuc {y in YEARS, t in PERIODS}:
	F_Mult_t [y,"NUCLEAR", t] = Power_nuclear [y];

# [Eq. 25] Operating strategy in mobility passenger (to make model more realistic)
# Each passenger mobility technology (j) has to supply a constant share  (Shares_Mobility_Passenger[j]) of the passenger mobility demand
subject to operating_strategy_mob_passenger{y in YEARS, j in TECHNOLOGIES_OF_END_USES_CATEGORY["MOBILITY_PASSENGER"], t in PERIODS}:
	F_Mult_t [y, j, t]   = Shares_Mobility_Passenger [y, j] * (end_uses_input[y, "MOBILITY_PASSENGER"] / total_time);
	
	
# NEW CONSTRAINT to fix the use of trucks (not having FC trucks during summer and other during winter).
# [Eq. 25bis] Operating strategy in mobility freight (to make model more realistic)
# Each freight mobility technology (j) has to supply a constant share  (Shares_Mobility_Freight[j]) of the passenger mobility demand
subject to operating_strategy_mobility_freight{y in YEARS, j in TECHNOLOGIES_OF_END_USES_CATEGORY["MOBILITY_FREIGHT"], t in PERIODS}:
	F_Mult_t [y, j, t]   = Shares_Mobility_Freight [y, j] * (end_uses_input[y, "MOBILITY_FREIGHT"] / total_time);

## Thermal solar & thermal storage:

# [Eq. 26] relation between decentralised thermal solar power and capacity via period capacity factor.
subject to thermal_solar_capacity_factor {y in YEARS, j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}, t in PERIODS}:
	F_Mult_t_Solar [y, j, t] <= F_Solar[y, j] * c_p_t["DEC_SOLAR", t];
	
# [Eq. 27] Overall thermal solar is the sum of specific thermal solar 	
subject to thermal_solar_total_capacity {y in YEARS} :
	F_Mult [y, "DEC_SOLAR"] = sum {j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}} F_Solar[y, j];

# [Eq. 28]: Decentralised thermal technology must supply a constant share of heat demand.
subject to decentralised_heating_balance  {y in YEARS, j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}, t in PERIODS}:
	F_Mult_t [y, j, t] + F_Mult_t_Solar [y, j, t]  
		= Shares_LowT_Dec[y, j] * (end_uses_input[y, "HEAT_LOW_T_HW"] / total_time + end_uses_input[y, "HEAT_LOW_T_SH"] * heating_month [t] / t_op [t]);

### Hydroelectric dams. (Not for the case of Belgium).
## In this version applied for the Swiss case, we use Eqs. 40-42 instead of Eqs. 29-31. Hence, the following is commented
## [Eq. 29] Seasonal storage in hydro dams.
## When installed power of new dams 0 -> 0.44, maximum storage capacity changes linearly 0 -> 2400 GWh/y
#subject to storage_level_hydro_dams: 
#	F ["DAM_STORAGE"] <= f_min ["DAM_STORAGE"] + (f_max ["DAM_STORAGE"]-f_min ["DAM_STORAGE"]) * (F ["HYDRO_DAM"] - f_min ["HYDRO_DAM"])/(f_max ["HYDRO_DAM"] - f_min ["HYDRO_DAM"]);
#
## [Eq. 30] Hydro dams can stored the input energy and restore it whenever. Hence, inlet is the input river and outlet is bounded by max capacity
#subject to impose_hydro_dams_inflow {h in HOURS, td in TYPICAL_DAYS}: 
#	Storage_in ["DAM_STORAGE", "ELECTRICITY", h, td] = F_Mult_t ["HYDRO_DAM", h, td];
#
## [Eq. 31] Hydro dams production is lower than installed F_Mult_t capacity:
#subject to limit_hydro_dams_output {h in HOURS, td in TYPICAL_DAYS}: 
#	Storage_out ["DAM_STORAGE", "ELECTRICITY", h, td] <= F ["HYDRO_DAM"];


## EV storage :

## [Eq. 32] Compute the equivalent size of V2G batteries based on the share of V2G, the amount of cars and the battery capacity per EVs technology
#subject to EV_storage_size {j in V2G, i in EVs_BATT_OF_V2G[j]}:
#	F [i] = n_car_max * Shares_Mobility_Passenger[j] * Batt_per_Car[j];# Battery size proportional to the amount of cars
#	
## [Eq. 33]  Impose EVs to be supplied by their battery.
#subject to EV_storage_for_V2G_demand {j in V2G, i in EVs_BATT_OF_V2G[j], h in HOURS, td in TYPICAL_DAYS}:
#	Storage_out [i,"ELECTRICITY",t] * t_op[t] >=  - layers_in_out[y, j,"ELECTRICITY"]* F_Mult_t [j, h, td];
		
## Peak demand :

# [Eq. 34] Peak in decentralized heating
subject to peak_lowT_dec {y in YEARS, j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DECEN"] diff {"DEC_SOLAR"}, t in PERIODS}:
	F_Mult [y,j] >= peak_sh_factor  * F_Mult_t [y,j, t] ;


# [Eq. 1.27] Calculation of max heat demand in DHN 
var Max_Heat_Demand_DHN {YEARS}  >= 0;
subject to max_dhn_heat_demand {y in YEARS, t in PERIODS}:
	Max_Heat_Demand_DHN [y] >= End_Uses [y,"HEAT_LOW_T_DHN", t];
# Peak in DHN
subject to peak_dhn {y in YEARS} :
	sum {j in TECHNOLOGIES_OF_END_USES_TYPE["HEAT_LOW_T_DHN"]} (F_Mult [y,j]) >= peak_sh_factor  * Max_Heat_Demand_DHN [y];

## Adaptation for the case study: Constraints needed for the application to Switzerland (not needed in standard LP formulation)
#-----------------------------------------------------------------------------------------------------------------------

# [Eq. 36]  constraint to reduce the GWP subject to Minimum_gwp_reduction :
subject to Minimum_GWP_reduction {y in YEARS} :
	TotalGWP [y] <= gwp_limit [y];
	
subject to Minimum_GWP_transition  :
	sum {y in YEARS} TotalGWP [y] * t_phase <= gwp_limit_transition;

# [Eq. 37] Minimum share of RE in primary energy supply
subject to Minimum_RE_share {y in YEARS} :
	sum {j in RE_RESOURCES, t in PERIODS} F_Mult_t [y,j, t] * t_op [t] 
	>=	re_share_primary [y]*
	sum {j in RESOURCES, t in PERIODS} F_Mult_t [y, j, t] * t_op [t]	;
		
# [Eq 1.22] Definition of min/max output of each technology as % of total output in a given layer. 
# Normally for a tech should use either f_max/f_min or f_max_%/f_min_%
subject to f_max_perc {y in YEARS, i in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE[i]}:
	sum {t in PERIODS} (F_Mult_t [y,j, t] * t_op[t]) <= fmax_perc [y,j] * sum {j2 in TECHNOLOGIES_OF_END_USES_TYPE[i], t2 in PERIODS} (F_Mult_t [y,j2, t2] * t_op [t2]);
subject to f_min_perc {y in YEARS, i in END_USES_TYPES, j in TECHNOLOGIES_OF_END_USES_TYPE[i]}:
	sum {t in PERIODS} (F_Mult_t [y,j, t] * t_op[t])  >= fmin_perc [y,j] * sum {j2 in TECHNOLOGIES_OF_END_USES_TYPE[i], t2 in PERIODS} (F_Mult_t [y,j2, t2] * t_op [t2]);

# Energy efficiency is a fixed cost
subject to extra_efficiency {y in YEARS}:
	F_Mult [y, "EFFICIENCY"] = efficiency[y];	



### Variant equations for hydro dams	
## [Eq. 40] Seasonal storage in hydro dams.
## When installed power of new dams 0 -> 0.44, maximum storage capacity changes linearly 0 -> 2400 GWh/y
#subject to storage_level_hydro_dams: 
#	F ["DAM_STORAGE"] <= f_min ["DAM_STORAGE"] + (f_max ["DAM_STORAGE"]-f_min ["DAM_STORAGE"]) * (F ["NEW_HYDRO_DAM"] - f_min ["NEW_HYDRO_DAM"])/(f_max ["NEW_HYDRO_DAM"] - f_min ["NEW_HYDRO_DAM"]);
#
## [Eq. 41] Hydro dams can stored the input energy and restore it whenever. Hence, inlet is the input river and outlet is bounded by max capacity
#subject to impose_hydro_dams_inflow {h in HOURS, td in TYPICAL_DAYS}: 
#	Storage_in ["DAM_STORAGE", "ELECTRICITY", h, td] = F_Mult_t ["HYDRO_DAM", h, td] + F_Mult_t ["NEW_HYDRO_DAM", h, td];
#
## [Eq. 42] Hydro dams production is lower than installed F_Mult_t capacity:
#subject to limit_hydro_dams_output {h in HOURS, td in TYPICAL_DAYS}: 
#	Storage_out ["DAM_STORAGE", "ELECTRICITY", h, td] <= (F ["HYDRO_DAM"] + F ["NEW_HYDRO_DAM"]);


# [Eq. XX] Mob infrastructures
subject to mob_infrastructures_motorways {y in YEARS}:
	F_Mult [y,"INLAND_WATER_TRANSPORT"] = sum {j in TECHNOLOGIES_OF_END_USES_TYPE["MOB_FREIGHT_BOAT"], t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) / 10343.7; 

# [Eq. XX] Mob infrastructures
subject to mob_infrastructures_roads {y in YEARS}:
	F_Mult [y,"ROADS"] =      0.592  * sum {j in TECHNOLOGIES_OF_END_USES_TYPE["MOB_PRIVATE"], t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) / 126399 
						   + 0.132  * sum {j in TECHNOLOGIES_OF_END_USES_TYPE["MOB_PUBLIC"] diff {"TRAIN_PUB","TRAMWAY_TROLLEY"}, t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) / 18012
						   + 0.272  * sum {j in TECHNOLOGIES_OF_END_USES_TYPE["MOB_FREIGHT_ROAD"], t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) / 47980; # 126399 is the total Mkm-pass supplied by private cars. 18012 is the same supplied by MOB PUBLIC - train - tram.47980 same for freight ROAD

# [Eq. XX] Mob infrastructures
subject to mob_infrastructures_rails {y in YEARS}:
	F_Mult [y,"RAILWAYS"] =      0.9 * sum {j in {"TRAIN_PUB","TRAMWAY_TROLLEY"}, t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) / 13588
						   + 0.1 * sum {j in TECHNOLOGIES_OF_END_USES_TYPE["MOB_FREIGHT_RAIL"], t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) /  8250; # 126399 is the total Mkm-pass supplied by private cars. 18012 is the same supplied by MOB PUBLIC - train - tram.47980 same for freight ROAD


# [Eq. XX] Station infrastructures :
subject to infrastructures_stations_liq {y in YEARS}:
	F_Mult [y,"STATION_LIQUID_FUELS"] =   0.8 * sum {j in {"BUS_COACH_DIESEL","BUS_COACH_HYDIESEL","CAR_GASOLINE","CAR_DIESEL","CAR_HEV","CAR_PHEV"}, t in PERIODS} 
							     (F_Mult_t[y,j,t] * t_op[t]) * 1 /( 1 * 13588)
							   +   0.2 * sum {j in {"BOAT_FREIGHT_DIESEL","TRUCK_DIESEL"}, t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) * 1 /( 1 *  8250); # 126399 is the total Mkm-pass supplied by private cars. 18012 is the same supplied by MOB PUBLIC - train - tram.47980 same for freight ROAD

subject to infrastructures_stations_gas {y in YEARS}:
	F_Mult [y,"STATION_GAS_FUELS"] =    0.8 * sum {j in {"BUS_COACH_CNG_STOICH","TRUCK_NG"}, t in PERIODS} 
							     (F_Mult_t[y,j,t] * t_op[t]) * 1 /( 1 * 13588)
							   + 0.2 * sum {j in {"BOAT_FREIGHT_NG","TRUCK_DIESEL"}, t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) * 1 /( 1 *  8250); # 126399 is the total Mkm-pass supplied by private cars. 18012 is the same supplied by MOB PUBLIC - train - tram.47980 same for freight ROAD

subject to infrastructures_stations_elec {y in YEARS}:
	F_Mult [y,"STATION_ELEC"] =   sum {j in {"CAR_BEV"}, t in PERIODS} 
							     (F_Mult_t[y,j,t] * t_op[t]) * 1 /( 1 * 13588)
							   ; # 126399 is the total Mkm-pass supplied by private cars. 18012 is the same supplied by MOB PUBLIC - train - tram.47980 same for freight ROAD

subject to infrastructures_stations_h2 {y in YEARS}:
	F_Mult [y,"STATION_H2"] =           0.5 * sum {j in {"BUS_COACH_FC_HYBRIDH2","CAR_FUEL_CELL"}, t in PERIODS} 
							     (F_Mult_t[y,j,t] * t_op[t]) * 1 /( 1 * 13588)
							   + 0.5 * sum {j in {"TRUCK_FUEL_CELL"}, t in PERIODS} 
								  (F_Mult_t[y,j,t] * t_op[t]) * 1 /( 1 *  8250); # 126399 is the total Mkm-pass supplied by private cars. 18012 is the same supplied by MOB PUBLIC - train - tram.47980 same for freight ROAD



##########################
### OBJECTIVE FUNCTION ###
##########################


### ### NEW objective function :

# OPEX
var C_opex {YEARS} >=0;
var C_opex_tot >=0;


subject to Opex_cost_calculation{y in YEARS} :
	C_opex [y] = sum {j in TECHNOLOGIES} C_maint [y,j] + sum {i in RESOURCES} C_op [y,i]; #In â‚¬_y

subject to Opex_tot_cost_calculation :
	C_opex_tot = C_opex["YEAR_2015"] 
				 + sum {p in PHASE,y_start in PHASE_START [p],y_stop in PHASE_STOP [p]} ( 
					t_phase * (C_opex [y_start] + C_opex [y_stop])/2 
							   / ((1+i_rate)^diff_2015_phase[p])
					); #

# CAPEX
var C_capex_tot >=0;

subject to total_capex  :
	C_capex_tot = sum {i in TECHNOLOGIES} C_inv ["YEAR_2015",i] # 2015 investment
				 + sum{p in PHASE} Phase_investment [p];# Ã¢â€šÂ¬_2015


## NEW CONSTRAINTS FOR PATHWAY:

set AGE {TECHNOLOGIES,PHASE} within PHASE union {"2010_2015"} union {"STILL_IN_USE"};
param decom_allowed {PHASE,PHASE  union {"2010_2015"},TECHNOLOGIES} default 0;

# [Eq. XX] Relate the installed capacity between years
subject to phase_new_build {p in PHASE, y_start in PHASE_START[p], y_stop in PHASE_STOP[p], i in TECHNOLOGIES}:
	F_Mult[y_stop,i] = F_Mult[y_start,i] + F_newBuild[p,i] - F_old [p,i] 
  											     - sum {p2 in {PHASE union {"2010_2015"}}} F_decommissioning[p,p2,i];

# [Eq. XX] Impose F_decommissioning to 0 when not physical
subject to define_f_decom_properly {p in PHASE, p_stop in PHASE, i in TECHNOLOGIES}:
	if decom_allowed[p,p_stop,i] == 0 then F_decommissioning [p,p_stop,i] = 0;

# [Eq. XX] Intialise the first phase based on YEAR_2015 results
subject to F_new_initiatlisation {tech in TECHNOLOGIES}:
	F_newBuild ["2010_2015",tech] = F_Mult["YEAR_2015",tech]; # Generate F_new2010_2015

# [Eq. XX] Impose the exact capacity that reaches its lifetime
subject to phase_out_assignement {i in TECHNOLOGIES, p in PHASE, age in AGE [i,p]}:
	F_old [p,i] = if (age == "STILL_IN_USE") then  0 #<=> no problem
					else F_newBuild [age,i]    - sum {p2 in PHASE} F_decommissioning [p2,age,i]
				;
				
				
var Delta_change {PHASE,TECHNOLOGIES} >=0;				
# Limit renovation rate:
# [Eq. XX] Define the amount of change between years 
subject to delta_change_definition {p in PHASE, y_start in PHASE_START[p], y_stop in PHASE_STOP[p], j in TECHNOLOGIES} :
	Delta_change [p,j] >= (sum {t in PERIODS} F_Mult_t [y_start,j,t] * t_op[t]) - (sum {t in PERIODS} F_Mult_t [y_stop,j,t] * t_op[t]) ;

# [Eq. XX] Limit the amount of change for low temperature heating
subject to limit_changes_heat {p in PHASE, y_start in PHASE_START[p], y_stop in PHASE_STOP[p]} :
	sum {euc in END_USES_TYPES_OF_CATEGORY["HEAT_LOW_T"], j in TECHNOLOGIES_OF_END_USES_TYPE[euc]} Delta_change[p,j] 
		<= limit_LT_renovation * (end_uses_input[y_start,"HEAT_LOW_T_HW"] + end_uses_input[y_start,"HEAT_LOW_T_SH"]) ;

# [Eq. XX] Limit the amount of change for passenger mobility
subject to limit_changes_mob {p in PHASE, y_start in PHASE_START[p], y_stop in PHASE_STOP[p]} :
	sum {euc in END_USES_TYPES_OF_CATEGORY["MOBILITY_PASSENGER"], j in TECHNOLOGIES_OF_END_USES_TYPE[euc]} Delta_change[p,j] 
		<= limit_pass_mob_changes * (end_uses_input[y_start,"MOBILITY_PASSENGER"]);

# [Eq. XX] Limit the amount of change for freight mobility
subject to limit_changes_fright {p in PHASE, y_start in PHASE_START[p], y_stop in PHASE_STOP[p]} :
	sum {euc in END_USES_TYPES_OF_CATEGORY["MOBILITY_FREIGHT"], j in TECHNOLOGIES_OF_END_USES_TYPE[euc]} Delta_change[p,j] 
		<= limit_freight_changes * (end_uses_input[y_start,"MOBILITY_FREIGHT"]);


subject to investment_computaiton {p in PHASE, y_start in PHASE_START[p], y_stop in PHASE_STOP[p]}:
	 Phase_investment [p] = sum {i in TECHNOLOGIES} F_newBuild[p,i]*annualised_factor[p]*(c_inv[y_start,i]+c_inv[y_stop,i])/2; #In bÃ¢â€šÂ¬

subject to maxInvestment {p in PHASE}:
	 Phase_investment [p] <= max_inv_phase[p]; #In bÃ¢â€šÂ¬


var Fixed_phase_investment;
subject to sameInvestmentPerPhase {p in PHASE}:
	 Phase_investment [p] = Fixed_phase_investment; #In bÃ¢â€šÂ¬

subject to New_totalTransitionCost_calculation :
	TotalTransitionCost = C_capex_tot + C_opex_tot;


# [Eq. XX] Limit the amount of electricity imported over the year (energy dependency)
subject to elec_import_limit_share {y in YEARS}:
	sum {t in PERIODS} (F_Mult_t [y,"ELECTRICITY",t] * t_op[t]) 
	      <= elec_max_import_share[y] * sum{t in PERIODS} (End_Uses [y,"ELECTRICITY", t] * t_op [t]);


# To limit the mobility changes in periods to 15-25%:
param limit_mobility_pass {PHASE} >= 0, <=1, default 0.02; # Limit on the changes of mobility strategy. param = 0.05 <=> 20% of changes in the mobility supply in a phase.
param limit_mobility_freight {PHASE} >= 0, <=1 default 0.02; # Limit on the changes of mobility strategy. param = 0.05 <=> 20% of changes in the mobility supply in a phase.


/*
##New formulation to tackle the boundary condition of 2050_2055


# Former expression. However it doesn't take into account if technologies have been installed a long time ago or not.
subject to phase_new_build2_after {p in PHASE_AFTER , y_start in PHASE_START[p], y_stop in PHASE_STOP[p], i in TECHNOLOGIES}:
	F_newBuild[p,i] = F_old [p,i];


# At this stage, F_old seems to work accordingly to what is expected.
subject to phase_out_assignement_after {i in TECHNOLOGIES, p in PHASE_AFTER, age in AGE [i,p]}:
	F_old [p,i] = if (age == "STILL_IN_USE") then  0 #<=> no problem
					else (  if (age == "BEFORE_2015") then
								F_newBuild["2010_2015",i] - sum {p2 in PHASE} F_decommissioning [p2,"2010_2015",i] # We cannot do decom in periods AFTER
							else  
								F_newBuild [age,i]  #Si age within PHASE_AFTER => decomm bug 
		  );

#		  else  (	if (age within PHASE) then
#								F_newBuild [age,i]    - sum {p2 in PHASE} F_decommissioning [p2,age,i]
#								else F_newBuild [age,i]
#		  ));

subject to investment_computaiton_2 {p in PHASE_AFTER, y_start in PHASE_START[p], y_stop in PHASE_STOP[p]}:
	 Phase_investment [p] = sum {i in TECHNOLOGIES} F_newBuild[p,i]*annualised_factor["2045_2050"]*c_inv["YEAR_2050",i]; #In bÃ¢â€šÂ¬

subject to investment_limit_AFTER {p in PHASE_AFTER}:
	Phase_investment [p] <= Fixed_phase_investment;
*/


# Can choose between TotalTransitionCost_calculation and TotalGWP and TotalCost
minimize obj:  TotalTransitionCost;#sum {y in YEARS} TotalCost [y];
# minimize obj: sum {y in YEARS} TotalGWP [y] * t_phase;

