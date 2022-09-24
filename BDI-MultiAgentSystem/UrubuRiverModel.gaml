/**
* Name: FRBModel 
* Authors: Déborah S. Sousa, Cássio G. C. Coelho, Conceição de M. A. Alves, Célia G. Ralha.
* Tags: irrigation; water regulation
*/

model UrubuRiverModel

global {	
	//input data
	//Files: matrices and shapefiles
	file shapefile_pumps <- file("../includes/urubu_pumps.shp"); //irrigation pumps from GAN
	matrix farmers_data <- file("../includes/urubu_farmers.csv"); //Farmer agents information
	matrix pumps_data <- file("../includes/pumps_urubu.csv"); //Pumps information
	file shapefile_channels <- file("../includes/canais_semarh_clip.shp"); //irrigation channels from SEMARH
	file shapefile_land <- file("../includes/area_urubu.shp"); // agricultural properties in the Urubu river basin

	//modelling variables
	float soybean_yield <- 3.5; // [ton/ha] //Soybean seed productivity of Tocantins state. Source: CONAB (avg 2017-2021).
	float step <- 1 #day;
	int crop_irrigation_dt <- 51 ; //crop cycle total duration (planting day to harvest day) [days]. Source: Fagundes (2021). 
	date starting_date <- date("2020-06-15"); //15th of June, beginning of irrigation period.
	date irrigation_end_date <- date("2020-08-05"); //05 of August, 51 days of irrigation, end of irrigation period. Source: Fagundes (2021). 
	int initial_day <- 1; //day count
	int end_irrigation_period <- initial_day + crop_irrigation_dt; //number of days
	int day_count update: update_day_count(); 
//	int start_irrigation_period <- initial_day + first_irrigation_dt;
//	date starting_date <- date("2020-05-01"); //1st of May, beginning of the dry period.
//	date irrigation_start_date <- date("2020-06-15"); //15 of June, beginning of irrigation period. Source: Fagundes (2021).
//	int crop_cycle_dt <- 152 ; //crop cycle total duration (planting day to harvest day) [days]. Source: Fagundes (2021). 
//	int end_cycle_period <- initial_day + crop_cycle_dt;
//	int first_irrigation_dt <- 45;
	float sell_price <- 2.63; //[R$/kg]. Source: CONAB (2021).
	float previous_wet_season <- 25; //Previous observed water supply (flow or precipitation).
	float h_flow_average <- 50; //Average observed water supply (flow or precipitation).
	float initial_level <- 4.5;
	float current_level <- initial_level update:current_level - 0.05; // level variation at the reference gauging station [m] //might be given as an input of a hydrological model output
	string CP; //Cooperative-Proactive profile
	string CI; //Cooperative-Ideological profile
	string NC; //Non-Cooperative profile
	
	string scenario <- "S1" among: ["S1","S2"]; //simulation scenarios
	
	//initial state
	init {
		// loading parameters for scenarios simulation
		do load_parameters;
		
		create Regulator;
		
		//creating the pump agent
		create Pump from: shapefile_pumps;
		list<Pump> pumps;
//		create Farmer from:shapefile_pumps with:[agent_number::(string(read("agent_numb")))]{
		
		//creating the Farmer agent
		create Farmer number:24;
		list<Farmer> farmers;
		int i <- 1; 
		loop farmers over:Farmer{ //todo assign correct order
			farmers.agent_number <- i;
			i <- i + 1;
		}
		
		//assigning pumps to farmers //fictional
		loop i from:0 to:23 step:1 {
			add Pump[i] to:Farmer[i].owned_pumps;
		}
//todo correct assignment				
//		list agent_numb;
//		loop i from:1 to:24 step:1{
//			loop pumps over:Pumps{
//				if (pumps.agent_numb = i){
//					add Pump[i] to: Farmer[i].owned_pumps;	
//				}
//			}	
//		}

		//assigning farmers profile
		loop farmers over:Farmer{
			if ([9,13,10,15,16,8,1] contains farmers.agent_number){
				farmers.profile <- "CI";
			}else if ([7,11,21,17] contains farmers.agent_number){
				farmers.profile <- "CP";
			}else{
				farmers.profile <- "NC";
			}	
		}
				
		//assigning farmers demand group
		loop farmers over:Farmer{
			if ([24] contains farmers.agent_number){
				farmers.demand_group <- "D3";
			}else if ([14,23,19,17,16,15,22,18,20,21] contains farmers.agent_number){
				farmers.demand_group <- "D2";
			}else{
				farmers.demand_group <- "D1";
			}	
		}
		
		//assigning farmers potential irrigation area
		loop farmers over:Farmer{
			if ([24] contains farmers.agent_number){
				farmers.demand_group <- "D3";
			}else if ([14,23,19,17,16,15,22,18,20,21] contains farmers.agent_number){
				farmers.demand_group <- "D2";
			}else{
				farmers.demand_group <- "D1";
			}	
		}
		
	}
	
	action load_parameters { //changing parameters in simulation scenarios
		switch scenario {
			match "S1" {
				//scenario 1: Greater than the average
				ask Farmer {
					previous_wet_season <- 100; 
				}
			}
			match "S2" {
				//scenario 2: Less than the average
				ask Farmer {
					previous_wet_season <- 25; 
				}
			}
		}
	}
	
	action update_day_count type:int { 
		if(cycle = 0) {
			return 1;	
		}else{
			return day_count + 1;
		}
	}
}

