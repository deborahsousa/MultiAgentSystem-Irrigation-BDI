/**
* Name: BDI
* Based on the internal empty template. 
* Author: desou
* Tags: 
*/

model Farmer

species FarmerBDI control: simple_bdi{
	float cash;
	int number_of_fields;
	int initial_sow_day <- 15;
	float price_tolerance;
	int max_simultaneous_crops;
	list private_data;
	float my_area;
	float water_level;
		
	float threshold_law <- 1.0;
	float threshold_obligation <- 1.0;
	float threshold_norm <- 0.5;	

	predicate green_level <- new_predicate("g_lvl");
	predicate yellow_level <- new_predicate("y_lvl");
	predicate red_level <- new_predicate("r_lvl");
	predicate emit_new_regulation <- new_predicate("new_reg");
	predicate intensify_regulation <- new_predicate("intensify_reg");
	predicate has_loan_money <- new_predicate("loan");
	predicate no_pumping_allowed <- new_predicate("no_pumping");
	predicate effective_regulation <- new_predicate("effective_reg");
	predicate cooperate_reg <- new_predicate("coop");
	predicate not_cooperate <- new_predicate("not coop");
	predicate profit_obey <- new_predicate("profit_obey");
	
	rule belief:"cooperative" new_desire: profit_obey;
	rule belief:"undefined" new_desire: profit_obey;
	rule belief:"resistant" new_desire: profit_obey;
	
	init{
		do add_desire(effective_regulation);
	}
	
	reflex update_color_level{
		if (water_level < 5.0){
			do add_belief(red_level);
		}
		else if (water_level < 8.0){
			do add_belief(yellow_level);
		}else{
			do add_belief(green_level);
		}
	}
	
	plan emit_new_regulation intention:intensify_regulation; 
		
	plan prohibit_pumping intention:intensify_regulation{
		do add_belief(no_pumping_allowed);	
	}
	
	reflex update_emission{
		if (water_level < 5.0){
			do add_belief(red_level);
		}
		if (water_level < 8.5){
			do add_belief(yellow_level);
		}else{
			do add_belief(green_level);
		}
	}
}

species CoopFarmer parent: FarmerBDI{
	
}

species UndefFarmer parent: FarmerBDI{
	
}

species ResFarmer parent: FarmerBDI{
	
}

// if he has a certain profile, then he should act like this or that
// decision making about water usage or crop area or obedience level
