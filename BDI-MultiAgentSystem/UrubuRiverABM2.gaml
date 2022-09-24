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
	matrix pumps_data <- file("../includes/urubu_pumps_info.csv"); //Pumps information
	matrix prob_CI <- file("../includes/CI-prob.csv");
	matrix prob_NC <- file("../includes/NC-prob.csv");
	matrix prob_CP <- file("../includes/CP-prob.csv");
	matrix limits_withdrawal <- file("../includes/limits-withdrawal.csv");
	file shapefile_hidro <- file("../includes/streamwork.shp"); //irrigation channels from SEMARH	
	file shapefile_channels <- file("../includes/irrigation_channels.shp"); //irrigation channels from SEMARH
	file shapefile_land <- file("../includes/area_urubu.shp"); // agricultural properties in the Urubu river basin
	geometry shape <- envelope(shapefile_land);
	
	//counters and time steps
	int day_count update: update_day_count();
	float step <- 1 #day;
	int nb_days <- 126;
	int initial_day <- 1; //day count
	int twoweeks_count <- 1 update: 1 + floor(day_count/15);
	string crop_season <- "soybean" among: ["soybean","rice"];
	int simulation_count <- 1 update: 1 + floor(cycle/365);
	int day_in_twoweeks <- 1 update: update_day_in_twoweeks() ;
	
	action update_day_count type: int {
		if mod(cycle,nb_days) != 0 {
			return day_count + 1;
		} else {
			return 1;
		}
	}	
	
	action update_day_in_twoweeks type: int {
		if mod(day_count,15) != 0 {
			return day_in_twoweeks + 1;
		} else {
			return 1;
		}
	}
	
	//economy
	/*float soybean_yield <- 3.5; // [ton/ha] //Soybean seed productivity of Tocantins state. Source: CONAB (avg 2017-2021).
	int crop_irrigation_dt <- 51; //crop cycle total duration (planting day to harvest day) [days]. Source: Fagundes (2021). 
	date starting_date <- date("2020-06-15"); //15th of June, beginning of irrigation period.
	date irrigation_end_date <- date("2020-08-05"); //05 of August, 51 days of irrigation, end of irrigation period. Source: Fagundes (2021). 
	int end_irrigation_period <- initial_day + crop_irrigation_dt; //number of days
	int start_irrigation_period <- initial_day + first_irrigation_dt;
	date starting_date <- date("2020-05-01"); //1st of May, beginning of the dry period.
	date irrigation_start_date <- date("2020-06-15"); //15 of June, beginning of irrigation period. Source: Fagundes (2021).
	int crop_cycle_dt <- 152 ; //crop cycle total duration (planting day to harvest day) [days]. Source: Fagundes (2021). 
	int end_cycle_period <- initial_day + crop_cycle_dt;
	int first_irrigation_dt <- 45;
	float sell_price <- 2.63; //[R$/kg]. Source: CONAB (2021).*/
	
	//hydrology
	/*float previous_wet_season <- 25.0; //Previous observed water supply (flow or precipitation).
	float h_flow_average <- 50.0; //Average observed water supply (flow or precipitation).
	float initial_level <- 4.5;
	float current_level <- initial_level update: current_level - 0.05; // level variation at the reference gauging station [m] //might be given as an input of a hydrological model output
	float yellow_level <- 3.98; // meters
	float red_level <- 2.20; // meters*/
	
	//scenarios
	string scenario <- "S2" ;//among: ["S1", "S2"]; //simulation scenarios

	//initial state
	init {
	// loading parameters for scenarios simulation
		//do load_parameters;
		create Land from: shapefile_land;
		create Channel from: shapefile_channels;
		create Pump from: shapefile_pumps;
		create Hidro from: shapefile_hidro;
		//		create Farmer from:shapefile_pumps with:[agent_number::(string(read("agent_numb")))]{

		list<int> farmer_id_list <- Pump collect each.agent_numb;
		list<int> farmer_id_list <- remove_duplicates(Pump collect each.agent_numb);
		list<int> pump_id_list <- Pump collect each.pump_numbe;
		
		//creating the Farmer agents
		create Farmer number: length(farmer_id_list);
		int i <- 0;
		loop farmer over: Farmer {
			farmer.farmer_id <- farmer_id_list[i];
			i <- i + 1;
		}

		//relate farmers to profiles, demand group and area
		loop j from: 0 to: length(farmer_id_list) - 1 step: 1 {
			loop i from: 0 to: length(farmer_id_list) - 1 step: 1{
				int my_farmer_data_id <- int(farmers_data[0,i]);
				if Farmer[j].farmer_id = my_farmer_data_id{
					Farmer[j].irrigation_area <- farmers_data[5,i]; 
					Farmer[j].demand_group <- farmers_data[3,i];
					Farmer[j].profile <- farmers_data[2,i];
					Farmer[j].nb_pumps <- length(Farmer[j].owned_pumps); // number of owned pumps	
				}
			}
		}	
		
		//relate pumps to farmers 
		loop i from: 0 to: length(pump_id_list) - 1 step: 1 {
			loop j from: 0 to: length(farmer_id_list) - 1 step: 1 {
				if Pump[i].agent_numb = Farmer[j].farmer_id {
					add Pump[i] to: Farmer[j].owned_pumps;
					Pump[i].pump_owner <- Farmer[j];
					Pump[i].irrigation_area <- Farmer[j].irrigation_area;
				}
			}
		}
		
		//relate pumps' owners profiles to their probabilities matrixes
		matrix prob_matrix;
		loop pump over:Pump {
			if pump.behavior_g = 'CP'{
				pump.prob_matrix <- prob_CP;
			}else if pump.behavior_g = 'NC'{
				pump.prob_matrix <- prob_NC;
			}else if pump.behavior_g = 'CI'{
				pump.prob_matrix <- prob_CI;
			}
		}
	}

	/*action load_parameters { //changing parameters in simulation scenarios
		switch scenario {
			match "S1" {
			//scenario 2: Less than the average
				ask Farmer {
					previous_wet_season <- 25.0;
				}
			}
			match "S2" {
			//scenario 1: Greater than the average
				ask Farmer {
					previous_wet_season <- 100.0;
				}
			}
		}
	}*/	
}

