/**
* Name: FRBModel 
* Authors: Deborah S. Sousa and Cássio G. Coelho
* Tags: irrigation; water regulation
*/

model FRB_Model

global {	
	//input data
	//Files: matrices and shapefiles
	file shapefile_pumps <- file("../includes/urubu_pumps.shp"); //irrigation pumps from GAN
	matrix farmers_data <- file("../includes/urubu_farmers.csv"); //Farmer agents information
	matrix pumps_data <- file("../includes/pumps_urubu.csv"); //Pumps information
	file shapefile_channels <- file("../includes/canais_semarh_clip.shp"); //irrigation channels from SEMARH
	file shapefile_land <- file("../includes/duxav.shp"); // agricultural properties from SIG-CAR
	matrix monthly_prices <- csv_file("../includes/MonthlyPrices.csv") as matrix; //sell prices for 60kg from CONAB

	//modelling variables
	float p_NC;
	float p_CP;
	list<int> farmer_number;
	float soybean_yield <- 3.5; // [ton/ha] //Soybean seed productivity of Tocantins state. Source: CONAB (avg 2017-2021) 
	float step <- 1 #day;
	int crop_cycle_dt <- 152 ; //crop cycle total duration (planting day to harvest day) [days]. Source: Fagundes (2021) 
	date starting_date <- date("2020-05-01"); //1st of May, beginning of the dry period
	int initial_day <- 1; //day count
	int day_count <- initial_day + cycle; // day count
	int end_irrigation_period <- initial_day + crop_cycle_dt;// In our example, ends on the 30th of september
	float sell_price <- 2.63; //[R$/kg]. Source: CONAB (2021).	
	
	//initial state
	init {
		create Pump from: shapefile_pumps;
		
		create Farmer from: farmers_data;
	}
}

species Pump {	
	rgb color <- #grey;
}

species Regulator control: simple_bdi {
	float fiscalization_day_rule1 <- 61; //1st of July //belief de começar a contar o contador de fiscalizacao
	float fiscalization_day_rule2 <- 92; // 1st of August
	date fiscalization_date1 <- date("2020-07-01");
	date fiscalization_date2 <- date("2020-08-01");
	float yellow_level <- 3.98; // meters
	float red_level <- 2.20; // meters
	//matrix<float> PB_levels; //a 5 x 3 matrix (gauge station x yellow level x red level)
	//matrix<float> water_permits; //a 52 x 2  (water permits x farmer agent)
	
	plan IssueRules intention: regulate_use { // colocar prioridade 1
		ask myself{
			if(current_day = date("2020-07-01") or (current_level <= yellow_level)) {
				do add_belief(attention_rule);
			}else if(current_day = date("2020-08-01") or (current_level <= red_level)) { 
				do add_belief(restriction_rule);
			}	
		}
	}
		
	/*rule belief: attention_rule new_desire: reduce_consumed_volume;
	rule belief: restriction_rule new_desire: suspend_water_withdrawal;
	*/
	
	plan IdentifyDisobFarmers intention: fiscalize_farmers{ //chamado antes de reduzir, suspender, antes de penalidades
		//list disob_farmers;
		//loop farmers over Farmers;
			//if farmers.tot_consume > farmers.permit{
				//add farmers to disob_farmers;
		//do remove_intention(fiscalize_farmers, true);
	}
	
	plan ApplyPenalties intention: penalize_farmers{
		predicate apply_penalty <- new_predicate("apply penalty");
		// loop farmers over Farmers
			//if farmers in disob_farmers
				//farmers.permit <- 0.5*permit //regulatory penalty // example value
				//atualizar tambem na tabela de permits do regulador
				//farmers.cash <- 0.9*farmers.cash //economic penalty // example value
	}	
}