species Pump {	
	int pump_numbe; // pump identification number
	string rotulo; // pump identification Source: GAN (2022).
	int agent_numb; //pump owner/farmer agent identification number
	string behavior_g; //behaviour group of the pump's owner (cooperative profile)
	string demand_gro; //demand group of the pump's owner. Source: Volken (2022).
	float area; // irrigation area of the land property. Source: GAN (2022).
	rgb color <- #grey;
}

species Regulator control: simple_bdi {
//	date fiscalization_date1 <- date("2020-07-01");
//	date fiscalization_date2 <- date("2020-08-01");
	float yellow_level <- 3.98; // meters
	float red_level <- 2.20; // meters
	predicate restriction_rule <- new_predicate('restriction_rule');
	predicate attention_rule <- new_predicate('attention_rule');
	
	plan regulate intention: regulate { // colocar prioridade 1
		if(current_date >= date("2020-08-01") or (current_level <= red_level)) { 
			do add_belief(restriction_rule);
		}else if(current_date >= date("2020-07-01") or (current_level <= yellow_level)) {
			do add_belief(attention_rule);
		}	
	}
		
	plan fiscalize_farmers intention: fiscalize_farmers{ //chamado antes de reduzir, suspender, antes de penalidades
		//list<Farmers> disob_farmers <- [];
		//loop farmers over:Farmers;
			//if farmers.consumed_volume > 0 when: date >= 2020-08-01 or farmers.consumed_volume > previous when: date >= 2020-07-01 {
				//add farmers to disob_farmers;
	}
	
	plan apply_penalties intention: apply_penalties{
		// loop farmers over Farmers
			//if farmers in disob_farmers
				//farmers.permit <- 0.5*permit //regulatory penalty // example value
				//atualizar tambem na tabela de permits do regulador
				//farmers.cash <- 0.9*farmers.cash //economic penalty // example value
	}	
}