// espécie auxiliar
species Land {

	aspect default {
		draw shape color: #darkgreen border: #black;
	}
}

species Channel {

	aspect default {
		draw shape color: #black border: #black;
	}
}

species Hidro {

	aspect default {
		draw shape color: #blue border: #black;
	}
}

species Pump {
	Pump pump;
	int pump_numbe;
	int pump_id; // pump identification number
	string rotulo; // pump identification Source: GAN (2022).
	int agent_numb;
	matrix prob_matrix;
	float daily_withdrawal update: update_withdrawal;
	Farmer pump_owner; //pump owner/farmer agent identification number
	string behavior_g; //behaviour group of the pump's owner (cooperative profile)
	string demand_gro; //demand group of the pump's owner. Source: Volken (2022).
	float irrigation_area; // irrigation area of the land property. Source: GAN (2022).
	int size <- 150;
	rgb color <- #black;

	aspect default {
		draw circle(size) color: color border: #black;
	}
	
	reflex update_withdrawal when: (twoweeks_count < 9) {
		loop j from:0 to:7 {
			list p_list <- prob_matrix column_at j;
			map<int,float> prob_map <- create_map([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17],[p_list[0],p_list[1],p_list[2],p_list[3],p_list[4],p_list[5],p_list[6],p_list[7],p_list[8],p_list[9],p_list[10],p_list[11],p_list[12],p_list[13],p_list[14],p_list[15],p_list[16],p_list[17]]);
			int interval_index <- rnd_choice(prob_map);
			float a <- limits_withdrawal[0,interval_index];
			float b <- limits_withdrawal[1,interval_index];
			daily_withdrawal <- rnd(a,b);
		}
	}
}

species Regulator control: simple_bdi {
//	date fiscalization_date1 <- date("2020-07-01");
//	date fiscalization_date2 <- date("2020-08-01");
	float yellow_level <- 3.98; // meters
	float red_level <- 2.20; // meters
	predicate restriction_rule <- new_predicate('restriction_rule');
	predicate attention_rule <- new_predicate('attention_rule');
	/*plan regulate intention: regulate { // colocar prioridade 1
		if (current_date >= date("2020-08-01") or (current_level <= red_level)) {
			do add_belief(restriction_rule);
		} else if (current_date >= date("2020-07-01") or (current_level <= yellow_level)) {
			do add_belief(attention_rule);
		}
	}*/

	plan fiscalize_farmers intention: fiscalize_farmers { //chamado antes de reduzir, suspender, antes de penalidades
	//list<Farmers> disob_farmers <- [];
	//loop farmers over:Farmers;
	//if farmers.consumed_volume > 0 when: date >= 2020-08-01 or farmers.consumed_volume > previous when: date >= 2020-07-01 {
	//add farmers to disob_farmers;
	}

	plan apply_penalties intention: apply_penalties {
	// loop farmers over Farmers
	//if farmers in disob_farmers
	//farmers.permit <- 0.5*permit //regulatory penalty // example value
	//atualizar tambem na tabela de permits do regulador
	//farmers.cash <- 0.9*farmers.cash //economic penalty // example value
	}
}

