/**
* Name: FRBModel 
* Authors: Déborah S. Sousa, Cássio G. C. Coelho, Conceição de M. A. Alves, Célia G. Ralha.
* Tags: irrigation; water regulation
*/
model UrubuRiverModel

global {
	//INPUTS
	//Files: matrices and shapefiles
	file shapefile_pumps <- file("../includes/urubu_pumps.shp"); //irrigation pumps from GAN
	matrix farmers_data <- file("../includes/urubu_farmers.csv"); //Farmer agents information
	matrix pumps_data <- file("../includes/urubu_pumps_info.csv"); //Pumps information
	list<string> daily_date <- file("../includes/daily_date.txt");
	matrix<float> prob_CI <- file("../includes/CI-prob.csv");
	matrix<float> prob_NC <- file("../includes/NC-prob.csv");
	matrix<float> prob_CP <- file("../includes/CP-prob.csv");
	matrix<float> limits_withdrawal <- file("../includes/limits-withdrawal.csv");
	file shapefile_hidro <- file("../includes/streamwork.shp"); //irrigation channels from SEMARH	
	file shapefile_channels <- file("../includes/irrigation_channels.shp"); //irrigation channels from SEMARH
	file shapefile_land <- file("../includes/area_urubu.shp"); // agricultural properties in the Urubu river basin
	geometry shape <- envelope(shapefile_land);
	
	//Biennium Plan rules
	float yellow_level <- 3.98; // meters
	float red_level <- 2.20; // meters
	date attention_date <- date("2020-07-01");
	date restriction_date <- date("2020-08-01");
	/*********FICTIONAL**********/
	float initial_level <- 4.5; //fictional
	float current_level <- initial_level update:current_level - 0.05; // fictional //level variation at the reference gauging station [m] //might be given as an input of a hydrological model output
	//TODO adicionar a média dos níveis reais da estação de referência do Urubu para estação seca
	bool aux_level_red update:(current_level <= red_level);
	bool aux_level_yellow update:(current_level <= yellow_level);
	bool aux_date_08 update:(my_day >= restriction_date);
	bool aux_date_07 update:(my_day >= attention_date);
	date my_day <- starting_date update: update_my_date();
		
	//counters and time steps (dry season)
	date starting_date <- date("2020-04-30");
	float step <- 1 #day;
	int nb_days <- 123; //day count from the first to the last day of one dry season simulation
	string crop_season <- "soybean" among: ["soybean","rice"];
	int twoweeks_count update:update_twoweeks_count(cycle);	
	int day_in_twoweeks  update: update_day_in_twoweeks();

	action update_my_date type: date {
		if cycle>1 {
			date my_new_date <- daily_date[cycle-1]; 
			return my_new_date;
		} else {
			return starting_date;
		} 
	}
	
	action update_day_in_twoweeks type: int {
		if mod(cycle-1,15) != 0 or (cycle-1) >= 120 {
			return day_in_twoweeks + 1;
		} else {
			return 0;
		} 
	}
	
	action update_twoweeks_count (int cycle) type: int {
		if cycle = 0{
			return 0;
		}else if ((cycle-1) < 120) {
			return floor((cycle-1)/15);
		}else if ((cycle-1) >= 120) {
			return 7;
		}
	}
			
	//SCENARIOS
	//string scenario <- "S0"; //baseline
	string scenario <- "S1" ;//all CP
	//string scenario <- "S2"; //all NC	
	//string scenario <- "S3"; //all CI	
	
	//Demand group effect
	float n_CP; //fraction of CP farmers in a demand_group
	float n_CI; //fraction of CI farmers in a demand_group
	float n_NC; //fraction of NC farmers in a demand_group
	
	//COLLECTIVE VARIABLES IN OUTPUT	
	//list<float> f_daily_withdrawal update: Farmer collect sum (each.owned_pumps collect each.daily_withdrawal); //TODO
	list<float> all_pumps_daily_withdrawal update: Pump collect (each.daily_withdrawal);	

/***********
initial state****************/
	init {
		//loading parameters for scenarios simulation
		create Land from: shapefile_land;
		create Channel from: shapefile_channels;
		create Hidro from: shapefile_hidro;
		
		//creating the Pump agent
		create Pump from: shapefile_pumps;
		list<int> farmer_id_list <- Pump collect each.agent_numb;
		list<int> farmer_id_list <- remove_duplicates(Pump collect each.agent_numb);
		list<int> pump_id_list <- Pump collect each.pump_numbe;
		
		//creating the Farmer agent
		create Farmer number: length(farmer_id_list);
		int i <- 0;
		loop farmer over: Farmer {
			farmer.farmer_id <- farmer_id_list[i];
			i <- i + 1;
		}
		
		//creating the Regulator agent
		create Regulator;

		//relate farmers to profiles, demand group and area
		loop j from: 0 to: length(farmer_id_list) - 1 step: 1 {
			loop i from: 0 to: length(farmer_id_list) - 1 step: 1{
				int my_farmer_data_id <- int(farmers_data[0,i]);
				if Farmer[j].farmer_id = my_farmer_data_id{
					Farmer[j].irrigation_area <- farmers_data[5,i]; 
					Farmer[j].demand_group <- farmers_data[3,i];
					Farmer[j].nb_pumps <- length(Farmer[j].owned_pumps); // number of owned pumps	
				}
			}
		}	
		
		//Scenarios settings
		switch scenario {
			match 'S0'{
				loop j from: 0 to: length(farmer_id_list) - 1 step: 1 {
					loop i from: 0 to: length(farmer_id_list) - 1 step: 1{
						int my_farmer_data_id <- int(farmers_data[0,i]);
						if Farmer[j].farmer_id = my_farmer_data_id{
							Farmer[j].profile <- farmers_data[2,i];
						}
					}
				}
			}
		
			match 'S1'{
				loop farmer over:Farmer {
					farmer.profile <- 'CP';
				}
				
				loop pump over:Pump {
					pump.behavior_g <- 'CP';
				} 
			}
			
			match 'S2'{
				loop farmer over:Farmer {
					farmer.profile <- 'NC';
				}
				
				loop pump over:Pump {
					pump.behavior_g <- 'NC';
				} 
			}
			
			match 'S3'{
				loop farmer over:Farmer {
					farmer.profile <- 'CI';
				}
				
				loop pump over:Pump {
					pump.behavior_g <- 'CI';
				} 
			}
			
			match 'S4'{
				loop j from: 0 to: length(farmer_id_list) - 1 step: 1 {
					loop i from: 0 to: length(farmer_id_list) - 1 step: 1{
						int my_farmer_data_id <- int(farmers_data[0,i]);
						if Farmer[j].farmer_id = my_farmer_data_id{
							Farmer[j].profile <- farmers_data[2,i];
						}
					}
				}
				
				/*loop farmer over:Farmer{
					farmer.neighb_effect <- 'None';//assign_neighb_effect();	
				}*/
			}			
		}			
		
		//relate pumps' owners profiles to their probabilities matrixes
		loop pump over:Pump {
			if pump.behavior_g = 'CP'{
				pump.prob_matrix <- prob_CP;
			}else if pump.behavior_g = 'NC'{
				pump.prob_matrix <- prob_NC;
			}else if pump.behavior_g = 'CI'{
				pump.prob_matrix <- prob_CI;
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
		
		list<Farmer> mygroup1 <- Farmer where (each.demand_group = 'D1');
		list<Farmer> mygroup2 <- Farmer where (each.demand_group = 'D2');
		list<Farmer> mygroup3 <- Farmer where (each.demand_group = 'D3');
		
		//assign farmers list of peers according to demand group
		loop farmer over:Farmer {
			if farmer.demand_group = "D1" {
				farmer.my_group <- mygroup1;
			}else if farmer.demand_group = "D2" {
				farmer.my_group <- mygroup2;
			}else if farmer.demand_group = "D3" {
				farmer.my_group <- mygroup3;
			}
		}
		
		//neighb_effect for each demand group
		loop farmer over:Farmer{
			//if length(farmer.my_group) = 0
			farmer.n_CP <- length(farmer.my_group where (each.profile = 'CP'))/length(farmer.my_group);
			farmer.n_NC <- length(farmer.my_group where (each.profile = 'NC'))/length(farmer.my_group);
		}
							
	}/******END INIT*****/		
			
	reflex save_daily_data when: cycle > 1 {		
		//string day_of_the_year <- daily_date[cycle-1];
		//save [cycle,int(self),day_of_the_year,all_pumps_daily_withdrawal] to: "../results/cenarios/daily_withdrawal"+scenario+".csv"  type:csv rewrite:false header:false;				 
		//write 'ciclo '+cycle+' '+day_of_the_year+' '+' '+all_pumps_daily_withdrawal;
		//list<float> all_pumps_daily_withdrawal <- Pump collect (each.daily_withdrawal);	
		//save [cycle,int(self),day_of_the_year,all_pumps_daily_withdrawal]to: "../results/exemplo1.csv"  type:csv rewrite:false header:false;				
		//save [cycle,int(self),day_of_the_year,f_daily_withdrawal]to: "../results/daily_withdrawal-farmer-100.csv"  type:csv rewrite:false;
		//save [cycle,int(self),day_of_the_year,all_pumps_daily_withdrawal]to: "../results/daily_withdrawal-pumps-1000-keepseed"+scenario+"-init0.csv"  type:csv rewrite:false;
	}
	
	reflex end_simulation when:cycle=nb_days+2{
		do pause;
	}
}/******END GLOBAL*****/

species Pump {
	Pump pump;
	int pump_numbe;
	int pump_id; // pump identification number
	string rotulo; // pump identification. Source: GAN (2022).
	int agent_numb;
	matrix prob_matrix;
	list<float> p_list;
	Farmer pump_owner; //pump owner/farmer agent identification number
	string behavior_g; //behaviour group of the pump's owner (cooperative profile)
	string demand_gro; //demand group of the pump's owner. Source: Volken (2022).
	float irrigation_area; // irrigation area of the land property. Source: GAN (2022).
	int size <- 150;
	rgb color <- #black;
	float daily_withdrawal update:update_withdrawal(cycle);

	aspect default {
		draw circle(size) color:color border: #black;
	}
	
	action update_withdrawal (int cycle){
		ask pump_owner {
			if has_belief(trigger_restriction_rule){
				myself.daily_withdrawal <- 0.0;
			}else{
				list<float> p_list <- column_at(myself.prob_matrix,twoweeks_count);
				int interval_index <- rnd_choice(p_list);
				float a <- limits_withdrawal[0,interval_index];
				float b <- limits_withdrawal[1,interval_index];
				return rnd(a,b);
			}
		}
	}	
}

species Farmer control: simple_bdi {
	Farmer farmer;
	int farmer_id;
	string profile;
	string demand_group;
	list<Pump> owned_pumps; // list of owned pumps 
	list<Farmer> my_group;
	int nb_pumps;
	float irrigation_area; //potential irrigation area [ha]
	float f_daily_withdrawal update: update_f_withdrawal();
	string neighb_effect;
	rgb color <- #grey;
	float n_NC;
	float n_CP;
	
	reflex neighbors_beliefs {
		if n_NC > n_CP {
			do add_belief(new_predicate('Most are NC in my group'));
		}else if n_CP > n_NC {
			do add_belief(new_predicate('Most are CP in my group'));
		}else{
			do add_belief(new_predicate('No neighbourhood effect'));
		}
	}
	
	predicate trigger_attention_rule <- new_predicate("Attention rule must be obeyed");
	predicate trigger_restriction_rule <- new_predicate("Restriction rule must be obeyed");
	predicate obey_restriction_rule <- new_predicate("I am obeying the restriction rule");
	
	/*aspect default {
		draw circle(150) color: color border: #black;
	}*/

	action update_f_withdrawal {
		return sum(collect(owned_pumps,each.daily_withdrawal));
	}
	
	reflex assign_beliefs {
		if(profile = "CP"){
			if((aux_date_08) or (aux_level_red)){
				do add_belief(trigger_restriction_rule);
			}
		}else if (profile = 'CI'){
			if((aux_date_08) and (aux_level_red)){
				do add_belief(trigger_restriction_rule);
			}
		}
	}
	
	rule belief: trigger_restriction_rule new_desire: obey_restriction_rule;
	// como associar com as bombas?
	
	plan lets_obey_restriction intention:obey_restriction_rule when: trigger_restriction_rule = true {
		do adjust_withdrawal();	
	}
		
	action adjust_withdrawal{
		f_daily_withdrawal <- 0;
		loop pump over:owned_pumps{
			pump.daily_withdrawal <- 0;
		}
	}
	
	//Neighbourhood effect
		
	reflex assign_intentions{
		
	}
	
	reflex assign_colours{
		bool is_respecting_red_rules <- false;
		bool is_respecting_yellow_rules <- false;
		
		if ((aux_date_08) or (aux_level_red)) {
			if f_daily_withdrawal = 0 {
				is_respecting_red_rules <- true;
			}
		} else if ((aux_date_07) or (aux_level_yellow)) {
			if f_daily_withdrawal < 1000 {
				is_respecting_yellow_rules <- true;
			}
		}
		
		if (!(aux_date_08) and !(aux_level_red)){
			is_respecting_red_rules <- true;
		}

		if (!(aux_date_07) and !(aux_level_yellow)){
			is_respecting_yellow_rules <- true;
		}
		
		if (!is_respecting_red_rules or !is_respecting_yellow_rules){
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
}

species Regulator control:simple_bdi{
	date fiscalization_date1 <- attention_date;
	date fiscalization_date2 <- restriction_date;
	predicate restriction_rule <- new_predicate('restriction_rule');
	predicate attention_rule <- new_predicate('attention_rule');
	
	plan regulate intention: regulate { // colocar prioridade 1
		if(current_date >= restriction_date or (current_level <= red_level)) { 
			do add_belief(restriction_rule);
		}else if(current_date >= attention_date or (current_level <= yellow_level)) {
			do add_belief(attention_rule);
		}	
	}
		
	plan fiscalize intention:fiscalize when: current_date >=fiscalization_date1 priority:1{ //chamado antes de reduzir, suspender, antes de penalidades
		list<Farmer> disob_farmers <- [];
		loop farmer over:Farmer{
			if farmer.f_daily_withdrawal > 0.0 {
				add farmer to: disob_farmers;
			}	
		}
	}	
}

// Auxiliar species for GUI experiments
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

experiment teste_gui type: gui {
	output {
		display map refresh: every(1 #cycle) {
			species Hidro;
			species Channel;
			species Land;
			species Pump;
			species Farmer;
		}

		display Irrigation_per_pump refresh: every(1 #cycle) {
			chart "Individual water consumption (m³)" type: series {
				datalist Pump collect (each.rotulo) value: Pump collect (each.daily_withdrawal) style: line ;
			}
		}

		display Irrigation_per_farmer refresh: every(1 #cycle) {
			chart "Total water consumption (m³)" type: series {
				datalist Farmer collect string(each.farmer_id) value: Farmer collect sum (each.owned_pumps collect each.daily_withdrawal) style: line;
			}
		}
		
		display Irrigation_total refresh: every(1 #cycle) {
			chart "Total water consumption (m³)" type: series {
				data "All pumps" value: sum((Pump collect (each.daily_withdrawal))) style: line color: #black;
			}
		}

		display Irrigation_total_pump_profile refresh: every(1 #cycle) {
			chart "Water consumption (m³) per profile" type: series {
				data "CP" value: sum((Pump where (each.behavior_g = "CP")) collect (each.daily_withdrawal)) style: line color: #magenta;
				data "CI" value: sum((Pump where (each.behavior_g = "CI")) collect (each.daily_withdrawal)) style: line color: #cyan;
				data "NC" value: sum((Pump where (each.behavior_g = "NC")) collect (each.daily_withdrawal)) style: line color: #yellow;
			}
		}
		
		display Irrigation_total_pump_group refresh: every(1 #cycle) {
			chart "Water consumption (m³) per profile" type: series {
				data "D1" value: sum((Pump where (each.demand_gro = "D1")) collect (each.daily_withdrawal)) style: line color: #magenta;
				data "D2" value: sum((Pump where (each.demand_gro = "D2")) collect (each.daily_withdrawal)) style: line color: #cyan;
				data "D3" value: sum((Pump where (each.demand_gro = "D3")) collect (each.daily_withdrawal)) style: line color: #yellow;
			}
		}
		
		/*display AverageIrrigation_total_pump_profile refresh: every(1 #cycle) {
			chart "Average water consumption (m³) per pump per profile" type: series {
				data "CP" value: sum((Pump where (each.behavior_g = "CP")) collect (each.daily_withdrawal))*length(Pump)/length(Pump where(each.behavior_g = "CP")) color: #magenta;
				data "CI" value: sum((Pump where (each.behavior_g = "CI")) collect (each.daily_withdrawal))*length(Pump)/length(Pump where(each.behavior_g = "CI"))  color: #cyan;
				data "NC" value: sum((Pump where (each.behavior_g = "NC")) collect (each.daily_withdrawal))*length(Pump)/length(Pump where(each.behavior_g = "NC"))  color: #yellow;
			}
		}*/
	}
}

experiment repetitions type: batch repeat: 1 autorun: false keep_seed:true until: cycle = nb_days+2 { 	
	reflex end_of_runs {
		int sim <- 0;
		ask simulations { // no fim da simulação, para cada simulação
			sim <- sim + 1;	
		}
	}
}