species Farmer control: simple_bdi {
	int agent_number;
	string demand_group;
	list<Pump> owned_pumps; // list of owned pumps
	int number_of_pumps; // number of owned pumps 
	float pot_irrigation_area <- 1000; //potential irrigation area before alpha and beta factors [ha] //todo correct area assignment
	float total_irrigated_area update:crop_area();
	float alpha;// <- 1.0 update: previous_wet_season_reaction();  //previous wet season factor
	float beta <- 1.0; // neighbourhood effect factor
	float production update:crop_production(); //crop production [kg]
	float revenue update:crop_sell(); //revenue from selling crop production [R$] 
	float consumed_volume update: new_consumed_volume(); //consumed volume given by the irrigation area after application of alpha and beta [m3]
	float exp_irrigation_area update:choose_irrigation_area(); //expected irrigation after aplication of alpha and beta, calculated at the beginning of the simulation
	float daily_vol_per_area <- 55; // daily irrigation volume/irrigation area [m3/ha](transformation factor)
	float lower_alpha; // lower limit of alpha
	float upper_alpha; // upper limit of alpha
	string profile;
	float last_cons_vol; // last consumed volume corresponding to the final irrigation area to be sold as crop production
	float yellow_level <- 3.98; // meters
	float red_level <- 2.20; // meters
	
	//beliefs
	predicate less_than_average <- new_predicate("less available water than average");	
	predicate more_than_average <- new_predicate("more available water than average");	
	predicate attention_rule <- new_predicate("Attention rule is on");
	predicate restriction_rule <- new_predicate("Restriction rule is on");
	
	//intentions
	predicate obey_restriction_rule <- new_predicate("I will suspend water withdrawal");	
	predicate obey_attention_rule <- new_predicate("I will reduce my water consumption");
	predicate reduce_consumed_volume <- new_predicate('reduce_consumed_volume');
	predicate suspend_water_withdrawal <- new_predicate('suspend_water_withdrawal');

	
	reflex assign_alpha_limits when: (cycle = 0){ // assigning upper and lower limits of alpha for each farmer profile
		if(profile = "CP"){
				lower_alpha <- 0.89;
				upper_alpha <- 0.95;
		}else if(profile = "CI"){
				lower_alpha <- 0.92;
				upper_alpha <- 1.00;
		}else if(profile = "NC") {
				lower_alpha <- 1.00;
				upper_alpha <- 1.00;
		}
	}	
	
	reflex previous_wet_season_reaction when:(cycle=0) {
		float my_alpha <- 1.0;
		float my_alphaCP;
		float my_alphaCI;
		float my_alphaNC;
		
		if (previous_wet_season >= h_flow_average) {
				do add_belief(more_than_average);
				my_alpha <- 1.0;
			}else{
				do add_belief(less_than_average);
				
					if(profile = 'CP') {
						alpha <- rnd(0.89,0.95);
						my_alpha <- alpha;
						my_alphaCP <- my_alpha;
					}else if(profile = 'CI') {
						alpha <- rnd(0.92,1.00);
						my_alpha <- alpha;
						my_alphaCI <- my_alpha;
					}else if(profile = 'NC') {
						alpha <- 1.00;
						my_alpha <- alpha;
						my_alphaNC <- my_alpha;
					}
				
			}
		return my_alpha;
		
	}
	
	action choose_irrigation_area {
		exp_irrigation_area <- pot_irrigation_area*alpha*beta;
		return exp_irrigation_area ;
	}
	
	rule belief: attention_rule new_desire: reduce_consumed_volume;
	rule belief: restriction_rule new_desire: suspend_water_withdrawal;
	
	reflex assign_rules_reactions {
		bool aux_date_08 <- (current_date >= date("2020-08-01"));
		bool aux_date_07 <- (current_date >= date("2020-07-01"));
		bool aux_level_red <- (current_level <= red_level);
		bool aux_level_yellow <- (current_level <= yellow_level);
		
		
			if(profile = "CP"){
				if((aux_date_08) or (aux_level_red)){
					do add_belief(restriction_rule);
					consumed_volume <- 0.0*consumed_volume;
				}else if((aux_date_07) or (aux_level_yellow)){
					do add_belief(attention_rule);
					consumed_volume <- 0.75*consumed_volume;
					last_cons_vol <- consumed_volume;
				}
			}else if(profile = "CI"){
				if((aux_date_08) and (aux_level_red)){
					do add_belief(restriction_rule);
					consumed_volume <- 0.0*consumed_volume;
				}else if((aux_date_07) and (aux_level_yellow)) {
					do add_belief(attention_rule);
					consumed_volume <- 0.75*consumed_volume;
					last_cons_vol <- consumed_volume;
				}
			}else if(profile = "NC"){
				last_cons_vol <- consumed_volume;
			}
		}
	
	//Update consumed volume daily
	action new_consumed_volume {
		return exp_irrigation_area*daily_vol_per_area;
	}
	
		action crop_area{
		float total_irrigated_area <- last_cons_vol/daily_vol_per_area; // [m3/(m3/ha)] correlated with consumed volume 
		return total_irrigated_area; //[ha]
	}
	
	action crop_production {
		return total_irrigated_area*soybean_yield*1000; //[ha*kg/ha]
	}
	
	action crop_sell  {
		float production <- total_irrigated_area*soybean_yield*1000; //[ha*kg/ha]
		return production*sell_price; //[kg*R$/kg]
	}
//	action update_color {
//		if (aux_date_08) or (current_level <= red_level) and (consumed_volume>0){
//			owned_pumps.color <-#red;
//		}
//	}
		
}

experiment teste_batch type:batch until:(cycle=100) {
	parameter scenario var: scenario among: ["S1","S2"];
}

experiment  teste_gui type: gui {

	parameter "initial level" var:initial_level;
	parameter "previous wet season" var:previous_wet_season;
	// Define parameters here if necessary
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	output {
	// Define inspectors, browsers and displays here
	
	// inspect one_or_several_agents;
	//
	display "My display" { 
		species Pump;
	 }

	}
}