species Farmer control: simple_bdi {
	Farmer farmer;
	int farmer_id;
	string profile;
	string demand_group;
	list<Pump> owned_pumps; // list of owned pumps 
	float irrigation_area; //potential irrigation area [ha]
	float f_daily_withdrawal update: update_f_withdrawal;
	int nb_pumps;
	/*float total_irrigated_area update: float(crop_area());
	float alpha <- 1.0; //previous wet season factor
	float beta <- 1.0; // neighbourhood effect factor
	float production update: float(crop_production()); //crop production [kg]
	float revenue update: float(crop_sell()); //revenue from selling crop production [R$] 
	float consumed_volume update: float(new_consumed_volume()); //consumed volume given by the irrigation area after application of alpha and beta [m3]
	float exp_irrigation_area <- pot_irrigation_area * alpha * beta update: float(choose_irrigation_area()); //expected irrigation after aplication of alpha and beta, calculated at the beginning of the simulation
	float daily_vol_per_area <- float(55); // daily irrigation volume/irrigation area [m3/ha](transformation factor)
	float lower_alpha; // lower limit of alpha
	float upper_alpha; // upper limit of alpha
	float last_cons_vol <- daily_vol_per_area * exp_irrigation_area; // last consumed volume corresponding to the final irrigation area to be sold as crop production*/
	rgb color <- #grey;

	aspect default {
		draw circle(150) color: color border: #black;
	}

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

	reflex update_f_withdrawal {
		f_daily_withdrawal <- sum(collect(owned_pumps,each.daily_withdrawal));
	}
	
	/*reflex assign_alpha_limits when: (cycle = 0) { // assigning upper and lower limits of alpha for each farmer profile
		if (profile = "CP") {
			lower_alpha <- 0.89;
			upper_alpha <- 0.95;
		} else if (profile = "CI") {
			lower_alpha <- 0.92;
			upper_alpha <- 1.00;
		} else if (profile = "NC") {
			lower_alpha <- 1.00;
			upper_alpha <- 1.00;
		}

		exp_irrigation_area <- float(choose_irrigation_area());
	}

	reflex previous_wet_season_reaction when: (cycle = 0) {
		float my_alpha <- 1.0;
		float my_alphaCP;
		float my_alphaCI;
		float my_alphaNC;
		if (previous_wet_season >= h_flow_average) {
			do add_belief(more_than_average);
			my_alpha <- 1.0;
		} else {
			do add_belief(less_than_average);
			if (profile = 'CP') {
				alpha <- rnd(0.89, 0.95);
				my_alpha <- alpha;
				my_alphaCP <- my_alpha;
			} else if (profile = 'CI') {
				alpha <- rnd(0.92, 1.00);
				my_alpha <- alpha;
				my_alphaCI <- my_alpha;
			} else if (profile = 'NC') {
				alpha <- 1.00;
				my_alpha <- alpha;
				my_alphaNC <- my_alpha;
			}
		}

		exp_irrigation_area <- float(choose_irrigation_area());
		return my_alpha;
	}

	reflex debug when: (cycle >= 0) {
		if (agent_number = 7) {
			write "" + current_date;
			write "" + current_level;
		}
	}

	action choose_irrigation_area {
		float aux_exp_irrigation_area <- pot_irrigation_area * alpha * beta;
		return aux_exp_irrigation_area;
	}

	rule belief: attention_rule new_desire: reduce_consumed_volume;
	rule belief: restriction_rule new_desire: suspend_water_withdrawal;

	reflex assign_rules_reactions {
		bool aux_data_08 <- (current_date >= date("2020-08-01"));
		bool aux_data_07 <- (current_date >= date("2020-07-01"));
		bool aux_level_red <- (current_level <= red_level);
		bool aux_level_yellow <- (current_level <= yellow_level);
		bool is_respecting_red_rules <- false;
		bool is_respecting_yellow_rules <- false;
		if (profile = "CP") {
			if ((aux_data_08) or (aux_level_red)) {
				do add_belief(restriction_rule);
				consumed_volume <- 0.0;
				is_respecting_red_rules <- true;
			} else if ((aux_data_07) or (aux_level_yellow)) {
				do add_belief(attention_rule);
				consumed_volume <- 0.75 * consumed_volume;
				is_respecting_yellow_rules <- true;
			}

		} else if (profile = "CI") {
			if ((aux_data_08) and (aux_level_red)) {
				do add_belief(restriction_rule);
				consumed_volume <- 0.0;
				is_respecting_red_rules <- true;
			} else if ((aux_data_07) and (aux_level_yellow)) {
				do add_belief(attention_rule);
				consumed_volume <- 0.75 * consumed_volume;
				is_respecting_yellow_rules <- true;
			}

		}
		last_cons_vol <- consumed_volume;
		
		if (!(aux_data_08) and !(aux_level_red)){
			is_respecting_red_rules <- true;
		}

		if(!(aux_data_07) and !(aux_level_yellow)){
			is_respecting_yellow_rules <- true;
		}
		
		if(!is_respecting_red_rules or !is_respecting_yellow_rules){
			loop pump over: owned_pumps {
				pump.color <- #red;
				pump.size <- 200;
			}
		}else{
			loop pump over: owned_pumps {
				pump.color <- #black;
				pump.size <- 150;
			}
		}
	}

	//Update consumed volume daily
	action new_consumed_volume {
		return exp_irrigation_area * daily_vol_per_area;
	}

	action crop_area {
		float aux_total_irrigated_area <- last_cons_vol / daily_vol_per_area; // [m3/(m3/ha)] correlated with consumed volume 
		return aux_total_irrigated_area; //[ha]
	}

	action crop_production {
		return total_irrigated_area * soybean_yield * 1000; //[ha*kg/ha]
	}

	action crop_sell {
		float aux_production <- total_irrigated_area * soybean_yield * 1000; //[ha*kg/ha]
		return aux_production * sell_price; //[kg*R$/kg]
		} 
	}*/
}