species Farmer control: simple_bdi {
	list<Farmer> farmer_number <- list(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24); //24 farmers in Urubu river basin 
	list<Pump> pumps;	
	// resgatar o perfil de cada um a partir da matriz "farmer_data", coluna //baseline profile scenario
	// resgatar as bombas de cada farmer a partir da matriz "pumps_data" //baseline profile scenario
	float pot_irr_area; //total irrigation area before alfa and beta factors
	float alfa;  //previous wet season factor
	float beta; // neighbourhood effect factor
	float revenue; //revenue from selling crop production 
	float consumed_volume; //after application of alfa, beta, calculated at the end of simulation
	float avf; // irrigation area x water volume (transformation factor)
	float total_irr_area <- consumed_volume*avf; //correlated with consumed volume 
	float lower_alfa;
	float upper_alfa;
	float lower_beta;
	float upper_beta;
	float p_NC_d; //percentage of NC farmers within a demand group
	float p_CP_d; //percentage of CP farmers within a demand group
	int nT_d; // the total number of farmers (all profiles)
	
	// relating farmers to pumps
	/*loop farmer over: Farmer {
		list<Pump> empty_fields <- Pump where (each.farmer = nil);
		farmer.pump <- empty_fields closest_to (farmer, farmer.number_of_fields);
		//farmer.my_area <- ;
		loop pump over: farmer.pump {
			pump.farmer <- farmer;
		}
	}*/
	
	//assigning each Farmer with their behaviour profiles
	string farmer_profile <- farmers_data[2,farmer_number] as string; //baseline farmer profile 
	/*loop farmer over: Farmer
		farmer.profile <- ;*/
	
	plan ChooseIrrigationArea intention: irrigate{
		float exp_irr_area <- pot_irr_area*alfa*beta;
	}
	
	//Previous wet season behavioural rules
	/* if (previous_wet_season >= average) {
		alfa <- 1.0
	}else{
		alfa <- rnd(lower_alfa,upper_alfa)
	}
	*/
	
	//Biennium Plan behavioural rules
	
	
	//Neighbourhood effect behavioural rules
	/*
	loop i over Di
		nT <- sum(Farmer);
		p_NC_d <- (sum(Farmer where (each.farmer_profile = 'NC'))) / nT_d ;
		p_CP_d <- (sum(Farmer where (each.farmer_profile = 'CP'))) / nT_d ;
		if (p_NC_d > 0.75) {
			beta <- upper_beta;
		}else if (p_CP_d> 0.75)){
			beta <- lower_beta;
		}else{
			beta <- rnd(lower_beta,upper_beta);
	*/
	
	// Defining farmers' profiles: Biennium Plan reactions, and Alfa and Beta limits
	species CP_Farmer parent: Farmer  {
		rgb color <- #green;
		lower_alfa <- 0.89;
		upper_alfa <- 0.95;
		lower_beta <- 0.89;
		upper_beta <- 0.95;
		
		reflex reduce_demand when: (current_date = date("2020-07-01") or current_level <= yellow_level) {
			consumed_volume <- 0.75*consumed_volume;
		}
	
		reflex suspend_withdrawal when: (current_date = date("2020-08-01") or current_level <= red_level) {
			consumed_volume <- 0.0*consumed_volume;
		}
	}
	
	species NC_Farmer parent: Farmer{
		rgb color <- #red;
		lower_alfa <- 1.0;
		upper_alfa <- 1.0;
		lower_beta <- 0.9;
		upper_beta <- 1.0;
	}
	
	species CI_Farmer parent: Farmer{
		rgb color <- #yellow;
		lower_alfa <- 0.92;
		upper_alfa <- 1.0;
		lower_beta <- 0.92;
		upper_beta <- 1.0;
		
		reflex reduce_demand when: (current_date >= date("2020-07-01") and current_level <= yellow_level) {
			consumed_volume <- 0.75*consumed_volume;
		}
	
		reflex suspend_withdrawal when: (current_date >= date("2020-08-01") and current_level <= red_level) {
			consumed_volume <- 0.0*consumed_volume;
		}	
	}	

	rule when: (day_count = end_irrigation_period) add_desire: sell_crops;
	
	plan SellCrops intention: generate_income{
		//float production <- consumed_volume*soybean_yield //[L*kg/ha]
		//float revenue <- production*total_irr_area*sell_price //[kg*ha*R$/kg]
	}
	
}	

/*experiment RegulatorProfile type:batch repeat:2 autorun: true keep_seed: true{	
{
	parameter "Regulator profile" var: reg_profile among: [inactive, active, proactive]  ;	
}		
	
	// the reflex will be activated at the end of each run; in this experiment a run consists of the execution of 4 simulations (repeat: 3)
	reflex end_of_runs {
		ask simulations	{
			//save [individual income, collective income, total withdrawn water] 
			type: "csv" rewrite: false to: "results/farmerprofile" + ".csv";
		}
	}
}*/

/*experiment FarmerProfile type:batch repeat:3 autorun: true keep_seed: true{	
{
	parameter "percentage of farmers with CP profile" var: p_CP among: [0.75, 1.00, 0.00, 0.00]  ;
	parameter "percentage of farmers with CI profile" var: p_CI among: [0.25, 0.00, 1.00, 0.00] ;
	parameter "percentage of farmers with NC profile" var: p_NC among: [0.00, 0.00, 0.00, 1.00] ;	
}		
	
	// the reflex will be activated at the end of each run; in this experiment a run consists of the execution of 4 simulations (repeat: 3)
	reflex end_of_runs {
		ask simulations	{
			//save [individual income, collective income, total withdrawn water] 
			type: "csv" rewrite: false to: "results/farmerprofile" + ".csv";
		}
	}
}*/