experiment teste_gui type: gui {
	//parameter scenario var: scenario among: ["S1", "S2"];
	output {
		display map refresh: every(1 #cycle) {
			species Hidro;
			species Channel;
			species Land;
			species Pump;
			species Farmer;
		}

		/*display levels refresh: every(1 #cycle) {
			chart "Stream level (m)" type: series {
				data "Initial level" value: initial_level style: line color: #blue;
				data "Yellow level" value: yellow_level style: line color: #yellow;
				data "Red level" value: red_level style: line color: #red;
				data "Current level" value: current_level style: line color: #black;
			}
		}*/

		display Irrigation_per_farmer {
			chart "Water consumption (m3) per farmer" type: series {
				data "farmer" value: Farmer collect (each.f_daily_withdrawal) style: line color: #magenta;
			}
		}
		
		display Irrigation_per_pump {
			chart "Water consumption (m3) per farmer" type: series {
				data "pump" value: Pump collect (each.daily_withdrawal) style: line color: #magenta;
			}
		}

		/*display Irrigation_per_profile {
			chart "Water consumption (m3) per profile" type: series {
				data "CP" value: sum((Farmer where (each.profile = "CP")) collect (each.f_daily_withdrawal)) style: line color: #magenta;
				data "CI" value: sum((Farmer where (each.profile = "CI")) collect (each.f_daily_withdrawal)) style: line color: #cyan;
				data "NC" value: sum((Farmer where (each.profile = "NC")) collect (each.f_daily_withdrawal)) style: line color: #yellow;
			}
		}
		
		display Irrigatior_demand_group {
			chart "Water consumption (m3) per demand group" type: series {
				data "D1" value: sum((Farmer where (each.demand_group = "D1")) collect (each.f_daily_withdrawal)) style: line color: #magenta;
				data "D2" value: sum((Farmer where (each.demand_group = "D2")) collect (each.f_daily_withdrawal)) style: line color: #cyan;
				data "D3" value: sum((Farmer where (each.demand_group = "D3")) collect (each.f_daily_withdrawal)) style: line color: #yellow;
			}
		} */
		
		/*display Revenue {
			chart "Revenue (BRL)" type: series {
				data "CP" value: sum((Farmer where (each.profile = "CP")) collect (each.revenue)) style: line color: #magenta;
				data "CI" value: sum((Farmer where (each.profile = "CI")) collect (each.revenue)) style: line color: #cyan;
				data "NC" value: sum((Farmer where (each.profile = "NC")) collect (each.revenue)) style: line color: #yellow;
			}
		}*/
	}
	
	reflex daily_withdrawal_per_pump{	//saves daily_data in a csv file	
		save[	
			sum((Farmer where (each.profile = "CP")) collect (each.f_daily_withdrawal))
			] to: "../results/daily_withdrawal_CP.csv" type: "csv" rewrite:false;
				
		save[	
			sum((Farmer where (each.profile = "NC")) collect (each.f_daily_withdrawal))
			] to: "../results/daily_withdrawal_NC.csv" type: "csv" rewrite:false;		
					
		save[	
			sum((Farmer where (each.profile = "CI")) collect (each.f_daily_withdrawal))
			] to: "../results/daily_withdrawal_CI.csv" type: "csv" rewrite:false;
		
		save[	
			Pump collect (each.daily_withdrawal)
			] to: "../results/daily_withdrawal_pumps.csv" type: "csv" rewrite:false;
	}
}

experiment teste_batch type: batch 	keep_seed: false until: cycle = 500*nb_days {
	
}